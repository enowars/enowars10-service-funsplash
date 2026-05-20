ARG GLEAM_VERSION=v1.16.0
ARG ERLANG_VERSION=29

# --- Build stage ---
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

# 1. Install build tools immediately
RUN apk add --no-cache make gcc musl-dev

WORKDIR /build

# 2. Optimize caching: Copy ONLY manifest files first
COPY ./shared/gleam.toml ./shared/manifest.toml ./shared/
COPY ./client/gleam.toml ./client/manifest.toml ./client/
COPY ./server/gleam.toml ./server/manifest.toml ./server/

# Download dependencies (Docker will cache this heavily)
RUN cd shared && gleam deps download
RUN cd client && gleam deps download
RUN cd server && gleam deps download

# 3. Copy actual source code
COPY ./shared ./shared
COPY ./client ./client
COPY ./server ./server

# 4. Compile client (assumes lustre_dev_tools is in gleam.toml)
RUN cd client \
    && gleam run -m lustre/dev build --minify --outdir=../server/priv/static

# 5. Compile server
RUN cd server \
    && gleam export erlang-shipment


# --- Runtime stage ---
# Use plain Erlang to avoid shipping the Gleam compiler to production
FROM erlang:${ERLANG_VERSION}-alpine

WORKDIR /app

# Set up non-root user for security
RUN addgroup --system webapp \
    && adduser --system webapp -g webapp

# Copy the compiled release and assign ownership to webapp
COPY --from=builder --chown=webapp:webapp /build/server/build/erlang-shipment /app

# Drop root privileges
USER webapp

# Execute the native shipment script directly
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
