#!/bin/bash

# Variables
BUILD_CLEAN=false
WITH_DOCKER=false
PPA="valhalla-core/valhalla"
NODE="node_10.x"

for arg in "$@"; do
  shift
  case "$arg" in
    --clean) BUILD_CLEAN=true ;;
    --with-docker) WITH_DOCKER=true ;;
    --help|-h|*) echo "Usage: ./build.sh [OPTIONS]"
              echo "Available options:"
              echo "  --with-docker  Build with docker. False if ommited."
              echo "  --clean        Cleanup build artifacts and ignore docker cache. False if ommited."
              echo "  --help, -h     Show this message"
    exit ;;
  esac
done

if [ $BUILD_CLEAN = true ]; then
  if [ -d "build" ]; then
    rm -rf build
  fi
  if [ -d "node_modules" ]; then
    rm -rf node_modules
  fi
fi

git submodule update --init --recursive

if [ $WITH_DOCKER = true ]; then
  if [ $BUILD_CLEAN = true ]; then
    docker build --shm-size 512M --no-cache -t tpportugal/tpp_valhalla:latest .
  else
    docker build --shm-size 512M -t tpportugal/tpp_valhalla:latest .
  fi
else
  sudo apt-get install -y software-properties-common curl gnupg
  if [ ! grep -q "^deb .*$PPA" /etc/apt/sources.list /etc/apt/sources.list.d/* ]; then
    sudo add-apt-repository -y ppa:"$PPA"
  fi
  if [ ! grep -q "^deb .*$NODE" /etc/apt/sources.list /etc/apt/sources.list.d/* ]; then
    sudo curl -sL https://deb.nodesource.com/setup_10.x | bash
  fi
  sudo apt-get update
  sudo apt-get upgrade -y --no-install-recommends
  sudo apt-get install -y --no-install-recommends \
  cmake \
  g++ \
  gcc \
  jq \
  lcov \
  libboost1.58-all-dev \
  libboost-date-time1.58.0 \
  libboost-filesystem1.58.0 \
  libboost-program-options1.58.0 \
  libboost-regex1.58.0 \
  libboost-system1.58.0 \
  libboost-thread1.58.0 \
  libboost-iostreams1.58.0 \
  libcurl4-openssl-dev \
  libgeos-3.5.0 \
  libgeos-dev \
  libgeos++-dev \
  liblua5.2 \
  liblua5.2-dev \
  liblz4-dev \
  libprime-server0.6.3-dev \
  libprotobuf9v5 \
  libprotobuf-dev \
  libspatialite-dev \
  libsqlite3-0 \
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
  if [ ! -d "build" ]; then
    mkdir build
  fi
  cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_PYTHON_BINDINGS=Off -DENABLE_NODE_BINDINGS=Off
  make -j$(nproc)
  make -j$(nproc) tests
  make -j$(nproc) check
  sudo make install
  sudo ldconfig
fi
