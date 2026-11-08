# NetHunter patches — SM-A920F kernel 4.4.205

Source: `kali-nethunter-kernel/patches/4.04` (dir `4.04` = kernel 4.4; some files are
symlinks into `4.14`). Applied inside the container with `patch -p1` against the
case-sensitive source in the Docker volume. Copied into `./patches/` (numeric prefix =
apply order). Build verification is the real test; see BUILD.md.

## Applied (8) — shipped in `patches/`

| # | Patch | Purpose | Result |
|---|-------|---------|--------|
| 01 | mac80211-refactor-monitor (`v2-2-6-...-in-sdata`) | mac80211 monitor-iface refactor, prerequisite for injection | clean |
| 02 | add-wifi-injection | **core mac80211 packet injection** (cfg.c, tx.c, rtl8187, zd1211rw, wireless/chan.c) | clean |
| 04 | fix-ath9k-freq2fbin | AR9271/ath9k_htc EEPROM freq fix | clean |
| 05 | fix-ath9k-naming (from 4.14) | ath9k_htc symbol naming conflict fix | clean |
| 06 | fix-rt2800-injection | rt2800usb injection fix | clean |
| 09 | fix-rndis-configs | gadget Makefile fix so RNDIS gadget coexists | clean |
| 10 | add-ub500-btusb | TP-Link UB500 BT dongle id in btusb | clean |
| 11 | fix-hci-uart | hci_uart build fix | clean |

Verified post-apply: injection code present in `net/mac80211/tx.c`. The gaps in the
numbering (03, 07, 08) are the omitted patches documented below.

## Omitted (3) — with reason

**03 `fix-mac80211-compile`** — SKIPPED.
Conflict: `net/mac80211/mlme.c` hunk FAILED (context expected `case NL80211_BAND_2GHZ`,
our tree has `case IEEE80211_BAND_2GHZ`).
Analysis: all three hunks (tx.c, mlme.c, regd.c) are pure `IEEE80211_BAND_*` →
`NL80211_BAND_*` renames. Our Samsung tree keeps the compat aliases
(`include/net/cfg80211.h:113-115`: `IEEE80211_BAND_60GHZ = NL80211_BAND_60GHZ`), so the
names are equivalent and the compile errors this patch fixes do not occur here.
Resolution: dropped (no functional impact). File kept as `patches/03-*.patch.skip`.

**07 `add-rtl8xxxu-with-rtl8188eus-drivers`** — SKIPPED.
Conflict: integration hunks for `drivers/net/wireless/Kconfig` (@340) and
`drivers/net/wireless/realtek/Makefile` (@5) FAILED.
Analysis: our Samsung tree **already integrates** `rtl8xxxu` — both the `source
".../rtl8xxxu/Kconfig"` line and `obj-$(CONFIG_RTL8XXXU) += rtl8xxxu/` already exist; the
patch's context additionally expects `rtl8812au` lines absent in our tree. Applying the
NetHunter rtl8xxxu variant would overwrite Samsung's working in-tree rtl8xxxu.
Resolution: dropped. Our target adapter AR9271 uses `ath9k_htc` (unaffected). RTL8188EUS
support is lost. Does not touch the required features (mac80211 injection / HID / modules).

**08 `add-rtl88xxau` (RTL8812AU/8814AU)** — OMITTED.
The patch applies cleanly, but the out-of-tree 88xxau driver trips Samsung's strict
`scripts/gcc-wrapper.py` "forbidden warning" gate (e.g. empty declaration @
`rtw_mlme_ext.c:261`) and does not compile on this tree, so it was config-disabled
(`# CONFIG_88XXAU is not set`). The 16 MB patch is left out of this repo to keep it lean;
the primary adapter AR9271 (`ath9k_htc`) is unaffected. To add RTL8812AU support, pull
`add-rtl88xxau-5.6.4.2-drivers-4.04.patch` from the Kali NetHunter build-scripts and
clean the driver's warnings.
