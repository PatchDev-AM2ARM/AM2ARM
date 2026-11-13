AM2ARM Linux Autopatcher - optional desktop source interface

The published Linux download is the handheld installer. These sources also
retain a desktop interface for preparing ARM64 game folders on a computer.
It does not turn the game into a native x86/x86-64 desktop release.

Use Python 3.11 or newer, Tk and an xdelta3 decoder built for the host processor.
Restore the matching UI assets and supply both generated edition patch bundles
as described in this source archive's README. Then run:

  python3 linux_patcher.py

Select the original AM2R 1.1 ZIP, edition and an empty output folder. The command
line accepts the same inputs:

  python3 linux_patcher.py --zip /path/to/AM2R_11.zip --out /path/to/output --edition standard
  python3 linux_patcher.py --zip /path/to/AM2R_11.zip --out /path/to/output --edition dual

Copy the prepared game folder and matching .sh launcher together into Ports
on a compatible handheld's Linux card. RUNNING.txt covers installation and
supported firmware. No original game data or complete game is supplied here.
The patcher verifies its inputs and output and refuses to overwrite an existing
game directory. Keep save backups before preparing an update.

build_portable.py retains an optional x86-64 Linux packaging path. It is a
development option, not a separately verified desktop download in this release.
The source and all dependencies retain their supplied license notices.
