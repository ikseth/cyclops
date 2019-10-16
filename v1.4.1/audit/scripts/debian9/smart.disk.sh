#!/bin/bash

_prefix="60;smart disk"
_smart_disk=""  
_smart_disk_count=0

_smart_cmd=$( which smartctl 2>/dev/null )
_lsblk_cmd=$( which lsblk 2>/dev/null )

if [ ! -z "$_smart_cmd" ] && [ ! -z "$_lsblk_cmd" ]
then
	for _disk in $( eval exec $_lsblk_cmd  --nodeps --noheadings | awk '{ print $1 }' ) 
	do 
		_data=$( eval exec $_smart_cmd -i /dev/$_disk | egrep "Vendor|Product|Serial|Firmware|Revision|Capacity|Model" 2>/dev/null ) 
		_check_data=$( echo $_data | grep "NETAPP" | wc -l )
		if [ "$_check_data" -eq 0 ] 
		then
			let "_smart_disk_count++"
			_data=$( echo "${_data}" | sed "s/^/$_smart_disk_count;local disk;$_disk;/" )
			_smart_disk=$_smart_disk"\n"$_data
		fi
	done 
fi

if [ ! -z "$_smart_disk" ] 
then
	echo -e "${_smart_disk}" | sed -e '/^$/d' -e "s/^/$_prefix;/" -e 's/:/;/' -e 's/;[ ]*/;/g' 
fi

