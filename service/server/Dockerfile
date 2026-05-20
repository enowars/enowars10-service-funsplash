ARG ERLANG_VERSION=29
ARG GLEAM_VERSION=v1.16.0

# Gleam stage
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# Build stage
FROM erlang:${ERLANG_VERSION}-alpine AS build
COPY --from=gleam /bin/gleam /bin/gleam
COPY . /app/
RUN apk add --no-cache make gcc musl-dev wget
RUN wget https://s3.amazonaws.com/rebar3/rebar3 && chmod +x rebar3 && mv rebar3 /usr/local/bin/rebar3
RUN cd /app && gleam export erlang-shipment

# Final stage
FROM erlang:${ERLANG_VERSION}-alpine
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}
COPY healthcheck.sh /app/healthcheck.sh
RUN \
  chmod +x /app/healthcheck.sh \
  && addgroup --system webapp \
  && adduser --system webapp -g webapp
USER webapp
COPY --from=build /app/build/erlang-shipment /app
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
