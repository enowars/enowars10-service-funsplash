FROM ghcr.io/gleam-lang/gleam:v1.17.0-erlang-alpine AS erlang

FROM python:3.14-alpine

# Copy Erlang runtime (same OTP version as server, both musl)
COPY --from=erlang /usr/local/lib/erlang /usr/local/lib/erlang
ENV PATH="/usr/local/lib/erlang/bin:${PATH}"

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apk add --no-cache libzbar binutils
RUN ln -s /usr/lib/libzbar.so.0 /usr/lib/libzbar.so

RUN adduser -s /bin/bash -u 1000 checker -D -S

WORKDIR /checker

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-cache --no-dev --no-install-project

COPY ./src .
COPY ./photos ./photos

RUN chown -R checker: /checker

USER checker

ENTRYPOINT [ "/checker/.venv/bin/gunicorn", "-c", "gunicorn.conf.py", "checker:app" ]
