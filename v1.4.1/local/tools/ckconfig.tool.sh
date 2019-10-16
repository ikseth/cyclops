#!/bin/bash

#### Check Active Services on boot ####
#### WARN: Change "activo ~ on" depends environment variables (local language)

export LANG="en_EN.UTF-8"

for _daemon in `chkconfig | grep "3:on" | awk '{ print $1 }'`
do 
	_status=`/etc/init.d/$_daemon status 2>&1 >/dev/null ; echo $?` 
	echo $_daemon" : "$_status 
done

