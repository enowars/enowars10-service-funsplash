FROM ghcr.io/gleam-lang/gleam:v1.16.0-erlang-alpine

WORKDIR /build

COPY ./server /build/server

# compile backend
RUN cd /build/server \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

# run server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
