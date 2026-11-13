AM2ARM Autopatcher 1.6.1 - Android source

This archive contains the exact patcher code, tests and build definitions.
Original UI images, fonts and audio are omitted. Restore them on a development
PC with Python 3.11+, xdelta3 on PATH and your original AM2R 1.1 ZIP:

  python3 /path/to/AM2ARM-Source-Restore/restore_project.py --project . --zip /path/to/AM2R_11.zip
  python3 /path/to/AM2ARM-Source-Restore/restore_project.py --project . --check

Use AM2ARM-Source-Restore-1.6.1.zip from this release. Its catalog identifies
this exact patcher manifest and selects the small matching UI asset delta.
Keep asset-inputs.json unchanged. Source edits and existing files are preserved;
restored artwork remains private. This does not reconstruct a complete game.

Generated patch-bundle inputs are listed separately under generated_inputs.
They are created with make_patch_data.py from your own signed Android APKs or
canonical Linux game ZIPs plus the original AM2R 1.1 ZIP. These game builds come
from the separate restored game sources. Match both edition payloads. The
published game compilers/signatures need not produce byte-identical new builds.
The release patcher packages also contain their own complete generated bundles.
The restorer reports generated_inputs; it does not generate or overwrite them.
Optional desktop vendor binaries are external tools, not restored UI assets.

Use JDK 17, Gradle 8.10.2, Android SDK 36 and NDK 27.0.12077973.
From app-android run your Gradle installation with assembleDebug. There
is no Gradle wrapper. Set ANDROID_HOME and use your own signing keys.
prepare_game_metadata.py and prepare_runtime_performance.py prepare the
matching game builds. Artwork generation, when requested, uses Pillow;
the exact restored artwork needs no regeneration.

The source export removes the Android host-specific Java installation path.
All other retained program code matches the frozen release source. No signing
key, complete game, proprietary SDK or prebuilt executable is distributed here.

LICENSE and dependency notices retain their original terms. The Android embedded
xdelta3 and optional newer desktop decoder use their supplied Apache notices.
The ARM64 handheld decoder is Debian xdelta3 3.0.11-dfsg-1.2 under GPL-2+; its
notice and exact corresponding sources accompany the runtime/source downloads.
Use AM2ARM-1.6.1-dependency-sources.zip for corresponding runtime sources.
Repository: https://github.com/PatchDev-AM2ARM/AM2ARM
