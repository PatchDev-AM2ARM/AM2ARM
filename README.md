# AM2ARM — Autopatcher

Rebuild AM2R for **ARM64 Android or Linux** from your own original Windows
**AM2R 1.1 ZIP**. Standard plays on one screen. Dual Screen puts gameplay above
the interactive map on supported two-screen devices.

AM2ARM is based on **AM2R Community Updates 1.5.5**. The title screen displays
**V1.6.3** on Linux and **V1.6.2** on Android.

## Downloads

| Platform | Download |
| --- | --- |
| ARM64 Android | [AM2ARM-Autopatcher-1.6.2.apk](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.2/AM2ARM-Autopatcher-1.6.2.apk) |
| Supported ARM64 Linux handhelds with PortMaster | [am2arm.zip](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.3/am2arm.zip) |
| ARM64 Linux standalone (stock TrimUI, NextUI and other supported firmware) | [AM2ARM-Autopatcher-1.6.3-linux-arm64.zip](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.3/AM2ARM-Autopatcher-1.6.3-linux-arm64.zip) |

Keep your original 2016 **AM2R_11.zip** zipped. Each Autopatcher reconstructs
and verifies the selected edition locally. The Linux installer works with
physical buttons. A touchscreen is needed for the Dual Screen map.

## Linux 1.6.3 prerelease

Choose one Linux download. Both install the same game from your original ZIP.
With PortMaster, use its **autoinstall** folder. With the standalone download,
copy its folders to the card and open **AM2ARM** from your firmware menu.
The same entry installs on first launch and plays on later launches.
Single-screen devices select Standard. Supported two-screen devices offer both editions.

## What's new in 1.6.3

- PortMaster can install AM2ARM from a single ZIP. The standalone download
  also provides shortcuts for stock TrimUI, NextUI and spruceOS.
- Standard supports the BATLEXP G350 on the AmberELEC RG351MP image,
  including game audio and returning to Ports.
- Miyoo Flip V2 (RK3566 / MY355) has a working Standard display path. TrimUI
  Smart Pro S (TG5050) has its own 1280 × 720 profile for its firmware's SDL2
  and Mali graphics libraries.
- The GameMaker source for both editions and platforms is now in the repository
  alongside the Autopatcher and native display code. The development guide
  explains how to restore the omitted assets.

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

