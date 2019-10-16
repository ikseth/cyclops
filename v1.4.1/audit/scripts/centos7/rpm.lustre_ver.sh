#!/bin/bash

_prefix="130;rpm lustre ver"
_order="130"
_rpm_lustre_ver=$( rpm -qa | grep lustre-modules | grep -o "\-[0-9.]*\-" | sed 's/\-//g' | sort -u )

if [ ! -z "$_rpm_lustre_ver" ] 
then
	echo "${_rpm_lustre_ver}" | sed -e "s/^/$_prefix;$_order;packages;lustre module version;/"
fi

