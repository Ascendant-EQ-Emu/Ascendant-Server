# Multi-stage build for Ascendant Server (EQEmu)
# Stage 1: Build
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    git \
    libtool \
    ninja-build \
    ccache \
    pkg-config \
    zip \
    unzip \
    tar \
    libmariadb-dev \
    libssl-dev \
    libsodium-dev \
    libperl-dev \
    liblua5.1-dev \
    libluabind-dev \
    libcurl4-openssl-dev \
    libyaml-cpp-dev \
    libboost-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy source code
COPY code/ /build/code/

WORKDIR /build/code

# Build with vcpkg and CMake
RUN cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DEQEMU_BUILD_LOGIN=ON \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    && cmake --build build --parallel $(nproc)

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libmariadb3 \
    libssl3 \
    libsodium23 \
    libperl5.36 \
    liblua5.1-0 \
    libcurl4 \
    libyaml-cpp0.7 \
    mariadb-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash eqemu

WORKDIR /home/eqemu/server

# Copy built binaries from builder
COPY --from=builder /build/code/build/bin/ /home/eqemu/server/bin/

# Copy server runtime data
COPY server/assets/ /home/eqemu/server/assets/
COPY server/quests/ /home/eqemu/server/quests/
COPY server/plugins/ /home/eqemu/server/plugins/
COPY server/lua_modules/ /home/eqemu/server/lua_modules/
COPY server/maps/ /home/eqemu/server/maps/
COPY server/shared/ /home/eqemu/server/shared/
COPY server/export/ /home/eqemu/server/export/

# Create needed directories
RUN mkdir -p logs shared && chown -R eqemu:eqemu /home/eqemu

USER eqemu
