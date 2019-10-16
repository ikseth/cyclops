#!/bin/bash

_prefix="110;rpm packages"
_order="110"
_rpm_packages=$( rpm -qa | wc -l )

if [ ! -z "$_rpm_packages" ] 
then
	echo "${_rpm_packages}" | sed -e "s/^/$_prefix;$_order;packages;total install;/"
fi

