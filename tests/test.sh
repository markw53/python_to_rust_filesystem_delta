#!/bin/bash
set -u
export PATH="/usr/local/cargo/bin:/opt/task-venv/bin:${PATH}"
export RUSTUP_HOME="/usr/local/rustup"
export CARGO_HOME="/usr/local/cargo"
mkdir -p /logs/verifier

# Apply hidden behavioral tests
cd /target
git apply /tests/test_patch.diff
if [ $? -ne 0 ]; then
    echo "Failed to apply test patch" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Build the binary
cargo build --release
if [ $? -ne 0 ]; then
    echo "Build failed" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

cp target/release/filesystem-delta /target/filesystem-delta

# Run behavioral tests
FILESYSTEM_DELTA_BIN=/target/filesystem-delta \
    /opt/task-venv/bin/python3 -m pytest /target/tests/test_behavioral.py \
    --rootdir=/target/tests \
    -v --tb=short --no-header -rA --color=no -p no:cacheprovider \
    > /logs/verifier/pytest_output.txt 2>&1

if [ $? -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
    exit 0
else
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi
