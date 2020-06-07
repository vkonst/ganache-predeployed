#!/usr/bin/env sh

while true; do
    nc -z localhost "${GANACHE_PORT:-8555}" && break
    sleep 1
done
