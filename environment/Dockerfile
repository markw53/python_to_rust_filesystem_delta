FROM rust:1.85-slim-bookworm

ENV RUSTUP_HOME="/usr/local/rustup"
ENV CARGO_HOME="/usr/local/cargo"
ENV PATH="/usr/local/cargo/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    patch \
    && rm -rf /var/lib/apt/lists/*

# Symlink cargo and rustc to /usr/local/bin
RUN ln -sf /usr/local/cargo/bin/cargo /usr/local/bin/cargo && \
    ln -sf /usr/local/cargo/bin/rustc /usr/local/bin/rustc

# Install pytest system-wide before USER switch
RUN pip3 install pytest --break-system-packages

# Git config
RUN git config --global user.email "test@test.com" && \
    git config --global user.name "Test"

# Copy source code into /source
COPY source_code/ /source/

# Remove all existing tests
RUN rm -rf /source/tests/ /source/test/ && \
    find /source -name "test_*.py" -delete && \
    find /source -name "*_test.py" -delete

# Initialize /source as a git repo
RUN cd /source && \
    git init && \
    git add -A && \
    git commit -m "source state - ready for translation"

# Initialize /target as empty git repo
RUN git init /target && \
    cd /target && \
    git commit --allow-empty -m "init"

# Create required directories
RUN mkdir -p /logs/verifier /logs/artifacts /tests /solution

# Create user with uid 1000
RUN id user >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash user
RUN chown -R user:user /source /target /logs /tests /solution && \
    chown -R user:user /usr/local/cargo || true

USER user
WORKDIR /source
