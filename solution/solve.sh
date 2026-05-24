#!/bin/bash
set -euo pipefail

# Extract the golden Rust repository into /target
rm -rf /target/*
tar -xzf /solution/golden_repo.tar.gz -C /target

# Build the binary to verify it compiles
cd /target
cargo build --release
cp target/release/filesystem-delta /target/filesystem-delta

echo "Golden solution installed and built successfully."
