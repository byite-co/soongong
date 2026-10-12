-- Uses okbob/plpgsql_check's documented active-mode API. This is a diagnostic
-- baseline, not a replacement for pgTAP's ownership / ledger / epoch tests.
-- Run ONLY against the disposable test database, after migrations and pgTAP.
-- Dynamic SQL / polymorphic records can require runtime context. Diagnostics
-- are visible in CI; do not suppress existing findings to fabricate a clean gate.
BEGIN;
CREATE EXTENSION IF NOT EXISTS plpgsql_check;
CREATE TEMP TABLE static_diagnostics (
  routine text, relation text, line integer, level text, sqlstate text, message text
);
DO $$
DECLARE f record;
BEGIN
  FOR f IN
    SELECT p.oid, p.oid::regprocedure::text AS routine,
           COALESCE(t.tgrelid, 0)::oid AS relid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_language l ON l.oid = p.prolang
    LEFT JOIN pg_trigger t ON t.tgfoid = p.oid AND NOT t.tgisinternal
    WHERE n.nspname = 'public' AND l.lanname = 'plpgsql'
      AND p.prokind IN ('f', 'p')
      AND p.prorettype <> 'event_trigger'::regtype
      AND (p.prorettype <> 'trigger'::regtype OR t.tgrelid IS NOT NULL)
      AND NOT EXISTS (
        SELECT FROM pg_depend d WHERE d.classid = 'pg_proc'::regclass
          AND d.objid = p.oid AND d.deptype = 'e'
      )
    ORDER BY p.oid, t.tgrelid
  LOOP
    BEGIN
      INSERT INTO static_diagnostics
      SELECT f.routine, CASE WHEN f.relid = 0 THEN NULL ELSE f.relid::regclass::text END,
             c.lineno, c.level, c.sqlstate, c.message
      FROM plpgsql_check_function_tb(f.oid::regprocedure, f.relid::regclass,
        fatal_errors := false, performance_warnings := true,
        security_warnings := true) c;
    EXCEPTION WHEN OTHERS THEN
      -- Record unsupported/context-dependent checks explicitly, not silently.
      INSERT INTO static_diagnostics VALUES
        (f.routine, NULL, NULL, 'checker_exception', SQLSTATE, SQLERRM);
    END;
  END LOOP;
END $$;
SELECT * FROM static_diagnostics ORDER BY routine, line, level;
SELECT level, count(*) FROM static_diagnostics GROUP BY level ORDER BY level;
ROLLBACK; -- no extension/schema changes survive the diagnostics
