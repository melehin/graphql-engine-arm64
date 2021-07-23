# graphql-engine-arm64
Dockerfile for [Hasura GraphQL Engine](https://github.com/hasura/graphql-engine) to run on arm64/aarch64 (tested on Nvidia Jetson Nano, Rpi4, Apple M1)

# Image versions on DockerHub (main images, cli-migrations available on DockerHub also)
* fedormelexin/graphql-engine-arm64:v2.0.3 **(latest stable)**
* fedormelexin/graphql-engine-arm64:v2.0.2
* fedormelexin/graphql-engine-arm64:v2.0.1
* fedormelexin/graphql-engine-arm64:v2.0.0
* fedormelexin/graphql-engine-arm64:v1.3.3 
* fedormelexin/graphql-engine-arm64:v1.3.1

# Build from source
For v2.0.2+
```bash
export DOCKER_USERNAME=fedormelexin
export HASURA_VERSION=v2.0.3
git clone https://github.com/melehin/graphql-engine-arm64
cd graphql-engine-arm64
docker build --build-arg HASURA_VER=${HASURA_VERSION} -t "${DOCKER_USERNAME}/graphql-engine-arm64:${HASURA_VERSION}" .
```
CLI migrations v2 or v3 for v2.0.2+
```bash
export DOCKER_USERNAME=fedormelexin
export HASURA_VERSION=v2.0.3
export SCRIPT_VERSION=v3
git clone https://github.com/melehin/graphql-engine-arm64
cd graphql-engine-arm64/cli-migrations
docker build --build-arg SCRIPT_VERSION=${SCRIPT_VERSION} --build-arg SERVER_IMAGE_TAG=${HASURA_VERSION} --build-arg SERVER_IMAGE=${DOCKER_USERNAME}/graphql-engine-arm64  -t "${DOCKER_USERNAME}/graphql-engine-arm64:v${HASURA_VERSION}.cli-migrations-${SCRIPT_VERSION}" .
```
Use ghc-8.10.2 branch for versions below v2.0.1

# Start a Hasura instance on aarch64
```bash
docker run -d -p 8080:8080 \
  -e HASURA_GRAPHQL_DATABASE_URL=postgres://username:password@hostname:port/dbname \
  -e HASURA_GRAPHQL_ENABLE_CONSOLE=true \
  -e HASURA_GRAPHQL_ADMIN_SECRET=myadminsecretkey \
  fedormelexin/graphql-engine-arm64
```

Hasura Console will be available at http://localhost:8080

# Using docker-compose
## :warning: Replace MYPGDBPASSWORD to your password or generate a new one!
Uncomment HASURA_GRAPHQL_ADMIN_SECRET and set a password if you need it
```
dd if=/dev/random bs=128 count=1 2>/dev/null | sha1sum
```
Example docker-compose.yaml for hasura and postgres:
```yaml
version: '3.6'
services:
  postgres:
    image: postgres
    restart: always
    volumes:
    - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: MYPGDBPASSWORD 
  graphql-engine:
    image: fedormelexin/graphql-engine-arm64
    ports:
    - "8080:8080"
    depends_on:
    - "postgres"
    restart: always
    environment:
      HASURA_GRAPHQL_DATABASE_URL: postgres://postgres:MYPGDBPASSWORD@postgres:5432/postgres
      HASURA_GRAPHQL_ENABLE_CONSOLE: "true" # set to "false" to disable console
      ## uncomment next line to set an admin secret
      # HASURA_GRAPHQL_ADMIN_SECRET: myadminsecretkey
volumes:
  db_data:
```
