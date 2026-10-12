/// Local-only confirmed OCR/solution drafts. Kept outside the sync protocol
/// until S13 has an explicit server contract. Included in wipe/purge/export
/// and the whole-file encryption migration (not just syncTables).
const String createStudyDocuments = '''
CREATE TABLE study_documents (
 id TEXT NOT NULL PRIMARY KEY,
 user_id TEXT NOT NULL,
 purge_epoch INTEGER NOT NULL,
 revision INTEGER NOT NULL CHECK (revision > 0),
 kind TEXT NOT NULL CHECK (kind IN ('text', 'math')),
 text TEXT NOT NULL,
 transcription_json TEXT NOT NULL,
 solution_json TEXT,
 planner_item_id TEXT,
 updated_at TEXT NOT NULL
)
''';
