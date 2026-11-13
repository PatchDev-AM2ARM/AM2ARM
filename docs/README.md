# Developing AM2ARM 1.6.1

## Autopatcher code in the repository; game projects in release assets

The repository's Code tab contains both patchers and release documentation:

```text
autopatcher/android/         Android Autopatcher
autopatcher/linux/           Linux Autopatcher
autopatcher/trimui-brick/    TrimUI Brick stock/NextUI adapters
```

Download the named source archives from the release Assets section for game
development. GitHub's automatic Source code downloads contain this repository
and do not include the game projects or their assets.

Extract each downloaded project into its own working folder:

```text
  AM2ARM-Android-Standard      Android Standard
  AM2ARM-Android-DualScreen    Android Dual Screen
  AM2ARM-Linux-Standard        Linux Standard
  AM2ARM-Linux-DualScreen      Linux Dual Screen
  AM2ARM-Autopatcher-Android   Android Autopatcher, also in this repository
  AM2ARM-Autopatcher-Linux     Linux Autopatcher, also in this repository
  AM2ARM-Linux-integration     Native display, input and graphics support
  AM2ARM-Source-Restore        Command-line asset restoration utility
```

The Brick adapters use the Linux Standard project and common patcher. They
need no separate game project or media catalog. See [Brick integration](../autopatcher/trimui-brick/README.md).

The separation is intentional. Shared gameplay is maintained across the
projects, while target options, platform guards and display/input extensions
differ. Open the project for the intended target instead of building an Android
project as Linux without its platform integration. Keep the projects in separate
working folders. Each has a matching asset manifest and source fingerprint.

Game source downloads

- AM2ARM-1.6.1-android-standard-source.zip
- AM2ARM-1.6.1-android-dual-source.zip
- AM2ARM-1.6.1-linux-standard-source.zip
- AM2ARM-1.6.1-linux-dual-source.zip

Other source downloads

- AM2ARM-Autopatcher-1.6.1-android-source.zip
- AM2ARM-Autopatcher-1.6.1-linux-source.zip
- AM2ARM-1.6.1-linux-integration-source.zip
- AM2ARM-1.6.1-trimui-brick-integration-source.zip
- AM2ARM-1.6.1-trimui-brick-dependency-sources.zip
- AM2ARM-Source-Restore-1.6.1.zip
- AM2ARM-1.6.1-dependency-sources.zip

Download matching files from:
https://github.com/PatchDev-AM2ARM/AM2ARM/releases/tag/v1.6.1

## Restore a game project

The game source ZIPs contain code, resource definitions and notices, but not
the original artwork, audio or fonts. To open and build a complete project,
restore the missing files into your own working copy.

1. Extract the chosen source archive and the matching Source Restore archive
   on a computer. Keep an untouched copy of the source archive.
2. Install Python 3.11 or newer and xdelta3 if they are not already available.
   This source utility is a command-line developer tool. It is different from
   the handheld Autopatcher, which already bundles its own installer runtime.
3. Keep your original Windows AM2R 1.1 ZIP unchanged. From the folder containing
   the extracted directories, run, for example:

   ```sh
   python3 AM2ARM-Source-Restore/restore_project.py --project AM2ARM-Android-Standard --zip /path/to/AM2R_11.zip
   ```

   On Windows, use the installed Python launcher instead of python3 if needed.
   Substitute the extracted project directory for the edition you downloaded.
4. Verify the restored inputs:

   ```sh
   python3 AM2ARM-Source-Restore/restore_project.py --project AM2ARM-Android-Standard --check
   ```

5. Read that project's README and the native integration build instructions
   before opening its .yyp in GameMaker. The builds use IDE 2026.100.0.1083 and
   runtime 2026.100.0.1046. GameMaker and the platform toolchains are separate
   requirements; the restoration tool does not install them.

