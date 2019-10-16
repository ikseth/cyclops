#!/bin/bash
##### RAZOR RESOURCE CTRL CONFIG FILE ####

_rsc_rzr_pth=$( pwd )
_rsc_rzr_nam="net_if"
_rsc_rzr_des="Cyclops Local Network Interfaces Ctrl Razor"
_rsc_rzr_cmd="/sbin/ip addr"
_rsc_rzr_dae=""
_rsc_rzr_cfg=""
_rsc_rzr_cfg_pth="/etc/sysconfig/network-scripts"
_rsc_rzr_out_cod="119"
_rsc_rzr_hostname=$( hostname -s )

## SPECIFIC RAZOR VARS ##

_rsc_rzr_if_up="/sbin/ifup"
_rsc_rzr_if_down="/sbin/ifdown"

# [ ! -f "$_rsc_rzr_cmd" ] && exit $_rsc_rzr_out_cod

case "$1" in
	check)
		_rsc_rzr_out_cod="0"

		for _if in $( ls -1 /etc/sysconfig/network-scripts/ifcfg-* | grep -v "ifcfg-lo" ) 
		do
			if [ "$_rsc_rzr_out_cod" == "0" ]
			then
				_rsc_rzr_if=$( awk -F\= '$1 == "DEVICE" { print $2 }' $_if )
				_rsc_rzr_if_cod=$( awk -F\= '$1 == "ONBOOT" { if ( $2 == "yes" ) { print "0" } else { print "21" }}' $_if ) 

				[ "$_rsc_rzr_if_cod" == "0" ] && _rsc_rzr_if_cod=$( eval exec $_rsc_rzr_cmd show $_rsc_rzr_if 2>/dev/null | awk -v _i="$_rsc_rzr_if" '$2 == _i":" { if ( $9 == "UP" ) { print "0" } else { print "1"}}') 
				[ "$_rsc_rzr_if_cod" != "0" ] && [ "$_rsc_rzr_if_cod" != "21" ] && [ ! -z "$_rsc_rzr_if_cod" ] && _rsc_rzr_out_cod="11"
			fi
		done
	;;
	start|link|up|repair)
		_rsc_rzr_out_cod="0"

		for _if in $( ls -1 $_rsc_rzr_cfg_pth/ifcfg-* | grep -v "ifcfg-lo" ) 
		do
			if [ "$_rsc_rzr_out_cod" == "0" ]
			then
				_rsc_rzr_if=$( awk -F\= '$1 == "DEVICE" { print $2 }' $_if )
				_rsc_rzr_if_cod=$( awk -F\= '{ if ( $1 == "ONBOOT" && $2 == "yes" ) { print "0" } else { print "1" }}' $_if ) 
				[ "$_rsc_rzr_if_cod" == "0" ] && _rsc_rzr_if_cod=$( eval exec $_rsc_rzr_cmd show $_rsc_rzr_if 2>/dev/null | awk '{ if ( $11 == "UP" ) { print "0" } else { print "1"}}') 
				[ "$_rsc_rzr_if_cod" != "0" ] && _rsc_rzr_if_cod=$( $_rsc_rzr_if_up $_rsc_rzr_if 2>&1 >/dev/null ; echo $? )
				[ "$_rsc_rzr_if_cod" != "0" ] && _rsc_rzr_out_cod="12"
			fi
		done
	;;
	drain|diagnose|boot|init|stop|content|unlink|reset|reboot)
		_rsc_rzr_out_cod="21"
	;;
	info)
		_rsc_rzr_out_code="0"
	;;
esac

exit $_rsc_rzr_out_cod
