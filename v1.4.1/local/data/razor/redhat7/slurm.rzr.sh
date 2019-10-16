#!/bin/bash
##### RAZOR RESOURCE CTRL CONFIG FILE ####

_rsc_rzr_nam="slurm"
_rsc_rzr_des="Slurm Client Node Ctrl Razor"
_rsc_rzr_cmd="/usr/bin/scontrol"
_rsc_rzr_dae="slurm"
_rsc_rzr_cfg="/etc/slurm/slurm.conf"
_rsc_rzr_out_cod="119"
_rsc_rzr_hostname=$( hostname -s )

# [ ! -f "$_rsc_rzr_cmd" ] && exit $_rsc_rzr_out_cod

case "$1" in
	check)
		_rsc_rzr_out_cod=$( [ -f "$_rsc_rzr_cfg" ] && echo 0 || echo 11 )
		if [ "$_rsc_rzr_out_cod" == "0" ]
		then
			_rsc_rzr_slm_srv=$( 
				eval exec $_rsc_rzr_cmd ping 2>/dev/null | 
				head -n 1 | 
				tr ' ' '\n' | 
				sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | 
				awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c1 }' | 
				grep -o ";UP$" 2>&1 >/dev/null ; 
				echo $? 
				)
			_rsc_rzr_slm_bkp=$(  
				eval exec $_rsc_rzr_cmd ping 2>/dev/null | 
				head -n 1 | 
				tr ' ' '\n' | 
				sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | 
				awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c2 }' | 
				grep -o ";UP$" 2>&1 >/dev/null ; 
				echo $? 
				)
			if [ "$_rsc_rzr_slm_srv" == "0" ] || [ "$_rsc_rzr_slm_bkp" == "0" ]
			then
				[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod=$( /sbin/service $_rsc_rzr_dae status 2>&1 >/dev/null ; echo $? )
				[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod=$( /usr/bin/sinfo -h -n $_rsc_rzr_hostname | egrep "drain|down" | wc -l )
				[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod="0" || _rsc_rzr_out_cod="18"

			else
				_rsc_rzr_out_cod="181"
			fi
		fi
	;;
	start)
		_rsc_rzr_out_cod=$( service $_rsc_rzr_dae start 2>&1 >/dev/null ; echo $? ) 	
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="17" 
	;;
	stop)
		_rsc_rzr_out_cod=$( service $_rsc_rzr_dae stop 2<&1 >/dev/null ; echo $? )
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="16" 
	;;
	up)
		_rsc_rzr_out_cod=$( service $_rsc_rzr_dae status 2>&1 >/dev/null ; echo $? )
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod=$( service $_rsc_rzr_dae start 2>&1 >/dev/null ; echo $? )
		[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod=$( /usr/bin/sinfo -h -n $_rsc_rzr_hostname | egrep "drain|down" | wc -l )
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=idle 2>&1 >/dev/null ; echo $? )  
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="19" 
	;;
	link)
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=idle 2>&1 >/dev/null ; echo $? ) 
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="12" 
	;;
	unlink)
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=drain reason=unlink_mode 2>&1 >/dev/null ; echo $? ) 
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="13" 
	;;
	drain)
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=drain reason=maintenance_mode 2>&1 >/dev/null ; echo $? ) 
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="14" 
	;;
	boot)
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=drain reason=booting_safe_mode 2>&1 >/dev/null ; echo $? ) 
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="14" 
	;;
	diagnose|init|info)
		_rsc_rzr_out_cod="21"
	;;
	content)
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=drain reason=content_mode 2>&1 >/dev/null ; echo $? ) 
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=idle 2>&1 >/dev/null ; echo $? ) 
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="15" 
	;;
	repair)
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=drain reason=repair_mode 2>&1 >/dev/null ; echo $? ) 
		_rsc_rzr_out_cod=$( $_rsc_rzr_cmd update nodename=$_rsc_rzr_hostname state=idle 2>&1 >/dev/null ; echo $? ) 
		[ "$_rsc_rzr_out_cod" != "0" ] && _rsc_rzr_out_cod="15" 
	;;
esac

exit $_rsc_rzr_out_cod

