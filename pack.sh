#!/usr/bin/env bash
# Repack stock boot.img with the freshly built NetHunter kernel, using magiskboot.
# Runs inside the container. Needs: /work/stock/boot.img and a built kernel in
# /src/kernel/out/arch/arm64/boot/. Produces /work/out/boot.img and /work/out/boot.tar.
set -euo pipefail

STOCK=/work/stock/boot.img
KBOOT=/src/kernel/out/arch/arm64/boot
OUT=/work/out
WORK=/tmp/repack

[ -f "$STOCK" ] || { echo "!! missing $STOCK (download stock firmware first)"; exit 1; }

rm -rf "$WORK"; mkdir -p "$WORK" "$OUT"; cd "$WORK"
cp "$STOCK" boot.img

echo ">>> unpack stock boot.img"
magiskboot unpack boot.img
echo "--- stock kernel format ---"; file kernel 2>/dev/null || true

# Pick the built kernel whose format matches the stock one.
# Samsung A920F uses a gzip+appended-dtb kernel -> Image.gz-dtb; fall back to Image.gz.
if head -c4 kernel | grep -q $'\x1f\x8b' 2>/dev/null; then
    if [ -f "$KBOOT/Image.gz-dtb" ]; then NEW="$KBOOT/Image.gz-dtb"; else NEW="$KBOOT/Image.gz"; fi
else
    NEW="$KBOOT/Image"
fi
echo ">>> replacing kernel with: $NEW ($(stat -c%s "$NEW") bytes)"
cp "$NEW" kernel

echo ">>> repack"
magiskboot repack boot.img "$OUT/boot.img"

echo ">>> make boot.tar (ustar, for odin4/heimdall)"
cd "$OUT"
tar -H ustar -cf boot.tar boot.img

echo ">>> result:"
ls -la "$OUT/boot.img" "$OUT/boot.tar"
