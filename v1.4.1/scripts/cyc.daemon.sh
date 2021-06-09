#!/bin/bash

#    GPL License
#
#    This file is part of Cyclops Suit.
#
#    Foobar is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Foobar is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

############# VARIABLES ###################
#

	IFS="
	"

	_command_name=$( basename "$0" )
	_command_dir=$( dirname "${BASH_SOURCE[0]}" )
	_command="$_command_dir/$_command_name $_command_opts"

	[ -f "/etc/cyclops/global.cfg" ] && source /etc/cyclops/global.cfg || _exit_code="111"

	[ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
	[ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
	[ -f "$_libs_path/node_ungroup.sh" ] && source $_libs_path/node_ungroup.sh || _exit_code="114"
	[ -f "$_color_cfg_file" ] && source $_color_cfg_file

	[ ! -f "$_config_path_sys/cyc.daemon.cfg" ] && _exit_code="200"

	case "$_exit_code" in
	111)
		echo "Main Config file doesn't exists, please revise your cyclops installation"
		exit 1
	;;
	112)
		echo "HA Control Script doesn't exists, please revise your cyclops installation"
		exit 1
	;;
	11[3-5])
		echo "Necesary libs files doesn't exits, please revise your cyclops installation"
		exit 1
	;;
	200)
		echo "Mandatory config file [$_config_path_sys/cyc.daemon.cfg] missing"
		exit 1
	;;
	esac

	_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

	_cyc_dae_pid_file=$_lock_path"/cyc.dae.pid"
	_cyc_mon_pid_file=$_lock_path"/cyc.mon.pid"
	_cyc_aud_pid_file=$_lock_path"/cyc.aud.pid"
	_cyc_rzr_pid_file=$_lock_path"/cyc.rzr.pid"
	_cyc_has_pid_file=$_lock_path"/cyc.has.pid"
	_cyc_sts_pid_file=$_lock_path"/cyc.sts.pid"
	_cyc_his_pid_file=$_lock_path"/cyc.his.pid"

###########################################
#              PARAMETERs                 #
###########################################

case "$1" in
start|stop|status|config|restart)
	_opt_dae="yes"
	_par_dae=$1
	_par_act="daemon"
;;
*)
	while getopts ":s:a:v:t:fh:" _optname
	do
		case "$_optname" in
			"s")
				_opt_srv="yes"
				_par_srv=$OPTARG
			;;
			"a")
				_opt_act="yes"
				_par_act=$OPTARG
			;;	
			"f")
				_opt_for="yes"
			;;
			"t")
				_opt_freq="yes"
				_par_freq=$OPTARG
			;;
			"h")
				_opt_help="yes"
				_par_help=$OPTARG

				case "$_par_help" in
				"des")
					echo "$( basename "$0" ) : Cyclops Global Status Tool"
					echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
					echo "	Global config path : $_config_path"
					echo "		Global config file: global.cfg"
					echo "	Daemon config path : $_config_path_sys"
					echo "		Service config file: cyc.daemon.cfg"
					echo "	Cyclops dependencies:"
					echo "		Cyclops libs: $_libs_path"
					exit 0
				esac
			;;
			":")
				case "$OPTARG" in
				"h")
					echo "CYCLOPS DAEMON SERVICE"
					echo "	core for cyclops unattended exec"
					echo 
					echo "Main Cyclops Options"
					echo "	Without any other setting"
					echo
					echo "	start: enable main cyclops service and configurated start module services"
					echo "	stop: disable main cyclops service and configuraded start module services"
					echo "	status: show main cyclops services status and modules"
					echo "	restart: stop and start configured services"
					echo "	config: show daemon config"
					echo
					echo "	-f : force action"
					echo
					echo "Specific services settings"
					echo
					echo "-s [service] manage specific service"
					echo "	monitor: cyclops main monitor service"
					echo "	audit: audit module" 
					echo "	history: history log module"
					echo "	stats: statistics module"
					echo "	razor: management module"
					echo "	reactive: auto-repairing module ( razor dependency )"
					echo "	backup: cyclops auto-backup system"
					echo	
					echo "-a [action] Cyclops daemon action"
					echo "	enable: active module for start as service, start it if is stopped"
					echo "	disable|kill: disable module as service, stop it if is started"
					echo "	restart: stop and start specific service"
					echo "	status: show cyclops daemon status"
					echo "	config: change service setting"
					echo "		-t [seconds] : Seconds frequency for launch service, less than 10 is continuous launch"
					
					exit 0
				;;
				esac
			;;
		esac
	done
