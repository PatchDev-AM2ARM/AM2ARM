# AM2ARM Android Autopatcher source

Android interface and reconstruction tools for AM2ARM 1.6.2. Installation
and supported-device information are
in the [main repository README](https://github.com/PatchDev-AM2ARM/AM2ARM).
The [development guide](https://github.com/PatchDev-AM2ARM/AM2ARM/tree/main/docs)
explains how to restore the game sources in this repository.

## Build

Use **JDK 17**, **Gradle 8.10.2**, **Android SDK 36** and **NDK 27.0.12077973**.
There is no Gradle wrapper; use an installed Gradle and set `ANDROID_HOME`.
From `app-android`, run `gradle assembleDebug` for an independent build.
Use your own package IDs and signing identity when distributing your changes.
Release signing keys are not included.

From the repository root, restore the interface images and fonts with your
original AM2R 1.1 ZIP and the 1.6.1 restoration archive.

```sh
python3 restoration/prepare_bundle.py /path/to/AM2ARM-Source-Restore-1.6.1.zip
python3 restoration/restore_project.py --project autopatcher/android --zip /path/to/AM2R_11.zip
```

The [development guide](../../docs/README.md) covers the complete restoration
workflow. `asset-inputs.json` lists the required files and hashes. Build the
game privately, then regenerate the `patch-bundle` data using
`make_patch_data.py`.

For the game, use the documented GameMaker toolchain and Android ARM64 YYC.
Apply `prepare_game_metadata.py` and `prepare_runtime_performance.py
--runtime-copy /path/to/isolated/runtime` to an isolated runtime copy before
compilation. The second helper preserves the shared method cache. Match
`game-metadata/game.json` to the intended release and preserve save identities.

## Reconstruction

The patch data is `wrapper.bin`, `droid.xdelta` and `assembly.json`. The wrapper
omits original-game byte ranges; the delta rebuilds the game data from the
verified original `data.win`. The assembly plan reassembles the APK and accepts
only the expected checksum. The result must match the exact signed game APK,
including its signature. A complete playable APK is not distributed here.

## gmloader-next

Linux handhelds run the same build with gmloader-next. `make_port_data.py` packs
it for their ports. Attach both of its files to the release.

```sh
python3 make_port_data.py /path/to/game.apk patch-bundle /path/to/output
```

`AM2ARM-gmloader-<version>.zip` is about 35 MB. `AM2ARM-music.zip` is 243 MB
and only changes when a track does. Neither contains files from the AM2R 1.1 ZIP.

## Checks

Run the included tests and verify reconstruction against the matching private
game build. Check package identities, signing, Android compatibility and
permission declarations on the final APK, not just the build configuration.
Keep original media, complete games, private paths, saves and keys out of
public exports. LICENSE and dependency notices retain their original terms.
