# Translate a Python filesystem delta library to Rust

## Task

You are given a Python repository in `/source` that implements a filesystem delta
tool. It computes the difference between two directory snapshots and generates a
list of patch operations to transform one directory into another. It also applies
those patch operations to the filesystem.

Translate the entire repository into idiomatic Rust in `/target`.

## Requirements

### Build
The translated project must produce a single CLI binary named `filesystem-delta`.
The following command must succeed:
cd /target && cargo build --release && cp target/release/filesystem-delta /target/filesystem-delta

### CLI Surface
The binary must expose two subcommands matching the Python CLI exactly:

**compute** — computes a delta between two directories and writes a JSON patch file:
filesystem-delta compute --src <dir> --dst <dir> --out <file>

**apply** — applies a JSON patch file to a directory:
filesystem-delta apply --root <dir> --patch <file> [--dry-run]

### Patch Operations
The following patch operation types must be supported:
- `create_file` — create an empty file
- `delete_file` — delete a file or symlink
- `create_dir` — create a directory
- `delete_dir` — delete a directory recursively
- `modify_file` — truncate a file to zero bytes
- `chmod` — change file permissions
- `utimes` — set file modification time
- `symlink` — create or update a symlink

### Behavioral Requirements
- `compute` must produce deterministic output — identical inputs must always
  produce identical patch operation lists in the same order
- Deletions must be ordered deepest-first so children are removed before parents
- Creations must be ordered shallowest-first so parents are created before children
- Symlinks must be detected and handled correctly, including circular symlinks
- File identity is determined by SHA-256 hash of contents
- The patch JSON format must be a list of objects, each with an `op` field and
  relevant fields (`path`, `target`, `mode`, `mtime`) depending on the op type

### Project Structure
- The library logic must be in a Rust library crate
- The CLI entry point must be at `src/main.rs`
- The project must have a valid `Cargo.toml`
- All code must compile with `cargo build --release` without errors or warnings

## Source
The Python source repository is at `/source`. Read it to understand the intended
behavior before writing any Rust code.

## Target
Write your Rust translation to `/target`. The directory is empty — build the
entire project structure from scratch.
