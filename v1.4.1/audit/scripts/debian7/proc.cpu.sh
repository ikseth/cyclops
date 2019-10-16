#!/bin/bash

_prefix="50;cpu info"
_order="50"
_proc_cpuinfo=$( cat /proc/cpuinfo | 
	awk -F\: -v _order="$_order" '$1 ~ "vendor_id" || $1 ~ "model name" { 
		if ( $1 ~ "model name" ) { 
			_model=$NF ; 
			_core++ 
		} else { 
			_vendor=$NF 
		}
	} END { 
		print  _order++";cpu info;vendor;"_vendor ; 
		print _order++";cpu info;model;"_model ; 
		print _order++";cpu info;cores;"_core 
	}' | 
	tr -s ' ' | 
	sed -e 's/; /;/g' )

if [ ! -z "$_proc_cpuinfo" ] 
then
	echo "${_proc_cpuinfo}" | sed -e "s/^/$_prefix;/"
fi

