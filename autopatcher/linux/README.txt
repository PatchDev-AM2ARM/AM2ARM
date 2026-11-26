AM2ARM Linux Autopatcher source

From the repository root, prepare the restoration bundle using docs/README.md.
Use your original Windows AM2R 1.1 ZIP to restore the interface artwork,
fonts and audio for this patcher:

  python3 restoration/restore_project.py --project autopatcher/linux --zip "/path/to/AM2R_11.zip"
  python3 restoration/restore_project.py --project autopatcher/linux --check

asset-inputs.json lists the editable sources, restorable files and generated
inputs. The installer reads a release's AM2ARM-gmloader ZIP, which
autopatcher/android/make_port_data.py writes, and builds the archive that
gmloader-next runs. Nothing is patched separately for Linux.

  python3 linux_patcher.py --zip "/path/to/AM2R_11.zip" --game AM2ARM-gmloader-VERSION.zip

The handheld uses Python 3.11, Tk and a bundled ARM64 decoder. Read RUNNING.txt
for the layout. See native/unified for the launcher and dependencies/README.txt
for exact matching runtime sources. The handheld's Debian xdelta3
3.0.11-dfsg-1.2 retains its own license. See LICENSE and licenses/.
