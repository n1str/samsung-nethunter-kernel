# BUILD — Kali NetHunter kernel for Samsung Galaxy A9 2018 (SM-A920F)

Device: SM-A920F `a9y18qlte`, Snapdragon 660 (sdm660), arm64, Android 10, kernel **4.4.205**.
Firmware baseline: **A920FPUS7CVJ2** (CP A920FXXS7CVI6 / CSC A920FSER7CVJ2, region SER) — the
latest stock for this device. Build runs in a `linux/amd64` Docker container (macOS host
can't build the kernel directly — case-insensitive FS collapses case-colliding sources).

## Inputs

| Path | What | How to get it |
|------|------|---------------|
| `~/Downloads/SM-A920F_EUR_QQ_Opensource.zip` | kernel source (opensource `A920FXXS7CVL2`, Android Q) | opensource.samsung.com → search `SM-A920F` → the Q entry |
| `stock/boot.img` | stock boot image of **A920FPUS7CVJ2** | extract from the AP of the matching firmware (see "Getting stock boot.img") |

`_staging/Kernel.tar.gz` (unzipped from the opensource zip) is the pristine source the
build extracts into a case-sensitive Docker volume.

## One-time setup

```bash
# from repo root
unzip -o ~/Downloads/SM-A920F_EUR_QQ_Opensource.zip -d _staging        # -> _staging/Kernel.tar.gz
docker build --platform linux/amd64 -t a920f-kbuild .                   # image: GCC4.9, python2, dtc, magiskboot
docker volume create a920f-src                                          # case-sensitive source volume
```

## Build the kernel (one command)

```bash
# STOCK (baseline):
docker run --rm --platform linux/amd64 -v "$PWD":/work -v a920f-src:/src a920f-kbuild bash /work/build.sh

# NetHunter (patches already applied to the volume; config fragment on top):
docker run --rm --platform linux/amd64 -v "$PWD":/work -v a920f-src:/src a920f-kbuild bash /work/build.sh /work/nethunter.config
```

Output: `out/Image`, `out/Image.gz` (and `out/Image.gz-dtb` inside the volume). ~12 min.
To rebuild fully clean, `docker volume rm a920f-src` first (re-extracts pristine, re-applies
patches via the steps in PATCHES.md).

NetHunter patches live in `patches/` (applied with `patch -p1` inside the volume; see
PATCHES.md). Config changes are in `nethunter.config` (see CONFIG_CHANGES.md).

## Package into boot.img (after stock/boot.img is in place)

```bash
docker run --rm --platform linux/amd64 -v "$PWD":/work -v a920f-src:/src a920f-kbuild bash /work/pack.sh
```

Output: **`out/boot.img`** and **`out/boot.tar`** (ustar, for odin4/heimdall).
`pack.sh` unpacks the stock boot.img with magiskboot, swaps in the matching built kernel
(gzip+dtb → `Image.gz-dtb`), repacks, and tars it.

## Getting stock boot.img

FUS auto-download can't be scripted from this environment (Samsung's edge blocks non-Kies
clients; automating the Kies client is treated as bot-check circumvention). Fetch it yourself:

```bash
python3 -m venv ~/sl3 && ~/sl3/bin/pip install "git+https://github.com/MatrixEditor/samloader3.git"
~/sl3/bin/python3 -m samloader3 -M SM-A920F -R SER -I <device-IMEI>
# at the (sl3)> prompt:
#   download -o ~/A920F_fw --decrypt A920FPUS7CVJ2/A920FSER7CVJ2/A920FXXS7CVI6/A920FPUS7CVJ2
```
Then extract `boot.img` from the decrypted `AP_*.tar.md5` (it's `boot.img.lz4` → `lz4 -d`) and
place it at `stock/boot.img`.

## What you get

- `out/boot.img` — stock boot.img with a NetHunter 4.4.205 kernel: mac80211 packet injection,
  ath9k_htc (AR9271), rt2800 injection, USB HID/RNDIS/ECM gadget, unsigned module loading,
  Samsung security (DEFEX/FIVE/PROCA/DSMS/KNOX_KAP/TIMA) removed.
- `out/boot.tar` — the same, packaged for Odin/Heimdall.

## Flashing (manual, your call)

`heimdall flash --BOOT out/boot.img` or Odin (`boot.tar` in the AP slot) with the device in
Download mode. **Flashing a custom kernel trips KNOX (e-fuse, irreversible) and needs an
unlocked bootloader (OEM unlocking).** Not done here — verify before flashing.

## Known risks / notes

- **RTL8812AU (88xxau) driver is left disabled** — it trips Samsung's `scripts/gcc-wrapper.py`
  forbidden-warning gate. Primary adapter AR9271 (ath9k_htc) is built and unaffected.
  Patches 03 and 07 are skipped with rationale in PATCHES.md.
- `htc_9271.fw` (AR9271 firmware) is not compiled in; it must exist on-device — the NetHunter
  installer provides it.
- Source version (opensource `CVL2`) is one revision newer than the device AP (`CVJ2`); both are
  the final Android 10 / 4.4 for this model, kernel-compatible. `boot.img` is taken from the
  device's exact `CVJ2` build.
- Security modules were removed via Kconfig only; no source edits. If `olddefconfig` ever
  re-selects one (it didn't here), check the final `.config`.
