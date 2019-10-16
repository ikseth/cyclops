#!/bin/bash

_prefix="20;serial"
_order="20"
_grp_data="BMC information"
_ipmi_serial=$( ipmitool fru | awk -F\: -v _grp="$_grp_data" '$1 ~ "Board Serial"  { for(i=1;i<=2;i++) { gsub(/^ +/,"",$i) ; gsub(/ +$/,"",$i) } ;print _grp";"$1";"$2 }' | sort -u )

if [ ! -z "$_ipmi_serial" ] 
then
	echo "${_ipmi_serial}" | sed -e "s/^/$_prefix;$_order;/"
fi
