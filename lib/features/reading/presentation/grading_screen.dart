import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/contracts/reading_engine.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/entities/subject.dart';
import '../../../core/domain/ids.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/photos/owned_picker_coordinator.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/temp/owned_temp_store.dart';
import '../../../data/temp/temp_providers.dart';
import '../../measure/application/measure_controller.dart';
import '../application/study_providers.dart';

final _subjects = StreamProvider.autoDispose(
  (ref) => ref.watch(subjectRepositoryProvider).watchAll(),
);
final _readingRequests = StreamProvider.autoDispose(
  (ref) => ref.watch(readingRepositoryProvider).watchByStatus({
    ReadingRequestStatus.processing,
    ReadingRequestStatus.takingLong,
    ReadingRequestStatus.doneUnsaved,
  }),
);

class GradingScreen extends ConsumerStatefulWidget {
  const GradingScreen({super.key, this.plannerItemId});
  final String? plannerItemId;
  @override
  ConsumerState<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends ConsumerState<GradingScreen> {
  final range = TextEditingController();
  Uint8List? image;
  String? subject, id, message;
  int? generation;
  int operation = 0;
  bool busy = false, agreed = false, saved = false;
  ReadingResult? result;
  QuotaSnapshot? quota;
  final marks = <String, Mark?>{};
  final wrongIds = <String, String>{};
  StreamSubscription<ReadingStatus>? subscription;
  OwnedTempTask? task;
  @override
  void dispose() {
    operation++;
    subscription?.cancel();
    task?.cleanup();
    image?.fillRange(0, image!.length, 0);
    range.dispose();
    super.dispose();
  }

  String key(int page, int number) => '$page:$number';
  void reset() {
    operation++;
    subscription?.cancel();
    task?.cleanup();
    task = null;
    image?.fillRange(0, image!.length, 0);
    setState(() {
      image = null;
      result = null;
      marks.clear();
      wrongIds.clear();
      id = null;
      busy = false;
      agreed = false;
      saved = false;
      generation = null;
    });
  }

  Future<void> pick(ImageSource source) async {
    if (busy ||
        (source == ImageSource.camera &&
            ref.read(measureControllerProvider).isLive))
      return;
    final op = ++operation;
    final owner = ref.read(currentUserIdProvider);
    final writer = ref.read(syncWriterProvider);
    final ownership = ref.read(tempOwnershipProvider);
    final token = ownership.epoch(owner);
    bool current() =>
        mounted &&
        op == operation &&
        ref.read(currentUserIdProvider) == owner &&
        ownership.epoch(owner) == token;
    setState(() => busy = true);
    try {
      generation = await writer.refreshPurgeGeneration();
      final picked = await ref
          .read(ownedPickerCoordinatorProvider)
          .pick(
            source,
            createTask: () => ownership.create(
              writer,
              'picker',
              generation: generation!,
              alive: current,
            ),
          );
      if (picked == null) return;
      try {
        if (await picked.length() > 4194304)
          throw const FormatException('image_too_large');
        final bytes = await picked.readAsBytes();
        if (!current()) {
          bytes.fillRange(0, bytes.length, 0);
          return;
        }
        setState(() {
          image?.fillRange(0, image!.length, 0);
          image = bytes;
          result = null;
          id = null;
          marks.clear();
          saved = false;
          agreed = false;
        });
      } finally {
        await picked.cleanup();
      }
    } on Object {
      if (current()) setState(() => message = '사진을 읽지 못했습니다. 다시 선택해 주세요.');
    } finally {
      if (current()) setState(() => busy = false);
    }
  }

  void watch(String requestId) {
    subscription?.cancel();
    final op = operation;
    final owner = ref.read(currentUserIdProvider);
    subscription = ref
        .read(readingEngineProvider)
        .watch(requestId)
        .listen(
          (status) {
            if (!mounted ||
                op != operation ||
                ref.read(currentUserIdProvider) != owner)
              return;
            setState(() {
              if (status is Done) {
                result = status.result;
                marks.clear();
                for (final p in result!.pages) {
                  for (final i in p.items) {
                    marks[key(p.index, i.number)] = i.mark;
                  }
                }
                message = '표시와 문항 번호를 확인하고 각 표시를 확정해 주세요. 미검출 문항은 추가할 수 있습니다.';
              } else if (status is Deleted || status is NotFound) {
                result = null;
                message = '요청이 없거나 삭제되었습니다.';
              } else if (status is Failed) {
                message = '판독 종료: ${status.reason}';
              } else {
                message = status is TakingLong ? '판독이 지연되고 있습니다.' : '판독 중입니다.';
              }
            });
          },
          onError: (Object _) {
            if (mounted && op == operation)
              setState(() => message = '상태 조회 실패 · 이전 요청에서 다시 조회할 수 있습니다.');
          },
        );
  }

  Future<void> submit() async {
    if (busy ||
        image == null ||
        !agreed ||
        subject == null ||
        range.text.trim().isEmpty)
      return;
    final gate = ref.read(authGateProvider);
    if (gate is! AuthGateSignedIn ||
        gate.profile?.readingConsentActive != true) {
      setState(() => message = '판독 동의가 필요합니다.');
      return;
    }
    final op = ++operation;
    final owner = gate.userId;
    final repo = ref.read(readingRepositoryProvider);
    final engine = ref.read(readingEngineProvider);
    bool current() =>
        mounted &&
        operation == op &&
        ref.read(currentUserIdProvider) == owner &&
        repo.writer.purgeGeneration == generation;
    setState(() => busy = true);
    try {
      generation = await repo.writer.refreshPurgeGeneration();
      quota = await engine.quota();
      if (!current()) return;
      final draft = await repo.writer.runOwnedTransaction(
        () => repo.createDraft(
          subjectId: subject!,
          rangeText: range.text.trim(),
          origin: widget.plannerItemId == null
              ? ReadingOrigin.home
              : ReadingOrigin.planner,
          plannerItemId: widget.plannerItemId,
        ),
        generation: generation,
        alive: current,
      );
      id = draft.requestId;
      task = await ref
          .read(tempOwnershipProvider)
          .create(
            repo.writer,
            'picker',
            generation: generation!,
            alive: current,
          );
      final file = task!.file('page.jpg');
      await file.writeAsBytes(image!, flush: true);
      task!.check();
      final outcome = await engine.submit(
        ReadingJob(
          requestId: id!,
          subjectId: subject!,
          rangeText: range.text.trim(),
          photoPaths: [file.path],
          origin: draft.origin.wire,
          plannerItemId: widget.plannerItemId,
        ),
      );
      if (!current()) return;
      if (outcome is SubmitAccepted) {
        watch(id!);
      } else if (outcome is SubmitActiveExists) {
        id = outcome.requestId;
        watch(id!);
      } else {
        setState(
          () => message = switch (outcome) {
            SubmitQuotaExhausted() => '이번 달 판독 횟수를 모두 사용했습니다.',
            SubmitNotEntitled() => '판독 이용 권한이 없습니다.',
            SubmitConsentRequired() => '판독 동의가 필요합니다.',
            SubmitOffline() => '전송 결과를 확인하지 못했습니다. 같은 요청을 조회해 주세요.',
            _ => '요청이 거절되었습니다.',
          },
        );
      }
    } on Object {
      if (current())
        setState(() => message = '판독을 시작하지 못했습니다. 개발 설정과 이용 권한을 확인해 주세요.');
    } finally {
      await task?.cleanup();
      task = null;
      if (current()) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy ||
        id == null ||
        result == null ||
        marks.isEmpty ||
        marks.values.any((m) => m == null))
      return;
    final requestId = id!;
    final op = operation;
    final engine = ref.read(readingEngineProvider);
    final confirmed = <ConfirmedMark>[];
    final items = <WrongItemDraft>[];
    for (final entry in marks.entries) {
      final parts = entry.key.split(':');
      final page = int.parse(parts[0]), number = int.parse(parts[1]);
      final mark = entry.value!;
      final wrong = mark == Mark.correct
          ? null
          : wrongIds.putIfAbsent(entry.key, newUuid);
      confirmed.add(
        ConfirmedMark(
          pageIndex: page,
          number: number,
          mark: mark,
          wrongItemId: wrong,
        ),
      );
      if (wrong != null)
        items.add(
          WrongItemDraft(
            id: wrong,
            pageIndex: page,
            number: number,
            mark: mark,
            confidence: null,
            userConfirmed: true,
          ),
        );
    }
    setState(() => busy = true);
    try {
      final outcome = await engine.save(requestId, confirmed, items);
      if (!mounted || op != operation) return;
      setState(() {
        saved = outcome is SaveSaved || outcome is SaveAlreadySaved;
        message = saved
            ? '확정한 오답과 복습 초깃값을 저장했습니다.'
            : '저장하지 못했습니다. 교정 내용은 유지됩니다.';
      });
    } finally {
      if (mounted && op == operation) setState(() => busy = false);
    }
  }

  Future<void> addNumber(int page) async {
    final controller = TextEditingController();
    final op = operation;
    final number = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('문항 번호 추가'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(controller.text);
              if (n != null && n >= 0 && n <= 999999) Navigator.pop(dialog, n);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (mounted && op == operation && number != null)
      setState(() => marks.putIfAbsent(key(page, number), () => null));
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(_subjects).asData?.value ?? <Subject>[];
    final pending = ref.watch(_readingRequests).asData?.value ?? [];
    ref.listen(currentUserIdProvider, (_, _) => reset());
    ref.listen(studyGenerationProvider, (_, next) {
      if (generation != null &&
          next.asData?.value != null &&
          next.asData!.value != generation)
        reset();
    });
    ref.listen(tempInvalidationProvider, (_, next) {
      if (next.asData?.value == ref.read(currentUserIdProvider)) reset();
    });
    ref.listen(authGateProvider, (_, next) {
      if (next is! AuthGateSignedIn ||
          next.profile?.readingConsentActive != true)
        reset();
    });
    final enabled = AppConfig.devOcrEnabled && AppConfig.hasBackendConfig;
    return Scaffold(
      appBar: AppBar(title: const Text('채점표시 판독')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '문항 번호와 채점표시 후보를 읽습니다. 모든 결과를 직접 확인해야 합니다. 신규 AI 포인트는 차감하지 않으며 기존 판독 횟수를 사용합니다.',
          ),
          if (!enabled) const Text('현재 빌드에서는 개발 판독이 꺼져 있습니다.'),
          DropdownButton<String>(
            value: subjects.any((s) => s.id == subject) ? subject : null,
            hint: const Text('과목 선택'),
            items: subjects
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: busy ? null : (v) => setState(() => subject = v),
          ),
          TextField(
            controller: range,
            enabled: !busy,
            decoration: const InputDecoration(labelText: '학습 범위'),
            maxLength: 500,
          ),
          TextButton(
            onPressed: enabled && !busy
                ? () => pick(ImageSource.gallery)
                : null,
            child: const Text('사진 선택'),
          ),
          TextButton(
            onPressed:
                enabled && !busy && !ref.watch(measureControllerProvider).isLive
                ? () => pick(ImageSource.camera)
                : null,
            child: const Text('촬영'),
          ),
          if (image != null)
            Image.memory(
              image!,
              height: 230,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text('지원하지 않는 사진'),
            ),
          CheckboxListTile(
            value: agreed,
            onChanged: busy ? null : (v) => setState(() => agreed = v ?? false),
            title: const Text('선택한 사진을 판독 서버로 전송하는 데 동의합니다. 처리 후 삭제됩니다.'),
          ),
          FilledButton(
            onPressed: enabled && !busy && agreed ? submit : null,
            child: const Text('기존 판독 횟수로 실행'),
          ),
          if (quota != null) Text('조회 시 남은 판독: ${quota!.remaining}회'),
          if (message != null) Text(message!),
          if (id != null && result == null) ...[
            TextButton(
              onPressed: busy ? null : () => watch(id!),
              child: const Text('같은 요청 조회'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final op = operation;
                      final out = await ref
                          .read(readingEngineProvider)
                          .cancel(id!);
                      if (!mounted || op != operation) return;
                      setState(
                        () => message = out is CancelCancelled
                            ? '취소됨'
                            : out is CancelAlreadyDone
                            ? '완료가 먼저 처리되었습니다. 다시 조회해 주세요.'
                            : '이미 종료된 요청입니다.',
                      );
                    },
              child: const Text('취소 요청'),
            ),
          ],
          for (final p in result?.pages ?? <ReadingPage>[]) ...[
            Text('${p.index + 1}쪽 · 원본과 문항 번호를 대조해 주세요.'),
            for (final entry in marks.entries.where(
              (e) => e.key.startsWith('${p.index}:'),
            ))
              Row(
                children: [
                  Text('${entry.key.split(':')[1]}번'),
                  const SizedBox(width: 12),
                  DropdownButton<Mark>(
                    value: entry.value,
                    hint: const Text('확인 필요'),
                    items: Mark.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(switch (m) {
                              Mark.correct => '정답',
                              Mark.wrong => '오답',
                              Mark.partial => '부분 정답',
                              Mark.unsolved => '미풀이',
                              Mark.guessed => '추측',
                            }),
                          ),
                        )
                        .toList(),
                    onChanged: busy || saved
                        ? null
                        : (m) => setState(() => marks[entry.key] = m),
                  ),
                  IconButton(
                    tooltip: '번호 제거 후 올바른 번호로 추가',
                    onPressed: busy || saved
                        ? null
                        : () => setState(() => marks.remove(entry.key)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            TextButton(
              onPressed: busy || saved ? null : () => addNumber(p.index),
              child: const Text('미검출 문항 추가'),
            ),
          ],
          if (result != null)
            FilledButton(
              onPressed:
                  busy ||
                      saved ||
                      marks.isEmpty ||
                      marks.values.any((m) => m == null)
                  ? null
                  : save,
              child: const Text('모든 표시 확인 · 오답 저장'),
            ),
          const Text('이전 판독 요청'),
          for (final request in pending)
            ListTile(
              title: Text(request.rangeText),
              onTap: busy
                  ? null
                  : () {
                      id = request.requestId;
                      generation = ref.read(syncWriterProvider).purgeGeneration;
                      watch(id!);
                    },
            ),
        ],
      ),
    );
  }
}
