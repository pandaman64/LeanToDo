FROM debian:trixie-slim

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# System toolchain needed to build LeanToDo and its native dependencies
# (leansqlite compiles C code, so build-essential is required).
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    build-essential \
    sudo \
  && rm -rf /var/lib/apt/lists/*

# Cloud Agents run as the "ubuntu" user; create it with passwordless sudo.
RUN useradd --create-home --shell /bin/bash ubuntu \
  && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
  && chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu
WORKDIR /home/ubuntu

# Install elan (the Lean toolchain manager) and pre-warm the toolchain pinned
# by lean-toolchain. elan still auto-installs a different toolchain on demand
# if the repository changes lean-toolchain later.
ENV ELAN_HOME=/home/ubuntu/.elan
ENV PATH="/home/ubuntu/.elan/bin:${PATH}"
RUN curl -sSf https://elan.lean-lang.org/elan-init.sh \
    | sh -s -- -y --default-toolchain leanprover/lean4:v4.27.0 \
  && elan default leanprover/lean4:v4.27.0
