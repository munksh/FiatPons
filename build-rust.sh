#!/usr/bin/env bash
# Builds the FiatPons Rust library for the phone, inside the Sailfish build
# engine, with the toolchain wiring worked out the hard way. Run from anywhere:
#   ~/Projects/FiatPons/build-rust.sh
set -e

SFDK=~/SailfishOS/bin/sfdk
TOOL=/srv/mer/toolings/SailfishOS-5.0.0.62
SYSROOT=/srv/mer/targets/SailfishOS-5.0.0.62-aarch64.default
GCC=$TOOL/opt/cross/bin/aarch64-meego-linux-gnu-gcc

$SFDK engine exec sh -c '
  # rebuild the assembler/linker shim (cheap, survives VM restarts)
  mkdir -p ~/xshim
  ln -sf '"$TOOL"'/opt/cross/bin/aarch64-meego-linux-gnu-as ~/xshim/as
  ln -sf '"$TOOL"'/opt/cross/bin/aarch64-meego-linux-gnu-ld ~/xshim/ld
  ln -sf '"$TOOL"'/opt/cross/bin/aarch64-meego-linux-gnu-ar ~/xshim/ar

  export PATH=/home/mersdk/xshim:'"$TOOL"'/opt/cross/bin:$PATH
  export LD_LIBRARY_PATH='"$TOOL"'/opt/cross/lib:$LD_LIBRARY_PATH
  . ~/.cargo/env
  export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER='"$GCC"'
  export CC_aarch64_unknown_linux_gnu='"$GCC"'
  export CFLAGS_aarch64_unknown_linux_gnu="--sysroot='"$SYSROOT"'"
  export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="-C link-arg=--sysroot='"$SYSROOT"'"

  cd /home/prometheus/Projects/FiatPons/rust
  cargo build --release --target aarch64-unknown-linux-gnu
'

echo ""
echo "Built: ~/Projects/FiatPons/rust/target/aarch64-unknown-linux-gnu/release/libfiatpons_ffi.so"