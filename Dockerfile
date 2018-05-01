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
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:valhalla-core/valhalla
RUN apt-get update
RUN apt-get install -y autoconf automake make libtool pkg-config g++ gcc jq lcov protobuf-compiler vim-common libboost-all-dev libboost-all-dev libcurl4-openssl-dev zlib1g-dev liblz4-dev libprime-server0.6.3-dev libprotobuf-dev prime-server0.6.3-bin
RUN apt-get install -y libgeos-dev libgeos++-dev liblua5.2-dev libspatialite-dev libsqlite3-dev lua5.2
RUN apt-get install -y python-all-dev
# Mount data A.K.A "ADD" after packages installation for docker caching
ADD . /data/valhalla/
RUN ./autogen.sh
RUN ./configure
RUN make test -j$(nproc)
RUN make install
RUN ldconfig