#!/bin/bash
dir=$(cd "$(dirname "$0")" && pwd)
echo "Restarting: $@"
bash -x $dir/stop.sh "$@"
bash -x $dir/start.sh
