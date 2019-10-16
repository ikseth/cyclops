#!/bin/bash

_prefix="20;dmi motherboard"
_order="20"
_dmi_cmd=$( which dmidecode 2>/dev/null )
[ ! -z "$_dmi_cmd" ] && _dmi_motherboard=$( $_dmi_cmd 2>/dev/null | grep -A 4 "^Base Board Information$" | sed 's/^ *//' | awk '{ if ( NR == 1 ) { _seccion=$0 } else { print _seccion";"$0 }}' | tr -d '\t'  | sed -e 's/: /;/' )

if [ ! -z "$_dmi_motherboard" ]
then
	echo "${_dmi_motherboard}" | sed -e "s/^/$_prefix;$_order;/"
fi
