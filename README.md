# spin-containerd-shim-installer

This project provides an automated method to install and configure the containerd shim for Fermyon Spin in Kubernetes.

## Versions

The version of the container image and Helm chart directly correlates to the version of the containerd shim. For simplicity, here is a table depicting the version matrix between Spin and the containerd shim.

| containerd-shim-spin-v*                                                         | Spin                                                          |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| [v0.9.3](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.9.3) | [v2.0.0](https://github.com/fermyon/spin/releases/tag/v2.0.0) |
| [v0.9.2](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.9.2) | [v1.5.0](https://github.com/fermyon/spin/releases/tag/v1.5.0) |
| [v0.9.1](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.9.1) | [v1.4.1](https://github.com/fermyon/spin/releases/tag/v1.4.1) |
| [v0.9.0](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.9.0) | [v1.4.1](https://github.com/fermyon/spin/releases/tag/v1.4.1) |
| [v0.8.0](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.8.0) | [v1.4.0](https://github.com/fermyon/spin/releases/tag/v1.4.0) |
| [v0.7.0](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.7.0) | [v1.2.0](https://github.com/fermyon/spin/releases/tag/v1.2.0) |
| [v0.6.0](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.6.0) | [v1.1.0](https://github.com/fermyon/spin/releases/tag/v1.1.0) |
| [v0.5.1](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.5.1) | [v1.0.0](https://github.com/fermyon/spin/releases/tag/v1.0.0) |

## Installation Requirements

At a high level, in order to add a new runtime shim to containerd we must accomplish the following:

1. Adding the `containerd-shim-spin-v1` binary to the node's path (default location: `/usr/local/bin`)
2. Appending the `containerd-shim-spin-v1` runtime to containerd's config (default location: `/etc/containerd/config.toml`)
3. Applying a `RuntimeClass` that you can specify in a pod's spec for containerd to use

Because of these constraints, installing an additional runtime for containerd requires _privileged access_ to a node. Currently this repository only contains a way to install the runtime shim via Kubernetes resources but another option would be to customize a base image for your nodes with these constraints in mind.

### Install via Helm

This project provides a Helm chart that includes a [DaemonSet](chart/templates/daemonset.yaml) which runs an [init container](image/Dockerfile) _in privileged mode_ in order to copy the binary to the node and update the containerd config with the new runtime. This is the most generic way to install the containerd runtime shim in Kubernetes environments.

```shell
helm install spin-containerd-shim-installer oci://ghcr.io/fermyon/charts/spin-containerd-shim-installer --version 0.9.3
```

## Disclaimer

As mentioned above, the Helm chart's method of installation does currently require privileged access to a node. Please be sure to review the [DaemonSet](chart/templates/daemonset.yaml), install script [entrypoint.sh](image/entrypoint.sh) and accompanying [Dockerfile](image/Dockerfile).
