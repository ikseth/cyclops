#!/bin/bash

if [ -f $_sensor_remote_path/sensor.pid ]
then
	rm $_sensor_remote_path/sensor.pid 2>&1 >/dev/null
fi

exit 0
