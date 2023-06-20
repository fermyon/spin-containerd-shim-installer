#!/usr/bin/env sh

set -euo

##
# variables
##
HOST_CONTAINERD_CONFIG="${HOST_CONTAINERD_CONFIG:-/host/etc/containerd/config.toml}"
HOST_BIN="${HOST_BIN:-/host/bin}"

RUNTIME_CONFIG_TYPE="${RUNTIME_CONFIG_TYPE:-io.containerd.spin.v1}"
RUNTIME_CONFIG_HANDLE="${RUNTIME_CONFIG_HANDLE:-spin}"
RUNTIME_CONFIG_TABLE="plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.${RUNTIME_CONFIG_HANDLE}"

##
# helper functions
##
get_runtime_type() {
  toml get -r "${1}" "${RUNTIME_CONFIG_TABLE}.runtime_type"
}

set_runtime_type() {
  echo "adding spin runtime '${RUNTIME_CONFIG_TYPE}' to ${HOST_CONTAINERD_CONFIG}"
  tmpfile=$(mktemp)
  toml set "${HOST_CONTAINERD_CONFIG}" "${RUNTIME_CONFIG_TABLE}.runtime_type" "${RUNTIME_CONFIG_TYPE}" > "${tmpfile}"

  # ensure the runtime_type was set
  if [ "$(get_runtime_type "${tmpfile}")" = "${RUNTIME_CONFIG_TYPE}" ]; then
    # overwrite the containerd config with the temp file
    mv "${tmpfile}" "${HOST_CONTAINERD_CONFIG}"
    echo "committed changes to containerd config"
  else
    echo "failed to set runtime_type to ${RUNTIME_CONFIG_TYPE}"
    exit 1
  fi
}

##
# assertions
##
if [ ! -f "./containerd-shim-spin-v1" ]; then
  echo "shim binary not found"
  exit 1
fi

if [ ! -d "${HOST_BIN}" ]; then
  echo "one of the host's bin directories should be mounted to ${HOST_BIN}"
  exit 1
fi

if [ ! -f "${HOST_CONTAINERD_CONFIG}" ]; then
  echo "containerd config '${HOST_CONTAINERD_CONFIG}' does not exist"
  echo "creating a default containerd config with 'containerd config default'"
  nsenter -m/proc/1/ns/mnt -- containerd config default > "${HOST_CONTAINERD_CONFIG}"
fi

echo "copying the shim to the node's bin directory '${HOST_BIN}'"
cp "./containerd-shim-spin-v1" "${HOST_BIN}"

# check if the shim is already in the containerd config
if [ "$(get_runtime_type "${HOST_CONTAINERD_CONFIG}")" = "${RUNTIME_CONFIG_TYPE}" ]; then
  echo "runtime_type is already set to ${RUNTIME_CONFIG_TYPE}"
else
  set_runtime_type

  echo "restarting containerd"
  nsenter -m/proc/1/ns/mnt -- systemctl restart containerd

  #TODO: add label to node for scheduling
fi
