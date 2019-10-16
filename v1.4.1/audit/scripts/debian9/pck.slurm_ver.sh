#!/bin/bash

_prefix="120;pck slurm ver"
_order="120"
_pck_cmd=$( which dpkg-query 2>/dev/null )
[ ! -z "$_pck_cmd" ] && _pck_slurm_ver=$( eval exec $_pck_cmd -l | 
	grep "^slurm-[0-9]" | 
	grep -o "\-[0-9.]*\-" | 
	sed 's/\-//g' )

if [ ! -z "$_pck_slurm_ver" ] 
then
	echo "${_pck_slurm_ver}" | sed -e "s/^/$_prefix;$_order;packages;slurm version;/"
fi

