#!/bin/bash

_prefix="40;dmi memory"

_dmi_cmd=$( which dmidecode 2>/dev/null )
[ ! -z "$_dmi_cmd" ] && _dmi_memory=$( $_dmi_cmd 2>/dev/null | grep -A 18 "^Memory Device$" | egrep "^Memory Device$|Locator|Size|Type|Speed|Part Number|Manufacturer|Serial Number|\-\-" | sed 's/^\-\-$/\@/' |  tr -d '\t' | tr '\n' ';' | tr '@' '\n'  | sed -e 's/^;//' -e 's/;$/\@/' | tr '@' '\n' | sed -e '/^$/d' -e 's/ *;/;/g' | awk -F\; '{ for  (i = 1; i <= NF; i++) { if ( i == 1 ) { _head=$i } else { if ( $i ~ "^Locator" ) { _lock=";"$i } else {  _line=_line";"$i }}} print _head _lock _line ;  _head="" ; _line="" } '  | awk -F\; '{ for ( i = 1 ; i <= NF ; i++ ) { if ( i < 3 ) { _head=_head";"$i } else { print _head";"$i }} _head="" }' | awk -F\; '{ for ( i = 1 ; i <= NF ; i++ ) { if ( i == 1 ) { _line=_line";"$i";"NR } else { _line=_line";"$i }} { print _line ; _line="" }}' | sed -e 's/^;//' ) 

if [ ! -z "$_dmi_memory" ] 
then
	echo "${_dmi_memory}" | grep -vi "unknown" | sed -e "s/^/$_prefix/" -e 's/\:\ /;/g' -e 's/;Locator;/;Module /'
fi

