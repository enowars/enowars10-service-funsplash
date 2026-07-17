FROM python:3.14-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get update && apt-get install -y libzbar0 binutils && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/lib/x86_64-linux-gnu/libzbar.so.0 /usr/lib/libzbar.so

RUN useradd -m -s /bin/bash checker

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
