#!/bin/bash

_prefix="130;package lustre ver"
_order="130"
_pck_cmd=$( which dpkg-query 2>/dev/null )
[ ! -z "$_pck_cmd" ] && _pck_lustre_ver=$( eval exec $_pck_cmd -l | 
	grep lustre-modules | 
	grep -o "\-[0-9.]*\-" | 
	sed 's/\-//g' | 
	sort -u )

if [ ! -z "$_pck_lustre_ver" ] 
then
	echo "${_pck_lustre_ver}" | sed -e "s/^/$_prefix;$_order;packages;lustre module version;/"
fi