;;
esac

shift $((OPTIND-1))

#### FUNCTIONS ####

err_cyc_dae()
{
	# CYC DAE ERR MSG FUNCTION	
	case "$1" in
	daemon)
		echo "[$( date +%FT%T )] [$1] [ERR MSG] [$2] [$_check_pid]" 
	;;
	service)
	;;
	esac
}

check_pid()
{

	# exit 0 # PID SAVED IS A RUNNING PROCESS 
	# exit 1 # NOT PID SAVED
	# exit 2 # PID SAVED IS NOT A RUNNING PROCESS 
	# exit 3 # GET PID FAIL

	_pid=$( get_pid $1 ) 

	case "$_pid" in
	[0-9]*)
		_check_pid=$( ps -eFl | awk -v _ps="$_pid" 'BEGIN { _st="2" } $4 == _ps { _st="0" } END { print _st }' )
	;;
	"none")
		_check_pid="1"
	;;
	"")
		_check_pid="3"
	;;
	esac

	#echo "[$1:$_pid:$_check_pid]" >>/opt/cyclops/logs/debug.cycdaemon.log

	return $_check_pid
}

get_pid()
{
	_pid_file=$( get_pid_file $1 )

	[ -f "$_pid_file" ] && _pid=$( awk '$1 ~ "[0-9]+" { print $1 }' $_pid_file ) || _pid="none"
	echo $_pid
}

get_pid_file()
{
	case "$1" in
	cyclops)
		_pid_file=$_cyc_dae_pid_file
	;;
	monitor)
		_pid_file=$_cyc_mon_pid_file
	;;
	audit)
		_pid_file=$_cyc_aud_pid_file
	;;
	razor)
		_pid_file=$_cyc_rzr_pid_file
	;;
	hasync)
		_pid_file=$_cyc_has_pid_file
	;;
	stats)
		_pid_file=$_cyc_sts_pid_file
	;;
	history)
		_pid_file=$_cyc_his_pid_file
	;;
	esac

	echo $_pid_file
}

start_cyc_dae()
{
	_dae_func_pid=$$

	while true
	do
		cyc_service status monitor
		cyc_service status audit
		cyc_service status razor
		cyc_service status hasync
		cyc_service status stats
		cyc_service status history
		cyc_service status backup

		_file_pid=$( awk '$1 ~ "[0-9]+" { print $1 }' $_cyc_dae_pid_file ) 
		_dae_pid_status=$( check_pid cyclops 2>&1 >/dev/null ; echo $? )

		sleep 10s
	done
}

stop_cyc_dae()
{
	for _dae_nam in $( awk -F\; '$1 ~ "[0-9]+" { print $4 }' $_config_path_sys/cyc.daemon.cfg )	
	do
		_mon_status=$( check_pid $_dae_nam 2>&1 >/dev/null ; echo $? )
		_pid_file=$( get_pid_file $_dae_nam ) 

		if [ "$_mon_status" == "0" ]
		then
			_pid=$( get_pid $_dae_nam )
			if [ ! -z "$_pid" ] 
			then	
				[ "$_opt_for" == "yes" ] && _stop_status=$( kill -TERM -- -$_pid ; echo $? ) || _stop_status=$( kill $_pid ; echo $? ) 
				[ "$_stop_status" == "0" ] && [ -f "$_pid_file" ] && rm -f $_pid_file
			fi
			[ "$_stop_status" == "0" ] && _srv_status=$_sh_color_green"STOPPED"$_sh_color_nformat || _srv_status=$_sh_color_red"FAILED:"$_pid""$_sh_color_nformat
		else
			_srv_status=$_sh_color_green"STOP"$_sh_color_nformat
		fi

		[ -f "$_pid_file" ] && rm -f $_pid_file

		echo -e "	MODULE STATUS [ "$_srv_status" ] [ "$_dae_nam" ]"
	done

	_mon_status=$( check_pid cyclops 2>&1 >/dev/null ; echo $? )

	case "$_mon_status" in
	0)
		_pid=$( get_pid cyclops )
		if [ ! -z "$_pid" ] 
		then
			[ "$_opt_for" == " yes" ] && _stop_daemon=$( kill -TERM -- -$_pid 2>&1 >/dev/null ; echo $? ) || _stop_daemon=$( kill $_pid 2>&1 >/dev/null ; echo $? )
			_pid_file=$( get_pid_file cyclops )
			[ "$_stop_daemon" == "0" ] && [ -f "$_pid_file" ] && rm -f $_pid_file	
		fi

		[ "$_stop_daemon" == "0" ] && _dae_status="STOPPED" || _dae_status="FAILED:"$_pid

		echo -e "CYCLOPS DAEMON STATUS: [ "$_dae_status" ]"
	;;
	1)
		echo -e "CYCLOPS DAEMON STATUS: [ "$_sh_color_green"STOP"$_sh_color_nformat" ]"
	;;
	2)
		echo -e "CYCLOPS DAEMON STATUS: [ "$_sh_color_red"DEAD"$_sh_color_nformat" ]"
	;;
	esac

	echo -e "[$( date +%s )] CYCLOPS DAEMON STATUS: [ "$_dae_status" ]" >> $_mon_log_path/cyc.daemon.log
}

