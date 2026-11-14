# AM2ARM — Autopatcher

Turns **your own original AM2R 1.1 Windows ZIP** into Standard or Dual Screen
for **ARM64 Android and Linux**. Android and the Ports-based Linux package offer both
editions; the TrimUI package offers Standard. Nothing playable is hosted here: the patcher rebuilds the game from
your files and verifies it before installation.

AM2ARM is based on **AM2R Community Updates 1.5.5**. **1.6.1 is this port's
release number**, not a new Community Updates version. It brings the Android
port and native ARM64 Linux edition together. The games retain the original
AM2R logo and show **V1.6.1** in the title-screen corner.

## Downloads

Download from [AM2ARM 1.6.1](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/tag/v1.6.1):

| Your device's operating system | Download |
| --- | --- |
| Android | **AM2ARM-Autopatcher-1.6.1.apk** |
| ARM64 Linux with a supported Ports menu | **AM2ARM-Autopatcher-1.6.1-linux-arm64.zip** |
| TrimUI Brick or original Smart Pro / NextUI or stock menu | **AM2ARM-Autopatcher-1.6.1-trimui-arm64.zip** (Standard) |

All require the original **2016 AM2R_11.zip**. Keep it zipped; modded copies
and Community Updates packages are not accepted. The Linux installer and
Standard work without a touchscreen or Wi-Fi. Dual Screen's map requires touch.
GitHub's automatic **Source code** download is for development, not installation.

## What's new in 1.6.1

**1.6.1 — Native ARM64 Linux support and redesigned Autopatchers.**

Standard and Dual Screen now run natively on supported ARM64 Linux handhelds.
The Linux Autopatcher works offline with physical controls, and the game includes
controller-operated **Backup / Restore** for transfers with Android and PC
Community Updates 1.5.5. TrimUI has a shared package for Brick and original Smart Pro on NextUI
or the stock Apps menu, with automatic model and resolution selection.
Smart Pro hardware confirmation is still pending.

Both Autopatchers use a vertical title-style menu with the planet background
and AM2ARM banner. The game title screen shows V1.6.1 and the repository address.

X parasite and Core-X transformations use a new pixelation shader to reduce
slowdown while preserving the effect and its timing. Linux includes Nano
rendering improvements, smoother room transitions and vibration support on
compatible devices. Standard supports **4:3 / 16:9 / 3:2** without stretching.

Includes the touch-control adjustments, Retroid Dual Screen Add-on support,
translations and earlier fixes from **1.5.5.14**.

## Install on Android

The Autopatcher requires **Android 10 or newer on an ARM64 device**.

1. Put your original `AM2R_11.zip` in Downloads or another folder the system
   file picker can access.
2. Install **AM2ARM Autopatcher**. Allow installation from your browser or
   file manager when Android asks.
3. Open it, select **Standard** or **Dual Screen**, then select your ZIP.
   Wait for reconstruction and verification.
4. The generated game APK is saved in **Downloads**. Choose **Install Standard**
   or **Install Dual Screen**, allowing the patcher to install it when asked.
5. Open **AM2ARM** or **AM2ARM DS** directly. The game no longer needs the
   Autopatcher to run. Dual Screen asks for a hardware profile on first boot.

For **Retroid Pocket Nova + Dual Screen Add-on**, select the **Retroid Pocket
Duo / Duo Lite** profile and enable **Dual Screen Add-on**. Leave that option
off on ordinary Duo/Duo Lite devices. RG DS has its own screen-order option;
use the order that places gameplay above the map.

To update, back up your saves, install the new Autopatcher, reconstruct the
edition you use and install its generated APK over the existing game. Updating
only the patcher does not update the game. **Do not uninstall the old game**:
uninstalling deletes its private saves. Package IDs and signing are preserved.

## Install on Linux

