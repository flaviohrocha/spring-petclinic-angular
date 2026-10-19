#!/bin/sh
set -eu

: "${REST_API_URL:=http://localhost:9966/petclinic/api/}"
export REST_API_URL

envsubst '${REST_API_URL}' \
  < /etc/petclinic/runtime-config.js.template \
  > /var/run/petclinic-runtime-config.js

exec "$@"
