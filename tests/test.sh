cat > /home/mwork/projects/micro1/python_to_rust_filesystem_delta/tests/test.sh << 'EOF'
#!/bin/bash
set -u
mkdir -p /logs/verifier

# Apply hidden behavioral tests
cd /target
git apply /tests/test_patch.diff

# Build the binary
cd /target
cargo build --release
if [ $? -ne 0 ]; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

cp target/release/filesystem-delta /target/filesystem-delta

# Run behavioral tests
FILESYSTEM_DELTA_BIN=/target/filesystem-delta \
    python3 -m pytest /target/tests/test_behavioral.py \
    --rootdir=/target/tests \
    -v --tb=short --no-header -rA --color=no -p no:cacheprovider \
    > /logs/verifier/pytest_output.txt 2>&1

if [ $? -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
else
    echo 0 > /logs/verifier/reward.txt
fi
EOF

chmod +x /home/mwork/projects/micro1/python_to_rust_filesystem_delta/tests/test.sh
