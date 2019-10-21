#!/bin/bash
echo "Starting"
if [ -f ${flight_SERVICE_etc}/example.rc ]; then
  . ${flight_SERVICE_etc}/example.rc
fi
echo "${example_things:-Things}"
tool_bg sleep ${example_time:-60}
tool_set pid=$!
