FROM ubuntu:20.04
LABEL maintainer="fedormelexin@gmail.com"

ARG HASURA_VER
ARG PG_CLIENT_VER
ENV HASURA_VER ${HASURA_VER:-v1.3.3}
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
RUN apt-get update && apt-get install -y libncurses5 libtinfo-dev unixodbc-dev git build-essential llvm-9 wget libnuma-dev zlib1g-dev libpq-dev mysql-client libmysqlclient-dev libghc-pcre-light-dev freetds-dev postgresql-client-${PG_CLIENT_VER} libkrb5-dev libssl-dev
RUN wget https://downloads.haskell.org/~ghc/8.10.2/ghc-8.10.2-aarch64-deb10-linux.tar.xz && \
    wget https://downloads.haskell.org/~cabal/cabal-install-3.4.0.0/cabal-install-3.4.0.0-aarch64-ubuntu-18.04.tar.xz && \
    tar xf ghc* && tar xf cabal-install-3.4.0.0* && \
    rm *.xz
WORKDIR $HASURA_ROOT/ghc-8.10.2
RUN ./configure && make install
WORKDIR $HASURA_ROOT/
RUN mv cabal /usr/bin

# graphql-engine
WORKDIR $HASURA_ROOT
RUN git clone -b $HASURA_VER https://github.com/hasura/graphql-engine.git
WORKDIR graphql-engine/server
RUN cabal v2-update
RUN cabal v2-build --ghc-options="+RTS -M3G -c -RTS -O0 -j1" -j1
RUN mv `find ../dist-newstyle/ -type f -name graphql-engine` /srv/

FROM ubuntu:18.04
ARG PG_CLIENT_VER
ENV HASURA_ROOT /hasura/
ENV PG_CLIENT_VER ${PG_CLIENT_VER:-13}
WORKDIR $HASURA_ROOT/
COPY --from=0 $HASURA_ROOT/graphql-engine/console .
RUN apt-get update && apt-get install -y wget make
RUN wget -O - https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update && apt-get install -y nodejs python3-pip libffi-dev libssl-dev && pip3 install --upgrade pip
RUN pip3 install gsutil
RUN make deps server-build

FROM ubuntu:20.04
ARG PG_CLIENT_VER
ENV HASURA_ROOT /hasura/
ENV PG_CLIENT_VER ${PG_CLIENT_VER:-13}
LABEL maintainer="fedormelexin@gmail.com"
ENV HASURA_ROOT /hasura/
COPY --from=0 /srv/graphql-engine /srv/
COPY --from=1 $HASURA_ROOT/static/dist/ /srv/console-assets
RUN apt-get update && apt-get install -y curl gnupg2
# Create the file repository configuration
RUN echo "deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# Import the repository signing key
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get install -y libnuma-dev unixodbc-dev libpq-dev libmysqlclient-dev postgresql-client-${PG_CLIENT_VER} ca-certificates && apt remove -y curl gnupg2 && apt autoremove -y && apt-get clean all
ENV PATH=/srv/:$PATH
CMD ["graphql-engine", "serve"]
