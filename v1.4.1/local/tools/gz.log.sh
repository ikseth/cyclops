#!/bin/bash 

_file=$1
[ -z "$2" ] && _date=$( date +%Y%m%d ) || _date=$2
_gz_file=$_file"-"$_date".gz"

if [ ! -f "$_gz_file" ] 
then 
	mv $_file $_file-$_date
	touch $_file
	gzip $_file-$_date
fi


