#!/bin/bash

#### DEMON TO KILL TO MUCH TIME SENSOR MONITOR ####


_my_sensor_soul=$1
_my_sensor_soul_file=$2

trap 'kill $$' EXIT

sleep 60s


_alive_soul=$( ps aux | awk -v soul="$_my_sensor_soul" '$2 == soul { print $2 }' )

_log_msg="pid "$_my_sensor_soul 

if [ ! -z "$_alive_soul" ]
then
	echo $(date +%s)" : "$_log_msg" : alive "$_alive_soul" : BURN TO HELL!!" >> ./torquemada.log
	[ -f "$_my_sensor_soul_file" ] && rm -f $_my_sensor_soul_file 2>&1 >/dev/null
	kill $_alive_soul

	echo ";FAIL mon timeout"
	exit 1
fi

#echo $(date +%s)" : "$_log_msg" : dead : SAINT TO HEAVEN!" >> ./torquemada.log 
exit 0
