# AM2ARM Android Autopatcher source

Android interface and reconstruction tools for AM2ARM 1.6.1, with Standard
and Dual Screen payloads. Installation and supported-device information are
in the [main repository README](https://github.com/PatchDev-AM2ARM/AM2ARM).
The [development guide](https://github.com/PatchDev-AM2ARM/AM2ARM/tree/main/docs)
explains game-source downloads and asset restoration.

## Build

Use **JDK 17**, **Gradle 8.10.2**, **Android SDK 36** and **NDK 27.0.12077973**.
There is no Gradle wrapper; use an installed Gradle and set `ANDROID_HOME`.
From `app-android`, run `gradle assembleDebug` for an independent build.
Use your own package IDs and signing identity when distributing your changes.
Release signing keys are not included.

Restore interface images/fonts with **AM2ARM-Source-Restore-1.6.1.zip** and
your original AM2R 1.1 ZIP. The source package's README and `asset-inputs.json`
identify the exact inputs. Generated `patch-bundle` data is separate: build
both games privately and regenerate each edition using `make_patch_data.py`.

For the games, use the documented GameMaker toolchain and Android ARM64 YYC.
Apply `prepare_game_metadata.py` and `prepare_runtime_performance.py
--runtime-copy /path/to/isolated/runtime` to an isolated runtime copy before
compilation. The second helper preserves the shared method cache. Match
`game-metadata/game.json` to the intended release and preserve save identities.

## Reconstruction

Each edition has `wrapper.bin`, `droid.xdelta` and `assembly.json`. The wrapper
omits original-game byte ranges; the delta rebuilds the game data from the
verified original `data.win`. The assembly plan reassembles the APK and accepts
only the expected checksum. The result must match the exact signed game APK,
including its signature. A complete playable APK is not distributed here.

Run the included tests and verify reconstruction against the matching private
game builds. Check package identities, signing, Android compatibility and
permission declarations on the final APK, not just the build configuration.
Keep original media, complete games, private paths, saves and keys out of
public exports. LICENSE and dependency notices retain their original terms.
