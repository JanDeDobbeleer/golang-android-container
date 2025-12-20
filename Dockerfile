FROM ubuntu:20.04

LABEL maintainer "Jan De Dobbeleer"

ENV NDK_VERSION "r29"
ENV GO_VERSION "1.25.5"
ENV GO_BOOTSTRAP_VERSION "1.24.11"

ARG DEBIAN_FRONTEND=noninteractive

# Dependencies
RUN apt-get update \
    && apt-get install --no-install-recommends build-essential wget unzip ca-certificates -y

# Setup NDK
RUN mkdir /opt/android-ndk-tmp && cd /opt/android-ndk-tmp \
    && wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip \
    && unzip ./android-ndk-${NDK_VERSION}-linux.zip \
    && mv ./android-ndk-${NDK_VERSION} /opt/android-ndk \
    && rm -rf /opt/android-ndk-tmp

# Setup Golang Bootstrap to build Golang
RUN wget https://go.dev/dl/go${GO_BOOTSTRAP_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_BOOTSTRAP_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_BOOTSTRAP_VERSION}.linux-amd64.tar.gz

ENV PATH /usr/local/go/bin:$PATH
ENV GOROOT /usr/local/go
ENV NDK_CC /opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi32-clang
ENV CGO_ENABLED 1

# setup flags, taken from
# https://github.com/termux/termux-packages/blob/5bdbfc6b1a134a46e70708706f627e80da2d8d7e/scripts/build/toolchain/termux_setup_toolchain_26b.sh
ENV CFLAGS "-target armv7-none-linux-androideabi -march=armv7-a -mfpu=neon -mfloat-abi=softfp -mthumb -fstack-protector-strong -Oz"
ENV CGO_LDFLAGS "-march=armv7-a -fopenmp -Wl,--enable-new-dtags -Wl,--as-needed"
ENV GO_LDFLAGS="-extldflags=-pie"

# Build Golang for Android
RUN wget -O go.tgz https://dl.google.com/go/go${GO_VERSION}.src.tar.gz \
    && tar -C /opt -xzf go.tgz \
    && rm go.tgz \
    && cd /opt/go/src/ \
    && export GOROOT_BOOTSTRAP="$(go env GOROOT)" \
    && CC_FOR_TARGET=$NDK_CC GOOS=android GOARCH=arm GOARM=7 ./make.bash \
    && rm -rf /usr/local/go

# Setup runtime environment
ENV GOROOT /opt/go
ENV PATH /opt/go/bin:$PATH
ENV CC $NDK_CC
ENV GOOS android
ENV GOARCH arm
ENV GOARM 7

# Create non-root app user and set ownership for runtime
RUN groupadd -g 1000 app || true \
    && useradd -u 1000 -g 1000 -m -d /home/app -s /bin/bash app || true \
    && mkdir -p /work /home/app/.cache \
    && chown -R app:app /opt/go /opt/android-ndk /work /home/app

ENV HOME=/home/app
WORKDIR /work
USER app
