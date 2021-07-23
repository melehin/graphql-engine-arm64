FROM golang as cli-builder
ARG SERVER_IMAGE=fedormelexin/graphql-engine-arm64
ARG SERVER_IMAGE_TAG=v2.0.0-beta.2
RUN apt update && apt install -y npm

RUN mkdir -p /go/src/github.com/hasura
WORKDIR /go/src/github.com/hasura
RUN git clone https://github.com/hasura/graphql-engine -b $SERVER_IMAGE_TAG
WORKDIR graphql-engine/cli

# Patching
RUN sed -i '/osarch/s+linux/amd64\|darwin/amd64\|darwin/arm64\|windows/amd64++g' Makefile
RUN sed -i '/linux-x64\|macos\|win/d' Makefile
RUN sed -i -E '/osarch/s/[ ]+"/"/' Makefile
RUN sed -i -E '/osarch/s/"[ ]+/"/' Makefile
RUN sed -i 's/cli-ext-hasura-node12-linux-arm64/cli-ext-hasura-linux/' Makefile
RUN sed -i -E 's|node([0-9]+).+"|node\1-linux-arm64"|' ../cli-ext/package.json
RUN sed -i 's|bin/cli-ext-hasura|bin/cli-ext-hasura-linux|' ../cli-ext/package.json
RUN sed -i -E 's|\$\(BUILDDIR\)/cli-ext-hasura-node(.+)-linux-x64.+|\$\(BUILDDIR\)/cli-ext-hasura-linux|' ../cli-ext/Makefile

RUN make build-cli-ext copy-cli-ext deps build

FROM fedormelexin/graphql-engine-arm64:v2.0.0-beta.2
RUN apt-get update && apt-get install -y netcat

# set an env var to let the cli know that
# update notification is disabled
ENV HASURA_GRAPHQL_SHOW_UPDATE_NOTIFICATION=false

ARG SCRIPT_VERSION=v3
ARG SERVER_IMAGE_TAG=v2.0.0-beta.2
COPY --from=cli-builder /go/src/github.com/hasura/graphql-engine/scripts/cli-migrations/${SCRIPT_VERSION}/docker-entrypoint.sh /bin/
COPY --from=cli-builder /go/src/github.com/hasura/graphql-engine/cli/_output/${SERVER_IMAGE_TAG}-dirty/cli-hasura-linux-arm64 /bin/hasura-cli

RUN chmod +x /bin/hasura-cli 
RUN chmod +x /bin/docker-entrypoint.sh

# set an env var to let the cli know that
# it is running in server environment
ENV HASURA_GRAPHQL_CLI_ENVIRONMENT=server-on-docker

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["graphql-engine", "serve"]