status_cyc_dae()
{
	_mod_status=$( check_pid cyclops 2>&1 >/dev/null ; echo $? )
	
	case "$_mod_status" in
	0)
		echo -e "CYCLOPS DAEMON STATUS: [ "$_sh_color_green"RUNNING"$_sh_color_nformat" ]"

		for _line in $( awk -F\; '$1 ~ "[0-9]+" { print $0 }' $_config_path_sys/cyc.daemon.cfg )
		do
			_dae_cfg=$( echo "$_line" | cut -d';' -f2 )
			_dae_nam=$( echo "$_line" | cut -d';' -f4 )
			
			_mod_status=$( check_pid $_dae_nam 2>&1 >/dev/null ; echo $? )

			[ "$_mod_status" == "0" ] && [ "$_dae_cfg" == "start" ] && _dae_srv_status=$_sh_color_green"RUNNING"$_sh_color_nformat
			[ "$_mod_status" == "0" ] && [ "$_dae_cfg" == "stop" ] &&  _dae_srv_status=$_sh_color_red"RUNNING"$_sh_color_nformat
			[ "$_mod_status" == "1" ] && [ "$_dae_cfg" == "start" ] && _dae_srv_status=$_sh_color_red"STOPPED"$_sh_color_nformat
			[ "$_mod_status" == "1" ] && [ "$_dae_cfg" == "stop" ] && _dae_srv_status=$_sh_color_green"STOPPED"$_sh_color_nformat
			[ "$_mod_status" == "2" ] && _dae_srv_status=$_sh_color_red"DEAD"$_sh_color_nformat

			[ "$_dae_cfg" == "start" ] && _dae_sw_show=$_sh_color_green"ENABLED "$_sh_color_nformat
			[ "$_dae_cfg" == "stop" ] && _dae_sw_show=$_sh_color_red"DISABLED"$_sh_color_nformat

			echo -e "	MODULE STATUS: [ $_dae_srv_status ] [ $_dae_sw_show ] [ $_dae_nam ]"
		done
	;;
	1)
		echo -e "CYCLOPS DAEMON STATUS: [ "$_sh_color_green"STOP"$_sh_color_nformat" ]"

		for _line in $( awk -F\; '$1 ~ "[0-9]+" { print $0 }' $_config_path_sys/cyc.daemon.cfg )
		do
			_dae_cfg=$( echo "$_line" | cut -d';' -f2 )
			_dae_nam=$( echo "$_line" | cut -d';' -f4 )
			
			_mon_status=$( check_pid $_dae_nam 2>&1 >/dev/null ; echo $? )

			[ "$_mod_status" == "0" ] && _dae_srv_status=$_sh_color_red"RUNNING"$_sh_color_nformat
			[ "$_mod_status" == "1" ] && _dae_srv_status=$_sh_color_green"STOP"$_sh_color_nformat
			[ "$_mod_status" == "2" ] && _dae_srv_status=$_sh_color_yellow"DEAD"$_sh_color_nformat

			[ "$_dae_cfg" == "start" ] && _dae_sw_show=$_sh_color_green"ENABLED "$_sh_color_nformat
			[ "$_dae_cfg" == "stop" ] && _dae_sw_show=$_sh_color_red"DISABLED"$_sh_color_nformat

			echo -e "	MODULE STATUS: [ $_dae_srv_status ] [ "$_dae_sw_show" ] [ $_dae_nam ]"
		done
	;;
	2)
		echo -e "CYCLOPS DAEMON STATUS: [ "$_sh_color_red"DEAD"$_sh_color_nformat" ]"

		for _line in $( awk -F\; '$1 ~ "[0-9]+" { print $0 }' $_config_path_sys/cyc.daemon.cfg )
		do
			_dae_cfg=$( echo "$_line" | cut -d';' -f2 )
			_dae_nam=$( echo "$_line" | cut -d';' -f4 )
			
			_mon_status=$( check_pid $_dae_nam 2>&1 >/dev/null ; echo $? )

			[ "$_mod_status" == "0" ] && _dae_srv_status=$_sh_color_yellow"RUNNING"$_sh_color_nformat
			[ "$_mod_status" == "1" ] && _dae_srv_status=$_sh_color_yellow"STOP"$_sh_color_nformat
			[ "$_mod_status" == "2" ] && _dae_srv_status=$_sh_color_yellow"DEAD"$_sh_color_nformat

			[ "$_dae_cfg" == "start" ] && _dae_sw_show=$_sh_color_green"ENABLED "$_sh_color_nformat
			[ "$_dae_cfg" == "stop" ] && _dae_sw_show=$_sh_color_red"DISABLED"$_sh_color_nformat

			echo -e "	MODULE STATUS: [ $_dae_srv_status ] [ "$_dae_sw_show" ] [ $_dae_nam ]"
		done
	;;
	*)
		echo -e "CYCLOPS DAEMON STATUS: ["$_sh_color_"UNKNOWN"$_sh_color_nformat"] [$_mod_status]"
	;;
	esac
	
}

