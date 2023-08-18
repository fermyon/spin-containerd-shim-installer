# Download the containerd-shim-spin
FROM debian:bullseye as shim-downloader
WORKDIR /downloads
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y \
    && apt-get install -y wget
# NOTE: this binary uses the $(ARCH)-unknown-linux-musl triplet
ARG SHIM_VERSION=0.5.1
RUN wget -q -O - "https://github.com/deislabs/containerd-wasm-shims/releases/download/v${SHIM_VERSION}/containerd-wasm-shims-v1-linux-$(uname -m).tar.gz" | tar -xvz -f - containerd-shim-spin-v1

# Download the toml CLI tool
FROM rust:bullseye as toml-downloader
RUN export TARG="$(uname -m)-unknown-linux-musl" \
  && rustup target add "$TARG" \
  && cargo install --target "$TARG" --version 0.2.3 toml-cli

# Copy dependencies into the final image
FROM busybox:1.36
WORKDIR /work

COPY --from=toml-downloader /usr/local/cargo/bin/toml /usr/local/bin/toml
COPY --from=shim-downloader /downloads/containerd-shim-spin-v1 ./containerd-shim-spin-v1

COPY ./entrypoint.sh .
CMD ["./entrypoint.sh"]
