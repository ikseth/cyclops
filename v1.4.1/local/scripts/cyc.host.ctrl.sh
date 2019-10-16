#!/bin/bash

###########################################
#         CYCLOPS LOCAL HOST CTRL         #
#	         MAIN SCRIPT 		  # 
###########################################

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

## SPECIFIC --

_debug_code="HOST CONTROL "
_debug_prefix_msg="Host Ctrl Local: "
_exit_code="0"
_hostname=$( hostname -s )

## GLOBAL --

_local_cfg_path="/opt/cyclops/local/etc"

if [ -f $_local_cfg_path/local.main.cfg ]
then
	source $_local_cfg_path/local.main.cfg
else
	echo "Main local config file don't exists"
	exit 1
fi

## LOCAL --

_hctrl_rzrrol_file=$_cyc_clt_rzr_cfg"/"$_hostname".rol.cfg"
_hctrl_rzr_last=$_cyc_clt_rzr_cfg"/"$_hostname".rzr.last"

## AUTOCTRL

_torquemada="/opt/cyclops/local/scripts/torquemada.sensor.sh"
_my_pid=$( echo $$ )
_my_pid_file="/opt/cyclops/local/lock/"$_my_pid".cyc.host.ctrl.pid"

trap 'kill -TERM -- -$$ 2>/dev/null' EXIT

################ LIBS #####################

###########################################
#              PARAMETERs                 #
###########################################

[ "$#" == "0" ] && echo "ERR: Use -h for help" && exit 1

while getopts ":a:v:h:x" _optname
do

        case "$_optname" in
		"a")
			_opt_act="yes"
			_par_act=$OPTARG
		;;
		"v")
			_opt_show="yes"
			_par_show=$OPTARG
		;;
                "h")
                        case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Audit Module, insert bitacora events, log nodes and device event, and inventary system"
                                echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
                                echo "  Data path: $_audit_data_path"
                                exit 0
                        ;;
                        "*")
                                echo "ERR: Use -h for help"
                                exit 1
                        ;;
                        esac
		;;
                ":")
                        if [ "$OPTARG" == "h" ]
                        then
                                echo
                                echo "CYCLOPS LOCAL RESOURCES CONTROL"
                                echo "  Manage Resources and control them"
                                echo
                                echo " -a [boot|link|unlink|start|stop|check|drain|diagnose|content|up|init] Action for ctrl resource"
                                echo "	boot: host boot event action"
                                echo "	link: host link action with the system"
                                echo "	unlink: host unlink action out of the system"
                                echo "	start: run the resource action"
                                echo "	stop: stop the resource"
                                echo "	check: knows resource status"
                                echo "	drain: maintenace resource status"
                                echo "	diagnose: put resource in diagnose mode"
                                echo "	content: put resource in content mode"
                                echo "	up: put resource in content mode"
				echo "	init: initializate host"
				echo "	disable: host ctrl off"
				echo "	enable:	host ctrl on"
				echo
				echo " -v [human|commas] verbose mode"
				echo "	human: format output human comprensible"
				echo "	commas: format output comma separated"
			fi
		;;
	esac
done

shift $((OPTIND-1))

###########################################
#              FUNCTIONs                  #
###########################################

host_mon()
{
	## 1. CTRL MON FILE EXISTS
	## 2. IF NOT GENERATE MON FILE ( DO WITH LIB, FOR COMMON WITH OTHER MODULES ) 
	## 3. LAUNCH MON FILE
	## 4. CHECK MON FILE
	
	echo "FACTORING"

}

host_launch()
{
	## USE IT'S OWN SCRIPT.... WITH START, STOP, LINK, UNKLINK... ALL ACTIONS, AND OWN ERROR CODES

	$_torquemada $_my_pid $_my_pid_file &

	_host_launch_act=$1
	_host_check_status="0"

	for _rzr_line in $( cat $_cyc_clt_rzr_lst | egrep -v "^$|^#" )
	do
		_rzr=$( echo $_rzr_line | cut -d';' -f1 )
		_rzr_cfg_file=$( echo $_rzr_line | cut -d';' -f2 )

		_rsc_output=$( $_cyc_clt_rzr_rsc -a $_host_launch_act  -r $_rzr -t $_hctrl_host_stk 2>&1 >/dev/null ; echo $? )
		[ "$_opt_show" == "yes" ] && echo $_hostname";"$_hctrl_host_stk";"$_rzr";"$_rsc_output

		case "$_host_launch_act" in 
		repair|link|up|boot) 
			[ "$_rsc_output" != "0" ] && [ "$_rsc_output" != "21" ] && _host_check_status="1" && break
		;;
		unlink|content|stop)
			[ "$_rsc_output" != "0" ] && [ "$_rsc_output" != "21" ] && _host_check_status="1" && break
		;;
		*) 
			[ "$_rsc_output" != "0" ] && [ "$_rsc_output" != "21" ] && _host_check_status="1"
		;;
		esac
	done
}

