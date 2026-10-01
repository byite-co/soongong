#!/usr/bin/env bash
# Local test runner (no Supabase CLI): recreates the test DB on a plain
# PostgreSQL 16 with pgTAP + pg_cron, applies the emulation shim, every
# migration, the dev-only migration, then runs pg_prove over supabase/tests.
#
#   PGHOST=/tmp PGPORT=54329 PGUSER=postgres supabase/tests/local/run.sh [test files…]
set -euo pipefail
cd "$(dirname "$0")/../../.."
: "${PGHOST:=/tmp}" "${PGPORT:=54329}" "${PGUSER:=postgres}" "${PGDATABASE:=soongong_test}"
export PGHOST PGPORT PGUSER
psql -d postgres -v ON_ERROR_STOP=1 -q -c "drop database if exists ${PGDATABASE} with (force)" -c "create database ${PGDATABASE}"
psql -d "$PGDATABASE" -v ON_ERROR_STOP=1 -q -c "create extension pgtap; create extension pg_cron;"
psql -d "$PGDATABASE" -v ON_ERROR_STOP=1 -q -f supabase/tests/local/00_shim.sql
for f in supabase/migrations/*.sql; do
  echo "== apply $f"
  psql -d "$PGDATABASE" -v ON_ERROR_STOP=1 -q -f "$f"
done
for f in supabase/dev/*.sql; do
  [ -e "$f" ] || continue
  echo "== apply (dev) $f"
  psql -d "$PGDATABASE" -v ON_ERROR_STOP=1 -q -f "$f"
done
if [ $# -gt 0 ]; then tests=("$@"); else tests=(supabase/tests/*.sql); fi
export PGDATABASE
pg_prove -d "$PGDATABASE" --verbose "${tests[@]}"
