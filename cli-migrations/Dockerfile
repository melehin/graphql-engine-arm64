FROM golang as cli-builder
ARG SERVER_IMAGE=fedormelexin/graphql-engine-arm64
ARG SERVER_IMAGE_TAG=v2.0.0-alpha.10
RUN apt update && apt install -y npm

RUN mkdir -p /go/src/github.com/hasura
WORKDIR /go/src/github.com/hasura
RUN git clone https://github.com/hasura/graphql-engine -b $SERVER_IMAGE_TAG
WORKDIR graphql-engine/cli

# Patching
RUN sed -i 's/ darwin windows//' Makefile
RUN sed -i 's/amd64/arm64/' Makefile
RUN sed -i -E 's|hasura-linux(.+)|hasura-linux|' ../cli-ext/Makefile
RUN sed -i -E 's|node(.+)-linux-.+"|node\1-linux-arm64"|' ../cli-ext/package.json
RUN sed -i 's|bin/cli-ext-hasura|bin/cli-ext-hasura-linux|' ../cli-ext/package.json

RUN make build-cli-ext copy-cli-ext deps assets build

FROM ${SERVER_IMAGE}:${SERVER_IMAGE_TAG}
RUN apt-get update && apt-get install -y netcat

# set an env var to let the cli know that
# update notification is disabled
ENV HASURA_GRAPHQL_SHOW_UPDATE_NOTIFICATION=false

ARG SCRIPT_VERSION=v2
ARG SERVER_IMAGE_TAG=v2.0.0-alpha.10
COPY --from=cli-builder /go/src/github.com/hasura/graphql-engine/scripts/cli-migrations/${SCRIPT_VERSION}/docker-entrypoint.sh /bin/
COPY --from=cli-builder /go/src/github.com/hasura/graphql-engine/cli/_output/${SERVER_IMAGE_TAG}-dirty/cli-hasura-linux-arm64 /bin/hasura-cli

RUN chmod +x /bin/hasura-cli 
RUN chmod +x /bin/docker-entrypoint.sh

# set an env var to let the cli know that
# it is running in server environment
ENV HASURA_GRAPHQL_CLI_ENVIRONMENT=server-on-docker

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["graphql-engine", "serve"]
