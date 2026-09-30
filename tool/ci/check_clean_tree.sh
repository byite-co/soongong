#!/usr/bin/env sh
# Fails when the working tree is not clean — used by CI right after
# `dart run build_runner build` so that stale or untracked generated files
# (*.g.dart / *.freezed.dart) fail the job instead of silently drifting.
set -eu
status="$(git status --porcelain --untracked-files=all)"
if [ -n "$status" ]; then
  echo "Working tree is not clean after codegen. Commit the generated files:" >&2
  echo "$status" >&2
  exit 1
fi
echo "Working tree clean."
