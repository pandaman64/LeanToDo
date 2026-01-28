FROM debian:trixie-slim AS builder

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

ENV ELAN_HOME=/root/.elan
ENV PATH="${ELAN_HOME}/bin:${PATH}"

RUN curl -sSf https://elan.lean-lang.org/elan-init.sh | sh -s -- -y \
  && elan toolchain install 4.27.0 \
  && elan default 4.27.0

WORKDIR /workspace

COPY lakefile.toml lake-manifest.json lean-toolchain /workspace/

RUN lake update

COPY . /workspace

RUN mkdir -p /out \
  && lake build \
  && cp /workspace/.lake/build/bin/leantodo /out/leantodo

FROM debian:trixie-slim AS runtime

WORKDIR /app

COPY --from=builder /out/leantodo /app/leantodo

ENTRYPOINT ["/app/leantodo"]
