# Download the containerd-shim-spin
FROM debian:bullseye as shim-downloader
WORKDIR /downloads
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y \
    && apt-get install -y wget

RUN wget -q -O - "https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.9.0/containerd-wasm-shims-v1-spin-linux-x86_64.tar.gz" | tar -xvz -f - containerd-shim-spin-v1 \
    && mv containerd-shim-spin-v1 containerd-shim-spin-v0-9-0-v1 \
    && wget -q -O - "https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.9.1/containerd-wasm-shims-v1-spin-linux-x86_64.tar.gz" | tar -xvz -f - containerd-shim-spin-v1 \
    && mv containerd-shim-spin-v1 containerd-shim-spin-v0-9-1-v1 \
    && wget -q -O - "https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.9.2/containerd-wasm-shims-v1-spin-linux-x86_64.tar.gz" | tar -xvz -f - containerd-shim-spin-v1 \
    && mv containerd-shim-spin-v1 containerd-shim-spin-v0-9-2-v1 \
    && wget -q -O - "https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.9.3/containerd-wasm-shims-v2-spin-linux-x86_64.tar.gz" | tar -xvz -f - containerd-shim-spin-v2 \
    && mv containerd-shim-spin-v2 containerd-shim-spin-v0-9-3-v2 \
    && wget -q -O - "https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.10.0/containerd-wasm-shims-v2-spin-linux-x86_64.tar.gz" | tar xvz -f - containerd-shim-spin-v2 \
    && mv containerd-shim-spin-v2 containerd-shim-spin-v0-10-0-v2

# Download the toml CLI tool
FROM rust:bullseye as toml-downloader
RUN export TARG="$(uname -m)-unknown-linux-musl" \
  && rustup target add "$TARG" \
  && cargo install --target "$TARG" --version 0.2.3 toml-cli

# Copy dependencies into the final image
FROM busybox:1.36
WORKDIR /work

COPY --from=toml-downloader /usr/local/cargo/bin/toml /usr/local/bin/toml
COPY --from=shim-downloader /downloads/containerd-shim-spin-v0-9-0-v1 ./containerd-shim-spin-v0-9-0-v1
COPY --from=shim-downloader /downloads/containerd-shim-spin-v0-9-1-v1 ./containerd-shim-spin-v0-9-1-v1
COPY --from=shim-downloader /downloads/containerd-shim-spin-v0-9-2-v1 ./containerd-shim-spin-v0-9-2-v1
COPY --from=shim-downloader /downloads/containerd-shim-spin-v0-9-3-v2 ./containerd-shim-spin-v0-9-3-v2
COPY --from=shim-downloader /downloads/containerd-shim-spin-v0-10-0-v2 ./containerd-shim-spin-v0-10-0-v2

COPY ./entrypoint.sh .
CMD ["./entrypoint.sh"]
