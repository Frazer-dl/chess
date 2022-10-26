FROM ubuntu:bionic as btc-runner-18
USER root
RUN apt-get update
RUN apt-get install -y software-properties-common libzmq5 libfmt-dev make perl gcc libz-dev g++ nano  \
    doxygen build-essential libtool autotools-dev automake pkg-config libevent-dev bsdmainutils python3

FROM btc-runner-18 as chesscoin-build
USER root

COPY dependecies /usr/local/
WORKDIR /usr/local
# unpack dependecies
RUN tar xvfz openssl-1.1.1l.tar.gz
RUN tar xvfz berkeleydb.6.0.20.tar.gz
RUN tar xvfz boost_1_77_0.tar.gz
RUN tar xvfz libpng-1.6.37.tar.gz
RUN rm -rf *.tar.gz
# openssl-1.1.1l install
WORKDIR /usr/local/openssl-1.1.1l
RUN ./config --prefix=/usr/local/ssl.1.1.1 --openssldir=/usr/local/ssl.1.1.1 shared zlib
RUN make
RUN make install
# berkeleydb.6.0.20 install
WORKDIR /usr/local/db-6.0.20/build_unix
RUN ../dist/configure  --prefix=/usr/local/berkeleydb.6.0.20 --enable-cxx --enable-dbm --enable-compat185
RUN make -j4
RUN make install
# boost_1_77_0 install
WORKDIR  /usr/local/boost_1_77_0
RUN ./bootstrap.sh --prefix=/usr/local/boost.1.77.0
RUN ./b2 --with-chrono --with-filesystem --with-program_options --with-system --with-thread toolset=gcc cxxflags="-std=gnu++11" link=static threading=multi runtime-link=static stage
RUN ./b2 install
WORKDIR /usr/local
# miniupnpc install
RUN apt-get install -y libminiupnpc-dev libzmq3-dev
# source code building
COPY source /opt/source
WORKDIR /opt/source
WORKDIR /opt/source/src/leveldb
RUN chmod +x build_detect_platform
RUN TARGET_OS=Linux make libleveldb.a libmemenv.a
WORKDIR /opt/source/src
RUN mkdir obj
RUN mkdir obj/zerocoin
# source code compile
RUN make -f makefile.unix
RUN strip chesscoind

FROM btc-runner-18
USER root
COPY chesscoin.conf /opt/
#COPY --from=chesscoin-build /opt/source/src/chesscoin-cli /usr/local/bin/
COPY --from=chesscoin-build /opt/source/src/chesscoind /usr/local/bin/
COPY ./scripts/chesscoin-cli.sh /usr/local/bin
RUN chmod +x /usr/local/bin/chesscoin-cli.sh

EXPOSE 9332
EXPOSE 9333
#
WORKDIR /usr/local/bin
#ENTRYPOINT ["./litecoind", "--conf=/opt/.litecoin.conf", "-rpcuser=litecoin-rpc", "-rpcpassword=PVXbX9M4bFpucs3XxSlb0RzBrxvYQkF3RaVKf67SAb6G"]
