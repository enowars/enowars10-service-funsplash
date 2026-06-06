ARG GLEAM_VERSION=v1.16.0
ARG ERLANG_VERSION=29

# --- Dev / Builder stage ---
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS dev

RUN apk add --no-cache make gcc musl-dev curl bash

WORKDIR /app

# Download Tools & Hex Packages (Depends ONLY on manifests)
COPY ./shared/gleam.toml ./shared/manifest.toml ./shared/
COPY ./client/gleam.toml ./client/manifest.toml ./client/
COPY ./server/gleam.toml ./server/manifest.toml ./server/

RUN cd shared && gleam deps download \
    && cd ../client && gleam deps download \
    && cd ../server && gleam deps download

# Pre-compile Dependencies (The "Stub" Cache)
RUN mkdir -p shared/src client/src server/src \
    && echo "pub fn main() { Nil }" > shared/src/shared.gleam \
    && echo "pub fn main() { Nil }" > client/src/client.gleam \
    && echo "pub fn main() { Nil }" > server/src/server.gleam \
    && cd client && gleam run -m lustre/dev build \
    && cd ../server && gleam build

# For prod builds, we copy everything. For dev builds, volume mounts overwrite this anyway.
COPY . .

# --- Builder Stage (for Production) ---
FROM dev AS builder
RUN cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static
RUN cd server && gleam export erlang-shipment

# --- Runtime stage (for Production) ---
FROM erlang:${ERLANG_VERSION}-alpine AS prod
WORKDIR /app
RUN addgroup --system webapp && adduser --system webapp -g webapp
COPY --from=builder --chown=webapp:webapp /app/server/build/erlang-shipment /app
USER webapp
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]

