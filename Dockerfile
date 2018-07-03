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
    apt-get -q -y upgrade --no-install-recommends && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:valhalla-core/valhalla
RUN apt-get -qq update && \
    apt-get install -y --no-install-recommends \
    cmake \
    g++ \
    gcc \
    jq \
    lcov \
    libboost-all-dev \
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
    npm \
    pkg-config \
    prime-server0.6.3-bin \
    protobuf-compiler \
    vim-common \
    python-all-dev \
    spatialite-bin \
    zlib1g-dev \
    unzip
# Mount data A.K.A "ADD" after packages installation for docker caching
COPY . /data/valhalla/libvalhalla/
WORKDIR /data/valhalla/libvalhalla
RUN mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make check && \
    make install && \
    rm -rf /data/valhalla/libvalhalla/build
WORKDIR /data/valhalla
RUN rm -rf /data/valhalla/libvalhalla && \
    ldconfig
RUN apt-get -y purge  \
    cmake \
    g++ \
    gcc \
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
    libtool \
    make \
    pkg-config \
    protobuf-compiler \
    vim-common \
    python-all-dev \
    zlib1g-dev \
    && apt-get autoremove -y && apt-get clean
EXPOSE 8002
