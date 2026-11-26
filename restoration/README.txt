AM2ARM source restoration

Use Project Restore Tool 0.3.0 and this checkout's three-project catalog on
a development PC with Python 3.11 or newer and xdelta3 on PATH. Keep your
original Windows AM2R 1.1 ZIP and the unchanged v1.6.1 patch pack together
with a copy of the source for future offline use. Get the pack at

https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.1/AM2ARM-Source-Restore-1.6.1.zip

SHA-256 a5aae1330c3226d0b3945ddae4264b766a91132740b0cb346a5a09fe5c0d6484

From the repository root run

  python3 restoration/prepare_bundle.py "/path/to/AM2ARM-Source-Restore-1.6.1.zip"
  python3 restoration/restore_project.py --project game/android/dual-screen --zip "/path/to/AM2R_11.zip"
  python3 restoration/restore_project.py --project game/android/dual-screen --check

Choose the game or either Autopatcher directory listed in docs/README.md.
The local helper checks the published ZIP and the project fingerprints in
projects.json. It writes the matching game and patcher deltas, manifests
and PRT catalog into the ignored restoration/bundle directory. Re-running
the same command preserves a valid bundle. Use --output for another folder.

The PRT program and catalog format match the 0.3.0 release. Its November
2026 standalone catalog covers older source releases. A portable PRT 0.3.0
can use this freshly prepared bundle with --bundle in its command line.
The original donor and the two deltas are used only on the developer's PC.
Successful restoration reports the expected media hashes. Build game patch
bundles separately as documented in each project.

For a read-only check with JSON output, add --report "/path/to/new-report.json"
to --check. Existing reports and local edits are preserved. Tests:

  python3 -B -m unittest discover -s restoration/tests

The original builder scripts and license notices remain alongside the tool.
