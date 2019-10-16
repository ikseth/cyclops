#!/bin/bash

_prefix="120;rpm slurm ver"
_order="120"
_rpm_slurm_ver=$( rpm -qa | grep "^slurm-[0-9]" | grep -o "\-[0-9.]*\-" | sed 's/\-//g' )

if [ ! -z "$_rpm_slurm_ver" ] 
then
	echo "${_rpm_slurm_ver}" | sed -e "s/^/$_prefix;$_order;packages;slurm version;/"
fi

