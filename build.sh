#!/bin/bash
WITH_DOCKER=false
PPA=valhalla-core/valhalla
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
    sudo apt-get install -y autoconf automake make libtool pkg-config g++ gcc jq lcov protobuf-compiler vim-common libboost-all-dev libboost-all-dev libcurl4-openssl-dev zlib1g-dev liblz4-dev libprime-server0.6.3-dev libprotobuf-dev prime-server0.6.3-bin
    sudo apt-get install -y libgeos-dev libgeos++-dev liblua5.2-dev libspatialite-dev spatialite-bin libsqlite3-dev lua5.2 libsqlite3-mod-spatialite
    sudo apt-get install -y python-all-dev
    ./autogen.sh
    ./configure
    make test -j$(nproc)
    sudo make install
    sudo ldconfig
fi
