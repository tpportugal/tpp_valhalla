FROM ubuntu:16.04
MAINTAINER TPP <api@tpp.pt>
RUN apt-get -qq update && \
    apt-get -q -y upgrade && \
    apt-get install -y sudo curl wget locales && \
    rm -rf /var/lib/apt/lists/*
# Ensure that we always use UTF-8 and with European Portuguese locale
RUN locale-gen pt_PT.UTF-8
ENV LC_ALL=pt_PT.UTF-8
ENV LANG=pt_PT.UTF-8
ENV LANGUAGE=pt_PT.UTF-8
# Setting working dir
WORKDIR /data/valhalla
RUN apt-get -qq update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:valhalla-core/valhalla
RUN apt-get -qq update && \
    apt-get install -y --no-install-recommends autoconf automake make libtool \
    pkg-config g++ gcc jq lcov protobuf-compiler vim-common libboost-all-dev \
    libboost-all-dev libcurl4-openssl-dev zlib1g-dev liblz4-dev libgeos++-dev \
    libgeos-dev libprime-server0.6.3-dev libprotobuf-dev prime-server0.6.3-bin \
    liblua5.2-dev libspatialite-dev libsqlite3-dev lua5.2 python-all-dev \
    libsqlite3-mod-spatialite spatialite-bin
# Mount data A.K.A "ADD" after packages installation for docker caching
ADD . /data/valhalla/libvalhalla/
RUN cd libvalhalla && \
    ./autogen.sh && \
    ./configure --enable-static=yes && \
    make test -j$(nproc) && \
    make install && \
    make clean && \
    cd - && \
    rm -rf libvalhalla && \
    ldconfig