cyc_service()
{
	_cyc_action=$1
	_cyc_service=$2
	_cyc_srv_cod=$( awk -F\; -v _srv="$_cyc_service" '$4 == _srv { print $1 }' $_config_path_sys/cyc.daemon.cfg )
	
	[ -z "$_cyc_srv_cod" ] && echo "[$( date +%s )] CYC DAEMON: MONITOR CYCLOPS DAEMON [CODE ERR]:[$_cyc_service:$_cyc_action]" >> $_mon_log_path/cyc.daemon.log && return 1 

	_cyc_mpid_file=$( get_pid_file $_cyc_service )
	_cyc_act_cfg=$(   awk -F\; -v _cod="$_cyc_srv_cod" '$1 == _cod { print $2 }' $_config_path_sys/cyc.daemon.cfg ) 
	#echo "[$( date +%s )] CYC DEBUG[B]: [$_cyc_service] CYCLOPS DAEMON [$_cyc_action]:[$_cyc_srv_cod]:[$_cyc_act_cfg]:[$_opt_dae]" >> $_mon_log_path/cyc.daemon.log

	case "$_cyc_action" in
	status)
		_mod_status=$( check_pid $_cyc_service 2>&1 >/dev/null ; echo $? )

		if [ "$_opt_dae" == "yes" ]
		then
			case "$_mod_status" in
			0)
				if [ "$_cyc_act_cfg" == "kill" ]
				then
					cyc_service_stop $_cyc_service $_mod_status 2>/dev/null
					_err=$?

					[ "$_err" == "0" ] && _cyc_mod_stop="KILL" || _cyc_mod_stop="FAIL KILL:$_err:$( get_pid $_cyc_service )" 
					echo "[$( date +%s )] CYC DAEMON: [$_cyc_service] CYCLOPS DAEMON [RUNNING]:[$_cyc_mod_stop]" >> $_mon_log_path/cyc.daemon.log
				fi
			;;
			1)
				if [ "$_cyc_act_cfg" == "start" ]
				then
					cyc_service_start $_cyc_service 2>/dev/null &
					echo $! > $_cyc_mpid_file
					echo "[$( date +%s )] CYC DAEMON: [$_cyc_service] CYCLOPS DAEMON [STOPPED]:[START]" >> $_mon_log_path/cyc.daemon.log
				fi
			;;
			2)
				if [ "$_cyc_act_cfg" == "stop" ] 
				then
					cyc_service_stop $_cyc_service $_mod_status 2>/dev/null
					_err=$?
					[ "$_err" == "0" ] && _cyc_mod_stop="CLEAN" || _cyc_mod_stop="FAIL CLEAN:$_err" 
					echo "[$( date +%s )] CYC DAEMON: [$_cyc_service] CYCLOPS DAEMON [DEAD]:[$_cyc_mod_stop]" >> $_mon_log_path/cyc.daemon.log
				fi
			;;
			esac
		else
			echo -e "CYC DAEMON: [$_cyc_service] CYCLOPS DAEMON ["$_sh_color_yellow"WARNING"$_sh_color_nformat"]\n\tONLY CYC MAIN DAEMON CAN ["$_sh_color_red"STATUS"$_sh_color_nformat"] MODULE SERVICE, YOU CAN USE MAIN DAEMON ["$_sh_color_green"STATUS"$_sh_color_nformat"] IT"
		fi
	;;
	enable)
		if [ "$_cyc_act_cfg" == "stop" ] || [ "$_cyc_act_cfg" == "kill" ] 
		then
			sed -i "s/\($_cyc_srv_cod;\)[a-z]*\(;[0-9]*;$_cyc_service\)/\1start\2/" $_config_path_sys/cyc.daemon.cfg 
			echo -e "CYC DAEMON: ["$_cyc_action"] SERVICE ["$_cyc_service"] ["$_sh_color_red"DISABLED"$_sh_color_nformat"]:["$_sh_color_green"ENABLED"$_sh_color_nformat"]"
		else
			echo -e "CYC DAEMON: NO CHANGES ON SERVICE ["$_cyc_service"]"
		fi
	;;
	disable|kill)
		if [ "$_cyc_act_cfg" == "start" ] 
		then
			[ "$_cyc_action" == "disable" ] && _cyc_act_chg="stop" || _cyc_act_chg="kill"	
			sed -i "s/\($_cyc_srv_cod;\)start\(;[0-9]*;$_cyc_service\)/\1$_cyc_act_chg\2/" $_config_path_sys/cyc.daemon.cfg 
			echo -e "CYC DAEMON: ["$_cyc_action"] SERVICE ["$_cyc_service"] ["$_sh_color_green"ENABLED"$_sh_color_nformat"]:["$_sh_color_red"DISABLED"$_sh_color_nformat"]"
		else
			echo -e "CYC DAEMON: NO CHANGES ON SERVICE ["$_cyc_service"]"
		fi
	;;
	config)
		if [ "$_opt_freq" == "yes" ] && [ "$_opt_srv" == "yes" ]
		then
			_par_freq=$( echo "$_par_freq" | grep -o "[0-9]*" )
			if [ ! -z "$_par_freq" ]
			then
				sed -i "s/\([0-9]*;[a-z]*;\)[0-9]*\(;$_par_srv\)/\1$_par_freq\2/" $_config_path_sys/cyc.daemon.cfg
			else
				echo -e "CYC DAEMON: NO CHANGES ON SERVICE ["$_sh_color_red""$_cyc_service""$_sh_color_nformat"] FREQUENCY BAD SETTINGS"
			fi 
		else
				echo -e "CYC DAEMON: NO CHANGES ON CYCLOPS DAEMON "$_sh_color_red"BAD SETTINGS"$_sh_color_nformat
		fi
	;;
	restart)
		echo "WORKING ON IT"
	;;
	*)
		echo "[$( date +%s )] CYC DAEMON: [$_cyc_service] CYCLOPS DAEMON [$_cyc_action]:[$_cyc_act_cfg]" >> $_mon_log_path/cyc.daemon.log
	;;
	esac
}

