#!/usr/bin/env sh
# minimalistic web-server for a single file

file_to_serve="${1:-index.html}"
_port="${2:-8080}";

echo "serving ${file_to_serve} on localhost:${_port} ..."

while true; do
  sleep 1
  [ -f "${file_to_serve}" ] || break

  {
    echo -e 'HTTP/1.1 200 OK\r\n';
    cat "${file_to_serve}";
  } | nc -l -p "${_port}";
done