Use this release's matching Source Restore bundle, or PRT 0.3.0 with the
2026-11-13 catalog update. That catalog includes these final-release sources
and retains earlier supported releases. Older PRT packages need the refreshed
catalog; PRT 0.2.0 does not include AM2ARM.
The catalog identifies supported project contents; a renamed folder does not
turn a different source version into a supported one. Keep your own changes
separate when restoring a clean project for the first time.

Native Linux includes extensions that must be built from the provided C/C++
source before the game can be compiled. See the Linux integration instructions
for libAM2RThor.so, libAM2ARMHaptics.so, libAM2ARMSaves.so and the graphics/input
launcher dependencies. Restoring media
does not build native libraries or supply proprietary GameMaker tools.

## Building the Autopatchers

The Android and Linux patchers use separate platform interfaces around the
same reconstruction approach. Their source exports omit generated patch data
and game media. The same Source Restore command accepts the extracted
AM2ARM-Autopatcher-Android or AM2ARM-Autopatcher-Linux directory to restore its
interface assets. For a repository checkout, pass autopatcher/android or
autopatcher/linux as the --project directory instead. Both retain the matching
asset-inputs.json. Run --check afterward. Read the respective source package's
build instructions, build the private games, then regenerate both
edition patch bundles against your original AM2R 1.1 ZIP. Never publish those
complete private game outputs as source or release assets.

Rebuilt APKs cannot update the released Android apps without the matching
signing identity. Use your own package IDs and signing for independent builds;
no release signing keys are included. Do not replace the native game's save
identity just to rename the product: it is part of save-format compatibility.

## Licenses

Each game project preserves its original LICENSE.txt and other notices.
The game license is not the patcher's MIT license. Game media retains its
original ownership. Native integration and bundled dependencies retain their
individual licenses and corresponding-source information. Read those notices
before redistributing a modified build.

## Contributing

Report bugs at https://github.com/PatchDev-AM2ARM/AM2ARM/issues with the exact
platform, edition, device, firmware and repeatable actions. The main README lists verified hardware and remaining limits. Do not attach original game ZIPs, complete game packages,
signing credentials or saves containing progress unless they are requested.

Development uses GameMaker Studio 2 projects, not the original GameMaker 1.4
workspace. The pinned baseline is IDE 2026.100.0.1083 with runtime
2026.100.0.1046. Restore an isolated source project as described in
this guide before editing. Keep restored media and generated build output
out of the source repository. Patcher changes belong under autopatcher/android
or autopatcher/linux. Game changes use the named source archives attached to
the release as their baseline; include the exact archive filename and a focused
diff when proposing an update. Native Linux integration and source restoration
code are also supplied as separate release archives.

Changes shared by gameplay, enemies, rooms, save serialization or Nano should
be considered for both Android and Linux and for each applicable edition.
Keep platform-specific display, audio, input and packaging code in its existing
integration layer. If a change applies to only one target, explain the reason
and test the unaffected target where practical. Separate source directories do
not mean independently maintained game rules.

Prefer small changes with behavior checks over broad mechanical rewrites.
Match the surrounding GML, Java, C or Python conventions. Keep resource names
stable unless every reference and save consequence is understood. Do not
silence a warning by changing behavior without a reproducer.

Before proposing a change, record:

- The problem and affected platform/edition.
- What changed and why it preserves or intentionally changes behavior.
- How it was checked, including the exact hardware/firmware for device tests.
- Any remaining limitation or untested target.

For rendering work, compare the same scene/settings and inspect the picture.
For performance work, compare matching clock presets and avoid on-device
recording during measurement. Average FPS alone can hide stalls or slow game
simulation. Distinguish normal rendering from Nano and simulated limits from
real hardware results.

For packaging, verify patch reconstruction against the exact private game
build, preserve dependency notices, and ensure original game inputs, personal
paths, credentials, private saves and development recordings are absent from
public output. Android upgrades must preserve the published package/signing
identities; independent developer builds need their own identities.

Do not upload generated APKs, full restored projects or original media in a
pull request. Source and dependency licenses remain applicable to contributions.

[Back to installation and compatibility](../README.md).