cyc_mon_torquemada()
{
	_cyc_mon_freq=$1

	sleep $_cyc_mon_freq

	if [ -f "$_cyc_mon_pid_file" ]
	then
		_monsh_pid=$( awk '$1 ~ "[0-9]+" { _pid=$1 } END { print _pid }' $_lock_path/monitor.pid )
		_cycmonshps=$( ps -eFl | awk -v _ps="$_monsh_pid" 'BEGIN { _st="2" } $4 == _ps { _st="1" } END { print _st }' ) 
		if [ "$_cycmonshps" == "1" ]
		then
			while [ $_monsh_try -le 5 ]
			do
				let "_monsh_try++"
				echo "CYC DAEMON: MONITOR CYCLOPS DAEMON STALL WAITING 30s : TRY [$_monsh_try] [$_monsh_pid]" >> $_mon_log_path/cyc.daemon.log 
				sleep 30s
				_cycmonshps=$( ps -eFl | awk -v _ps="$_monsh_pid" 'BEGIN { _st="2" } $4 == _ps { _st="1" } END { print _st }' )
				if [ "$_cyc_monshps" == "2" ]
				then
					_monsh_try=99	
					echo "CYC DAEMON: MONITOR CYCLOPS DAEMON FREE LAUNCHING NEW MON" >> $_mon_log_path/cyc.daemon.log 
				fi
			done

			if [ "$_monsh_try" -eq 5 ]
			then
				kill -9 $_monsh_pid
				echo "CYC DAEMON: MONITOR CYCLOPS DAEMON TIMEOUT : KILL [$_monsh_pid]" >> $_mon_log_path/cyc.daemon.log
				## AUDIT EVENT ##
			fi
		fi
	fi 
}

