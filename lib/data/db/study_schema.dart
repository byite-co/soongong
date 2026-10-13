/// v3 body layout stays exact for safe historical recovery. In v4 this table
/// contains only available bodies; metadata-only documents live separately.
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

const String createStudyMetadata = '''
CREATE TABLE study_metadata (
 id TEXT NOT NULL PRIMARY KEY,
 user_id TEXT NOT NULL,
 purge_epoch INTEGER NOT NULL,
 revision INTEGER NOT NULL CHECK (revision > 0),
 kind TEXT NOT NULL CHECK (kind IN ('text', 'math')),
 title TEXT NOT NULL CHECK (length(title) <= 80),
 has_body INTEGER NOT NULL CHECK (has_body IN (0,1)),
 has_solution INTEGER NOT NULL CHECK (has_solution IN (0,1)),
 has_photo INTEGER NOT NULL CHECK (has_photo IN (0,1)),
 cache_state TEXT NOT NULL CHECK (cache_state IN ('missing','loading','available','error')),
 deleted INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1)),
 server_seq INTEGER,
 updated_at TEXT NOT NULL
)
''';

const String backfillStudyMetadata = '''
INSERT INTO study_metadata
(id,user_id,purge_epoch,revision,kind,title,has_body,has_solution,has_photo,cache_state,updated_at)
SELECT id,user_id,purge_epoch,revision,kind,
substr(trim(replace(replace(replace(text,char(13),' '),char(10),' '),char(9),' ')),1,80),
1,CASE WHEN solution_json IS NULL THEN 0 ELSE 1 END,0,'available',updated_at
FROM study_documents
''';
