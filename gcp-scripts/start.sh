#!/usr/bin/env sh

set -o errexit

export GANACHE_PORT=8555
export GCP_ROOT="/app/gcp-scripts"

tenEthers="10000000000000000000"
thousandEthers="1000000000000000000000"

# addresses:
#'0xDf08F82De32B8d460adbE8D72043E3a7e25A3B39',
#'0x6704Fbfcd5Ef766B287262fA2281C105d57246a6',
#'0x9E1Ef1eC212F5DFfB41d35d9E5c14054F26c6560',
#'0xce42bdB34189a93c55De250E011c68FaeE374Dd3'

accounts="\
--account=\"0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200,${thousandEthers}\" \
--account=\"0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201,${tenEthers}\" \
--account=\"0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501202,${tenEthers}\" \
--account=\"0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501203,${tenEthers}\" \
"

# do post-start jobs in background
[ -x "${GCP_ROOT}/post-start.sh" ] && (
  "${GCP_ROOT}/post-start.sh" &
) >&1 2>&1

exec node /app/ganache-core.docker.cli.js \
  --port "${GANACHE_PORT}" \
  --gasLimit 0xfffffffffff \
   ${accounts} \
   ${GANACHE_PARAMS}  # '--debug --verbose' for deugging
