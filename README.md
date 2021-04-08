# graphql-engine-arm64
Dockerfile for hasura/graphql-engine to run on arm64/aarch64 (tested on Nvidia Jetson Nano, Rpi4)

# To run on ARMv7 check this repo first
https://github.com/rebot/graphql-engine-armv7

# Build from source (or skip this step to pull image from hub.docker.com)
For 1.3.3 (default)
```bash
git clone https://github.com/melehin/graphql-engine-arm64
cd graphql-engine-arm64
docker build -t fedormelexin/graphql-engine-arm64 .
```
For 2.0.0-*
```bash
export DOCKER_USERNAME=fedormelexin
export HASURA_VERSION=2.0.0-alpha.7
git clone https://github.com/melehin/graphql-engine-arm64
cd graphql-engine-arm64
docker build --build-arg HASURA_VER=${HASURA_VERSION} -t "${DOCKER_USERNAME}/graphql-engine-arm64:${HASURA_VERSION}" .
```

# Image versions on DockerHub
* fedormelexin/graphql-engine-arm64:1.3.3 **(latest stable)**
* fedormelexin/graphql-engine-arm64:2.0.0-alpha.7 **(latest alpha)**
* fedormelexin/graphql-engine-arm64:2.0.0-alpha.6
* fedormelexin/graphql-engine-arm64:2.0.0-alpha.5
* fedormelexin/graphql-engine-arm64:2.0.0-alpha.4
* fedormelexin/graphql-engine-arm64:2.0.0-alpha.3
* fedormelexin/graphql-engine-arm64:1.3.1

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
    image: fedormelexin/graphql-engine-arm64 # 1.3.3 by default (see the Image versions above)
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
