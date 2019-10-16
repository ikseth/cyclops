#!/bin/bash
##### RAZOR RESOURCE CTRL CONFIG FILE ####

_rsc_rzr_nam="ipmi_bmc"
_rsc_rzr_des="Cyclops Local Ipmitool BMC Ctrl Razor"
_rsc_rzr_cmd="/usr/bin/ipmitool"
_rsc_rzr_dae=""
_rsc_rzr_cfg=""
_rsc_rzr_out_cod="119"
_rsc_rzr_hostname=$( hostname -s )

[ ! -f "$_rsc_rzr_cmd" ] && exit $_rsc_rzr_out_cod

case "$1" in
	check)
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd sel elist 2>/dev/null | wc -l )
	;;
	start|link|up|reset)
		_rsc_rzr_out_dat=$( $_rsc_rzr_cmd sel elist 2>/dev/null )
		_rsc_rzr_out_cod=$( echo "${_rsc_rzr_out_dat}" | wc -l )
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="11" && echo "${_rsc_rzr_out_dat}" | sed "s/^/$( date +%s )\:/" >> $_cyc_clt_log_path/$_rsc_rzr_hostname.bmc.log && $_rsc_rzr_cmd sel clear
	;;
	stop|unlink|content)
		_rsc_rzr_out_cod="21"
	;;
	drain|diagnose|boot|init|info|reboot)
		_rsc_rzr_out_cod="21"
	;;
	repair)
		_rsc_rzr_out_dat=$( $_rsc_rzr_cmd sel elist 2>/dev/null )
		_rsc_rzr_out_cod=$( echo "${_rsc_rzr_out_dat}" | wc -l )
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="11" && echo "${_rsc_rzr_out_dat}" | sed "s/^/$( date +%s )\:/" >> $_cyc_clt_log_path/$_rsc_rzr_hostname.bmc.log && $_rsc_rzr_cmd sel clear
	;;
esac

[ -z "$_rsc_rzr_out_cod" ] && _rsc_rzr_out_cod="19"

exit $_rsc_rzr_out_cod
