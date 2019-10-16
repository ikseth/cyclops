#!/bin/bash
##### RAZOR RESOURCE CTRL CONFIG FILE ####
##### WARNING : WE RECOMMENDED THIS RAZOR AT THE END OF RAZOR LIST OF FAMILY NODES ####
##### WARNING : CHANGE DRAIN COMMAND IF YOU DON'T WANT HALT THE NODE ( BY DEFAULT ) ####

_rsc_rzr_nam="host"
_rsc_rzr_des="Cyclops Razor Host General Main Actions Ctrl"  ## Use this script like family template for different types of hosts
_rsc_rzr_cmd=""
_rsc_rzr_dae=""
_rsc_rzr_cfg=""
_rsc_rzr_out_cod="119"
_rsc_rzr_hostname=$( hostname -s )
_rsc_rzr_drn_cmd="/sbin/halt -p"
_rsc_rzr_rbt_cmd="/sbin/reboot"

_rsc_rzr_sl_cmd="/usr/bin/squeue"
_rsc_rzr_sl_ctr="/usr/bin/scontrol"

###### NON-STANDARD RAZOR VARIABLES ####

_rsc_rzr_sl_cmd="/usr/bin/squeue"	### SLURM CMD FOR JOB CTRL ###

case "$1" in
        check|start|link|unlink|diagnose|boot|init|up)
                _rsc_rzr_out_cod="21"
        ;;
        stop|content)
		_rsc_rzr_out_cod=$( eval exec $_rsc_rzr_sl_cmd -h -w $_rsc_rzr_hostname | wc -l )
		[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod=$( eval exec $_rsc_rzr_drn_cmd 2>&1 >/dev/null )
        ;;
	reboot)
		_rsc_rzr_out_cod=$( eval exec $_rsc_rzr_sl_cmd -h -w $_rsc_rzr_hostname | wc -l )
		[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod=$( eval exec $_rsc_rzr_rbt_cmd 2>&1 >/dev/null )
	;;
	drain|repair|reboot)
		_rsc_rzr_out_cod="21"
	;;
        info)
                _rsc_rzr_out_cod="21"
        ;;
esac

exit $_rsc_rzr_out_cod
