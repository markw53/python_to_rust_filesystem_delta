#!/bin/bash

# Use this file to solve the task.cat > /home/mwork/projects/micro1/python_to_rust_filesystem_delta/solution/solve.sh << 'EOF'
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
EOF

chmod +x /home/mwork/projects/micro1/ython_to_rust_filesystem_delta/solution/solve.sh
