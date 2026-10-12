import 'dart:typed_data';

enum TranscriptionKind { text, math }

/// Coordinates are fractions of the upright image. No file path crosses
/// this boundary; images live only for the current, explicitly consented call.
class TranscriptionBlock {
  const TranscriptionBlock({required this.text, required this.box, this.confidence});
  final String text;
  final List<double> box;
  final double? confidence;

  factory TranscriptionBlock.fromJson(Map<String, dynamic> value) {
    final text = value['text'];
    final raw = value['box'];
    final score = value['confidence'];
    if (text is! String || text.length > 20000 || raw is! List || raw.length != 4) {
      throw const FormatException('invalid_transcription');
    }
    final box = raw.map((v) => v is num ? v.toDouble() : double.nan).toList();
    if (box.any((v) => !v.isFinite || v < 0 || v > 1) || box[0] > box[2] || box[1] > box[3] ||
        (score != null && (score is! num || !score.isFinite || score < 0 || score > 1))) {
      throw const FormatException('invalid_transcription');
    }
    return TranscriptionBlock(text: text, box: List.unmodifiable(box), confidence: (score as num?)?.toDouble());
  }

  Map<String, Object?> toJson() => {'text': text, 'box': box, 'confidence': confidence};
}

class DocumentTranscription {
  const DocumentTranscription({required this.kind, required this.blocks, required this.engine});
  final TranscriptionKind kind;
  final List<TranscriptionBlock> blocks;
  final String engine;
  String get text => blocks.map((b) => b.text).join('\n');

  factory DocumentTranscription.fromJson(Map<String, dynamic> value) {
    if (value['schema_version'] != 1 || value['engine'] is! String ||
        (value['engine'] as String).length > 200 || value['blocks'] is! List ||
        (value['blocks'] as List).length > 500) {
      throw const FormatException('invalid_transcription');
    }
    final kind = switch (value['kind']) {
      'text' => TranscriptionKind.text,
      'math' => TranscriptionKind.math,
      _ => throw const FormatException('invalid_transcription'),
    };
    final blocks = (value['blocks'] as List).map((v) => TranscriptionBlock.fromJson(Map<String, dynamic>.from(v as Map))).toList();
    if (blocks.fold<int>(0, (n, b) => n + b.text.length + 1) > 20000) {
      throw const FormatException('invalid_transcription');
    }
    return DocumentTranscription(kind: kind, blocks: List.unmodifiable(blocks), engine: value['engine'] as String);
  }

  Map<String, Object?> toJson() => {
    'schema_version': 1, 'kind': kind.name, 'engine': engine,
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };
}

class StudyEngineException implements Exception {
  const StudyEngineException(this.code);
  final String code;
  @override
  String toString() => 'StudyEngineException($code)';
}

abstract interface class TranscriptionEngine {
  Future<DocumentTranscription> transcribe(Uint8List image, TranscriptionKind kind, {required int epoch});
}
