# TrimUI Brick integration for AM2ARM 1.6.1

These adapters run Linux Standard on NextUI and the stock menu. They share
the game code, data and common Linux Autopatcher. No game assets, patches or
executables are included in this source directory.

Restore the matching Linux Autopatcher source with the 1.6.1 Source Restore
companion. Put its interface assets and shared Python modules in
`AM2ARM/patcher/`, and these adapters in `AM2ARM/runtime/`. The Standard patch
bundle belongs in `AM2ARM/patcher/patch-bundle/standard/`. The public Brick
download supplies the built runtime and patches; rebuilding the game still
requires your original AM2R 1.1 ZIP.

`nextui_gui.py` runs the shared controller interface. Its copy of
`handheld_gui.py` imports `prepare_game` from `nextui_install`; completion
instructions name Apps when `AM2ARM_FRONTEND=stock`, otherwise Tools.
`nextui_layout.py` creates the matching menu entry. NextUI uses
`Tools/tg5040/AM2ARM Standard.pak/`; stock uses `Apps/AM2ARMStandard/`.
Stock App directory names contain no spaces because its menu does not quote
the generated launch command. Labels can still contain spaces.

`nextui_session.py` uses bundled application libraries with firmware SDL/EGL
and the Westonpack Crusty/GL4ES bridge. Xvfb supplies the input/installer
display. System libraries and clocks stay unchanged. Stock saves live in
the installed game's `state/config/AM2RStandardLinux/`; an existing native
save directory is copied and preserved before redirection. NextUI retains
its existing `.userdata/tg5040/.config/AM2RStandardLinux/` location.

The printed Brick face buttons use 1/0/3/2 for A/B/X/Y. Existing user bindings
are preserved. `brick_rumble.py` drives the firmware motor for the built-in
pad through an application-local socket. It stops after 600 ms without an
update and on exit, and restores the previous motor voltage. The native
library retains the common evdev vibration backend for other controllers.

Build that library with Clang/LLD and an ARM64 Debian 12 development sysroot:

```sh
SYSROOT=/path/to/sysroot sh native/rumble/build.sh libAM2ARMHaptics.so
```

Put it in `AM2ARM/runtime/rumble/` with `library.json` containing the SHA-256
values `original` (the matching game's vibration library) and `brick` (this
built library). Startup replaces only the recognized original, preserves a
backup in the game's state folder, and leaves modified libraries alone.
`start.sh` selects the frontend explicitly; it does not replace firmware.

Run checks with `python3 -B -m unittest discover -s .`. A C compiler is needed
for the native bridge check. Set `AM2ARM_LINUX_LAUNCHER` to the restored game's
`runtime/launch.py` to include the optional existing-save integration check.

References: [stock App format](https://github.com/trimui/assets_brick),
[NextUI motor interface](https://github.com/LoveRetro/NextUI/blob/main/workspace/tg5040/platform/platform.c),
[display bridge](https://github.com/binarycounter/Westonpack),
[GL4ES](https://github.com/ptitSeb/gl4es).
