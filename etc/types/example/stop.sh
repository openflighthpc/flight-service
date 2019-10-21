#!/bin/bash
echo "Stopping: $@"
pid=$(cat "$1")
kill $pid
