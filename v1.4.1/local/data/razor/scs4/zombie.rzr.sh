#!/bin/bash
##### RAZOR RESOURCE CTRL CONFIG FILE ####

_rsc_rzr_nam="zombie"
_rsc_rzr_des="Cyclops Local Zombie Process Ctrl Razor"
_rsc_rzr_cmd="/bin/kill"
_rsc_rzr_dae=""
_rsc_rzr_cfg=""
_rsc_rzr_out_cod="119"
_rsc_rzr_hostname=$( hostname -s )

[ ! -f "$_rsc_rzr_cmd" ] && exit $_rsc_rzr_out_cod

case "$1" in
	check)
		_rsc_rzr_out_cod=$( ps -eFl | awk 'BEGIN { _num=0 } $2 ~ "^Z" { _num++ } END { print _num }' )
	;;
	start|link|up|reset)
		_rsc_rzr_out_cod=$( ps -eFl | awk 'BEGIN { _num=0 } $2 ~ "^Z" { _num++ } END { print _num }' )
		if [ "$_rsc_rzr_out_cod" != "0" ]
		then
			_rsc_rzr_chk_kill="0"

			for _rsc_rzr_zom_ps in $( ps -eFl | awk ' $2 ~ "^Z" { print $4";"$5 }' ) 
			do
				_rsc_rzr_zom_pid=$( echo $_rsc_rzr_zom_ps | cut -d';' -f1 )
				_rsc_rzr_zom_ppid=$( echo $_rsc_rzr_zom_ps | cut -d';' -f2 )

				_rsc_rzr_zom_kill=$( eval exec $_rsc_rzr_cmd -9 $_rsc_rzr_zom_ppid 2>&1 >/dev/null ; echo $? )
				[ "$_rsc_rzr_zom_kill" != "0" ] && _rsc_rzr_chk_kill="11"
			done
			
			_rsc_rzr_out_cod=$_rsc_rzr_chk_kill
		fi
	;;
	stop|unlink|content)
		_rsc_rzr_out_cod="21"
	;;
	drain|diagnose|boot|init|info|reboot)
		_rsc_rzr_out_cod="21"
	;;
	repair)
		_rsc_rzr_out_cod=$( ps -eFl | awk 'BEGIN { _num=0 } $2 ~ "^Z" { _num++ } END { print _num }' )
		if [ "$_rsc_rzr_out_cod" != "0" ]
		then
			_rsc_rzr_chk_kill="0"

			for _rsc_rzr_zom_ps in $( ps -eFl | awk ' $2 ~ "^Z" { print $4";"$5 }' ) 
			do
				_rsc_rzr_zom_pid=$( echo $_rsc_rzr_zom_ps | cut -d';' -f1 )
				_rsc_rzr_zom_ppid=$( echo $_rsc_rzr_zom_ps | cut -d';' -f2 )

				_rsc_rzr_zom_kill=$( eval exec $_rsc_rzr_cmd -9 $_rsc_rzr_zom_ppid 2>&1 >/dev/null ; echo $? )
				[ "$_rsc_rzr_zom_kill" != "0" ] && _rsc_rzr_chk_kill="11"
			done
			
			_rsc_rzr_out_cod=$_rsc_rzr_chk_kill
		fi
	;;
esac

[ -z "$_rsc_rzr_out_cod" ] && _rsc_rzr_out_cod="19"

exit $_rsc_rzr_out_cod
