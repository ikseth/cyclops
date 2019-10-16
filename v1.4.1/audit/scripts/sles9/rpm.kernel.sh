#!/bin/bash

_prefix="120;rpm slurm ver"
_order="120"
_rpm_kernel_ver=$( rpm -qa | grep "^kernel-[0-9]" )

if [ ! -z "$_rpm_kernel_ver" ] 
then
	echo "${_rpm_kernel_ver}" | sed -e "s/^/$_prefix;$_order;packages;Installed Kernels;/"
fi

