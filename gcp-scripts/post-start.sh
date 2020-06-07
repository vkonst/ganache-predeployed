#!/usr/bin/env sh

set -o errexit

# timeout in seconds
TIMEOUT_SECONDS=${GCP_TIMEOUT_SECONDS:-15};

panic() {
  echo "ERR: $* ... terminating"
  exit 1
}

concat_lines() {
  tr '\n' ';' < "${1}"
}

# 0. if provided, get expected addresses of libs
[ -z "${GCP_EXPECTED_LIBS_FILE}" ] && export GCP_EXPECTED_LIBS_FILE=/tmp/expected_contracts
[ -z "${GCP_DEPLOYED_LIBS_FILE}" ] && export GCP_DEPLOYED_LIBS_FILE="/tmp/deployed_contracts"
[ -f "${GCP_EXPECTED_LIBS_FILE}" ] && export GCP_EXPECTED_LIBS_ADRS=$(concat_lines "${GCP_EXPECTED_LIBS_FILE}")

# 1. wait ganache-cli
timeout -t "${TIMEOUT_SECONDS}" "${GCP_ROOT}/wait-for-ganache.sh" || \
  panic "failed to connect to ganache-cli"

# 2. deploy libs
timeout -t "${TIMEOUT_SECONDS}" "${GCP_ROOT}/deployLibs.js" || \
  panic "failed to deploy libs"

# 3. if defined, serve over http addresses of deployed libs
[ -z "${GCP_SERVE_DEPLOYED_LIBS_LIST}" ] ||
  exec "${GCP_ROOT}/serve_existing_file.sh" "${GCP_DEPLOYED_LIBS_FILE}"

echo "[$0] DONE"
# exit 0