cyc_service_start()
{
	_cyc_service=$1
	_cyc_srv_cod=$(  awk -F\; -v _srv="$_cyc_service" '$4 == _srv { print $1 }' $_config_path_sys/cyc.daemon.cfg )

	case "$_cyc_service" in
	monitor)
		_daemon="$_script_path/monitoring.sh -d 2>>$_mon_log_path/$HOSTNAME.mon.err.log"
	;;
	audit)
		_daemon="$_script_path/audit.nod.sh -d  2>>$_mon_log_path/audit.err.log >>$_mon_log_path/audit.err.log"
	;;
	razor)
		_daemon="$_script_path/razor.sh -d 2>>$_mon_log_path/razor.srv.err.log >>$_mon_log_path/razor.srv.log"
	;;
	hasync)
		return 1 #echo "WORKING ON IT"
	;;
	stats)
		_daemon="$_script_path/cyc.stats.sh -t daemon >/dev/null 2>>$_mon_log_path/$HOSTNAME.cyc.stats.err.log"
	;;
	history)
		_daemon="$_script_path/historic.mon.sh -d 2>>$_mon_log_path/historic.err.log"
	;;
	backup)
		_daemon="$_script_path/backup.cyc.sh -t all &>>$_mon_log_path/$HOSTNAME.bkp.log"
	;;
	procedures)
		return 1 #echo "WORKING ON IT"
	;;
	esac

	while true
	do
		_cyc_mon_stat=$( awk -F\; -v _srv="$_cyc_service" '$4 == _srv { print $2 }' $_config_path_sys/cyc.daemon.cfg )
		if [ "$_cyc_mon_stat" == "stop" ] 
		then 
			_cyc_mpid_file=$( get_pid_file $_cyc_service ) 
			[ -f "$_cyc_mpid_file" ] && rm $_cyc_mpid_file		
			echo "[$( date +%s )] CYC DAEMON: [$_cyc_service] CYCLOPS DAEMON [RUNNING]:[STOP]" >> $_mon_log_path/cyc.daemon.log
			break
		fi

		_cyc_mon_freq=$( awk -F\; -v _cod="$_cyc_srv_cod" 'BEGIN { _frq=10 } $1 == _cod && $3 ~ "[0-9]+" { if ( $3 <= 10 ) { _frq=10 } else { _frq=$3 }} END { print _frq }' $_config_path_sys/cyc.daemon.cfg )
		echo "[$( date +%s )] [DEBUG] CYC DAEMON: [$_cyc_service] CYCLOPS DAEMON [$_cyc_mon_freq]" >> $_mon_log_path/cyc.daemon.log

		eval exec $_daemon &
		#$_script_path/monitoring.sh -d 2>>/opt/cyclops/logs/$HOSTNAME.mon.err.log &
		#_monsh_pid=$!

		#cyc_mon_torquemada $_cyc_mon_freq &
		#echo $! > $_lock_path/montor.pid
		wait
		#_cycmontorps=$( ps -eFl | awk -v _ps="$_montor_pid" 'BEGIN { _st="2" } $4 == _ps { _st="1" } END { print _st }' )
		#[ "$_cycmontorps" == "1" ] && kill $_montor_pid

		sleep $_cyc_mon_freq
	done
}