host_daemon()
{
	## CHECK ACTION
	## MAYBE COULD BE DO ACTIONS IF THINGS HAPPENDS
	## COULD BE LIKE MONITORING IN LOCAL HOST



	if [ -f "$_hctrl_rzr_last" ] 	
	then
		_hctrl_last_tim=$( stat -c %Y $_hctrl_rzr_last ) 
		_hctrl_last_fml=$( cat $_hctrl_rzr_last | egrep -v "^$|^#" | head -n 1 | cut -d';' -f1 )
		_hctrl_last_grp=$( cat $_hctrl_rzr_last | egrep -v "^$|^#" | head -n 1 | cut -d';' -f2 )
		_hctrl_last_stk=$( cat $_hctrl_rzr_last | egrep -v "^$|^#" | head -n 1 | cut -d';' -f3 )
		_hctrl_last_pwr=$( cat $_hctrl_rzr_last | egrep -v "^$|^#" | head -n 1 | cut -d';' -f4 )
		_hctrl_last_sta=$( cat $_hctrl_rzr_last | egrep -v "^$|^#" | head -n 1 | cut -d';' -f5 )
		_hctrl_last_rol=$( cat $_hctrl_rzr_last | egrep -v "^$|^#" | head -n 1 | cut -d';' -f6 ) 

		if [ "$_hctrl_host_sta" != "$_hctrl_last_sta" ] 
		then
			_hctrl_chg_status=$( $_cyc_clt_rzr_scp -a $_hctrl_host_sta ; echo $? )
			if [ "$_hctrl_chg_status" == "0" ] || [ "$_hctrl_chg_status" == "21" ] 
			then
				echo "$( date +%s ) : CYC : HCTRL : $_hostname : status changed $_hctrl_last_sta to $_hctrl_host_sta ($_hctrl_chg_status)" >> $_cyc_clt_local_log 
				echo "$_hctrl_host_fml;$_hctrl_host_grp;$_hctrl_host_stk;$_hctrl_host_pwr;$_hctrl_host_sta;$_hctrl_host_rol" > $_hctrl_rzr_last
			else
				echo "$( date +%s ) : CYC : HCTRL : $_hostname : failing change status $_hctrl_last_sta to $_hctrl_host_sta ($_hctrl_chg_status)" >> $_cyc_clt_local_log
			fi
		fi
	else
		echo "$( date +%s ) : CYC : HCTRL: $_hostname : WRN: Host ctrl razor last status file don't exists create from rol file" >> $_cyc_clt_local_log 
		echo "$_hctrl_host_fml;$_hctrl_host_grp;$_hctrl_host_stk;$_hctrl_host_pwr;$_hctrl_host_sta;$_hctrl_host_rol" > $_hctrl_rzr_last
	fi

}

###########################################
#              MAIN EXEC                  #
###########################################

#### CHECK SENSORS ENABLE FILE STATUS ####


	#- CHECK IF FILE EXISTS


	if [ ! -f "$_hctrl_rzrrol_file" ] 
	then
		if [ "$_par_act" == "daemon" ] 
		then
			echo "$( date +%s ) : CYC : HCTRL: $_hostname : ERR: Host ctrl razor rol file don't exists auto disable me" >> $_cyc_clt_local_log 
			_par_act="disable"
		else
			[ "$_opt_show" == "yes" ] && echo "ERR: Host Ctrl Razor Rol file don't exists" && exit 1
		fi
	fi


	## WARN CTRL FILE DON'T EXIST! ## !!! PUT A TEMPLATE IN LOCAL ETC !!!

	#- CHECK IF ROL IF DEFINED

	_hctrl_host_tim=$( stat -c %Y $_hctrl_rzrrol_file ) 
	_hctrl_host_fml=$( cat $_hctrl_rzrrol_file | egrep -v "^$|^#" | head -n 1 | cut -d';' -f1 )
	_hctrl_host_grp=$( cat $_hctrl_rzrrol_file | egrep -v "^$|^#" | head -n 1 | cut -d';' -f2 )
	_hctrl_host_stk=$( cat $_hctrl_rzrrol_file | egrep -v "^$|^#" | head -n 1 | cut -d';' -f3 )
	_hctrl_host_pwr=$( cat $_hctrl_rzrrol_file | egrep -v "^$|^#" | head -n 1 | cut -d';' -f4 )
	_hctrl_host_sta=$( cat $_hctrl_rzrrol_file | egrep -v "^$|^#" | head -n 1 | cut -d';' -f5 )
	_hctrl_host_rol=$( cat $_hctrl_rzrrol_file | egrep -v "^$|^#" | head -n 1 | cut -d';' -f6 ) 

	#- CHECK IF ROL FILE EXISTS

	_cyc_clt_rzr_lst=$_cyc_clt_rzr_cfg"/"$_hctrl_host_fml".rzr.lst"
	if [ ! -f "$_cyc_clt_rzr_lst" ] 
	then
		[ "$_opt_show" == "yes" ] && echo "ERR: Host Ctrl Razor list file don't exists"
		[ "$_opt_act" == "daemon" ] && echo "$( date +%s ) : CYC : HCTRL: $_hostname : ERR: Host Ctrl Razor list file don't exists" >> $_cyc_clt_local_log
		exit 1
	fi

	#- ENABLE ROL FILE

