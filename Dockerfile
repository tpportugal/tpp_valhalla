FROM ubuntu:16.04
LABEL maintainer="TPP <api@tpp.pt>"
# Set working dir
WORKDIR /data/valhalla
RUN apt-get -qq update && \
    apt-get -q -y upgrade && \
    apt-get install -y sudo curl wget locales && \
    rm -rf /var/lib/apt/lists/*
# Ensure that we always use UTF-8 and with European Portuguese locale
RUN locale-gen pt_PT.UTF-8
ENV LC_ALL=pt_PT.UTF-8
ENV LANG=pt_PT.UTF-8
ENV LANGUAGE=pt_PT.UTF-8
RUN apt-get -qq update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:valhalla-core/valhalla
RUN apt-get -qq update && \
    apt-get install -y --no-install-recommends \
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
# Mount data A.K.A "ADD" after packages installation for docker caching
COPY . libvalhalla/
WORKDIR libvalhalla
RUN ./autogen.sh && \
    ./configure --enable-static=yes && \
    make test -j$(nproc) && \
    make install && \
    make clean
WORKDIR /data/valhalla
RUN rm -rf libvalhalla && \
    ldconfig
EXPOSE 8002