Check [compatibility](#compatibility) first and leave **at least 3 GB free** on
the data card. Use the package for your firmware. **TrimUI users follow the
separate instructions below.** Installation on a supported handheld works
offline; no terminal or system package installation is needed.

1. Download and extract **AM2ARM-Autopatcher-1.6.1-linux-arm64.zip** on your computer.
2. Choose how to access the game-data card:
   - **2A — Card reader:** power off the handheld, remove its card and connect
     it to the computer. Do not format it if Windows cannot read the Linux
     partition; use a computer that can.
   - **2B — USB transfer:** leave the card inside the handheld and use its
     firmware's file-transfer mode or USB networking. See [USB transfer](#usb-transfer-without-removing-the-card)
     below. Keep the game and installer closed while copying.
3. Open the existing **Ports** folder on the game-data partition. With a card
   reader, ROCKNIX's system card uses `STORAGE/games-internal/roms/ports` and a
   separate games card normally uses `roms/ports`. Over a network share, open
   `games-roms/ports`. Keep existing capitalization; the boot partition is not
   the game folder. Copy **AM2ARM Autopatcher.sh** and the **AM2ARM Autopatcher**
   folder together into Ports, without an extra enclosing download folder.
4. Put your original ZIP in **AM2ARM Autopatcher/input/**. Wait for copying to
   finish. For a card reader, safely eject, reinsert and boot. For USB, finish
   the transfer and leave file-transfer mode before opening the installer.
5. Open **Ports → AM2ARM Autopatcher**. Use the D-pad and Confirm/Back to select
   an edition, choose the ZIP and select **INSTALL**. **FOLDER → [USE THIS
   FOLDER]** chooses another destination. Do not power off during installation.
6. At **INSTALLATION COMPLETE**, close the message and exit. Launch **AM2ARM
   Standard** or **AM2ARM Dual Screen** from Ports. If an entry is missing,
   refresh the list; on ROCKNIX use **Start → Game Settings → Update Gamelists**.

### USB transfer without removing the card

USB access depends on both the handheld and its firmware. An **OTG label alone
does not guarantee PC file transfer**. Use a data cable and the correct data
port; copying uses the same folders as a card reader.

- **ROCKNIX:** open Network Settings, enable Samba or SSH, choose USB Gadget
  Function **Network**, then exit settings to apply it. Connect by USB and
  access the `games-roms` share or use SFTP at the address shown by the device.
  This needs no Wi-Fi. **File Transfer** is another option where supported.
  See the [ROCKNIX transfer guide](https://rocknix.org/play/add-games/).
- **NextUI:** [NextUI Dashboard](https://dashboard.loveretro.games/) provides
  browser-based USB/ADB uploads in Chrome or Edge. Connect the powered-on Brick,
  select it in the browser's connection prompt, then use **File Browser** to
  upload the extracted folders under `/mnt/SDCARD/`, preserving their paths.
  The original game ZIP stays zipped. The Brick needs no Wi-Fi; the PC needs
  access to the Dashboard website. See its [instructions](https://github.com/aaronhoogstraten/nextui-web-dashboard).
- **Other firmware:** use its documented USB file-transfer mode. If it supports
  an external USB drive through OTG and has a file manager, copying from that
  drive to the card is another route. Otherwise use a card reader.

On the **G350**, USB networking was verified with **ROCKNIX**. A working PC
transfer route was not established on the tested stock BATLEXPOS image, so
use a card reader for that setup. This is separate from game compatibility:
the Ports download below does not support stock BATLEXPOS.

### TrimUI / NextUI and stock menu

Use **AM2ARM-Autopatcher-1.6.1-trimui-arm64.zip**, not the Ports package.

1. Back up your saves and extract the package on the computer.
2. Copy **AM2ARM/**, **Tools/** and **Apps/** to the SD-card root, preserving
   their paths. Use a card reader (2A), NextUI Dashboard (2B), or the stock
   USB Storage function. Keep the game and installer closed during transfer;
   safely eject USB Storage before opening either app.
3. Copy your original `AM2R_11.zip` into **AM2ARM/patcher/input/**.
4. Open **Tools → AM2ARM Autopatcher** on NextUI, or **Apps → AM2ARM
   Autopatcher** on stock. Use the D-pad, **A** to select and **B** to go back.
   Choose the ZIP, keep the preset destination, and select **INSTALL**.
5. At **INSTALLATION COMPLETE**, exit the installer and open **AM2ARM
   Standard** from the same menu. Leave and reopen that menu if the new
   entry is missing. You do not need to patch it again.

The launcher automatically selects **1024x768 on Brick** or **1280x720
on Smart Pro**. New installations default to 4:3 or 16:9 respectively,
without stretching; existing display settings are preserved.

For this launcher-only update, back up your card, close the game and
installer, then merge the extracted AM2ARM, Tools and Apps folders with
their existing folders. Keep the installed game and saved data. An
existing 1.6.1 Standard game does not need to be patched again.

Both launchers use the same Standard game data. Firmware and clocks remain
unchanged. NextUI saves stay in its hidden
`.userdata/tg5040/.config/AM2RStandardLinux/` folder. Stock saves are in
`AM2ARM/games/AM2ARM Standard/state/config/AM2RStandardLinux/` with the preset
destination. Preserve these folders when backing up. The in-game Data picker
has not yet had a separate physical check on the Brick.

Logs are in **AM2ARM/logs/**. Download that folder through Dashboard or copy
it over USB Storage or with a card reader, then compress it into a ZIP.
Send the logs and your firmware/version, not your original ZIP or rebuilt game.

### Updates and startup problems

Each game needs both its folder and matching `.sh` launcher. The original ZIP
is left unchanged. The patcher refuses to overwrite an existing game directory.
For updates, export your saves through **Options → Data**, close the game and
keep a copy of its `state` folder. Install into a separate empty destination,
then use the new game's Restore menu. Keep the old copy until progress loads.

If the patcher returns to Ports, read **AM2ARM Autopatcher/compatibility.txt**
on the card. Report the exact device, firmware/version and startup message.
A missing Wayland session or incompatible system library needs firmware support;
repeatedly installing the same download will not fix it.

## Compatibility

| Platform | Device / setup | Verified scope |
| --- | --- | --- |
| Android | AYN Thor | Standard and Dual Screen |
| Android | AYANEO Pocket DS; Retroid Pocket Duo and Duo Lite | Community-tested Dual Screen |
| Android | Original RG DS, stock Android / GammaOS | Dual Screen; demanding scenes can slow down |
| Android | Retroid Pocket Nova + Retroid Dual Screen Add-on | Community-tested with the Retroid profile |
| Linux | Original RG DS, stock Linux 1.1-261008 | Fresh installation, Standard and Dual Screen, controls, sound, touch and Standard vibration |
| Linux | RG DS, ROCKNIX 20261101 | Installer and Standard; Dual Screen on this firmware unverified |
| Linux | BATLEXP G350, ROCKNIX | Installer, Standard, save transfer and aspect-ratio checks |
| Linux / TrimUI package | TrimUI Brick, NextUI 20261013-0 | Installer, Standard startup/gameplay, full-screen display, music output and printed A/B/X/Y mapping |
| Linux / TrimUI package | TrimUI Brick, stock menu 1.0.6 | Fresh-card installation, fullscreen gameplay, music, controls and damage vibration |

**Original Smart Pro: provisional support.** Model detection, 1280x720
installer navigation, controller mapping and settings preservation pass
software checks. Installation, actual gameplay, audio and vibration still
need physical confirmation. Smart Pro S and Brick Pro are not enabled.

The stock-menu check used a fresh card on a Brick retaining an internal
CrossMix 1.3.9 marker; a completely unmodified factory image was not checked.
The new Brick vibration path was verified on stock and is also included for
NextUI; its physical NextUI recheck remains outstanding.

The Ports package requires compatible **ARM64 userspace and a Wayland display
session**. The separate TrimUI package uses its firmware display backend.
The package uses the firmware's graphics/audio drivers and bundled app-local
support libraries; it does not change drivers, firmware or clock settings.
G350 stock **BATLEXPOS is not supported by this download**.

R36S, other TrimUI models/firmware, RG DS Plus and newer ARM64 RG35XX variants need their
own firmware checks. The **original Cortex-A9 RG35XX is ARMv7 and cannot run
this package**. This is not an x86 desktop build or a general PortMaster package.
A compatible processor alone does not establish firmware support.

The final packages are checked by reconstructing both editions from the original
1.1 ZIP and comparing them with the matching builds. This verifies the packages;
it does not replace gameplay testing on each device. Android 16 KB-page devices
and hardware combinations beyond those listed still need physical checks.

## Controls and display

**Standard** provides gameplay on a single screen. Android supports touch and
controllers; Linux uses physical controls. Aspect Ratio offers **4:3 / 16:9 /
3:2** without stretching. During play, a change applies at the next room transition.

Android Standard's **Touch Control Scale**, **Control Spacing** and **Diagonal
Aim Size** are independent. Enlarging diagonal arrows shrinks the joystick
inside the same overall area, and the touch targets follow the graphics.

**Dual Screen** puts gameplay above and the map/HUD below. Map buttons,
dragging and pinch zoom use touch; Samus uses the controller. **HUD Screen
Position** can move health and ammunition to the gameplay screen. A single
foldable/tablet canvas split into two panels is not supported.

**Nano**, in Display Options, reduces selected decorative effects to help
slower hardware. It is optional and does not guarantee 60 FPS everywhere.
Android launchers running behind the lower display, including some Cocoon
setups, can affect performance.
The lower screen may take a moment to resume after switching apps.

## Saves and transfer

Use **Options → Data → Back Up Saves** to create a portable backup. Copy that
entire folder to the other device, then choose **Data → Restore Saves** from
the title/file-selection options. This works with Android exports and PC
Community Updates 1.5.5 saves. Restore is unavailable during active gameplay.
Choose the source and destination slot; unlock records are a separate choice.

Android uses its system folder picker. Linux uses a controller-operated picker:
Confirm opens a folder, Back cancels, Left/Right move by a page, and **USE THIS
FOLDER** selects it. Backup creates a new folder instead of replacing an old
one. Restore validates files and keeps replaced progress in `pre-restore-backup`.

Keep the filenames `save1`, `save2`, `save3`, `data.sav` and `extras.sav`.
**Do not copy portable exports directly over raw Linux saves**; use Restore.
Linux's internal state is in `state/config/AM2RStandardLinux/` or
`state/config/AM2RDualLinux/` inside the installed game folder. Close the game
before copying raw state. Keep `config.ini` settings separate across platforms.

### Android folder synchronization

Choose **Data → Sync Folder** in each Android edition and synchronize that
folder with your own file-sync app. Wait for transfers before switching devices.
AM2ARM exports completed saves and checks incoming progress at file selection;
**Sync Now** checks on demand. It does not sign into a cloud account or perform
network transfers itself. Linux uses manual Backup/Restore, not automatic sync.

Keep the `am2r-sync-*.zip` files and `AM2R-Sync-Recovery` folder together. Do not
rename or merge their contents. Conflicts are held for **Review Sync Conflict**
at the title menu; missing shared slots do not delete local progress. **Disable
Sync** leaves saves intact. Use separate folders for independent playthroughs.
The desktop game does not read these sync ZIPs; use portable backups with it.

## Development

The repository contains **autopatcher/android/**, **autopatcher/linux/** and
**autopatcher/trimui-brick/**, build definitions, tests and documentation. GameMaker projects, native Linux
integration, Source Restore and corresponding dependency sources are separate
release assets. See [the development guide](docs/README.md) for downloads,
asset restoration, the pinned toolchain and contribution instructions.

Game source exports omit original artwork, audio, fonts, complete games and
signing material. Restore missing media locally using your own original 1.1 ZIP
and the matching Source Restore bundle. Do not upload the restored project.

## Support and credits

[Report a problem](https://github.com/PatchDev-AM2ARM/AM2ARM/issues) with the exact
model, firmware/OS, edition, Nano setting and steps to reproduce it. For Linux
startup failures include `compatibility.txt` and relevant state logs. Review logs
for personal paths before sharing. Do not attach the original ZIP or a complete
game package. Reports from stronger devices also help with compatibility.

AM2R and Community Updates retain their original credits. This is a community
port, not a Nintendo release. [LICENSE](LICENSE) covers the patcher code;
game source and dependencies retain their respective notices and licenses.
The patcher's MIT license does not relicense original game material.
