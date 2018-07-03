#!/bin/bash

# Variables
BUILD_CLEAN=false
WITH_DOCKER=false
PPA="valhalla-core/valhalla"

for arg in "$@"; do
  shift
  case "$arg" in
    --clean) BUILD_CLEAN=true ;;
    --with-docker) WITH_DOCKER=true ;;
    --help|-h|*) echo "Usage: ./build.sh [OPTIONS]"
              echo "Available options:"
              echo "  --with-docker  Build with docker. False if ommited."
              echo "  --clean        Cleanup build artifacts. False if ommited."
              echo "  --help, -h     Show this message"
    exit ;;
  esac
done

if [ $BUILD_CLEAN = true ]
then
    rm -rf build
fi

git submodule update --init --recursive

if [ $WITH_DOCKER = true ]
then
    docker build -t tpportugal/tpp_valhalla:latest .
else
    sudo apt-get install -y software-properties-common
    if ! grep -q "^deb .*$PPA" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
      sudo add-apt-repository -y ppa:"$PPA"
    fi
    sudo apt-get update
    sudo apt-get upgrade -y --no-install-recommends
    sudo apt-get install -y --no-install-recommends \
    cmake \
    g++ \
    gcc \
    jq \
    lcov \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libgeos-dev \
    libgeos++-dev \
    liblua5.2-dev \
    liblz4-dev \
    libprime-server0.6.3-dev \
    libprotobuf-dev \
    libspatialite-dev \
    libsqlite3-dev \
    libsqlite3-mod-spatialite \
    libtool \
    lua5.2 \
    make \
    nodejs \
    pkg-config \
    prime-server0.6.3-bin \
    protobuf-compiler \
    vim-common \
    python-all-dev \
    spatialite-bin \
    zlib1g-dev \
    unzip \
    wget

    mkdir build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_NODE_BINDINGS=OFF
    make -j$(nproc)
    make check
    sudo make install
    sudo ldconfig
fi
