# recdvb configured without `--enable-b25`
FROM debian:buster-slim AS recdvb-build

ARG recdvb_version=1.3.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq
RUN apt-get install -y -qq --no-install-recommends \
    ca-certificates curl \
    autoconf automake make pkg-config g++

RUN mkdir -p /build
WORKDIR /build
RUN curl -fsSL http://www13.plala.or.jp/sat/recdvb/recdvb-$recdvb_version.tgz \
    | tar -xz --strip-components=1
RUN ./autogen.sh
RUN ./configure --prefix=/usr/local
RUN sed -i -e s/msgbuf/_msgbuf/ recpt1core.h
RUN sed -i '1i#include <sys/types.h>' recpt1.h
RUN make -j $(nproc)
RUN make install


# recpt1 configured without `--enable-b25`
FROM debian:buster-slim AS recpt1-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq
RUN apt-get install -y -qq --no-install-recommends \
    ca-certificates curl \
    autoconf automake make pkg-config g++

RUN mkdir -p /build
WORKDIR /build
RUN curl -fsSL https://github.com/stz2012/recpt1/tarball/master \
    | tar -xz --strip-components=1
WORKDIR /build/recpt1
RUN ./autogen.sh
RUN ./configure --prefix=/usr/local
RUN make -j $(nproc)
RUN make install


# mirakc-arib
FROM debian:buster-slim AS mirakc-arib-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq
RUN apt-get install -y -qq --no-install-recommends \
    ca-certificates curl \
    cmake git dos2unix make ninja-build autoconf automake libtool pkg-config \
    g++

RUN mkdir -p /build
WORKDIR /build
RUN curl -fsSL https://github.com/masnagam/mirakc-arib/tarball/master \
    | tar -xz --strip-components=1
RUN cmake -S . -B . -G Ninja -D CMAKE_BUILD_TYPE=Release
RUN ninja vendor
RUN ninja


# mirakc
FROM rust:slim-buster AS mirakc-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq
RUN apt-get install -y -qq --no-install-recommends \
    ca-certificates curl g++

RUN mkdir -p /build
WORKDIR /build
RUN curl -fsSL https://github.com/masnagam/mirakc/tarball/master \
    | tar -zx --strip-components=1
RUN cargo build --release


# final image
FROM debian:buster-slim

COPY --from=recdvb-build /usr/local/bin/recdvb /usr/local/bin/
COPY --from=recpt1-build /usr/local/bin/recpt1 /usr/local/bin/
COPY --from=mirakc-arib-build /build/bin/mirakc-arib /usr/local/bin/
COPY --from=mirakc-build /build/target/release/mirakc /usr/local/bin/

RUN set -eux \
 && export DEBIAN_FRONTEND=noninteractive \
 && apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends ca-certificates curl socat \
 # cleanup
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/tmp/* \
 && rm -rf /tmp/*

ENV MIRAKC_CONFIG=/etc/mirakc/config.yml
EXPOSE 40772
VOLUME ["/var/lib/mirakc/epg"]
ENTRYPOINT ["mirakc"]
CMD []
