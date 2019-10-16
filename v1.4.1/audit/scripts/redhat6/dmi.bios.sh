#!/bin/bash

_prefix="30;bios"
_order="30"
_dmi_cmd=$( which dmidecode 2>/dev/null )
[ ! -z "$_dmi_cmd" ] && _dmi_bios=$( $_dmi_cmd 2>/dev/null | grep -A 28 "^BIOS Information$" | awk '{ if ( NR == 1 ) { _seccion=$0 } else { print _seccion";"$0 }}' | tr -d '\t'  | sed -e 's/: /;/' | egrep "Vendor|Version|Release Date|BIOS Revision" )

if [ ! -z "$_dmi_bios" ] 
then
	echo "${_dmi_bios}" | sed -e "s/^/$_prefix;$_order;/"
fi
