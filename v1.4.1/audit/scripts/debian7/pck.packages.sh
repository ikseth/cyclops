#!/bin/bash

_prefix="110;pck packages"
_order="110"
_pck_cmd=$( which dpkg-query 2>&1 >/dev/null )
[ ! -z "$_pck_cmd" ] && _pck_packages=$( eval exec $_pck_cmd -l | wc -l )

if [ ! -z "$_pck_packages" ] 
then
	echo "${_pck_packages}" | sed -e "s/^/$_prefix;$_order;packages;total install;/"
fi

