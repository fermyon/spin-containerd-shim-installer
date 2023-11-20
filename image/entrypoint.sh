#!/usr/bin/env sh

set -euo

default_shim="containerd-shim-spin-v0-9-2-v1"
shims="containerd-shim-spin-v0-9-0-v1 containerd-shim-spin-v0-9-1-v1 containerd-shim-spin-v0-9-2-v1 containerd-shim-spin-v0-9-3-v2 containerd-shim-spin-v0-10-0-v2"

##
# variables
##
HOST_CONTAINERD_CONFIG="${HOST_CONTAINERD_CONFIG:-/host/etc/containerd/config.toml}"
HOST_BIN="${HOST_BIN:-/host/bin}"

##
# helper functions
##
get_runtime_type() {
  toml get -r "${1}" "plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.${2}.runtime_type"
}

set_runtime_type() {
  tmpfile=$(toml set "${1}" "plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.${2}.runtime_type" "${3}")
  printf '%s' "${tmpfile}" > "${1}"
}

##
# assertions
##
if [ ! -d "${HOST_BIN}" ]; then
  echo "one of the host's bin directories should be mounted to ${HOST_BIN}"
  exit 1
fi

if [ ! -f "${HOST_CONTAINERD_CONFIG}" ]; then
  echo "containerd config '${HOST_CONTAINERD_CONFIG}' does not exist"
  echo "creating a default containerd config with 'containerd config default'"
  nsenter -m/proc/1/ns/mnt -- containerd config default > "${HOST_CONTAINERD_CONFIG}"
fi

# make a copy of the containerd config to work with
tmpconfig="$(mktemp)"
cat "${HOST_CONTAINERD_CONFIG}" > "${tmpconfig}"

ls -al ./

echo "$shims" | tr ' ' '\n' | while read -r shim; do
  if [ ! -f "./${shim}" ]; then
    echo "shim binary ${shim} not found"
    exit 1
  fi

  echo "copying the shim to the node's bin directory '${HOST_BIN}/${shim}'"
  cp "./${shim}" "${HOST_BIN}"
  shim_semver="${shim#containerd-shim-}"  # strip the prefix (ex: spin-v0-9-1-v1)
  shim_semver="${shim_semver%-v?}"        # strip the suffix (ex: spin-v0-9-1)
  shim_spec="${shim:-2}"                  # get version of the shim spec (ex: v1)
  echo "adding shim '${shim_semver}' to containerd config"
  set_runtime_type "${tmpconfig}" "${shim_semver}" "io.containerd.${shim_semver}.${shim_spec}"

  if [ "${shim}" = "${default_shim}" ]; then
    echo "setting the default shim to ${shim}"
    set_runtime_type "${tmpconfig}" "spin" "io.containerd.${shim_semver}.${shim_spec}"
  fi
done

echo "making backup of containerd config '${HOST_CONTAINERD_CONFIG}.bak'"
cp "${HOST_CONTAINERD_CONFIG}" "${HOST_CONTAINERD_CONFIG}.bak"

echo "copying the new containerd config to '${HOST_CONTAINERD_CONFIG}'"
cat "${tmpconfig}" > "${HOST_CONTAINERD_CONFIG}"

echo "restarting containerd"
nsenter -m/proc/1/ns/mnt -- systemctl restart containerd
