#!/usr/bin/env bash
# Runner unico das suites do engrama. Roda todas as tests/**/*.test.sh.
# Zero dependencia externa alem de git/bash. Usado local e em CI.
# Uso: bash tests/run.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$HERE"/gate/*.test.sh "$HERE"/contract/*.test.sh; do
  [ -f "$t" ] || continue
  echo "==================== $(basename "$t") ===================="
  bash "$t" || rc=1
  echo ""
done
if [ "$rc" -eq 0 ]; then echo "TODAS AS SUITES VERDES"; else echo "ALGUMA SUITE FALHOU"; fi
exit "$rc"
