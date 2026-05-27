#!/usr/bin/env bash
set -euo pipefail
GOLDEN_ARCHIVE="/solution/golden_repo.tar.gz"
if [ ! -f "$GOLDEN_ARCHIVE" ]; then
    echo "solution/golden_repo.tar.gz is missing" >&2
    exit 1
fi
find /target -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
tar -xzf "$GOLDEN_ARCHIVE" -C /target
