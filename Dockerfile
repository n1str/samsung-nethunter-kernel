FROM --platform=linux/amd64 ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Build deps (per task) + python2 for Samsung's scripts/gcc-wrapper.py
RUN apt-get update && apt-get install -y --no-install-recommends \
        bc bison flex libssl-dev make gcc g++ git zip unzip python3 wget cpio \
        liblz4-tool device-tree-compiler ca-certificates python2 patch \
    && ln -sf /usr/bin/python2 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Toolchain from README_Kernel.txt: GCC aarch64-linux-android-4.9 (AOSP prebuilt)
RUN git clone --depth 1 -b android10-gsi \
        https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 \
        /opt/gcc49 \
    && test -x /opt/gcc49/bin/aarch64-linux-android-gcc \
    && /opt/gcc49/bin/aarch64-linux-android-gcc --version

# magiskboot (from Magisk release APK) for boot.img unpack/repack
RUN wget -q https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk -O /tmp/magisk.apk \
    && unzip -o -q /tmp/magisk.apk "lib/x86_64/libmagiskboot.so" -d /tmp/magisk_x \
    && cp /tmp/magisk_x/lib/x86_64/libmagiskboot.so /usr/local/bin/magiskboot \
    && chmod +x /usr/local/bin/magiskboot \
    && rm -rf /tmp/magisk.apk /tmp/magisk_x \
    && magiskboot 2>&1 | head -1

WORKDIR /work
