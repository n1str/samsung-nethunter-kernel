#!/usr/bin/env bash
# Reproducible NetHunter kernel build for Samsung Galaxy A9 2018 (SM-A920F / a9y18qlte).
#
# Runs INSIDE the linux/amd64 container (see Dockerfile). The repo root is mounted
# at /work. The pristine Samsung source is extracted into a case-SENSITIVE Docker
# volume (/src) because macOS' case-insensitive FS collapses case-colliding kernel
# files (net/netfilter/xt_DSCP.c vs xt_dscp.c). On a native Linux host you can point
# $SRC at ./kernel directly.
#
# Flow: extract pristine source -> apply patches/ -> merge config/ -> build ->
#       copy Image.gz-dtb into anykernel/ and out/ -> pack AnyKernel3 zip.
#
# Usage (from repo root, Docker Desktop running):
#   docker build --platform linux/amd64 -t a920f-kbuild .
#   docker volume create a920f-src
#   docker run --rm --platform linux/amd64 -v "$PWD":/work -v a920f-src:/src a920f-kbuild bash /work/build.sh
set -euo pipefail

TARBALL=/work/kernel-source.tar.gz     # Samsung opensource Kernel.tar.gz (see README)
SRC=/src/kernel                         # case-sensitive build tree (Docker volume)
OUT=$SRC/out
DEFCONFIG=a9y18qlte_eur_open_defconfig
FRAGMENT=/work/config/nethunter.config

export ARCH=arm64
export CROSS_COMPILE=/opt/gcc49/bin/aarch64-linux-android-
export PYTHON=python2                   # scripts/gcc-wrapper.py is python2
MK="-C $SRC O=$OUT DTC_EXT=/usr/bin/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

# 1) pristine source into the case-sensitive volume (once)
if [ ! -f "$SRC/Makefile" ]; then
    [ -f "$TARBALL" ] || { echo "!! Missing $TARBALL - download the Samsung opensource package (see README) and place Kernel.tar.gz as kernel-source.tar.gz"; exit 1; }
    echo ">>> extracting pristine Samsung source"
    mkdir -p "$SRC"; tar -xzf "$TARBALL" -C "$SRC"
fi
[ -f "$SRC/net/netfilter/xt_dscp.c" ] && [ -f "$SRC/net/netfilter/xt_DSCP.c" ] \
    || { echo "!! case-colliding twins missing - build tree is not on a case-sensitive FS"; exit 1; }

# 2) apply NetHunter delta (idempotent)
if [ ! -f "$SRC/.nethunter_patched" ]; then
    echo ">>> applying patches/"
    for p in /work/patches/*.patch; do
        echo "  -- $(basename "$p")"
        patch -d "$SRC" -p1 < "$p"
    done
    find "$SRC" \( -name '*.orig' -o -name '*.rej' \) -delete
    touch "$SRC/.nethunter_patched"
fi

# 3) config: defconfig + fragment
mkdir -p "$OUT"
make $MK "$DEFCONFIG"
"$SRC/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" "$FRAGMENT"
make $MK olddefconfig

# 4) build
echo ">>> building (-j$(nproc))"
make $MK -j"$(nproc)"

# 5) collect artifacts + pack AnyKernel3 zip
cp -v "$OUT/arch/arm64/boot/Image.gz-dtb" /work/anykernel/Image.gz-dtb
mkdir -p /work/out
cp -v "$OUT/arch/arm64/boot/Image.gz-dtb" /work/out/Image.gz-dtb
cd /work/anykernel && rm -f /work/out/a920f-nethunter-kernel.zip \
    && zip -r9 /work/out/a920f-nethunter-kernel.zip . -x '.git*' >/dev/null \
    && echo ">>> flashable: out/a920f-nethunter-kernel.zip"
