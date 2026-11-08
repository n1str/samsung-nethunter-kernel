# Kali NetHunter kernel for Samsung Galaxy A9 2018 (SM-A920F)

A custom NetHunter-enabled kernel for the **Samsung Galaxy A9 2018 (SM-A920F,
`a9y18qlte`)**, which is **not** on the official Kali NetHunter device list.

This repo ships the **delta** (patches + config + packaging), not the full Samsung
kernel tree. You bring the official Samsung source, apply the patches, build, flash.

| | |
|---|---|
| Device | SM-A920F (`a9y18qlte`) |
| SoC | Qualcomm Snapdragon 660 (`sdm660`), arm64 |
| Android | 10 (One UI 2) |
| Kernel | 4.4.205 |
| Base source | Samsung opensource **`A920FXXS7CVL2`** (Android Q) |
| Built/tested firmware | `A920FPUS7CVJ2` (CP `A920FXXS7CVI6`, CSC SER) |

## What's included

- **mac80211 monitor mode + packet injection** (Kali NetHunter mac80211 patches)
- **ath9k_htc** built in — external **Atheros AR9271** USB Wi-Fi adapter (monitor /
  injection via `airmon-ng`, `aireplay-ng`, `wifite`)
- **rt2800usb** injection fix
- **USB gadget HID-ready** (`CONFIG_USB_CONFIGFS_F_HID`) + RNDIS/ECM/FunctionFS
- **Unsigned kernel module loading** (`MODULE_SIG=n`, `MODULE_FORCE_LOAD=y`)
- Samsung vendor security that blocks root / modules removed via Kconfig:
  **DEFEX, FIVE (+TEE), PROCA, DSMS, KNOX_KAP, TIMA**

See [`docs/CONFIG_CHANGES.md`](docs/CONFIG_CHANGES.md) and
[`docs/PATCHES.md`](docs/PATCHES.md) for the exact, itemised changes.

## What is NOT working out of the box

- **USB HID attacks (DuckHunter / BadUSB) from the NetHunter app.** The kernel
  supports the HID gadget function, but Samsung's proprietary USB gadget (configfs
  `g1`, system-managed via `sys.usb.config`) does not expose a HID composition the
  NetHunter app can switch to, and adding HID on top of the full Samsung composition
  is rejected by the dwc3 controller. Making the app's HID work needs an extra
  device-specific gadget shim (not included).
- **Internal Wi-Fi injection** — not possible (Qualcomm `qcacld` driver limitation).
  Use the external AR9271; that's what the kernel enables.

## Build (Docker, one command)

Requires Docker (Linux or Docker Desktop). The build runs in a `linux/amd64`
container; the Samsung source is unpacked into a case-sensitive Docker volume so it
also works on macOS.

1. Get the Samsung source: <https://opensource.samsung.com> -> search `SM-A920F` ->
   download the Android Q package (`SM-A920F_..._Opensource.zip`). Unzip it and place
   the inner `Kernel.tar.gz` in the repo root as **`kernel-source.tar.gz`**.
2. Build:
   ```bash
   docker build --platform linux/amd64 -t a920f-kbuild .
   docker volume create a920f-src
   docker run --rm --platform linux/amd64 -v "$PWD":/work -v a920f-src:/src a920f-kbuild bash /work/build.sh
   ```

Outputs:
- `out/Image.gz-dtb` — the raw kernel
- `out/a920f-nethunter-kernel.zip` — flashable AnyKernel3 package

Full details, toolchain (AOSP GCC 4.9, `android10-gsi`) and the macOS case-sensitivity
note are in [`docs/BUILD.md`](docs/BUILD.md).

## Flash

Your bootloader must be **unlocked** (OEM unlocking).

**Option A - AnyKernel3 zip (recovery):** flash `out/a920f-nethunter-kernel.zip` from
TWRP / a custom recovery. It patches the kernel into your current boot image.

**Option B - rooted boot.img (Odin / Heimdall):**
1. Build, then repack your stock `boot.img` with the new kernel (`pack.sh`), or let
   Magisk patch it: copy `out/Image.gz-dtb` into your stock boot and repack with
   `magiskboot`, then open **Magisk -> Install -> Patch a File** to add root.
2. Flash the result to the `BOOT` partition:
   ```bash
   heimdall flash --BOOT patched_boot.img      # or Odin: boot.tar in the AP slot
   ```

A prebuilt flashable zip is attached to the GitHub **Releases**.

> First custom-kernel flash on a stock (encrypted) device triggers Samsung's
> integrity check and asks for a **factory reset** (data wipe). This is expected.

## Disclaimer

This kernel **removes several Samsung vendor security modules** (DEFEX/FIVE/PROCA/
KNOX_KAP/TIMA/DSMS) and loads unsigned modules. Flashing a custom kernel **trips Knox
permanently (e-fuse), voids your warranty**, and can brick the device if done wrong.
It is intended for authorised security testing / education on **your own hardware**.
Everything here is provided **as-is, with no warranty. You do this at your own risk.**

Kernel is licensed **GPLv2** (see [`LICENSE`](LICENSE)). NetHunter patches are from the
[Kali NetHunter build-scripts](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel).
Packaging uses [AnyKernel3](https://github.com/osm0sis/AnyKernel3) by osm0sis.
