AM2ARM 1.6.2 — Android Autopatcher source

From the repository root, prepare the restoration bundle using docs/README.md.
Use your original Windows AM2R 1.1 ZIP to restore the interface artwork,
fonts and audio for this patcher:

  python3 restoration/restore_project.py --project autopatcher/android --zip "/path/to/AM2R_11.zip"
  python3 restoration/restore_project.py --project autopatcher/android --check

asset-inputs.json lists the editable sources, restorable files and generated
inputs. Build the game and use make_patch_data.py with the same original ZIP to
regenerate the patch payload. Retain your signed Android game privately for exact
reconstruction checks. Independently
built games can produce different hashes. Generated inputs in the released
patcher can also be checked against the recorded hashes.

Use JDK 17, Gradle 8.10.2, Android SDK 36 and NDK 27.0.12077973. Follow
README.md and use your own package IDs and signing keys for independent builds.
The embedded xdelta3 C source retains its license in app-android/app/src/main/jni.
Optional desktop vendor binaries are supplied separately.
