#!/bin/bash
WITH_DOCKER=false
for arg in "$@"; do
  shift
  case "$arg" in
    "--with-docker") WITH_DOCKER=true ;;
  esac
done

if [ $WITH_DOCKER = true ] 
then
    docker build -t tpportugal/tpp_valhalla:latest .
else
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:valhalla-core/valhalla
    apt-get update
    apt-get install -y autoconf automake make libtool pkg-config g++ gcc jq lcov protobuf-compiler vim-common libboost-all-dev libboost-all-dev libcurl4-openssl-dev zlib1g-dev liblz4-dev libprime-server0.6.3-dev libprotobuf-dev prime-server0.6.3-bin
    apt-get install -y libgeos-dev libgeos++-dev liblua5.2-dev libspatialite-dev spatialite-bin libsqlite3-dev lua5.2
    apt-get install -y python-all-dev
    ./autogen.sh
    ./configure
    make test -j$(nproc)
    make install
    ldconfig
fi