Use your original Windows **AM2R_11.zip** and allow **3 GB free** on the game card
after copying. Check the [handheld compatibility list](#compatibility).

Use a card reader or [USB file transfer](#usb-transfer-without-removing-the-card)
to open the destination for your firmware.

### With PortMaster

1. Copy **am2arm.zip**, still zipped, into **ports/autoinstall/** in the game
   library used by PortMaster. Create the autoinstall folder if needed.
2. Place your original **AM2R_11.zip** beside the **ports** folder.
3. Open **PortMaster** once, then return to **Ports → AM2ARM**. The first launch
   patches and starts the game. **AM2ARM Editions** lets you switch editions or
   repair an installation. Refresh your firmware's Ports list if required.

The [PortMaster installation guide](https://portmaster.games/installation/installing-ports/)
lists the autoinstall location for each firmware. For a display that needs
Westonpack, the offline setup instructions below also apply.

### Standalone

| Firmware | Where to copy the files | Where to open AM2ARM |
| --- | --- | --- |
| ROCKNIX | `games-internal/roms` on the system card, `roms` on a separate games card, or the `games-roms` network share | Ports |
| AmberELEC on G350 | Top of the initialized **GAMES** volume | Ports |
| NextUI on supported devices | Top level of the game card, where `Tools` lives | Tools |
| Stock TrimUI or spruceOS on supported devices | Top level of the game card | Apps |
| Other supported Ports firmware | The ROM library containing the `ports` folder | Ports |

1. Extract **AM2ARM-Autopatcher-1.6.3-linux-arm64.zip** on your computer.
   If extraction creates a folder named **AM2ARM-Autopatcher-1.6.3-linux-arm64**,
   open it. You should see **am2arm-launcher**, **ports**, **Tools**, **Apps**
   and **App** together.
2. Copy **everything inside** to the destination above. Merge the folders if
   prompted. Put your original **AM2R_11.zip** beside **am2arm-launcher** and
   keep it zipped.
3. Open **AM2ARM** in the handheld menu listed above. It finds your ZIP,
   verifies it, installs the game and starts it. Open the same entry to play again.

On ROCKNIX, you can check the placement by looking for these three paths in
your ROM library.

```text
AM2R_11.zip
am2arm-launcher/launch.sh
ports/AM2ARM.sh
```

If the entry is missing, open `ports` and check that `AM2ARM.sh` is directly
inside. Then choose **Start → Game Settings → Update Gamelists** on the handheld.

On a supported two-screen handheld, choose **Standard** or **Dual Screen** once.
**AM2ARM Editions** in Ports lets you change it later. If the launcher asks for
the ZIP, use the D-pad and A to select it. On Ports firmware that uses a
capital **Roms** directory, open **Roms** as the destination before copying.

The standalone launcher runs directly from the firmware menu. If a display
needs Westonpack, such as a fresh TrimUI Brick on NextUI or stock, setup
reuses a verified local copy or downloads it once (53 MiB) and checks it.
For an offline install on those devices, copy the official
`weston_pkg_0.2.squashfs` beside `AM2R_11.zip` before opening AM2ARM.
Supported Wayland and native KMS displays can install offline with the
original game ZIP alone. [Westonpack offline download](https://github.com/PortsMaster/PortMaster-New/releases/download/2025-07-24_0745/weston_pkg_0.2.squashfs)

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

On the **G350**, USB networking was verified with **ROCKNIX**.

### Updates and startup problems

Use **Options → Data → Back Up Saves** before updating. Open **AM2ARM** after
copying the new launcher. It reuses a complete copy of the matching version
in a recognized location and installs a different version alongside it.
New games and the edition choice live in **AM2ARM-data** in the game library.

For startup problems, include your model, firmware, installation method and
last screen you saw. The compatibility log is **AM2ARM/logs/compatibility.txt**
inside **ports/am2arm/** for PortMaster or **am2arm-launcher/** for standalone.
Keep your original ZIP, full game and saves private.

## Compatibility

The G350 AmberELEC result is from 1.6.3. The other Linux rows record
hardware checks from 1.6.2 and earlier.

| Platform | Device / setup | Verified scope |
| --- | --- | --- |
| Android | AYN Thor | Standard and Dual Screen |
| Android | AYANEO Pocket DS; Retroid Pocket Duo and Duo Lite | Community-tested Dual Screen |
| Android | Original RG DS, stock Android / GammaOS | Dual Screen; demanding scenes can slow down |
| Android | Retroid Pocket Nova + Retroid Dual Screen Add-on | Community-tested with the Retroid profile |
| Linux | Original RG DS, stock Linux 1.1-261008 | Fresh installation, Standard and Dual Screen, controls, sound, touch and Standard vibration |
| Linux | RG DS, ROCKNIX 20261101 | Installer and Standard; Dual Screen on this firmware unverified |
| Linux | BATLEXP G350, ROCKNIX | Installer, Standard, save transfer and aspect-ratio checks |
| Linux | BATLEXP G350, AmberELEC RG351MP prerelease 20261019_1835 | 1.6.3 Standalone, automatic Standard installation, title music and in-game exit back to Ports |
| Linux | TrimUI Brick, NextUI 20261013-0 | Installer, Standard startup/gameplay, full-screen display, music output and printed A/B/X/Y mapping |
| Linux | TrimUI Brick, stock menu 1.0.6 | Fresh-card installation, fullscreen gameplay, music, controls and damage vibration |
| Linux | Miyoo Flip V2, RK3566 / MY355, BaseOS 1.3.0 | Standard confirmed by a community tester |

**TrimUI Smart Pro S** uses a separate TG5050 profile. Standard gameplay was
reported on spruceOS at 3× and 16:9. The latest display and exit changes
await a hardware check. The **original Smart Pro** has a separate TG5040 profile and also awaits hardware
confirmation. Brick Pro and the 32-bit Miyoo Mini Flip use different hardware.

The stock Brick check used the stock menu on a Brick with a CrossMix 1.3.9
marker. Damage vibration was verified there. A physical NextUI vibration check
is still pending. Previous RG DS, G350 and Brick checks are listed above for
their tested firmware and features.

The Ports route uses the firmware's existing Wayland session. The supported
direct-display profiles use the handheld's own graphics libraries. Keep the
device's graphics drivers and firmware in place. Stock G350 BATLEXPOS is
outside the supported setups in this release. R36S, RG DS Plus and newer
ARM64 RG35XX variants still need their own firmware checks. The original
Cortex-A9 RG35XX runs 32-bit ARM and cannot run this ARM64 package.
On AmberELEC, the G350 and RG351P can select the firmware's KMSDRM display
when Wayland is unavailable. The RG351P firmware libraries were checked on
prerelease 20261019_1835. A physical RG351P run is still pending.
The G350 and Brick on KNULLI still need a running Wayland session.

## Controls and display

**Standard** provides gameplay on a single screen. Android supports touch and
controllers; Linux uses physical controls. Aspect Ratio offers **4:3 / 16:9 /
3:2** without stretching. During play, a change applies at the next room transition.

On supported single-screen Linux handhelds, Standard picks the best-fitting
aspect ratio on first launch. You can still choose another ratio in Display
Options. The handheld already fills its panel, so the desktop Fullscreen
switch is hidden. To exit to the handheld menu, save at a station and hold
**Start + Select** together for one second. On a Smart Pro S running spruceOS,
you can also use the physical Menu button if its tap or hold action is set to
**Exit game** in the firmware.

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
Ports keeps raw saves in `state/config/AM2RStandardLinux/` or
`state/config/AM2RDualLinux/` inside the installed game. Stock TrimUI uses the
game's state directory and keeps its previous save location on an update.
NextUI uses the firmware's home directory, usually
`.userdata/tg5040/.config/AM2RStandardLinux/` on Brick. On spruceOS and
direct-display Ports, new installations use
`AM2ARM-data/home/.config/AM2RStandardLinux/`. Upgrades reuse an existing
`AM2ARM/state/home/.config/AM2RStandardLinux/` when present. Close the game before copying
raw state and keep `config.ini` separate between platforms.

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

The repository contains the GameMaker project for Android and Linux, the
Autopatcher source, and the Linux launcher with its gmloader-next build.
Original media and signing material are omitted. Use your own original AM2R
1.1 ZIP to restore the missing inputs locally. The development guide lists
the matching restore files, toolchain and build steps. [Development guide](docs/README.md)

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
