# CONFIG changes — SM-A920F NetHunter kernel

Applied via `nethunter.config` fragment merged onto `a9y18qlte_eur_open_defconfig`
(`scripts/kconfig/merge_config.sh -m` + `make olddefconfig`). Never hand-edited `.config`.
"was" = value in the stock defconfig. All values below were re-verified in the final
`.config` after `olddefconfig` (nothing reverted by dependencies).

## Enabled

| CONFIG | was | now | why |
|--------|-----|-----|-----|
| CONFIG_CFG80211 | y | y | 802.11 config (already on) |
| CONFIG_MAC80211 | *not set* | **y** | soft-MAC stack — required for packet injection |
| CONFIG_WLAN_VENDOR_ATH | n/a | — | symbol absent in this tree (ath gated by `CONFIG_ATH_CARDS=y`); ath9k still builds |
| CONFIG_ATH9K_HW | *absent* | **y** | AR9271 HW support |
| CONFIG_ATH9K_COMMON | *absent* | **y** | ath9k common |
| CONFIG_ATH9K_HTC | *absent* | **y** | **ath9k_htc — AR9271 USB adapter** |
| CONFIG_USB_CONFIGFS | y | y | USB gadget via configfs (already on) |
| CONFIG_USB_CONFIGFS_F_HID | y | y | **HID gadget (keystroke injection)** — already on |
| CONFIG_USB_CONFIGFS_F_FS | y | y | FunctionFS — already on |
| CONFIG_USB_CONFIGFS_RNDIS | *not set* | **y** | RNDIS gadget networking |
| CONFIG_USB_CONFIGFS_ECM | *not set* | **y** | CDC-ECM gadget networking |
| CONFIG_BT_HCIBTUSB | *not set* | **y** | external USB Bluetooth (optional) |
| CONFIG_MODULES | y | y | loadable modules (already on) |
| CONFIG_MODULE_FORCE_LOAD | *not set* | **y** | allow forcing module load |

## Disabled

| CONFIG | was | now | why |
|--------|-----|-----|-----|
| CONFIG_MODULE_SIG | y | **n** | don't require signed modules |
| CONFIG_MODULE_SIG_FORCE | y | **n** | don't enforce signatures |
| CONFIG_MODULE_SIG_ALL | y | **n** | don't auto-sign at build |
| CONFIG_SECURITY_DEFEX | y | **n** | Samsung DEFEX — blocks root/exec policy |
| CONFIG_FIVE | y | **n** | Samsung FIVE integrity enforcement |
| CONFIG_FIVE_TEE_DRIVER | y | **n** | FIVE TEE driver |
| CONFIG_FIVE_EARLY_LOAD_TRUSTED_APP | y | **n** | FIVE early trusted-app load |
| CONFIG_FIVE_TRUSTED_KEYRING | y | **n** | FIVE keyring |
| CONFIG_PROCA | y | **n** | Samsung PROCA process authentication |
| CONFIG_SECURITY_DSMS | y | **n** | Samsung DSMS security log/attestation |
| CONFIG_KNOX_KAP | y | **n** | KNOX Kernel Auto Protection |
| CONFIG_TIMA | y | **n** | TIMA (TrustZone integrity) |
| CONFIG_TIMA_LOG | y | **n** | TIMA logging |
| CONFIG_TIMA_LKMAUTH | y | **n** | TIMA module-authentication (blocks unsigned .ko) |
| CONFIG_TIMA_UEVENT | y | **n** | TIMA uevents |
| CONFIG_88XXAU | *not set* | **n** | RTL8812AU out-of-tree driver left off — trips Samsung gcc-wrapper forbidden-warning check (see nethunter.config / PATCHES.md) |

## Not present in this defconfig (nothing to disable)

RKP / CONFIG_UH / CONFIG_RKP_CFP* / FASTUH, CONFIG_SEC_RESTRICT* — not configured in
`a9y18qlte_eur_open_defconfig`, so no action needed. (KNOX_NCM left as-is; task scoped
KNOX to KAP.)

## Firmware note

`CONFIG_ATH9K_HTC=y` loads `htc_9271.fw` via the userspace firmware loader at adapter
probe. The blob is **not** compiled in; it must exist on-device (the Kali NetHunter
installer ships ath9k_htc firmware under the chroot / `/vendor/firmware`). No kernel-build
action required.
