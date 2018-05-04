#!/bin/bash

# Variables
WITH_DOCKER=false
PPA="valhalla-core/valhalla"

for arg in "$@"; do
  shift
  case "$arg" in
    "--with-docker") WITH_DOCKER=true ;;
  esac
done

git submodule update --init --recursive

if [ $WITH_DOCKER = true ]
then
    docker build -t tpportugal/tpp_valhalla:latest .
else
    sudo apt-get install -y software-properties-common
    if ! grep -q "^deb .*$PPA" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
      sudo add-apt-repository -y ppa:valhalla-core/valhalla
    fi
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y --no-install-recommends \
    autoconf \
    automake \
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
    pkg-config \
    prime-server0.6.3-bin \
    protobuf-compiler vim-common \
    python-all-dev \
    spatialite-bin \
    zlib1g-dev \
    unzip
    ./autogen.sh
    ./configure
    make test -j$(nproc)
    sudo make install
    sudo ldconfig
fi
