# Building from source

A Git checkout and GitHub's source ZIP contain the same editable projects. For the ZIP, extract it and open the directory containing `game`, `autopatcher` and `restoration`. The commands below run from that directory.

One GameMaker project and one Android build serve Android and Linux handhelds. On Linux, gmloader-next runs that build. The game uses a second screen if there is one, and the player can turn it off.

| Project | Folder | Entry point |
| --- | --- | --- |
| Game | `game/android/dual-screen` | `AM2R-project.yyp` |
| Android Autopatcher | `autopatcher/android` | `app-android` for the app, `am2r_android_patcher.py` for the PC utility |
| Linux Autopatcher | `autopatcher/linux` | `handheld_launch.py` |
| Linux launcher | `native/unified` | `package_sd.py` |
| gmloader-next | `native/gmloader` | `Dockerfile` |

## Release

1. Build and sign the game as `game/android/dual-screen/BUILDING.txt` describes, then make the Android patch data and the Autopatcher. [Android patcher build](../autopatcher/android/README.md)
2. Run `autopatcher/android/make_port_data.py`.
3. Publish the release with the Autopatcher, `AM2ARM-gmloader-<version>.zip` and `AM2ARM-music.zip`. The **Linux release** workflow builds gmloader-next and adds the Linux download. The music ZIP is the same file until a track changes.

## Restore the missing project inputs

Install Python 3.11 or newer and xdelta3 on your development computer. Keep your own original Windows `AM2R_11.zip` and the **AM2ARM-Source-Restore-1.6.1.zip** download. The catalog is in this checkout. It reuses the same binary patches as 1.6.1. Place the checkout on a filesystem that supports hard links, such as NTFS or ext4. Once you have those inputs, the following commands work offline. [Download the matching patch pack from v1.6.1](https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.1/AM2ARM-Source-Restore-1.6.1.zip).

1. Prepare the bundle once. Pass the downloaded ZIP itself.

   ```sh
   python3 restoration/prepare_bundle.py "/path/to/AM2ARM-Source-Restore-1.6.1.zip"
   ```

   The helper verifies the whole ZIP's SHA-256, extracts the two verified patch sets, and builds the Project Restore Tool catalog for all three folders under `restoration/bundle`. Keep the complete checkout together for this step.
2. Restore and check the project you plan to edit. Substitute either Autopatcher folder from the table.

   ```sh
   python3 restoration/restore_project.py --project game/android/dual-screen --zip "/path/to/AM2R_11.zip"
   python3 restoration/restore_project.py --project game/android/dual-screen --check
   ```

   On Windows, use `py -3` in place of `python3`. PRT verifies the donor and every restored file. It preserves source edits, reports changes to a reference source file, and stops if existing media has different bytes. Keep each `asset-inputs.json` unchanged. To prepare the bundle elsewhere, pass `--output "/path/to/bundle"` to the first command and `--bundle "/path/to/bundle"` to both PRT commands.
3. Open the entry point for the selected project. The game uses GameMaker LTS 2026 with runtime 2026.1.1.30. Read its `BUILDING.txt` for the licensed toolchain and native inputs.

The two Autopatchers restore interface media. The Android one requires patch data from your privately built game. Android updates require the original signing identity. Use your own package ID and key for independent builds. Captions that came after the pack are in `game/android/dual-screen/datafiles/lang/port-text.json`. [Android patcher build](../autopatcher/android/README.md) · [Linux patcher build](../autopatcher/linux/README.txt)

## Native and dependency sources

The card layout, installer glue and game launcher live in `native/unified`. The gmloader-next build and its libraries live in `native/gmloader`. The corresponding-source index records the two unchanged dependency archives from the v1.6.1 tag, with original versions, URLs and hashes. [Runtime dependency sources](../dependencies/README.txt).

The game project carries its own source terms in `LICENSE.txt` and `THIRD-PARTY.txt`. Autopatcher and PRT tooling and third-party components retain their respective notices. Keep restored media, saves, generated builds and signing material private. For a source contribution, include the affected platform, whether one screen or two, the change, and the behavior you checked.
