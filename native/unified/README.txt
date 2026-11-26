AM2ARM Linux launcher

The standalone download contains one am2arm-launcher folder. Its Ports,
Apps and Tools shortcuts start the same launcher. See README-card.txt for
the card instructions. PortMaster is not required.

runtime/first_run.py locates an original Windows ZIP and checks whether the
game on the card came from this release. If it didn't, the handheld installer
builds it. Games and saves live in AM2ARM-data, outside the launcher folder. The
first installation copies the latest saves of the native Linux editions, up to
1.6.3.

route.py checks the compositor with a Wayland round trip, or identifies a
supported board. It passes the result to session.sh for both setup and play.
runtime/play.py runs the installed game with the bundled gmloader-next and the
firmware's SDL2, EGL, GLES and audio. On direct displays it tries the firmware's
libraries until one submits a frame. Boards, display sizes and SDL
drivers are in runtime/compat_display.py and trimui_device.py, controller
mappings in nextui_controls.py and the Brick's motor in brick_rumble.py.

The installer uses Python and Tk on Xwayland or Xvfb. They come from an earlier
release, and their sources are in dependencies. The game does not use them.

Run the launcher tests from the repository root:

  export PYTHONDONTWRITEBYTECODE=1
  export PYTHONPATH=native/unified/runtime:autopatcher/linux:native/unified/tests
  python3 -m unittest discover -s native/unified/tests -t native/unified/tests

Assembling the launcher

Publish a release with the two files autopatcher/android/make_port_data.py
writes. The Linux release workflow builds native/gmloader, runs package_sd.py
and adds the Linux download to the release. To do the same by hand:

  docker build --output gmloader native/gmloader
  python3 native/unified/package_sd.py --installer INSTALLER.zip --gmloader gmloader \
    --game AM2ARM-gmloader-VERSION.zip --music AM2ARM-music.zip --output linux

package_sd.py --help names the INSTALLER.zip it expects. The version comes from
the game files. See menus/dependencies/README.md for the included components,
notices and source archives.
