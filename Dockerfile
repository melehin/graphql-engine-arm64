FROM ubuntu:18.04
LABEL maintainer="fedormelexin@gmail.com"

ARG HASURA_VER
ENV HASURA_VER ${HASURA_VER:-1.3.1}
ENV HASURA_ROOT /hasura/
ENV LC_ALL=C.UTF-8
WORKDIR $HASURA_ROOT

# Deps
RUN apt-get update && apt-get install -y libncurses5 git build-essential llvm wget libnuma-dev zlib1g-dev libpq-dev postgresql-client-common postgresql-client libkrb5-dev libssl-dev
RUN wget https://downloads.haskell.org/~ghc/8.10.1/ghc-8.10.1-aarch64-deb9-linux.tar.xz && \
    wget http://downloads.haskell.org/~cabal/cabal-install-3.2.0.0/cabal-install-3.2.0.0.tar.gz && \
    tar xf ghc-8.10.1-aarch64-deb9-linux.tar.xz && tar xzf cabal-install-3.2.0.0.tar.gz && \
    rm *.gz *.xz
WORKDIR $HASURA_ROOT/ghc-8.10.1
RUN ./configure && make install
WORKDIR $HASURA_ROOT/
# from https://aur.archlinux.org/cgit/aur.git/plain/ghc_8_10.patch?h=cabal-static
COPY ghc_8_10.patch .
WORKDIR $HASURA_ROOT/cabal-install-3.2.0.0
RUN patch -p1 < ../ghc_8_10.patch
RUN bash ./bootstrap.sh

# graphql-engine
WORKDIR $HASURA_ROOT
RUN git clone -b v$HASURA_VER https://github.com/hasura/graphql-engine.git
WORKDIR graphql-engine/server
RUN /root/.cabal/bin/cabal v2-update
RUN /root/.cabal/bin/cabal v2-build --ghc-options="+RTS -M2G -c -RTS -j1" -j1
