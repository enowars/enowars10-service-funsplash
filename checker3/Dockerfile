FROM python:3.14-alpine

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apk add --no-cache libzbar binutils
RUN ln -s /usr/lib/libzbar.so.0 /usr/lib/libzbar.so

# add checker user
RUN adduser -s /bin/bash -u 1000 checker -D -S

WORKDIR /checker

# Install dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-cache --no-dev --no-install-project

# Copy source
COPY ./src .
COPY ./photos ./photos

# Ensure checker user owns the directory
RUN chown -R checker: /checker

USER checker

ENTRYPOINT [ "/checker/.venv/bin/gunicorn", "-c", "gunicorn.conf.py", "checker:app" ]
