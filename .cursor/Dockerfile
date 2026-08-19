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

# Install elan (the Lean toolchain manager). No toolchain is pinned here: elan
# reads lean-toolchain and installs the right toolchain on demand during the
# install step, so this image stays correct across toolchain upgrades.
ENV ELAN_HOME=/home/ubuntu/.elan
ENV PATH="/home/ubuntu/.elan/bin:${PATH}"
RUN curl -sSf https://elan.lean-lang.org/elan-init.sh \
    | sh -s -- -y --default-toolchain none
