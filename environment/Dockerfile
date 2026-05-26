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
    && rm -rf /var/lib/apt/lists/*

# Symlink cargo to /usr/local/bin so it's always in PATH
RUN ln -sf /usr/local/cargo/bin/cargo /usr/local/bin/cargo && \
    ln -sf /usr/local/cargo/bin/rustc /usr/local/bin/rustc

# Git config for commits
RUN git config --global user.email "test@test.com" && \
    git config --global user.name "Test"

# Install pytest system-wide (must be before USER switch)
RUN pip3 install pytest --break-system-packages

# Clone the Python source repo and checkout specific commit
RUN git clone --no-tags https://github.com/markw53/python_to_rust_delta.git /repo && \
    git -C /repo checkout 6ccf9b0

# Remove all existing tests (zero-test environment policy)
RUN rm -rf /repo/tests/ /repo/test/ && \
    find /repo -name "test_*.py" -delete && \
    find /repo -name "*_test.py" -delete

# Copy source repo to /source
RUN cp -a /repo/. /source/

# Squash git history to single commit
RUN cd /source && \
    git checkout --orphan single && \
    git add -A && \
    git commit -m "source state - ready for translation" && \
    for b in $(git branch | grep -v '^\*'); do git branch -D "$b"; done && \
    git branch -m main && \
    git remote remove origin 2>/dev/null || true && \
    rm -rf .git/refs/remotes .git/logs && \
    git reflog expire --expire=now --all && \
    git gc --prune=now --aggressive

# Initialize /target as an empty git repo (required for test_patch.diff apply)
RUN git init /target && \
    cd /target && \
    git commit --allow-empty -m "init"

# Create user with uid 1000
RUN id user >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash user
RUN mkdir -p /source /target && chown -R user:user /source /target

# Give user access to cargo registry cache
RUN chown -R user:user /usr/local/cargo || true

# Set rustup default toolchain accessible to all users
RUN rustup default stable && \
    chmod -R a+r /usr/local/rustup && \
    chmod -R a+rx /usr/local/rustup/toolchains

# Create /solution directory
RUN mkdir -p /solution && chown -R user:user /solution

USER user
WORKDIR /source
