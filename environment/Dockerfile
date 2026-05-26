FROM rust:1.85-slim-bookworm

ENV RUSTUP_HOME="/usr/local/rustup"
ENV CARGO_HOME="/usr/local/cargo"
ENV PATH="/usr/local/cargo/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    patch \
    && rm -rf /var/lib/apt/lists/*

# Symlink cargo to /usr/local/bin so it's always in PATH
RUN ln -sf /usr/local/cargo/bin/cargo /usr/local/bin/cargo && \
    ln -sf /usr/local/cargo/bin/rustc /usr/local/bin/rustc

# Git config for commits
RUN git config --global user.email "m.workman@outlook.com" && \
    git config --global user.name "markw53"

# Install pytest system-wide (must be before USER switch)
RUN pip3 install pytest --break-system-packages

# Copy source repo from local context
COPY source_code/ /source/

# Remove all existing tests (zero-test environment policy)
RUN rm -rf /source/tests/ /source/test/ && \
    find /source -name "test_*.py" -delete && \
    find /source -name "*_test.py" -delete

# Initialize git repo and squash history
RUN cd /source && \
    git init && \
    git add -A && \
    git commit -m "source state - ready for translation"

# Initialize /target as an empty git repo (required for test_patch.diff apply)
RUN git init /target && \
    cd /target && \
    git commit --allow-empty -m "init"

# Create required directories
RUN mkdir -p /logs/verifier /logs/artifacts /tests /solution

# Create user with uid 1000
RUN id user >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash user
RUN chown -R user:user /source /target /logs /tests /solution
RUN chown -R user:user /usr/local/cargo || true

USER user
WORKDIR /source
