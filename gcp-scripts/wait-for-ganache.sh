#!/usr/bin/env sh

while true; do
    nc -z localhost "${GANACHE_PORT:-8545}" && break
    sleep 1
done
