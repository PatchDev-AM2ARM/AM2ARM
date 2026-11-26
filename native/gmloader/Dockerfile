# Builds gmloader-next and the libraries it needs for ARM64 Linux into ./out:
#
#   docker build --output out .
#
# Add --build-context source=/path/to/gmloader-next to build another checkout.

# The base gmloader-next builds with. Runs on glibc 2.27 and newer.
FROM debian:bullseye AS tools
RUN SNAP=http://snapshot.debian.org/archive; STAMP=20260801T000000Z; \
    { echo "deb $SNAP/debian/$STAMP bullseye main"; \
      echo "deb $SNAP/debian/$STAMP bullseye-updates main"; \
      echo "deb $SNAP/debian-security/$STAMP bullseye-security main"; } > /etc/apt/sources.list && \
    dpkg --add-architecture arm64 && \
    apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Retries=5 update && \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        ca-certificates git build-essential cmake pkg-config python3 python3-clang \
        binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        libstdc++-10-dev-arm64-cross linux-libc-dev-arm64-cross zlib1g-dev:arm64 libzip-dev:arm64 \
        libasound2-dev:arm64 libpulse-dev:arm64 libudev-dev:arm64 libdbus-1-dev:arm64 \
        libdrm-dev:arm64 libgbm-dev:arm64 libgles2-mesa-dev:arm64 libegl1-mesa-dev:arm64 \
        libwayland-dev:arm64 libxkbcommon-dev:arm64

FROM tools AS checkout
ARG GMLOADER_COMMIT=13958c9944f7eb4df9ffd571aca6bbae8bd41226
RUN git clone -q --no-checkout https://github.com/JeodC/gmloader-next.git /src && \
    cd /src && git checkout -q "$GMLOADER_COMMIT" && git submodule update --init --depth 1

FROM scratch AS source
COPY --from=checkout /src /

FROM tools AS build
# For building, and for firmware without an ARM64 SDL2.
ARG SDL_VERSION=release-2.30.11
RUN git clone -q --depth 1 --branch "$SDL_VERSION" https://github.com/libsdl-org/SDL.git /sdl && \
    cmake -S /sdl -B /sdl/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib/aarch64-linux-gnu -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TEST=OFF -DSDL_X11=OFF && \
    make -C /sdl/build -j"$(nproc)" install
COPY --from=source / /src
COPY stage.sh rumble.c /
RUN sh /stage.sh "$SDL_VERSION"

FROM scratch
COPY --from=build /out /