#### MAIN ACTIONS ####

case "$_par_act" in
	mon)
		[ ! -f "$_cyc_clt_rzr_cfg/hctrl.disable" ] && host_mon || [ "$_opt_show" == "yes" ] && echo "Host Ctrl is disabled, use -a enable for re-activate"
	;;
	boot)
		if [ -f "$_cyc_clt_rzr_cfg/hctrl.disable" ]
		then
			[ "$_opt_show" == "yes" ] && echo "Host Ctrl is disabled, use -a enable for re-activate"
		else
			echo "$( date +%s ) : CYC : HCTRL: $_hostname : host control booting action, wait 20 seconds to begin." >> $_cyc_clt_local_log
			sleep 20s
			host_launch $_par_act
		fi
	;;
	check|stop|unlink|drain|diagnose|content)
		if [ -f "$_cyc_clt_rzr_cfg/hctrl.disable" ] 
		then
			[ "$_opt_show" == "yes" ] && echo "Host Ctrl is disabled, use -a enable for re-activate"
		else
			host_launch $_par_act 
		fi
	;;
	start|up|link|repair|init)
		if [ -f "$_cyc_clt_rzr_cfg/hctrl.disable" ] 
		then
			[ "$_opt_show" == "yes" ] && echo "Host Ctrl is disabled, use -a enable for re-activate"
		else
			host_launch $_par_act 
			host_launch check
		fi
	;;
	content)
		if [ -f "$_cyc_clt_rzr_cfg/hctrl.disable" ] 
		then
			[ "$_opt_show" == "yes" ] && echo "Host Ctrl is disabled, use -a enable for re-activate"
		else
			touch $_cyc_clt_rzr_cfg/hctrl.disable 
			echo "$( date +%s ) : CYC : HCTRL: $_hostname : Razor Content Action, Special Directive -> host control disabled" >> $_cyc_clt_local_log
			host_launch $_par_act 
		fi
	;;
	daemon)
		if [ ! -f "$_cyc_clt_rzr_cfg/hctrl.disable" ] 
		then
			host_daemon 
		else
			[ "$_opt_show" == "yes" ] && echo "$( date +%s ) : CYC : HCTRL: $_hostname : WRN : Host Ctrl is disabled, use -a enable for re-activate" >> $_cyc_clt_local_log
		fi
	;;
	disable)
		[ ! -f "$_cyc_clt_rzr_cfg/hctrl.disable" ] && touch $_cyc_clt_rzr_cfg/hctrl.disable && echo "$( date +%s ) : CYC : HCTRL: $_hostname : host control disabled" >> $_cyc_clt_local_log && _host_check_status="0"
		[ "$_opt_show" == "yes" ] && echo "Host Ctrl Disabled"
	;;
	enable)
		[ -f "$_cyc_clt_rzr_cfg/hctrl.disable" ] && rm -f $_cyc_clt_rzr_cfg/hctrl.disable && echo "$( date +%s ) : CYC : HCTRL: $_hostname : host control enabled" >> $_cyc_clt_local_log && _host_check_status="0"
		[ "$_opt_show" == "yes" ] && echo "Host Ctrl Enabled"
	;;
esac

[ "$_opt_show" == "yes" ] && echo $_hostname";"general status";"$_host_check_status
exit $_host_check_status


