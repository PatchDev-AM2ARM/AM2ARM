#!/bin/sh
# Build gmloader-next and the dualscreen plugin from /src into /out.
set -eu
CROSS=aarch64-linux-gnu
LIBS=/usr/lib/$CROSS
export PKG_CONFIG_LIBDIR=$LIBS/pkgconfig:/usr/share/pkgconfig

cd /src
rm -rf build plugins/dualscreen/build
make -f Makefile.gmloader ARCH=$CROSS PKG_CONFIG=pkg-config LLVM_FILE=/usr/lib/llvm-11/lib/libclang-11.so \
    LLVM_INC=/usr/$CROSS/include/c++/10/$CROSS -j"$(nproc)"
make -C plugins/dualscreen ARCH=$CROSS PKG_CONFIG=pkg-config

mkdir -p /out/lib/arm64-v8a /out/fallback /out/licenses
cp build/$CROSS/gmloader/gmloadernext.aarch64 /out/
cp plugins/dualscreen/build/libdualscreen.so /out/lib/
# Preloaded by the launcher when the firmware owns the motor
$CROSS-gcc -Wall -Wextra -Werror -O2 -fPIC -shared -fvisibility=hidden /rumble.c -o /out/lib/librumble.so -ldl
cp -L lib/arm64-v8a/*.so /out/lib/arm64-v8a/
# Used only when the firmware has no copy
for lib in libSDL2-2.0.so.0 libwayland-client.so.0 libwayland-cursor.so.0 libwayland-egl.so.1 libxkbcommon.so.0 libffi.so.7; do
    cp -L $LIBS/$lib /out/fallback/
done
for file in /out/gmloadernext.aarch64 /out/lib/*.so /out/lib/arm64-v8a/*.so /out/fallback/*; do
    $CROSS-strip --strip-unneeded "$file"
done
chmod 755 /out/gmloadernext.aarch64

# Fail when a needed library is neither in /out nor on every firmware.
for file in /out/gmloadernext.aarch64 /out/lib/*.so /out/fallback/*; do
    for lib in $($CROSS-readelf -d "$file" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'); do
        case "$lib" in
            ld-linux-aarch64.so.1|libc.so.6|libdl.so.2|libgcc_s.so.1|libm.so.6|libpthread.so.0|librt.so.1|libstdc++.so.6|libz.so.1) ;;
            *) [ -f "/out/fallback/$lib" ] || { echo "$file needs $lib"; exit 1; } ;;
        esac
    done
done

cp LICENSE.md /out/licenses/gmloader-next.txt
cp 3rdparty/libzip/LICENSE /out/licenses/libzip.txt
cp 3rdparty/libbsd/COPYING /out/licenses/libbsd.txt
cp 3rdparty/libmd/COPYING /out/licenses/libmd.txt
cp 3rdparty/json/LICENSE.MIT /out/licenses/json.txt
cp 3rdparty/FMOD_SDL/LICENSE /out/licenses/FMOD_SDL.txt
cp 3rdparty/opensles/LICENSE.khronos /out/licenses/opensles.txt
cp /sdl/LICENSE.txt /out/licenses/SDL2.txt
{
    echo "gmloader-next $(git rev-parse HEAD 2>/dev/null || echo 'from a local checkout')  https://github.com/JeodC/gmloader-next"
    echo "SDL $1  https://github.com/libsdl-org/SDL"
    for package in libwayland-client0 libwayland-cursor0 libwayland-egl1 libxkbcommon0 libffi7; do
        cp /usr/share/doc/$package/copyright /out/licenses/$package.txt
        dpkg-query -W -f 'Debian ${Package} ${Version}, source ${source:Package} ${source:Version}\n' $package:arm64
    done
} > /out/SOURCES.txt
cat /out/SOURCES.txt
find /out -type f -exec ls -l {} +
