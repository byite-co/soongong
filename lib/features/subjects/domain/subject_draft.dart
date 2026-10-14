// SubjectDraft (S09, pure Dart): the add/edit sheet's working copy — name
// (≤ 20 chars, unique among live subjects) and one of the 8 subject colours
// (unique among live subjects: two subjects never share a colour, PRD §8).

import '../../../core/domain/entities/entities.dart';
import '../../../core/theme/tokens.dart' show AppSubjectColors;

enum SubjectDraftError { nameEmpty, nameTooLong, nameDuplicate, colorTaken }

class SubjectDraft {
  const SubjectDraft({this.name = '', this.colorIndex = 0});

  static const int nameMaxLength = 20;
  static const int colorCount = AppSubjectColors.count;

  final String name;
  final int colorIndex;

  String get trimmedName => name.trim();

  factory SubjectDraft.fromSubject(Subject s) => SubjectDraft(name: s.name, colorIndex: s.colorIndex);

  SubjectDraft copyWith({String? name, int? colorIndex}) =>
      SubjectDraft(name: name ?? this.name, colorIndex: colorIndex ?? this.colorIndex);

  /// Colours already used by live subjects other than [editingId].
  static Set<int> takenColors(Iterable<Subject> live, {String? editingId}) => <int>{
        for (final s in live)
          if (s.id != editingId) s.colorIndex,
      };

  /// First free colour, or null when all 8 are in use (then no new subject).
  static int? firstFreeColor(Iterable<Subject> live) {
    final taken = takenColors(live);
    for (var i = 0; i < colorCount; i++) {
      if (!taken.contains(i)) return i;
    }
    return null;
  }

  List<SubjectDraftError> validate(Iterable<Subject> live, {String? editingId}) {
    final errors = <SubjectDraftError>[];
    final n = trimmedName;
    if (n.isEmpty) {
      errors.add(SubjectDraftError.nameEmpty);
    } else if (n.length > nameMaxLength) {
      errors.add(SubjectDraftError.nameTooLong);
    } else if (live.any((s) => s.id != editingId && s.name.trim().toLowerCase() == n.toLowerCase())) {
      errors.add(SubjectDraftError.nameDuplicate);
    }
    if (takenColors(live, editingId: editingId).contains(colorIndex)) errors.add(SubjectDraftError.colorTaken);
    return errors;
  }

  bool differsFrom(Subject s) => trimmedName != s.name || colorIndex != s.colorIndex;
}
