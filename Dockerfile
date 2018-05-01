FROM ubuntu:14.04
WORKDIR /valhalla
ADD . /valhalla/
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:valhalla-core/valhalla
RUN apt-get update
RUN apt-get install -y autoconf automake make libtool pkg-config g++ gcc jq lcov protobuf-compiler vim-common libboost-all-dev libboost-all-dev libcurl4-openssl-dev zlib1g-dev liblz4-dev libprime-server0.6.3-dev libprotobuf-dev prime-server0.6.3-bin
RUN apt-get install -y libgeos-dev libgeos++-dev liblua5.2-dev libspatialite-dev libsqlite3-dev lua5.2
RUN apt-get install -y python-all-dev
RUN bash autogen.sh
RUN configure
RUN make test -j$(nproc)
RUN make install