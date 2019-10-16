#!/bin/bash

_sensor_pid=$(echo $$)

export LANG="en_EN.UTF-8"

if [ -f "$_sensor_remote_path/torquemada.sensor.sh" ]
then
        chmod 755 $_sensor_remote_path/torquemada.sensor.sh
        $_sensor_remote_path/torquemada.sensor.sh $_sensor_pid $_sensor_remote_path/sensor.pid &
fi

trap 'kill -TERM -- -$$' EXIT
