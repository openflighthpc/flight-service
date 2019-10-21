#!/bin/bash
echo "Configuring"
echo "$@"
mkdir -p "${flight_SERVICE_etc}"
>"${flight_SERVICE_etc}/example.rc"
for a in "$@"; do
  IFS="=" read k v <<< "${a}"
  echo "example_$k=\"$v\"" >> "${flight_SERVICE_etc}/example.rc"
done
