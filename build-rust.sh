#!/bin/sh
set -eu

cd "$(dirname "$0")"

echo "== Fiat Pons Rust build =="

if [ ! -d rust ]; then
    echo "Error: rust/ directory not found."
    exit 1
fi

if [ ! -f rust/Cargo.toml ]; then
    echo "Error: rust/Cargo.toml not found."
    exit 1
fi

echo "Building Rust FFI library..."
cd rust
cargo build --release
cd ..

SRC="rust/target/release/libfiatpons_ffi.so"
DST="libfiatpons_ffi.so"

if [ ! -f "$SRC" ]; then
    echo "Error: expected output not found: $SRC"
    exit 1
fi

cp "$SRC" "$DST"

echo "Built:"
ls -lh "$DST"

echo "Done."
