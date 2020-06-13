#!/usr/bin/env sh
# a minimalistic web-server that
# 1) serves a file
# 2) tries killing the container, if 'GET /kill-container' requested

set -e

_file_to_serve="${1:-index.html}"
_port="${2:-8080}";

_pipe=$(mktemp -u)
trap "rm -f ${_pipe}" TERM EXIT INT

mkfifo ${_pipe}

echo "waiting ${_file_to_serve} to become accessable ..."
while true; do
  [ -f "${_file_to_serve}" ] && break || sleep 1
done

echo "serving ${_file_to_serve} on localhost:${_port} ..."
while true; do

  cat ${_pipe} | \
  (\
    read -r method url version;
    [ "${url}" == "/kill-container" ] && kill 1

    [ -f "${_file_to_serve}" ] && {
      echo -e 'HTTP/1.1 200 OK\r\n';
      echo;
      cat "${_file_to_serve}";
    } || echo -e "HTTP/1.0 404 Not Found\r\n404\r\n";

  ) | \
  nc -l -p "${_port}" > ${_pipe}

  sleep 1
done
