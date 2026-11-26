gmloader-next for the Linux download

gmloader-next runs the Android build of the game on ARM64 Linux, with the
firmware's SDL2 and OpenGL ES. Its dualscreen plugin opens the second window and
provides the functions of extensions/AM2RDualScreen.

Build it and its libraries with Docker:

  docker build --output out .

GMLOADER_COMMIT in the Dockerfile pins the version. stage.sh collects:

  gmloadernext.aarch64   the loader, for glibc 2.27 and newer
  lib                    the dualscreen plugin, rumble.c, and the Android C and C++
                         libraries the game links
  fallback               SDL2 and Wayland client libraries, used only when the
                         firmware has no ARM64 copy
  licenses, SOURCES.txt  notices and exact versions

rumble.c passes vibration the controller can't play to the launcher, which
drives the motor. See native/unified/runtime/brick_rumble.py.

The build stops if a file needs a library that neither firmware nor this folder
supplies. The Linux release workflow runs the same build. gmloader.json is the
game's configuration. The launcher adds the paths on the card.

https://github.com/JeodC/gmloader-next (GPL-2.0)
