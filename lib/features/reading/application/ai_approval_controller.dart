import '../../../core/contracts/transcription_engine.dart';
import '../../../core/domain/ids.dart';
import '../../../data/engines/transcription/remote_ai_jobs.dart';

class AiQuote {
  AiQuote(Map<String, dynamic> json)
    : id = json['quote_id'] as String,
      operation = json['operation'] as String,
      points = json['points'] as int,
      terms = json['terms_version'] as String {
    if (json['version'] != 2 ||
        points <= 0 ||
        terms.isEmpty ||
        terms.length > 200 ||
        !RegExp(r'^[0-9a-f-]{36}$').hasMatch(id)) {
      throw const FormatException('invalid_quote');
    }
  }
  final String id, operation, terms;
  final int points;
}

/// One screen operation owns the presenter. An old dialog cannot approve a
/// replacement operation; ownership/consent are checked around every await.
class AiApprovalController {
  Object? _ticket;
  bool Function()? _valid;
  Future<bool> Function(AiQuote)? _present;
  int _generation = 0;
  String? requestId;
  void Function() bind({
    required bool Function() valid,
    required int generation,
    required Future<bool> Function(AiQuote) present,
  }) {
    if (_ticket != null) throw StateError('approval_busy');
    final ticket = Object();
    _ticket = ticket;
    _valid = valid;
    _present = present;
    _generation = generation;
    requestId = null;
    return () {
      if (identical(_ticket, ticket)) {
        _ticket = null;
        _valid = null;
        _present = null;
      }
    };
  }

  void check() {
    if (_ticket == null || _valid?.call() != true) {
      throw const StudyEngineException('approval_cancelled');
    }
  }

  void close() {
    _ticket = null;
    _valid = null;
    _present = null;
  }

  Future<AiApproval> approve(
    RemoteAiJobs jobs,
    String operation,
    int epoch,
  ) async {
    check();
    final ticket = _ticket;
    void guard() {
      check();
      if (!identical(ticket, _ticket)) {
        throw const StudyEngineException('approval_cancelled');
      }
    }

    // Re-read before dispatch. A changed policy needs a new explicit decision.
    var quote = AiQuote(await jobs.quote(operation, epoch));
    guard();
    for (var changes = 0; changes < 3; changes++) {
      if (quote.operation != operation) {
        throw const FormatException('invalid_quote');
      }
      if (!await _present!(quote)) {
        throw const StudyEngineException('approval_cancelled');
      }
      guard();
      final latest = AiQuote(await jobs.quote(operation, epoch));
      guard();
      if (latest.id == quote.id &&
          latest.operation == quote.operation &&
          latest.points == quote.points &&
          latest.terms == quote.terms) {
        requestId = newUuid();
        return AiApproval(
          requestId: requestId!,
          quoteId: quote.id,
          operation: operation,
          epoch: epoch,
          generation: _generation,
        );
      }
      quote = latest;
    }
    throw const StudyEngineException('quote_changed');
  }
}