cyc_service_stop()
{
	_exit_func=254
	_cyc_service=$1
	_cyc_mpid_file=$( get_pid_file $_cyc_service ) 

	case "$2" in
	0)
		_pid=$( get_pid $2 )
		kill $_pid 2>/dev/null 
		_exit_func=$?
		[ "$_exit_func" == "0" ] && [ -f "$_cyc_mpid_file" ] && rm $_cyc_mpid_file		
	;;
	1)
		_exit_func=0
		[ -f "$_cyc_mpid_file" ] && rm $_cyc_mpid_file		
	;;
	2)
		if [ -f "$_cyc_mpid_file" ]
		then
			rm $_cyc_mpid_file 
			_exit_func=$?
		else
			_exit_func=1
		fi
	;;
	esac	

	return $_exit_func
}

### EXEC ###

	case $_par_act in
	enable|disable|restart|config)
		cyc_service $_par_act $_par_srv
	;;
	daemon)
		case "$_par_dae" in
		start)
			_dae_pid_status=$( check_pid cyclops 2>&1 >/dev/null ; echo $? )
			case "$_dae_pid_status" in
			0|3)
				err_cyc_dae daemon start log 
				echo -e $_sh_color_red"ERR:"$_sh_color_nformat" FAILED STARTING CYCLOPS DAEMON [$_dae_pid_status]"
			;;
			1)
				start_cyc_dae & 
				for _pid_file in $( ls -1 $_lock_path | grep "cyc.*pid" )
				do
					[ -f "$_lock_path/$_pid_file" ] && rm $_lock_path/$_pid_file
					[ "$?" == "0" ] && echo -e "[$( date +%s )] CYCLOPS DAEMON SERVICE [$_pid_file]: [PURGE]"  >> $_mon_log_path/cyc.daemon.log 
				done
				echo $! > $_cyc_dae_pid_file 
				echo -e "[$( date +%s )] CYCLOPS DAEMON STATUS: [ START ]"  >> $_mon_log_path/cyc.daemon.log 
			;;
			2)
				start_cyc_dae & 
				echo $! > $_cyc_dae_pid_file 
				echo -e "[$( date +%s )] CYCLOPS DAEMON STATUS: [ START ] [DEAD FILE]"  >> $_mon_log_path/cyc.daemon.log 
			;;
			esac

#			if [ "$_dae_pid_status" != "0" ] 
#			then
#				start_cyc_dae & 
#				echo $! > $_cyc_dae_pid_file 
#				echo -e "[$( date +%s )] CYCLOPS DAEMON STATUS: [ START ]"  >> $_mon_log_path/cyc.daemon.log 
#			else
#				err_cyc_dae daemon start log 
#				echo -e $_sh_color_red"ERR:"$_sh_color_nformat" FAILED STARTING CYCLOPS DAEMON"
#			fi
			status_cyc_dae
		;;
		stop)
			_dae_pid_status=$( check_pid cyclops 2>&1 >/dev/null ; echo $? )
			[ "$_dae_pid_status" == "0" ] && stop_cyc_dae || err_cyc_dae daemon stop log 
		;;
		status)
			_dae_pid_status=$( check_pid cyclops 2>&1 >/dev/null ; echo $? )
			status_cyc_dae
		;;
		config)
			awk -F\; 'BEGIN { print "CODE;CONFIG;FREQUENCY(sec);MODULE" } $1 ~ "[0-9]+" { print $0 }' $_config_path_sys/cyc.daemon.cfg | column -t -s\;
		;;
		restart)
			$_script_path/cyc.daemon.sh stop
			sleep 5s
			$_script_path/cyc.daemon.sh start
		;;
		*)
			#err_cyc_dae command exec log	
			echo "ERROR DEBUG:" >> $_mon_log_path/cyc.daemon.log
		;;
		esac
	;;
	esac

