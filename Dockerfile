FROM ubuntu:20.04
LABEL maintainer="fedormelexin@gmail.com"

ARG HASURA_VER
ARG PG_CLIENT_VER
ENV HASURA_VER ${HASURA_VER:-1.3.3}
ENV PG_CLIENT_VER ${PG_CLIENT_VER:-13}
ENV HASURA_ROOT /hasura/
ENV LC_ALL=C.UTF-8
WORKDIR $HASURA_ROOT

# Add PG repo to fetch last clients and libs
RUN apt-get update && apt-get install -y gnupg2 curl apt-transport-https
# Create the file repository configuration
RUN echo "deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# Import the repository signing key
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
# Deps
RUN apt-get update && apt-get install -y libncurses5 libtinfo-dev unixodbc-dev git build-essential llvm wget libnuma-dev zlib1g-dev libpq-dev postgresql-client-common postgresql-client-${PG_CLIENT_VER} libkrb5-dev libssl-dev
RUN wget https://downloads.haskell.org/~ghc/8.10.2/ghc-8.10.2-aarch64-deb10-linux.tar.xz && \
    wget http://downloads.haskell.org/~cabal/cabal-install-3.2.0.0/cabal-install-3.2.0.0.tar.gz && \
    tar xf ghc-8.10.2-aarch64-deb10-linux.tar.xz && tar xzf cabal-install-3.2.0.0.tar.gz && \
    rm *.gz *.xz
WORKDIR $HASURA_ROOT/ghc-8.10.2
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
RUN /root/.cabal/bin/cabal v2-build --ghc-options="+RTS -M3G -c -RTS -O0 -j1" -j1
RUN mv `find dist-newstyle/ -type f -name graphql-engine` /srv/

FROM ubuntu:18.04
ENV HASURA_ROOT /hasura/
WORKDIR $HASURA_ROOT/
COPY --from=0 $HASURA_ROOT/graphql-engine/console .
RUN apt-get update && apt-get install -y wget make
RUN wget -O - https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update && apt-get install -y nodejs python-pip libffi-dev libssl-dev
RUN pip install gsutil
RUN make deps server-build

FROM ubuntu:20.04
LABEL maintainer="fedormelexin@gmail.com"
ENV HASURA_ROOT /hasura/
COPY --from=0 /srv/graphql-engine /srv/
COPY --from=1 $HASURA_ROOT/static/dist/ /srv/console-assets
RUN apt-get update && apt-get install -y curl gnupg2
# Create the file repository configuration
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# Import the repository signing key
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get install -y libnuma-dev libpq-dev postgresql-client-common postgresql-client-${PG_CLIENT_VER} ca-certificates && apt remove -y curl gnupg2 && apt autoremove -y && apt-get clean all
ENV PATH=/srv/:$PATH
CMD ["graphql-engine", "serve", "--console-assets-dir", "/srv/console-assets"]
