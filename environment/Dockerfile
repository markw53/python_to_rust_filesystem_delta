FROM rust:1.85-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/cargo/bin:${PATH}"
ENV CARGO_NET_OFFLINE=true
ENV RUSTUP_TOOLCHAIN=stable

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    patch \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/task-venv \
    && /opt/task-venv/bin/pip install --upgrade pip \
    && /opt/task-venv/bin/pip install --no-cache-dir pytest

# Pre-cache cargo registry for offline builds
RUN mkdir -p /tmp/cache_project/src && \
    echo 'fn main() {}' > /tmp/cache_project/src/main.rs && \
    printf '[package]\nname = "cache"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\nwalkdir = "2"\nsha2 = "0.10"\nserde = { version = "1.0", features = ["derive"] }\nserde_json = "1.0"\nfiletime = "0.2"\nhex = "0.4"\nanyhow = "1.0"\n\n[dev-dependencies]\ntempfile = "3"\n' > /tmp/cache_project/Cargo.toml && \
    cd /tmp/cache_project && \
    cargo fetch && \
    cargo build --release 2>/dev/null || true && \
    rm -rf /tmp/cache_project

COPY source_code/ /source/

RUN rm -rf /source/.git /source/.github /source/.pytest_cache \
    /source/tests /source/test \
    && find /source -name "test_*.py" -delete \
    && find /source -name "*_test.py" -delete \
    && find /source -name "__pycache__" -type d -prune -exec rm -rf {} +

RUN if ! id -u user >/dev/null 2>&1; then \
    existing_user="$(getent passwd 1000 | cut -d: -f1)"; \
    if [ -n "$existing_user" ]; then \
    usermod -l user "$existing_user"; \
    existing_group="$(getent group 1000 | cut -d: -f1)"; \
    if [ -n "$existing_group" ]; then groupmod -n user "$existing_group"; fi; \
    else \
    useradd -m -u 1000 -s /bin/bash user; \
    fi; \
    fi \
    && mkdir -p /target /logs/verifier /logs/artifacts \
    && chmod -R a+rX /source \
    && chown -R user:user /source /target /logs /opt/task-venv \
    && chown -R user:user /usr/local/cargo || true \
    && chmod -R a+rwX /source /target /logs

RUN printf '%s\n' \
    '#!/bin/sh' \
    'for candidate in "$HOME"/.nvm/current/bin/opencode "$HOME"/.nvm/versions/node/*/bin/opencode /root/.nvm/current/bin/opencode /root/.nvm/versions/node/*/bin/opencode /home/user/.nvm/current/bin/opencode /home/user/.nvm/versions/node/*/bin/opencode; do' \
    '    if [ -x "$candidate" ]; then exec "$candidate" "$@"; fi' \
    'done' \
    'echo "opencode executable not found after Harbor agent setup" >&2' \
    'exit 127' \
    > /usr/local/bin/opencode \
    && chmod +x /usr/local/bin/opencode

USER user
WORKDIR /target

RUN git config --global user.email "m.workman@outlook.com" && \
    git config --global user.name "markw53" && \
    git config --global safe.directory "*" && \
    git config --global init.defaultBranch main && \
    git init /target && \
    git commit --allow-empty -m "init"

USER root

RUN git config --global --add safe.directory /source && \
    git config --global user.email "m.workman@outlook.com" && \
    git config --global user.name "markw53" && \
    cd /source && \
    git init && \
    git add -A && \
    git commit -m "source state - ready for translation"
