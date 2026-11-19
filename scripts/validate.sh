#!/usr/bin/env sh
# Consistency checks with no tool beyond POSIX sh/grep/sed; run by `task validate` and CI.
#   - pre-commit.lock pins the PRECOMMIT_VERSION the Dockerfile declares
#   - every <TOOL>_SHA256_<ARCH> ARG holds a 64-hex sha256
set -eu
dockerfile=${DOCKERFILE:-Dockerfile}
lock=${LOCK:-pre-commit.lock}

ver=$(sed -n 's/^ARG PRECOMMIT_VERSION=//p' "$dockerfile")
grep -q "^pre-commit==$ver " "$lock" \
  || { echo "✗ $lock does not pin pre-commit==$ver; run task lock" >&2; exit 1; }

bad=$(grep -E '^ARG [A-Z_]+_SHA256_(AMD64|ARM64)=' "$dockerfile" \
  | grep -vE '=[0-9a-f]{64}$' || true)
if [ -n "$bad" ]; then
  printf '✗ unset or malformed hashes (run task pin):\n%s\n' "$bad" >&2
  exit 1
fi
echo "✓ lock and hash pins are consistent"
