#!/bin/bash

for _disk in $( fdisk -l | grep -o "/dev/mapper/mpa[a-z]*" | sort -u ) 
do 
	echo $_disk";" $( tune2fs -l $_disk | grep "Filesystem volume name" | sed 's/Filesystem volume name://' ) ";" $( fdisk -l $_disk | grep $_disk | cut -d':' -f2 | cut -d',' -f1 ) | sed 's/ //g' 
done
