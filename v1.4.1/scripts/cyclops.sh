#!/bin/bash

#                                                                         
#                                                                         
#    ,----..                       ,--,                                   
#   /   /   \                    ,--.'|            ,-.----.               
#  |   :     :                   |  | :     ,---.  \    /  \              
#  .   |  ;. /                   :  : '    '   ,'\ |   :    |  .--.--.    
#  .   ; /--`      .--,   ,---.  |  ' |   /   /   ||   | .\ : /  /    '   
#  ;   | ;       /_ ./|  /     \ '  | |  .   ; ,. :.   : |: ||  :  /`./   
#  |   : |    , ' , ' : /    / ' |  | :  '   | |: :|   |  \ :|  :  ;_     
#  .   | '___/___/ \: |.    ' /  '  : |__'   | .; :|   : .  | \  \    `.  
#  '   ; : .'|.  \  ' |'   ; :__ |  | '.'|   :    |:     |`-'  `----.   \ 
#  '   | '/  : \  ;   :'   | '.'|;  :    ;\   \  / :   : :    /  /`--'  / 
#  |   :    /   \  \  ;|   :    :|  ,   /  `----'  |   | :   '--'.     /  
#   \   \ .'     :  \  \\   \  /  ---`-'           `---'.|     `--'---'   
#    `---`        \  ' ; `----'                      `---`                
#                  `--`                                                   

###########################################
#            CYCLOPS MAIN SCRIPT          #
###########################################

############################################################################
#									   #
#    Cyclops creator:   Ignacio Garcia Hoyos                               #
#                       ignaciogarciahoyos@gmail.com                       #
#									   #
#    GPL License							   #
#    -----------							   #
#									   #
#    This file is part of Cyclops Suit.					   #
#									   #
#    Foobar is free software: you can redistribute it and/or modify	   #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation, either version 3 of the License, or     #
#    (at your option) any later version.				   #
#									   #
#    Foobar is distributed in the hope that it will be useful, 		   #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.       #
#                                                                          #
############################################################################

############# VARIABLES ###################
#

IFS="
"

## LOCAL --

_pid=$( echo $$ )
_debug_code="CYCLOPS "
_debug_prefix_msg="Cyclops Main: "
_exit_code=0

_opt_show="no"
_opt_changes="no"
_opt_action="no"
_opt_node="no"

_def_msg_timelive=7200

## GLOBAL --

_config_path="/etc/cyclops"

if [ ! -f $_config_path/global.cfg ]
then
        echo "Global config file don't exits"
        exit 1
else
        source $_config_path/global.cfg
	[ -f "$_color_cfg_file" ] && source $_color_cfg_file || echo "WARNING: Cyclops Color Config File DONT EXITS"
fi

## CYCLOPS OPTION STATUS CHECK

_audit_status=$( awk -F\; '$1 == "CYC" && $2 == "0003" && $3 == "AUDIT" { print $4 }' $_sensors_sot )
_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )
_cyc_razor_status=$(    awk -F\; '$1 == "CYC" && $2 == "0014" && $3 == "RAZOR" { print $4 }' $_sensors_sot 2>/dev/null )

#### LIBS ####

	source $_libs_path/node_group.sh
	source $_libs_path/node_ungroup.sh

###########################################
#              PARAMETERs                 #
###########################################

_cyclops_action="start"
_command_opts=$( echo "$@" | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^m/ ) { gsub(/^[a-z] /,"&@",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' )


while getopts ":f:y:d:p:m:g:n:v:a:lcb:h:" _optname
do

        case "$_optname" in
		"a")
			_opt_action="yes"
			_par_action=$OPTARG

			[ "$_cyclops_action" == "start" ] && _cyclops_action="node_status" || exit 1 
		;;
		"f")
			_opt_mon_file="yes"
			_par_mon_file=$OPTARG
		;;
		"b")
			_opt_backup="yes"
			_par_backup=$( echo $OPTARG | sed 's/\/$//' )
			[ "$_cyclops_action" == "start" ] && _cyclops_action="backup" || exit 1
		;;
		"n")
			_opt_node="yes"
			_par_node=$OPTARG

			_ctrl_grp=$( echo $_par_node | grep @ 2>&1 >/dev/null ; echo $? )

			if [ "$_ctrl_grp" == "0" ]
			then
				_par_node_grp=$( echo "$_par_node" | tr ',' '\n' | grep ^@ | sed 's/@//g' | tr '\n' ',' )
				_par_node=$( echo $_par_node | tr ',' '\n' | grep -v ^@ | tr '\n' ',' )
				_par_node_grp=$( awk -F\; -v _grp="$_par_node_grp" '{ split (_grp,g,",") ; for ( i in g ) {  if ( $2 == g[i] || $3 == g[i] || $4 == g[i] ) { _n=_n""$2","  }}} END { print _n }' $_type )
				_par_node_grp=$( node_group $_par_node_grp )
				_par_node=$_par_node""$_par_node_grp

				[ -z "$_par_node" ] && echo "ERR: Don't find nodes in [$_par_node_grp] definited group(s)/family(s)" && exit 1
			fi
					
			_long=$( node_ungroup $_par_node | tr ' ' '\n' )
		;;
		"m")
			_opt_msg="yes"
			_par_msg=$OPTARG

			if [ "$_cyclops_action" == "start" ] 
			then
				 _cyclops_action="messages" 
			else
				if [ ! "$_cyclops_action" == "cyclops" ] 
				then
					echo "ERR: Incompatible Parameters"
					exit 1
				fi
			fi

			_par_msg=$( echo $_par_msg | sed -e 's/;/,/g' )
		;;
		"l")
			_opt_mail="yes"
		;;
		"d")
			_opt_date="yes"
			_par_date=$OPTARG
		;;
		"y")
			_opt_cyclops="yes"
			_par_cyclops=$OPTARG

			[ "$_cyclops_action" == "start" ] && _cyclops_action="cyclops" || exit 1
		;;
		"p")
			_opt_priority="yes"
			_par_priority=$OPTARG
		
			case "$_par_priority" in
			info)
				_par_priority=100
			;;
			low)
				_par_priority=80
			;;
			medium)
				_par_priority=30
			;;
			high)
				_par_priority=5
			;;
			esac	
		;;
                "v")
                        _opt_show="yes"
                        _par_show=$OPTARG

			[ "$_cyclops_action" == "start" ] && _cyclops_action="show" || exit 1

			case "$_par_show" in
			node|device|group|family|sensor|messages|procedures|critical)
				echo "" &>/dev/null
			;;
			*)
				echo "ERR: Use -h for help"
                                exit 1 
			;;
			esac
                ;;
		"c")
			#### APPLY CHANGES ####
			_opt_changes="yes"
		;;
		"h")
			_opt_help="yes"
			_par_help=$OPTARG	

			case "$_par_help" in 
					"des")
						echo "$( basename "$0" ) : Main cyclops management monitoring command"
						echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
						echo "	Global config path : $_config_path"
						echo "		Global config file: global.cfg"
						echo
						echo "	Cyc system config path: $_config_path_sys" 
						echo "		Wiki Apache config file: wiki.cfg"
						echo "		HA config file: $( echo $_ha_cfg_file | awk -F\/ '{ print $NF }' )"
						echo "		HA sync excludes: $( echo $_ha_sync_exc | awk -F\/ '{ print $NF }' )"
						echo "		Color config file: $( echo $_color_cfg_file | awk -F\/ '{ print $NF }' )"
						echo
						echo "		Cyc profiles rc file: cyclopsrc"
						echo "		Info cyc codes file: $( echo $_sensors_sot_codes_file | awk -F\/ '{ print $NF }' )"
						echo "		Command info file: $( echo $_cyc_script_code_file | awk -F\/ '{ print $NF }' )"
						
						exit 0
					;;
					"all")
						_help_filter=""

						echo "ALL CYCLOPS COMMANDS:"
						echo "---------------------"
					;;
					"cyc")
						_help_filter="CYC"
	
						echo
						echo "CYCLOPS SYSTEM COMMANDS:"
						echo "------------------------"
					;;
					"audit")
						_help_filter="AUD"

						echo
						echo "AUDIT COMMANDS:"
						echo "---------------"
					;;
					"mon")

						_help_filter="MON"

						echo
						echo "MONINTOR COMMANDS:"
						echo "------------------"
					;;
					"tools")
						_help_filter="TOL"

						echo
						echo "AVAILABLE TOOLS:"
						echo "----------------"
					;;
					"stat")
						_help_filter="STA"

						echo
						echo "STATISTICS COMMANDS:"
						echo "--------------------"
					;;
					"rzr")
						_help_filter="RZR"
					
						echo
						echo "RAZOR MODULE COMMANDS:"
						echo "----------------------"
					;;
					*)
						echo "ERR: Use -h for help"
						exit 1
					;;
			esac

			for _file in $( cat $_cyc_script_code_file | grep -v ^\# | awk -F\; -v _fil="$_help_filter" '$1 ~ _fil { print $0 }' )
			do
				unset _main_info

				_cmd_code=$( echo $_file | cut -d';' -f1 )
				_cmd_path=$( echo $_file | cut -d';' -f2 )
				_cmd_file=$( echo $_file | cut -d';' -f3 )
				_cmd_ver=$(  echo $_file | cut -d';' -f4 | awk -F\. '{ print $1"."$2" ("$3")" }' )
				_cmd_birth=$( echo $_file | cut -d';' -f5 )
				_cmd_des=$( echo $_file | cut -d';' -f6 )
				_cmd_dep=$(  echo $_file | cut -d';' -f7 )
				_store_sum_cmd=$( echo $_file | cut -d';' -f8 )
				_launch_path_cmd=$_base_path"/"$_cmd_path"/"$_cmd_file

				[ "$_cmd_dep" == "none" ] && [ -f "$_launch_path_cmd" ] && _main_info=$( $_launch_path_cmd -h des 2>/dev/null )

				[ -f "$_launch_path_cmd" ] && _real_sum_cmd=$( sha1sum $_launch_path_cmd | awk '{ print $1 }' ) 

				if [ -z "$_store_sum_cmd" ]
				then
					_sum_status="WARN> No exists Storage SUM"
				else
					if [ -z "$_real_sum_cmd" ]
					then
						_sum_status="WARN> No exists file"
					else
						_check_sum=$( echo $_store_sum_cmd | grep $_real_sum_cmd &>/dev/null ; echo $? )
						[ "$_check_sum" == "0" ] && _sum_status="OK" || _sum_status="FAIL CHECK"
					fi
				fi 

				if [ -z "$_main_info" ] 
				then
					if [ "$_cmd_dep" == "none" ] 
					then
						echo "$_cmd_file : cyc main command without info, check cyclops install"
					else
						echo "$_cmd_file : Sub script or Config file from $( cat $_cyc_script_code_file | awk -F\; -v _code="$_cmd_dep" '$1 == _code { print $3 }' )"
					fi
				else
					echo -e "${_main_info}"
				fi

				echo
				echo "	Cyclops Main Description: $_cmd_des"
				echo "		Birth Date: $( date -d $_cmd_birth +%d\ %B\ %Y)"
				echo "		Version: $_cmd_ver" 
				echo "		Check SUM: $_sum_status"
				echo
			done	
			exit 0
                ;;
                ":")
			case "$OPTARG" in 
			"h")
				echo
				echo "COMMAND TO MANAGE CYCLOPS MONITORING SYSTEM"
				echo
				echo "	MANAGE CYCLOPS GLOBAL TASK:"
				echo "	---------------------------"
				echo "	-y [[Install/Setup/Monitor] Options] Management Cyclops (EXCLUSIVE OPTION)"
				echo
				echo "	Cyclops Install Options:"
				echo "		config: Interactive Cyclops config"
				echo "		install: Init and Install Cyclops [NOT OPERATIVE YET]"
				echo "		cron: Active Monitoring System like Daemon [NOT OPERATIVE YET]"
				echo "		remove: Remove Monitoring System from Cron [NOT OPERATIVE YET]"
				echo
				echo "	Cyclops Setup Options:"
				echo "		recount: Put Cyclops Cycles at ZERO"
				echo "		[no]mail: Enable/Disable eMail Alerts"
				echo "		[no]sound: Enable/Disable Sound Web Alerts"
				echo "		[no]ha: Enable/Disable HA Mode"
				echo "		[no]audit: Enable/Disable Audit Module ( needs cron task )"
				echo "		[no]reactive: Enable/Disable Reactive Host Ctrl, beware cyclops auto manage nodes"
				echo "		[no]razor: Enable/Disable Host Control Razor"
				echo "		[no]well: Enable/Disable Welcome Cyclops Server Banner"
				echo "		[no]screen: Enable/Disable User Screen Control Security in Cyclops Server"
				echo "		[no]monsec: Enable/Disable Security Monitor Module"
				echo "		[no]monsrv: Enable/Disable Services Monitor Module"
				echo "		[no]monnod: Enable/Disable Nodes/Hosts Monitor Module"
				echo "		[no]monenv: Enable/Disable Environment Monitor Module"
				echo "		sum: Check cyclops command status and integrity"
				echo "		devel: show cyclops development timeline status"
				echo
				echo "	Cyclops monitor status (MANDATORY use -m to indicate reason when change state):"
				echo "		enable: Enable Monitoring System"
				echo "		disable: Disable Monitoring System"
				echo "		drain: Put Monitoring System in Maintenance Mode"
				echo "		testing: Put Monitoring System in Testing Mode"
				echo "		repair: Put Monitoring System in Repairing Mode"
				echo "		intervention: Put Monitoring System in Intervention Mode"
				echo "		status: Show Current Monitoring Status, no -m option necessary"
				echo "	    Change status Options:"
				echo "		-m Reason for change status, this message show in cyclops web dashboard"
				echo "		-d [date, YYYYMMDD [HHMM]], Caducity date ( By default 2h ) "
				echo
				echo "	-c APPLY changes, otherwise no changes would be do"
				echo
				echo "	MANAGE NODES:"
				echo "	---------------------------"
				echo "	If you want active actions you need to enable razor or/and reactive modules"
				echo "	otherwise only this actions are administrative"
				echo
				echo "	-a [action] change administrative node/device status (EXCLUSIVE OPTION)"
				echo "		list: show available actions"
				echo "		up: Monitoring Node"
				echo "		drain: put nodes/device on maintenance management task mode"
				echo "		content: put nodes/device on content mode (unsolved problem in it)"
				echo "		repair: waiting for repair action or request cyclops reactive module repair action"
				echo "		diagnose: checking device, disable all alerts on it"
				echo "		link: linking node to system, action before up mode"
				echo "		unlink: unlinking node to system, action before drain mode"
				echo "		status: check actually mon status from node/family/grouWp"
				echo "	-n [nodename] Choose one node or range of nodes"
				echo "		use -v to see avaible types"
				echo "		nodename: can use regexp, BEWARE, test before launch command"
				echo "	-f [ cyclops node monitor file ] : check node status from old monitor node file ( Only with -a option) TILL-EXPERIMENTAL!"
				echo "	-c APPLY changes, otherwise no changes would be do"
				echo 
				echo "	CYC MAIN MONTOR MESSAGES"
				echo "	---------------------------"
				echo "	-m [message|death|list|[0-9]*] Info to show in cyclops web dashboard (EXCLUSIVE OPTION)"
				echo "		message: text of the dashboard message you want to show (if have spaces use quotes)"
				echo "		death: if you wrote death all old messages will be deleted"
				echo "		list: show all menssages, mark non active messages with DEATH tag"
				echo "	-d [date, YYYYMMDD [HHMM]], Caducity date, with hour option use quotes, if you dont specify it,  system use now time plus 1h for caducity"
				echo "	-p [info,low,medium,high], Required field for some parameters"
				echo "		info: lowest priority messages, info will show with green color"
				echo "		low: priority will show with yellow color"
				echo "		medium: priority will show with orange color"
				echo "		high: highest level, priority will show with red color"
				echo "	-l : send message from email to configured emails"
				echo
				echo "	CYC BACKUP:"
				echo "	---------------------------"
				echo "	-b [script] create backup copy from cyclops scripts (EXCLUSIVE OPTION)"
				echo "	-d [date, YYYYMMDD [HHMM]], Caducity date for some parameters, with hour option use quotes, if you dont specify it,  system use now time plus 1h for caducity"
				echo "		day: format -> [number of week day].[ abbreviated week day name]"
				echo "		month: format -> [number of moth].[abbreviated month name]"
				echo "		week: format -> [number of week year].[abbreviated month name]"
				echo "		actually other values are ignored and use YYYYMMDD\ HHMM format"
				echo
				echo "	INFO:"
				echo "	---------------------------"
				echo "	-v [option] show available cyclops config resources (EXCLUSIVE OPTION)"
				echo "		node: configured nodes"
				echo "		device: NOT AVAILABLE YET"
				echo "		group:  show node cyclops group assignament" 
				echo "		family: show node cyclops family assignament"
				echo "		sensor: family/group/node/device active sensors"
				echo "		messages: show dashboard messages list"
				echo "		procedures: Show procedure status, configured codes, existing pages, etc"
				echo "		critical: Show Defined Critical Environment"
				echo
				echo "	HELP:"
				echo "	---------------------------"
				echo "	-h [cyc|audit|mon|tools|stat|all] You can specify detailed help about cyclops"
				echo "		cyc: help about cyclops management commands"
				echo "		audit: help about cyclops audit module commands"
				echo "		mon: help about cyclops monitoring module commands"
				echo "		tools: help about available tools"
				echo "		stat: help about statistics commands"
				echo "		all: help about all cyclops commands"
				echo "		des: Detailed command help"
				echo
			;;
			*)
				echo "ERR: $OPTARG option needs argument, use -h to see help" 
			;;
			esac
		;;
                --*)
                        echo "OPssss!!!"
			echo "NO OPTION AVAILABLE, USE -h to see options"
                        echo $_optname" "$OPTARG
                        exit 1
                ;;
                *)
                        echo "WHATs HAPPEND?!"
			echo "NO OPTION AVAILABLE, USE -h to see options"
                        echo $_optname" "$_OPTARG
                        exit 1
                ;;
        esac

done

shift $((OPTIND-1))

###########################################
#             FUNCTIONS                   #
###########################################

ha_check()
{

	_ha_master_host=$( cat $_sensors_sot | grep "^CYC;0006;HA" | cut -d';' -f5 )
	_ha_slave_host=$( cat $_ha_cfg_file | awk -F\; -v _m="$_ha_master_host" '$1 == "ND" && $2 != _m { print $2 }' ) 
	_ha_role_me=$( cat $_ha_role_file )

	if [ "$HOSTNAME" != "$_ha_master_host" ] 
	then
		if [ "$_ha_role_me" == "SLAVE" ] 
		then
			echo "WARNING: HA CONFIG ENABLED"
			echo "$HOSTNAME in SLAVE mode" 
			echo "Trying to execute command on master node ($_ha_master_host)"
			echo
			ssh $_ha_master_host $_script_path/cyclops.sh $_command_opts 
			_exit_code=$?
			[ "$_exit_code" != "0" ] && echo "ERROR ($_exit_code): please connect to $_ha_master_host to exec the command"
			exit $? 
		fi
	else
		if [ "$_ha_role_me" == "SLAVE" ] 
		then
			echo -e "WARNING: HA CONFIG ON POSIBLE SPLIT BRAIN SITUATION force MASTER on UPDATER node" 
			exit 1
		fi
	fi
}

debug_bkp()
{
        ## CYCLOPS SCRIPT BACKUP ##

        case "$_par_date" in
		day)
			_bkp_date=$( date +%u.%a )
		;;
		month)
			_bkp_date=$( date +%m.%b )
		;;
		week)
			_bkp_date=$( date +%W.%b )
		;;
		*|"")
			_bkp_date=$(date +%Y%m%dT%H%M)
		;;
	esac

        _bkp_file=$( echo $_par_backup | awk -F"/" '{ print $NF }' )
	[ -f "$_par_backup" ] && cp -p $_par_backup $_script_bkp_path'/'$_bkp_file'.'$_bkp_date'.bkp'
	[ -d "$_par_backup" ] && tar -z -c --exclude="$_script_bkp_path" -f $_script_bkp_path/$_bkp_file.$_bkp_date.tgz $_par_backup

}

mng_node_status_check()
{
	echo "testing changes over $_type config file, nodes: $_par_node action: $_par_action"
	echo "do backup before apply changes..." 
	echo

	echo -e "\tPROCESSING: "
	_total_nodes=$( echo "${_long}" | wc -l )
	[ -z "$_total_nodes" ] && _total_nodes=0

	_color_tot=$_sh_color_green

	_cfg_files=$_type" "$_dev

	for _host_node in $( echo "${_long}" )
	do
		let "_total_num++"
		_ctrl_node=$( eval exec cat $_cfg_files | awk -F\; -v _n="$_host_node" 'BEGIN { _s="X" } $2 == _n { _s="#" } END { print _s }' ) 
		if [ "$_ctrl_node" == "#" ]
		then
			_node_change_ok=$_node_change_ok" "$_host_node
			let "_total_ok++"
		else
			_node_change_bad=$_node_change_bad" "$_host_node
			let "_total_bad++"
		fi
		let "_total_per =  _total_num * 100  / _total_nodes "
		let "_ok_per =  _total_ok * 100  / _total_nodes "
		let "_bad_per =  _total_bad * 100  / _total_nodes "

		[ "$_total_bad" == "1" ] && _color_tot=$_sh_color_red

		echo -ne "\t TOTAL:[$_color_tot""$_total_per%""$_sh_color_nformat] OK:[$_sh_color_green""$_ok_per%""$_sh_color_nformat] FAIL:[$_sh_color_red""$_bad_per%""$_sh_color_nformat]\r"
	done

	echo
	echo -e "\tNODE CHANGES:"
	[ ! -z "$_node_change_ok" ] && echo -e  "\t OK  :[$_total_ok]\t $( node_group $_node_change_ok ) --> $_par_action" 
	[ ! -z "$_node_change_bad" ] && echo -e "\t FAIL:[$_total_bad]\t $( node_group $_node_change_bad ) --> not match"

	echo 
	echo "Finish test changes, use -c parameter for apply them" 
	echo
}

mng_node_status_do()
{
	echo "Doing changes..."
	echo
	
	echo -e "\tPROCESSING: "
	_total_nodes=$( echo "${_long}" | wc -l )
	[ -z "$_total_nodes" ] && _total_nodes=0

	_color_tot=$_sh_color_green
	_cfg_files=$_type" "$_dev

	for _host_node in $( echo "${_long}" )
	do
		let "_total_num++"
		_ctrl_node=$( eval exec cat $_cfg_files | awk -F\; -v _n="$_host_node" 'BEGIN { _s="X" } $2 == _n { _s="#" } END { print _s }' ) 
		if [ "$_ctrl_node" == "#" ]
		then
			sed -i "s/\(.*;$_host_node;.*;\)[a-z]*$/\1$_par_action/" $_type
			sed -i "s/\(.*;$_host_node;.*;\)[a-z]*$/\1$_par_action/" $_dev
			_node_change_ok=$_node_change_ok" "$_host_node
			[ "$_audit_status" == "ENABLED" ] &&  $_script_path/audit.nod.sh -i event -e status -m "mon status" -s $_par_action -n $_host_node 2>>$_mon_log_path/audit.log
			let "_total_ok++"
		else
			_node_change_bad=$_node_change_bad" "$_host_node
			let "_total_bad++"
			_color_tot=$_sh_color_red
		fi
		let "_total_per =  _total_num * 100  / _total_nodes "
		let "_ok_per =  _total_ok * 100  / _total_nodes "
		let "_bad_per =  _total_bad * 100  / _total_nodes "

		echo -ne "\t TOTAL:[$_color_tot""$_total_per%""$_sh_color_nformat] OK:[$_sh_color_green""$_ok_per%""$_sh_color_nformat] FAIL:[$_sh_color_red""$_bad_per%""$_sh_color_nformat]\r"
	done

	echo
	echo -e "\tNODE CHANGES:"
	[ ! -z "$_node_change_ok" ] && echo -e  "\t OK  :[$_total_ok]\t $( node_group $_node_change_ok ) --> $_par_action" 
	[ ! -z "$_node_change_bad" ] && echo -e "\t FAIL:[$_total_bad]\t $( node_group $_node_change_bad ) --> not match"

	echo
	echo "Cyclops System Notified"

	let "_cyc_msg_date=$( date +%s ) + 3600"
	$_script_path/cyclops.sh -m "CHANGING ADMINISTRATIVE NODE STATE: $( node_group $_node_change_ok ) TO $_par_action" -p info -d $( date -d @$_cyc_msg_date +%Y%m%d\ %H%M )

}

mng_node_status()
{
	## CHANGE NODE MANAGEMENT STATUS ##

	case "$_par_action" in
	drain)
		#### REFACTORY: ADD ACTIONS TO GO IN DRAIN ####
		
		[ "$_opt_node" == "no" ] && echo "-n parameter needed, node or node range mandatory" && exit 1

		if [ "$_opt_changes" == "no" ]
		then
			mng_node_status_check
		else
			mng_node_status_do
		fi
	;;
	up)

		#### REFACTORY: ADD CHECKS BEFORE GO TO UP ####

                [ "$_opt_node" == "no" ] && echo "-n parameter needed, node or node range mandatory" && exit 1

                if [ "$_opt_changes" == "no" ]
                then
			mng_node_status_check
                else
			mng_node_status_do
                fi
	;;
	content|repair|diagnose|link|unlink|exclude|poweroff)

		[ "$_opt_node" == "no" ] && echo "-n parameter needed, node or node range mandatory" && exit 1

		if [ "$_opt_changes" == "no" ]  
		then
			mng_node_status_check
		else
			mng_node_status_do
		fi
	;;
	status)
		[ "$_opt_node" == "no" ] && echo "-n parameter needed, nodename mandatory" && exit 1
		if [ -f "$_par_mon_file"  ] 
		then
			_stats_node_title=$( echo $_par_mon_file 2>/dev/null | awk -F\/ '{ split($NF,a,".") ;  print a[1] }' )
			#_status_node_title=$( date -d "$_status_node_title" +%s )
		else
			_par_mon_file=$_mon_path"/monnod.txt"
			_status_node_title=$( /usr/bin/stat -c %Y $_par_mon_file )
		fi


		_last_mon_status=$( 
			cat $_par_mon_file 2>/dev/null | 
			tr '|' ';' | 
			grep ";" | 
			sed -e 's/\ *;\ */;/g' -e '/^$/d' -e '/:wiki:/d' -e "s/$_color_disable/DISABLE/g" -e "s/$_color_unk/UNK/g" -e "s/$_color_up/UP/g" -e "s/$_color_down/DOWN/g" -e "s/$_color_mark/MARK/g" -e "s/$_color_fail/FAIL/g" -e "s/$_color_check/CHECK/g" -e "s/$_color_ok/OK/g" -e "s/$_color_disable/DISABLE/" -e "s/$_color_title//g" -e "s/$_color_header//g" -e 's/^;//' -e 's/;$//' -e '/</d' -e 's/((.*))//' -e '/:::/d' | 
			awk -F\; '
				BEGIN { 
					OFS=";" ; 
					_print=0 
				} { 
					if ( $1 == "family" ) { _print=1 } ; 
					if ( $2 == "name" ) { _print=0 } ; 
					if ( _print == 1 ) { print $0 }
				}' | 
			awk -F\; -v cols="hostname;mon_time;uptime" '
				BEGIN { 
					OFS=";" 
				} $0 ~ "family" { 
					split(cols,out,";") ; 
					for (i=1;i<=NF;i++) ix[$i]=i  
				} { 
					for (i in out) printf "%s%s", $ix[out[i]], OFS ; 
					print "" 
				}' | 
				sed -e 's/ /;/' -e 's/\(.*\);[A-Z]*\ \(.*\)$/\1;\2/g' -e 's/\(.*\);[A-Z]* \([0-9][0-9]\.[0-9][0-9]\.[0-9][0-9].*\)$/\1;\2/' 
			)

		echo
		echo "$( date -d @$_status_node_title +%Y-%m-%d\ %H:%M ) : Monitoring $_par_node status is:"
		echo

		_node_action_status_pr="index;name;family;group;os;power;mon status;mon time;node status;uptime"

		for _host_node in $( echo "${_long}" )
		do
			_node_action_status_pr=$_node_action_status_pr"\n"$( awk -F\; -v _par="$_host_node" '$2 == _par || $3 ~ _par || $4 ~ _par {  print $0 }' $_type )";"$( echo "${_last_mon_status}" | awk -F\; -v _d="$_status_node_title" -v _h="$_host_node" 'BEGIN { _d=strftime("%Y-%m-%d",_d) } $2 == _h { print _d" "$3";"$1";"$4 }' ) 
		done

		echo -e "${_node_action_status_pr}" | column -s\; -t

	
	;;
	list|*)
		echo "-a [action] change administrative node/device status"
		echo "          list: show available actions"
		echo "          up: put nodes/device on monitoring"
		echo "          drain: put nodes/device on maintenance management task mode"
		echo "          content: put nodes/device on content mode (unsolved problem in it)"
		echo "          repair: waiting for repair action"
		echo "          diagnose: checking device, disable all alerts on it"
		echo "		link: linking node to system, action before node go to up"
		echo "		status: check actually mon status from node/s"
	;;
	esac
}

show_config()
{
	## LIST CONFIG INFO ##

	case "$_par_show" in
	node)
		_show_node_list=$( awk -F\; '$0 !~ "^#" { 
			_f[$3]=_f[$3]" "$2 ; 
			_g[$4]=_g[$4]" "$2 ; 
			_o[$5]=_o[$5]" "$2 ; 
			_p[$6]=_p[$6]" "$2 ; 
			_s[$7]=_s[$7]" "$2 ; 
			_a=_a" "$2 
		} END { 
			for ( i in _f ) { 
				print "family:"i":"_f[i]  
			}
			for ( i in _g ) {
				print "group:"i":"_g[i] 
			}
			for ( i in _o ) {
				print "stock:"i":"_o[i] 
			}
			for ( i in _p ) {
				print "power:"i":"_p[i]
			}
			for ( i in _s ) {
				print "status:"i":"_s[i]
			}
			print "general:all:"_a
		}' $_type )

		for _show_node_line in $( echo "${_show_node_list}" ) 
		do
			_show_type=$( echo $_show_node_line | cut -d':' -f1 )
			_show_head=$( echo $_show_node_line | cut -d':' -f2 )
			_show_body=$( echo $_show_node_line | cut -d':' -f3 )

			echo "$_show_type:$_show_head:$( [ -z "$_show_body" ] && echo "none" || node_group $_show_body )"
		done
	;;
	device)
		echo "Actually environment monitoring is not implemented, we will working on it"
	;;
	family)
		_show_node_list=$( awk -F\; '$0 !~ "^#" { 
			_f[$3]=_f[$3]" "$2 ; 
			_a=_a" "$2 
		} END { 
			for ( i in _f ) { 
				print i":"_f[i]  
			}
			print "all:"_a
		}' $_type )

		for _show_node_line in $( echo "${_show_node_list}" ) 
		do
			_show_head=$( echo $_show_node_line | cut -d':' -f1 )
			_show_body=$( echo $_show_node_line | cut -d':' -f2 )

			echo "$_show_head:$( [ -z "$_show_body" ] && echo "none" || node_group $_show_body )"
		done | column -s\: -t
	;;
	group)
		_show_node_list=$( awk -F\; '$0 !~ "^#" { 
			_g[$4]=_g[$4]" "$2 ; 
			_a=_a" "$2 
		} END { 
			for ( i in _g ) { 
				print i":"_g[i]  
			}
			print "all:"_a
		}' $_type )

		for _show_node_line in $( echo "${_show_node_list}" ) 
		do
			_show_head=$( echo $_show_node_line | cut -d':' -f1 )
			_show_body=$( echo $_show_node_line | cut -d':' -f2 )

			echo "$_show_head:$( [ -z "$_show_body" ] && echo "none" || node_group $_show_body )"
		done | column -s\: -t
	;;
	sensor)

		show_sensor_config

	;;
	messages)
		awk -F\; 'BEGIN { OFS=";" } $1 == "INFO" { $3=strftime("%m-%d-%Y;%H:%M",$3);$4=strftime("%m-%d-%Y;%H:%M",$4) ; print $0 }' $_sensors_sot | column -s\; -t 
	;;
	procedures)
		show_config_procedures
	;;
	critical)
		cat $_critical_res | grep -v ^\# | cut -d';' -f2- | sed 's/;/,/4g' | sed '1 i\Total Nodes;Min Nodes;Family;Critical Sensors\n-----------;---------;------;----------------' | column -s\; -t 
	;;
	*)
	;;
	esac
}

show_sensor_config()
{

	if [ -z "$_par_node" ]
	then	
		_sensor_group_output=$( echo "AVAILABLE SENSOR GROUPS\nGROUP;ENABLE;NODES;SENSORS\n" )

		for _sensor_group in $( ls -1 $_config_path_nod/*.mon.cfg | awk -F\/ '{ print $NF }' |  sed 's/\.mon\.cfg//' )
		do
			_cfg_sensor_group=$( cat $_config_path_nod/$_sensor_group.mon.cfg )
			[ -z "$_cfg_sensor_group" ] && _cfg_sensor_group="none"
			_nodes_sensor_group=$( cat $_type | awk -F\; -v _group="$_sensor_group" 'BEGIN { count=0 } $3 == _group || $4 == _group { count++ } END { print count }' )
			[ "$_nodes_sensor_group" -ne 0 ] && _active_sensor_group="yes" || _active_sensor_group="no"
			
			_sensor_group_output=$_sensor_group_output"\n"$( echo "${_cfg_sensor_group}" | sed -e "1s/^/$_sensor_group;$_active_sensor_group;$_nodes_sensor_group;/" -e '2,$s/^/ ; ; ;/' )
		done


		_os_sensor_output=$( echo "AVAILABLE SENSORS\nSTOCK;SENSORS\n" )

		for _sensor_os in $( ls -1 $_sensors_script_path )
		do
			_os_sensor_available=$( ls -1 $_sensors_script_path/$_sensor_os | grep -v template | cut -d '.' -f2 )
			[ -z "$_os_sensor_available" ] && _os_sensor_available="none"
			 
			_os_sensor_output=$_os_sensor_output"\n"$( echo "${_os_sensor_available}" | sed -e "1s/^/$_sensor_os;/" -e '2,$s/^/ ;/')

		done
	fi

	echo -e "${_sensor_group_output}" | column -s\; -t
	echo
	echo -e "${_os_sensor_output}" | column -s\; -t

}

show_config_procedures()
{

	_header_procedure_output="CODE;DESCRIPTION;PRIORITY;HOST;SENSORS;WIKI FILE;WIKI INDEX;WIKI VER;OPERATIVE;VERIFICATED"

	## NODE IA PROCEDURES

	for _proc_file in $( ls -1 $_sensors_ia_path/*.rule ) 
	do 
		_code=$( echo $_proc_file | cut -d'.' -f2 )
		_priority=$( echo $_proc_file | awk -F\/ '{ print $NF }' | cut -d'.' -f1 )
		_host=$( cat $_proc_file | grep ^[0-9] | awk -F\; '{ if ( $3 == "" ) { $3="ALL" } { print $3 }}' | tr '\n' ',' | sed 's/,$//' )
		_sensors=$( cat $_proc_file | grep ^[0-9] | cut -d';' -f4- | sed -e 's/;/,/g' | tr '\n' ',' | sed 's/,$//'  )
        	_file_des=$( grep "^$_code;" $_sensors_ia_codes_file | cut -d';' -f2 )
        	[ -z "$_file_des" ] && _file_des="NONE"

        	_wiki_file=$( ls -1 $_pages_path/operation/procedures/*.txt | cut -d'.' -f1 | tr '[:lower:]' '[:upper:]' | grep $_code | wc -l )
        	_wiki_index=$( cat $_pages_path/operation/procedures/procedures.txt | grep $_code | wc -l )
		[ "$_wiki_index" -eq 0 ] && _wiki_index="NO" || _wiki_index="YES ("$_wiki_index")"
		if [ "$_wiki_file" -ne 0 ] 
		then	
			_wiki_file=$( echo $_code | tr '[:upper:]' '[:lower:]' | sed -e 's/$/\.txt/' )
			_wiki_version=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'  | awk -F\; '{ print $8 }' )
			_wiki_verif=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $4 }' )
			_wiki_opert=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $5 }' )
		else
			_wiki_file="NO EXIST"
			_wiki_version=""
			_wiki_verif=""
			_wiki_opert=""
		fi 
        	_proc_data=$_proc_data"\n"$_code";"$_file_des";"$_priority";"$_host";"$_sensors";"$_wiki_file";"$_wiki_index";"$_wiki_version";"$_wiki_opert";"$_wiki_verif
	done

	_node_proc=$( echo "#1#" ; echo $_header_procedure_output ; echo -e $_proc_data | sort )

	## ENV IA PROCEDURES 

	_proc_data=""

	for _proc_file in $( ls -1 $_sensors_env_ia/*.rule |  grep -v template  )  
        do
                _code=$( echo $_proc_file | cut -d'.' -f2 )
                _priority=$( echo $_proc_file | awk -F\/ '{ print $NF }' | cut -d'.' -f1 )
                _env_dev=$( cat $_proc_file | grep ^[0-9] | awk -F\; '{ if ( $3 == "" ) { $3="ALL" } { print $3 }}' | tr '\n' ',' | sed 's/,$//' )
                _sensors=$( cat $_proc_file | grep ^[0-9] | cut -d';' -f4- | sed -e 's/;/,/g' | tr '\n' ',' | sed 's/,$//'  )
                _file_des=$( grep "^$_code;" $_sensors_ia_codes_file | cut -d';' -f2 )
                [ -z "$_file_des" ] && _file_des="NONE"

                _wiki_file=$( ls -1 $_pages_path/operation/procedures/*.txt | cut -d'.' -f1 | tr '[:lower:]' '[:upper:]' | grep $_code | wc -l )
                _wiki_index=$( cat $_pages_path/operation/procedures/procedures.txt | grep $_code | wc -l )
		[ "$_wiki_index" -eq 0 ] && _wiki_index="NO" || _wiki_index="YES ("$_wiki_index")"
                if [ "$_wiki_file" -ne 0 ]
                then
                        _wiki_file=$( echo $_code | tr '[:upper:]' '[:lower:]' | sed -e 's/$/\.txt/' )
                        _wiki_version=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'  | awk -F\; '{ print $8 }' )
                        _wiki_verif=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $4 }' )
                        _wiki_opert=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $5 }' )
                else
                        _wiki_file="NO EXIST"
                        _wiki_version=""
                        _wiki_verif=""
                        _wiki_opert=""
                fi
                _proc_data=$_proc_data"\n"$_code";"$_file_des";"$_priority";"$_env_dev";"$_sensors";"$_wiki_file";"$_wiki_index";"$_wiki_version";"$_wiki_opert";"$_wiki_verif
        done

	_env_proc=$( echo "#2#" ; echo $_header_procedure_output ; echo -e $_proc_data | sort )
	echo -e "${_node_proc}" | column -s\; -t | sed -e '/^\#1\#/ i\
NODE MONITORING IA PROCEDURES' -e '/^CODE/ a\
' -e '/\#1\#/d'
	echo ""
	echo -e "${_env_proc}" | column -s\; -t | sed  -e '/^\#2\#/ i\
ENVIRONMENT MONITORING IA PROCEDURES' -e '/^NODE/ i\
' -e '/^CODE/ a\
' -e '/\#2\#/d'

}

mng_messages()
{	
	## INSERT DASHBOARD MESSAGES ##

	case "$_par_msg" in
	[0-9]*)
		_msg_exit=$( awk -F\; -v _test="$_par_msg" '$1 == "INFO" && $2 == _test { print $0 }' $_sensors_sot )
		if [ ! -z $_msg_exit ] 
		then
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i "/INFO;$_par_msg;.*/d" $_sensors_sot 
				echo $_msg_exit | column -s\; -t 
				echo "MESSAGE REMOVED"
			else
				echo $_msg_exit | column -s\; -t
				echo "MESSAGE WILL BE REMOVE IF USE -c OPTION"
			fi	
		else
			echo "MESSAGE DON'T EXIT"
		fi
	;;	
	death)
		_date_death=$( date +%s )

		for _old_messages in $( awk -F\; -v _date="$_date_death" '$1 == "INFO" && $4 < _date { print $2 }' $_sensors_sot )
		do
			sed -i "/INFO;$_old_messages;.*/d" $_sensors_sot
			echo "REMOVE MSG: "$_old_messages
		done
	;;
	list)
		_date_death=$( date +%s )
		_msg_list=$( awk -F\; -v _date="$_date_death" 'BEGIN { OFS=";" } $1 == "INFO" && $0 !~ "#" && $0 != "^$"  { if ( $4 < _date ) { $4="DEATH" } else {$4=strftime("%d-%m-%Y %H:%M:%S",$4)} if ( $5 > 99 ) { $5="info" } else if ( $5 > 59 ) { $5="low" } else if ( $5 > 9 ) { $5="medium" } else if ( $5 > 0 ) { $5="high" } if ( $7 == 1 ) { $7="YES" } else { $7="NO" } { $3=strftime("%d-%m-%Y %H:%M:%S",$3)  ; print $0 }}' $_sensors_sot )
		echo -e "TYPE;ID;BIRTH;ALIVE;PRIORITY;MESSAGE;MAIL SENT\n${_msg_list}" | column -s\; -t
	;;
	*)
		[ -z "$_par_date" ] && _par_date=$( date +%s 2>/dev/null | awk -v _dtl="$_def_msg_timelive" '{ _date=( $1 + _dtl ) ; print strftime("%Y%m%d %H%M",_date) }' )  
		[ -z "$_par_priority" ] && _par_priority="100"
		[ "$_opt_mail" == "yes" ] && _mail_send=0 || _mail_send=2

		_par_date=$( date -d "$_par_date" +%s )
		_code=$( awk -F\; 'BEGIN { _max="0" } $1 == "INFO" { if ( $2 > _max ) { _max=$2 } } END { print _max }' $_sensors_sot )

		[ "$_code" == "0" ] && _code="1" || let "_code++"

		echo "INFO;"$_code";"$( date +%s )";"$_par_date";"$_par_priority";"$_par_msg";"$_mail_send >> $_sensors_sot

		#[ "$_audit_status" == "ENABLED" ] && [ -z "$_host_node" ] && $_script_path/audit.nod.sh -i bitacora -m "MSG : $_par_msg" -s info -e info
	;;
	esac
}

mng_cyclops()
{
	## CYCLOPS MAINTENANCE TASK ##

	if [ "$_opt_cyclops" == "yes" ]
	then
		case "$_par_cyclops" in
		config)
			echo "WARNING!" 
			echo "We Working on it, but is to big for finish quickly"
			echo 
			config_cyclops
		;;	
		recount)
			if [ "$_opt_changes" == "yes" ]
			then
				echo "Reset CYCLOPS cycle count"
				mng_cyclops_recount
			else
				echo "Cyclops Count Reset:"
				sed -e 's/\(^CYC;0001;\)[0-9]*\(;.*\)/\10\2/' $_sensors_sot | grep "CYC;0001" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		enable)
			if [ "$_opt_changes" == "yes" ]
			then
				_par_msg="Cyclops Monitoring System Enabled"
				audit_cyclops_actions

				sed -i -e '/^ALERT/d' $_sensors_sot
				sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1ENABLED/' $_sensors_sot
				mng_cyclops_recount
				echo "Cyclops cycle count reset"
				echo "Cyclops Monitoring System Enabled at $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0001 : enable cyclops"
			else
				echo "This Alerts will be remove if you apply changes"
				grep "^ALERT" $_sensors_sot | column -s\; -t
				echo "Cyclops Mode Changes:"
				sed -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1ENABLED/' $_sensors_sot | grep "CYC;0001" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		disable)

                        if [ "$_opt_changes" == "yes" ]
                        then
				_par_priority="5"
				audit_cyclops_actions

                                sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1DISABLED/' $_sensors_sot
                                echo "Cyclops cycle count reset"
                                echo "Cyclops Monitoring System Disable at $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0001 : disable cyclops"
                        else
				echo "Cyclops Mode Changes:"
                                sed -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1DISABLED/' $_sensors_sot | grep "CYC;0001" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
		;;
		drain)

                        if [ "$_opt_changes" == "yes" ]
                        then

				_par_priority="80"
				audit_cyclops_actions

                                sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1DRAIN/' $_sensors_sot
                                echo "Cyclops cycle count reset"
                                echo "Cyclops Monitoring System Change to DRAIN at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0001 : change status cyclops to $_par_cyclops"
                        else
				echo "Cyclops Mode Changes:"
                                sed -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1DRAIN/' $_sensors_sot | grep "CYC;0001" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
		;;
		testing)

                        if [ "$_opt_changes" == "yes" ]
                        then
				_par_priority="80"
				audit_cyclops_actions

                                sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1TESTING/' $_sensors_sot
                                echo "Cyclops cycle count reset"
                                echo "Cyclops Monitoring System Change to TESTING at $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s ALERT -n cyclops -m "$( logname ) : CYC0001 : change status cyclops to $_par_cyclops"
                        else
				echo "Cyclops Mode Changes:"
                                sed -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1TESTING/' $_sensors_sot | grep "CYC;0001" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
		;;
                intervention)


                        if [ "$_opt_changes" == "yes" ]
                        then
				_par_priority="30"
				audit_cyclops_actions

                                sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1INTERVENTION/' $_sensors_sot
                                echo "Cyclops cycle count reset"
                                echo "Cyclops Monitoring System Change to INTERVENTION at $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s ALERT -n cyclops -m "$( logname ) : CYC0001 : change status cyclops to $_par_cyclops"
                        else
                                echo "Cyclops Mode Changes:"
                                sed -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1INTERVENTION/' $_sensors_sot | grep "CYC;0001" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
                ;;
		repair)

			if [ "$_opt_changes" == "yes" ]
                        then
				_par_priority="30"
				audit_cyclops_actions

                                sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1REPAIRING/' $_sensors_sot
                                echo "Cyclops cycle count reset"
                                echo "Cyclops Monitoring System Change to REPAIRING at $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s ALERT -n cyclops -m "$( logname ) : CYC0001 : change status cyclops to $_par_cyclops"
                        else
                                echo "Cyclops Mode Changes:"
                                sed -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1REPAIRING/' $_sensors_sot | grep "CYC;0001" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
		;;
		status)
			$_script_path/cyc.status.sh -a cyclops 

			echo -e $_sh_color_bolt"Cyclops Modules Cron Active"$_sh_color_nformat
			echo "-----------------------------------"
			[ "$( whoami )" == "root" ] && crontab -l | awk 'BEGIN { print "module/script;time frecuency" } $6 ~ /cyclops/ { split ($6,a,"/") ; print a[5]";"$2":"$1 }' | column -s\; -t | awk 'NR == "2" { print "" } { print $0 }' || echo "WARN: Needs to be root to see this information" 

			_cyc_status_alert=$( cat $_sensors_sot | grep ^ALERT | cut -d';' -f2- )
			
			$_script_path/cyc.status.sh -a critical
			
			echo
			echo -e $_sh_color_bolt"Node Monitoring Status"$_sh_color_nformat
			echo "-----------------------------------"

			awk -F\; -v _cb="$_sh_color_bolt" -v _cg="$_sh_color_green" -v _cy="$_sh_color_yellow" -v _ca="$_sh_color_gray" -v _nf="$_sh_color_nformat" '
			$1 ~ "[0-9]+" { 
				status[$7]++ ; 
				_total++     ;
			 } END {
 				for ( i in status ) {
					if ( i ~ /up/ ) { _f1c=_cg }
					if ( i ~ /diagnose|link|unlink|repair/ ) { _f1c=_cy }
					if ( i ~ /drain/ ) { _f1c=_ca }
					if ( i ~ /content/ ) { _f1c=_cr }
					printf "%s%-12s%s: %s\n", _f1c, toupper(i), _nf, status[i] ;
				}
				printf "\n%sTOTAL NODES%s : %s\n", _cb, _nf, _total ;
			}' $_type
			
			echo

			echo "Registered Alerts:"
			echo "-----------------------------------"

			if [ -z "$_cyc_status_alert" ]
			then
				echo "No Registered Alerts"
			else
				_cyc_status_alert=$( echo "${_cyc_status_alert}" | awk -F";" 'BEGIN { OFS=";" } { $5=strftime("%d-%m-%Y;%H:%M:%S",$5) ; print $0 }' )

				echo -e ";Type;id;node/dev;sensor;date;time;email state\n${_cyc_status_alert}" | column -s\; -t 
			fi

			echo
		;;
		wstatus)
			echo "|< 100% 40% 35% 25%>|" 
			echo "|  $_color_title {{ :wiki:cyclops_title.png?nolink |}}  |  $( awk -F\; -v _co="$_color_ok" -v _cf="$_color_fail" '$1 == "CYC" && $2 == "0001" { if ( $4 == "ENABLED" ) { _cstatus=_co } else { _cstatus=_cf } ; print _cstatus" "$4}' $_sensors_sot )  ||"
			echo "|  $_color_title ** CRITICAL OPERATIVE ENVIRONMENT **  |  $( $_tool_path/approved/test.productive.env.sh -t pasive -v simple | awk -F\; -v _co="$_color_ok" -v _cf="$_color_fail" '{ if ( $NF == "OPERATIVE" ) { print _co" "$NF } else { print _cf" "$NF }}' )  ||" 
			echo "|  $_color_title ** NODE STATUS **  |  $_color_header Status  |  $_color_header Total  |"
			cat $_type | awk -F\; -v _co="$_color_ok" -v _cf="$_color_fail" -v _ch="$_color_header" 'BEGIN { _u=0 ; _d=0 ; _m=0 ; _r=0 ; _c=0 ; _t=0 } { _t++ } $NF == "up" { _u++ } $NF == "diagnose" { _d++ } $NF == "drain" { _m++ } $NF == "repair" { _r++ } $NF == "content" { _c++ } END { if ( _u != 0 ) { print "|:::|  UP  |  "_u"  |" } ; if ( _d != 0 ) { print "|:::|  DIAGNOSE  |  "_d"  |" } ; if ( _m != 0 ) { print "|:::|  MAINTENANCE  |  "_m"  |" }  ; if ( _r != 0 ) { print "|:::|  REPAIRING  |  "_r"  |" } ; if ( _c != 0 ) { print "|:::|  CONTENT  |  "_c"  |" } ; if ( _t == _u ) if ( _u == _t ) { _cstatus=_co } else { _cstatus=_cf } ; print "|  "_ch" TOTAL NODES  ||  "_cstatus" "_t"  |" }' 
		;;
		cron)
			mng_cyclops_cron
		;;
		mail)
                        if [ "$_opt_changes" == "yes" ]
                        then
                                sed -i -e 's/\(CYC;0004;MAIL;\)DISABLED/\1ENABLED/' $_sensors_sot
                                echo "Cyclops Monitoring System Enable eMail Alert System at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0004 : enable cyclops option $_par_cyclops"
                        else
                                echo "Cyclops eMail Option Changes:"
                                sed -e 's/\(CYC;0004;MAIL;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0004" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
		;;
		nomail)
                        if [ "$_opt_changes" == "yes" ]
                        then
                                sed -i -e 's/\(CYC;0004;MAIL;\)ENABLED/\1DISABLED/' $_sensors_sot
                                echo "Cyclops Monitoring System Disable eMail Alert System at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0004 : disable cyclops option $_par_cyclops"
                        else
                                echo "Cyclops eMail Option Changes:"
                                sed -e 's/\(CYC;0004;MAIL;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0004" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
		;;
		sound)
                        if [ "$_opt_changes" == "yes" ]
                        then
                                sed -i -e 's/\(CYC;0005;SOUND;\)DISABLED/\1ENABLED/' $_sensors_sot
                                echo "Cyclops Monitoring System Enable Sound Web Alert System at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0005 : enable cyclops option $_par_cyclops"
                        else
                                echo "Cyclops Sound Option Changes:"
                                sed -e 's/\(CYC;0005;SOUND;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0005" | column -s\; -t
                                echo "Use -c option to apply changes"
                                echo "Use -c option to apply changes"
                        fi
		;;
		nosound)
                        if [ "$_opt_changes" == "yes" ]
                        then
                                sed -i -e 's/\(CYC;0005;SOUND;\)ENABLED/\1DISABLED/' $_sensors_sot
                                echo "Cyclops Monitoring System Disable Sound Web Alert System at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0005 : disable cyclops option $_par_cyclops"
                        else
                                echo "Cyclops Sound Option Changes:"
                                sed -e 's/\(CYC;0005;SOUND;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0005" | column -s\; -t
                                echo "Use -c option to apply changes"
                        fi
		;;
		ha)
			if [ "$_cyclops_ha" == "ENABLED" ]
			then
				mng_cyclops_ha_show
			else
				if [ "$_opt_changes" == "yes" ]
				then
					sed -i -e 's/\(CYC;0006;HA;\)DISABLED/\1ENABLED/' $_sensors_sot
					echo "Cyclops Monitoring System Enable HA Mode $(date +%H:%M\ %Z)"
					$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0006 : enable cyclops option $_par_cyclops"
				else
					mng_cyclops_ha_show
				fi
			fi
		;;
		noha)
			if [ "$_cyclops_ha" == "ENABLED" ] 
			then
				if [ "$_opt_changes" == "yes" ]
				then
					sed -i -e 's/\(CYC;0006;HA;\)ENABLED/\1DISABLED/' $_sensors_sot
					echo "Cyclops Monitoring System Disable HA Mode $(date +%H:%M\ %Z)"	
					$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0006 : disable cyclops option $_par_cyclops"
				else
					mng_cyclops_ha_show
				fi
			else
				mng_cyclops_ha_show
			fi
		;;
		audit)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0003;AUDIT;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Audit Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0003 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Audit Module Option Changes:"
				sed -e 's/\(CYC;0003;AUDIT;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0003" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		noaudit)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0003;AUDIT;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Audit Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0003 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Audit Module Option Changes:"
				sed -e 's/\(CYC;0003;AUDIT;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0003" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		screen)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0008;SCREENCTRL;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Screen Control Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0008 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Screen Control Module Option Changes:"
				sed -e 's/\(CYC;0008;SCREENCTRL;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0008" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		noscreen)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0008;SCREENCTRL;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Screen Control Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0008 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Screen Control Module Option Changes:"
				sed -e 's/\(CYC;0008;SCREENCTRL;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0008" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		well)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0009;WELCOMESYS;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Wellcome System Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0009 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Wellcome System Module Option Changes:"
				sed -e 's/\(CYC;0009;WELCOMESYS;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0009" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		nowell)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0009;WELCOMESYS;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Wellcome System Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0009 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Wellcome System Module Option Changes:"
				sed -e 's/\(CYC;0009;WELCOMESYS;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0009" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		reactive)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0007;REACTIVE;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Host Control Reactive Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0007 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Reactive Host Control Module Option Changes:"
				sed -e 's/\(CYC;0007;REACTIVE;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0007" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		noreactive)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0007;REACTIVE;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Host Control Reactive Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0007 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Reactive System Module Option Changes:"
				sed -e 's/\(CYC;0007;REACTIVE;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0007" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		razor)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0014;RAZOR;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Host Control Razor Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0014 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Razor System Module Option Changes:"
				sed -e 's/\(CYC;0014;RAZOR;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0014" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		norazor)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0014;RAZOR;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Host Control Razor Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0014 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Razor System Module Option Changes:"
				sed -e 's/\(CYC;0014;RAZOR;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0014" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		monsec)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0010;MON_SEC;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Security Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0010 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Security Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0010;MON_SEC;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0010" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		nomonsec)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0010;MON_SEC;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Security Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0010 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Security Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0010;MON_SEC;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0010" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		monsrv)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0011;MON_SRV;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Service Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0011 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Service Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0011;MON_SRV;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0011" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		nomonsrv)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0011;MON_SRV;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Service Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0011 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Service Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0011;MON_SRV;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0011" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		monnod)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0012;MON_NOD;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Nodes/Hosts Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0012 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Nodes/Hosts Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0012;MON_NOD;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0012" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		nomonnod)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0012;MON_NOD;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Nodes/Hosts Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0012 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Nodes/Hosts Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0012;MON_NOD;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0012" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		monenv)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0013;MON_ENV;\)DISABLED/\1ENABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Enable Environment Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s UP -n cyclops -m "$( logname ) : CYC0013 : enable cyclops option $_par_cyclops"
			else
				echo "Cyclops Environment Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0013;MON_ENV;\)DISABLED/\1ENABLED/' $_sensors_sot | grep "CYC;0013" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		nomonenv)
			if [ "$_opt_changes" == "yes" ]
			then
				sed -i -e 's/\(CYC;0013;MON_ENV;\)ENABLED/\1DISABLED/' $_sensors_sot
				echo "Cyclops Monitoring System Disable Environment Monitoring Module at  $(date +%H:%M\ %Z)"
				$_script_path/audit.nod.sh -i event -e status -s DOWN -n cyclops -m "$( logname ) : CYC0013 : disable cyclops option $_par_cyclops"
			else
				echo "Cyclops Environment Monitoring Module Option Changes:"
				sed -e 's/\(CYC;0013;MON_ENV;\)ENABLED/\1DISABLED/' $_sensors_sot | grep "CYC;0013" | column -s\; -t
				echo "Use -c option to apply changes"
			fi
		;;
		sum)
			mng_cyclops_sum
		;;
		pack)
			mng_cyclops_pkg
		;;
		devel)
			mng_cyclops_devel
		;;
		*)
			echo "CYCLOPS IS GREAT!!"
			echo "But now is to big to do now all options"
			echo "We working step by step"
			echo "WE?!, not we.... ME!! only one... ik!"
		;;
		esac
	fi
}

audit_cyclops_actions()
{
	[ -z "$_par_msg" ] && echo "Need a Reason for change to $_par_cyclops, please use -m parameter to include message" && exit 1
	[ "$_audit_status" == "ENABLED" ] && $_script_path/audit.nod.sh -i bitacora -m "$( echo -n "$_par_cyclops : " | tr [:lower:] [:upper:] ) $_par_msg : $( logname )" -s info -e $_par_cyclops
	_opt_mail="yes"
	mng_messages
}

mng_cyclops_ha_show()
{
	echo "HA CONFIG:"
	grep "^CYC;0006;HA" $_sensors_sot | cut -d';' -f4- | sed '1 i\HA status;Master Node' | column -s\; -t
	echo
	echo "ROLE STATUS:"

	for _ha_node in $( cat $_ha_cfg_file | grep ^"ND" | cut -d';' -f2 )
	do
		_ha_node_role_status=$( ssh -o ConnectTimeout=5 $_ha_node cat $_ha_role_file )

		[ "$_ha_node_role_status" != "MASTER" ] && [ "$_ha_node_role_status" != "SLAVE" ] && _ha_node_role_status="DOWN"
		[ "$_ha_node_role_status" != "DOWN" ] && _ha_node_role_time=$( ssh $_ha_node stat $_ha_role_file | grep "Modify:" | sed 's/Modify: //' )
		echo "$_ha_node -> $_ha_node_role_statuse( last role update at $( date -d"$_ha_node_role_time" ) )"
	done | column -t

	echo
	echo "HA SETTINGS:"
	cat $_ha_cfg_file | grep -v ^\# | sed '1 i\Type;Resource' | column -s\; -t
	echo
	echo "If you want to force node master ENABLE defined resources on SLAVE node"
}

mng_cyclops_recount()
{
	sed -i -e 's/\(^CYC;0001;\)[0-9]*\(;[A-Z]*\)/\10\2/' $_sensors_sot
}

mng_cyclops_cron()
{
	echo "Check cyclops cron jobs"

	crontab -l > $_cyclops_temp_path/cronjobs.txt
	_cron_status=$( grep monitor.sh $_cyclops_temp_path/cronjobs.txt | wc -l )

	if [ "$_cron_status" -ge 1 ]
	then
		if [ "$_opt_changes" == "yes" ]
		then
			sed -i '/cron/d' $_cyclops_temp_path/cronjobs.txt	
			_cron_changes=$( crontab $_cyclops_temp_path/cronjobs.txt 2>&1 >/dev/null ; echo $? )
                        [ "$_cron_changes" -eq 0 ] && echo "Cron Remove suscessfully" || echo "Cron update wit errors, check it manually"
		else
			echo "Cron cyclops config exist"
			echo
			echo $_cyclops_temp_path/cronjobs.txt
			echo
			echo "If you want to remove it use -c parameter"
		fi
	else
		if [ "$_opt_changes" == "yes" ]
		then
			echo "\*\/3 \* \* \* \* /opt/cyclops/scripts/monitoring.sh \-d 2>$_mon_log_path/monitor.err.log" >> $_cyclops_temp_path/cronjobs.txt
			_cron_changes=$( crontab $_cyclops_temp_path/cronjobs.txt 2>&1 >/dev/null ; echo $? )
			[ "$_cron_changes" -eq 0 ] && echo "Cron updated suscessfully" || echo "Cron update wit errors, check it manually"
		else
			echo '*/3 * * * * /opt/cyclops/scripts/monitoring.sh -d' >> $_cyclops_temp_path/cronjobs.txt
			echo "Cyclops Cron Changes:"
			echo
			cat $_cyclops_temp_path/cronjobs.txt
			echo
			echo "Use -c option to apply changes"
		fi
	fi
}

mng_cyclops_sum()
{

	[ "$_opt_changes" != "yes" ] && _cmd_output="CODE;PATH;COMMAND/FILE;VERSION;BIRTH;DESCRIPTION;PARENT;MASTER SUM;SLAVE SUM\n-----;------------;------------;------------;--------;------------;------;----------;---------\n"

	for _file in $( cat $_cyc_script_code_file | egrep -v "^#|^$")
	do
		_code_cmd=$( echo $_file | cut -d';' -f1 )
		_cmd_path=$( echo $_file | cut -d';' -f2 )
		_cmd_file=$( echo $_file | cut -d';' -f3 )
		_cmd_ver=$(  echo $_file | cut -d';' -f4 | awk -F\. '{ print $1"."$2" ("$3")" }' )
		_cmd_birth=$( echo $_file | cut -d';' -f5 )
		_cmd_des=$(  echo $_file | cut -d';' -f6 )
		_cmd_parent=$( echo $_file | cut -d';' -f7 )
		_storage_cmd_sum=$( echo $_file | cut -d';' -f8 )
		_sum_cmd_file=$_base_path"/"$_cmd_path"/"$_cmd_file
		
		[ -f "$_sum_cmd_file" ] && _real_cmd_sum=$( sha1sum $_sum_cmd_file | awk '{ print $1 }' ) || _real_cmd_sum=""	

		[ "$_cyclops_ha" == "ENABLED" ] && _ha_cmd_sum=$( ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $_ha_slave_host sha1sum $_sum_cmd_file 2>/dev/null | awk '{ print $1}' ) || _ha_cmd_sum="NA"

		if [ "$_opt_changes" == "yes" ]
		then
			if [ "$_storage_cmd_sum" != "$_real_cmd_sum" ] 
			then
				_cmd_ver=$( echo $_cmd_ver | awk -F\. 'BEGIN { _date=strftime("%Y%m%d") } { _ver=$2+1 } END { print $1"."_ver"."_date }' ) 
				_cmd_sum=$_real_cmd_sum 
			else
				_cmd_sum=$_storage_cmd_sum
			fi

			[ "$_cyclops_ha" == "ENABLED" ] && [ "$_storage_cmd_sum" != "$_ha_cmd_sum" ] && _ha_sum_sync_output=$_ha_sum_sync_output""$( scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no $_sum_cmd_file $_ha_slave_host:$_sum_cmd_file 2>&1 )
		else
			[ "$_storage_cmd_sum" == "$_real_cmd_sum" ] && _cmd_sum="OK" || _cmd_sum="FAIL"
			if [ "$_cyclops_ha" == "ENABLED" ]
			then
				[ "$_storage_cmd_sum" == "$_ha_cmd_sum" ] && _cmd_ha_sum="OK" || _cmd_ha_sum="FAIL" 
			else
				_cmd_ha_sum="NA"
			fi
		fi
			
		_cmd_output=$_cmd_output""$_code_cmd";"$_cmd_path";"$_cmd_file";"$_cmd_ver";"$_cmd_birth";"$_cmd_des";"$_cmd_parent";"$_cmd_sum";"$_cmd_ha_sum"\n"

	done

	if [ "$_opt_changes" == "yes" ] 
	then
		_cmd_output=$( cat $_cyc_script_code_file | grep ^\# ; echo -e "${_cmd_output}" | sed -e 's/\ (/\./' -e 's/)//' ) 
		echo -e "${_cmd_output}" > $_cyc_script_code_file 

		echo "Cyclops Management" 
		echo "Sum cyc files update"
		echo "File change : $_cyc_script_code_file"

		if [ "$_cyclops_ha" == "ENABLED" ]
		then
			echo "HA: $_cyclops_ha : $_ha_slave_host"
			[ -z "$_ha_sum_sync_output" ] && echo "	No HA slave files sync" || echo -e "HA Slave Sync files:\n${_ha_sum_sync_output}\n"
		fi
			
		echo 
		$_script_path/audit.nod.sh -i event -e status -s SEAL -n cyclops -m "$( logname ) : CYC0001 : cyclops seal all file sums"
	else
		echo
		echo "Cyclops Management"
		echo "Sum cyc files Status"
		echo "Cyclops Base Path: $_base_path"
		echo
		echo -e "${_cmd_output}" | column -s\; -t 
		echo
		echo "If you want to update sum files file use -c"
		echo "WARN: Only use -c if you have problem with ha sync or you are cyc dev guy"
		echo
	fi

}

mng_cyclops_pkg()
{
	# $_sensors_script_path ## sensors node packs
	# $_sensors_env_scripts ## sensors env pack
	# $_sensors_ia_path 	## Rules node pack
	# $_sensors_env_ia	## Rules env pack
	# $_cyc_clt_rzr_dat	## Razor packs

	## SENSORS NODE PACK 

	_action_pkg="check"
	_msg_pkg="NODE SENSORS PKG STATUS\nPackage Name;Status;Version;Action\n-------------;------;-------;------"

	for _dir in $( ls -d1 $_sensors_script_path/* )
	do
		_name_pkg=$( echo $_dir | awk -F\/ '{ print $NF }' )
		tar cvf $_cyclops_temp_path/sensors.node.$_name_pkg.pack.tar $_dir 2>/dev/null >/dev/null 

		_test_sum_pkg=$( sha1sum $_cyclops_temp_path/sensors.node.$_name_pkg.pack.tar 2>/dev/null | awk '{ print $1 }' )
		_org_sum_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKGN" && $3 == "sensors.node."_n".pack.tar" { print $8 }' $_cyc_script_code_file )
		_ver_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKGN" && $3 == "sensors.node."_n".pack.tar" { split($4,v,".") ; print v[1]"."v[2] }' $_cyc_script_code_file )
		[ "$_test_sum_pkg" == "$_org_sum_pkg" ] && _status_pkg="OK" || _status_pkg="FAIL"
		[ "$_opt_changes" == "yes" ] && [ "$_status_pkg" == "FAIL" ] && cp $_cyclops_temp_path"/sensors.node."$_name_pkg".pack.tar" $_sensors_pkg_dir/ && _action_pkg="packing new version"
	
		_msg_pkg=$_msg_pkg"\n$_name_pkg;$_status_pkg;$_ver_pkg;$_action_pkg"	
		_action_pkg="check"
	done 

	## NODE IA RULES PACK

	_msg_pkg=$_msg_pkg"; ;\n; ;\nNODE IA RULES PKG STATUS\nPackage Name;Status;Version;Action\n-------------;------;-------;------"

	tar cvf $_cyclops_temp_path/rules.node.pack.tar $_sensors_ia_path 2>/dev/null >/dev/null 

	_test_sum_pkg=$( sha1sum $_cyclops_temp_path/rules.node.pack.tar 2>/dev/null | awk '{ print $1 }' )
	_org_sum_pkg=$( awk -F\; '$1 ~ "PKG" && $3 == "rules.node.pack.tar" { print $8 }' $_cyc_script_code_file )
	_ver_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKG" && $3 == "rules.node.pack.tar" { split($4,v,".") ; print v[1]"."v[2] }' $_cyc_script_code_file )
	[ "$_test_sum_pkg" == "$_org_sum_pkg" ] && _status_pkg="OK" || _status_pkg="FAIL"
	[ "$_opt_changes" == "yes" ] && [ "$_status_pkg" == "FAIL" ] && cp $_cyclops_temp_path"/rules.node.pack.tar" $_sensors_pkg_dir/ && _action_pkg="packing new version"

	_msg_pkg=$_msg_pkg"\nnode ia rules;$_status_pkg;$_ver_pkg;$_action_pkg "	
	_action_pkg="check"

	## SENSORS ENV PACK

	_msg_pkg=$_msg_pkg"; ;\n; ;\nENV SENSORS PKG STATUS\nPackage Name;Status;Version;Action\n-------------;------;-------;------"

	tar cvf $_cyclops_temp_path/sensors.env.pack.tar $_sensors_env_scripts 2>/dev/null >/dev/null

	_test_sum_pkg=$( sha1sum $_cyclops_temp_path/sensors.env.pack.tar 2>/dev/null | awk '{ print $1 }' )
	_org_sum_pkg=$( awk -F\; '$1 ~ "PKG" && $3 == "sensors.env.pack.tar" { print $8 }' $_cyc_script_code_file )
	_ver_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKG" && $3 == "sensors.env.pack.tar" { split($4,v,".") ; print v[1]"."v[2] }' $_cyc_script_code_file )
	[ "$_test_sum_pkg" == "$_org_sum_pkg" ] && _status_pkg="OK" || _status_pkg="FAIL"
	[ "$_opt_changes" == "yes" ] && [ "$_status_pkg" == "FAIL" ] && cp $_cyclops_temp_path"/sensors.env.pack.tar" $_sensors_pkg_dir/ && _action_pkg="packing new version"

	_msg_pkg=$_msg_pkg"\nenv sensors;$_status_pkg;$_ver_pkg;$_action_pkg "	
	_action_pkg="check"

	## ENV IA RULES PACK

	_msg_pkg=$_msg_pkg"; ;\n; ;\nENV IA RULES PKG STATUS\nPackage Name;Status;Version;Action\n-------------;------;-------;------"

	tar cvf $_cyclops_temp_path/rules.env.pack.tar $_sensors_env_ia 2>/dev/null >/dev/null

	_test_sum_pkg=$( sha1sum $_cyclops_temp_path/rules.env.pack.tar 2>/dev/null | awk '{ print $1 }' )
	_org_sum_pkg=$( awk -F\; '$1 ~ "PKG" && $3 == "rules.env.pack.tar" { print $8 }' $_cyc_script_code_file )
	_ver_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKG" && $3 == "rules.env.pack.tar" { split($4,v,".") ; print v[1]"."v[2] }' $_cyc_script_code_file )
	[ "$_test_sum_pkg" == "$_org_sum_pkg" ] && _status_pkg="OK" || _status_pkg="FAIL"
	[ "$_opt_changes" == "yes" ] && [ "$_status_pkg" == "FAIL" ] && cp $_cyclops_temp_path"/rules.env.pack.tar" $_sensors_pkg_dir/ && _action_pkg="packing new version"

	_msg_pkg=$_msg_pkg"\nenv ia rules;$_status_pkg;$_ver_pkg;$_action_pkg "	
	_action_pkg="check"

	## RAZOR PACK

	_msg_pkg=$_msg_pkg"; ;\n; ;\nRAZOR PKG STATUS\nPackage Name;Status;Version;Action\n-------------;------;-------;------"
	
	for _dir in $( ls -d1 $_cyc_clt_rzr_dat/* )
	do
		_name_pkg=$( echo $_dir | awk -F\/ '{ print $NF }' )
		tar cvf $_cyclops_temp_path/razor.$_name_pkg.pack.tar $_dir 2>/dev/null >/dev/null

		_test_sum_pkg=$( sha1sum $_cyclops_temp_path/razor.$_name_pkg.pack.tar 2>/dev/null | awk '{ print $1 }' )
		_org_sum_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKG" && $3 == "razor."_n".pack.tar" { print $8 }' $_cyc_script_code_file )
		_ver_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKG" && $3 == "razor."_n".pack.tar" { split($4,v,".") ; print v[1]"."v[2] }' $_cyc_script_code_file )
		[ "$_test_sum_pkg" == "$_org_sum_pkg" ] && _status_pkg="OK" || _status_pkg="FAIL"
		[ "$_opt_changes" == "yes" ] && [ "$_status_pkg" == "FAIL" ] && cp $_cyclops_temp_path"/razor."$_name_pkg".pack.tar" $_sensors_pkg_dir/ && _action_pkg="packing new version"
	
		_msg_pkg=$_msg_pkg"\n$_name_pkg;$_status_pkg;$_ver_pkg;$_action_pkg "	
		_action_pkg="check"
	done 

	## AUDIT EXTRACTOR PACK

	_msg_pkg=$_msg_pkg"; ;\n; ;\nAUDIT EXTRACTOR PKG STATUS\nPackage Name;Status;Version;Action\n-------------;------;-------;------"

	for _dir in $( ls -d1 $_audit_scripts_path/* )
	do
		_name_pkg=$( echo $_dir | awk -F\/ '{ print $NF }' )
		tar cvf $_cyclops_temp_path/audit.$_name_pkg.pack.tar $_dir 2>/dev/null >/dev/null

		_test_sum_pkg=$( sha1sum $_cyclops_temp_path/audit.$_name_pkg.pack.tar 2>/dev/null | awk '{ print $1 }' )
		_org_sum_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKG" && $3 == "audit."_n".pack.tar" { print $8 }' $_cyc_script_code_file )
		_ver_pkg=$( awk -F\; -v _n="$_name_pkg" '$1 ~ "PKG" && $3 == "audit."_n".pack.tar" { split($4,v,".") ; print v[1]"."v[2] }' $_cyc_script_code_file )
		[ "$_test_sum_pkg" == "$_org_sum_pkg" ] && _status_pkg="OK" || _status_pkg="FAIL"
		[ "$_opt_changes" == "yes" ] && [ "$_status_pkg" == "FAIL" ] && cp $_cyclops_temp_path"/audit."$_name_pkg".pack.tar" $_sensors_pkg_dir/ && _action_pkg="packing new version"
	
		_msg_pkg=$_msg_pkg"\n$_name_pkg;$_status_pkg;$_ver_pkg;$_action_pkg "	
		_action_pkg="check"
	done 


	echo
	echo -e "$_msg_pkg" | column -t -s\; 
	echo -e "\n\n"

#	[ "$_opt_changes" == "yes" ] && echo "APPLY CHANGES IN CYCLOPS GLOBAL SUIT" && mng_cyclops_sum
}

mng_cyclops_devel()
{
	echo
	awk -F\; -v _cg="$_sh_color_green" -v _nf="$_sh_color_nformat" -v _bc="$_sh_color_bolt" '
		BEGIN { 
			_bot=99999999 ; 
			_eot=0 
			_date=strftime("%Y%m%d", systime())
		} $0 !~ "#" { 
			gr[$3]=$1 ; 
			split($4,de,".") ; 
			beg[$3]=$5 ; 
			end[$3]=de[3] ; 
			ver[$3]=sprintf("mk. %3.3s", de[2])
			if ( _bot >= $5 ) { _bot=$5 } ; 
			if ( _eot <= de[3] ) { _eot=de[3] }  
		} END { 
			_ym=int((_eot-_bot)/10000) ; 
			_yb=gensub(/^(....)....$/,"\\1","g",_bot) ; 
			for ( c=_yb;c<=_yb+_ym+1;c++ ) { 
				_cap=_cap""sprintf("%4.4s%s%4.4s%s%4.4s|", " ", _bc, c, _nf, " ") 
				_sepia=_sepia""sprintf("%s", " ----------- ")
				_sep=_sep"------------"
			}
			printf "00AA%s%-6.6s%s %s%-30.30s%s | %s%-8.8s%s %s%-8.8s%s |%s %s%8.8s%s |\n", _bc, "CODE", _nf, _bc, "FILE", _nf, _bc, "BIRTH", _nf, _bc, "CHANGE", _nf, _cap, _bc, "VERSION", _nf
			printf "00AB%6.6s %30.30s   %8.8s %8.8s %s  %8.8s \n", _sep, _sep, _sep, _sep, _sepia, _sep 
			for ( i in gr ) { 
				_fpb="" ; _fcn=""
				for(y=_yb;y<=_yb+_ym+1;y++) { 
					_line=_line"|" ; 
					for (m=10000001;m<=10000012;m++) { 
						_dpb=((y*100+m)-10000000)*100+31 ; 
						_dps=((y*100+m)-10000000)*100+1 ; 
						if ( beg[i] <= _dpb && end[i] >= _dps ) { 
							_line=_line">" 
							if ( _date >= _dps && _date < _dpb ) { _fpb=_cg ; _fcn=_bc }
						} else {
							_line=_line" " 
						}
					}
				} 
				printf "%s%6.6s%s %s%-30.30s%s | %8.8s %8.8s %s%s%s| %s%8.8s%s |\n", _bc, gr[i], _nf, _fcn, i, _nc, beg[i], end[i], _fpb, _line, _nf , _fcn, ver[i], _nf ;  
				_line=""   
			}   
		}' /etc/cyclops/system/script.code.cfg | sort | sed -e 's/^00AA//' -e 's/^00AB//' 
		echo
}

config_cyclops()
{
	echo "Cyclops configure tool"
	echo "----------------------"
	echo

	_cfg_main_system_help=$( 
		echo "0.Main System Settings"
		echo "	01. Apache/WebServer Settings "
		echo "	02. Mail Settings "
		echo "	NA. HA Management"
		echo "	NA. Web Interface Colors"
		echo 
	)

	_cfg_node_mod_help=$(
		echo "1. Node Monitor Module"
		echo "	11. Nodes definition"
		echo "	12. ILO/BMC Credentials"
		echo "	13. Family Sensors assignament" 
		echo "	NA. IA Rules definition"
		echo "	NA. Procedure Management"
		echo "	NA. Critical Environment Management"
		echo "	19. Monitoring Options"
		echo 
	)

	_cfg_env_mod_help=$(
		echo "2. Environment Monitor Module"
		echo "	NA. Environment definition"
		echo "	NA. Family Sensors assignament"
		echo "	NA. IA Rules definition"
		echo "	NA. Procedure Management"
		echo "	NA. Monitoring Options"
		echo
	)

	_cfg_sec_mod_help=$(
		echo "3. Security Module"
		echo "	NA. Users Nodes Definition"
		echo "	NA. Monitoring Options"
		echo
	)

	_cfg_srv_mod_help=$( 
		echo "4. Service Module"
		echo "	NA. Slurm Monitoring Management"
		echo "	NA. Monitoring Options" 
		echo 
	)
	_cfg_sta_mod_help=$(
		echo "5. Statistics Module"
		echo "	NA. FACTORING"
	)
	
	_cfg_aud_mod_help=$(
		echo "6. Audit Module"
		echo "	NA. FACTORING"
	)

	_cfg_tools_help=$(
		echo "9. Tools Configs"
		echo 
	)

	echo -e "${_cfg_main_system_help}\n${_cfg_node_mod_help}\n${_cfg_env_mod_help}\n${_cfg_sec_mod_help}\n${_cfg_srv_mod_help}\n${_cfg_sta_mod_help}\n${_cfg_tools_help}\n"

	while [ "$_ask_global_cfg" != "[0-9]" ] || [ "$_ask_global_cfg" == "help" ]
	do

		echo -n "choose Option (help|end): "
		read _ask_global_cfg
		 
		case "$_ask_global_cfg" in
			0)
				echo "${_cfg_main_system_help}"
			;;
			1)
				echo "${_cfg_node_mod_help}"
			;;
			2) 
				echo "${_cfg_env_mod_help}"
			;;
			3)	
				echo "${_cfg_sec_mod_help}"
			;;
			4)
				echo "${_cfg_srv_mod_help}"
			;;
			5)
				echo "${_cfg_tools_help}"
			;;
			01)
				config_web_srv
			;;
			02)
				config_mail_opts
			;;
			11)
				config_nodes
			;;
			12)
				config_nod_bmc_cred
			;;
			13)
				config_node_sensors
			;;
			19)
				echo "You choose option $_ask_global_cfg "
				config_nod_mon
			;;
			NA)
				echo "FACTORING: Still working on it" 
			;;
			"help")
				echo -e "${_cfg_main_system_help}\n${_cfg_node_mod_help}\n${_cfg_env_mod_help}\n${_cfg_sec_mod_help}\n${_cfg_srv_mod_help}\n${_cfg_tools_help}\n"
			;;
			"end"|"exit"|"quit"|"bye")
				echo 
				echo "	Bye, Bye and Have a nice day"
				echo
				exit 0
			;;
			"*")
				echo "ERR: This option not implemented"
			;;
		esac

	done
}

config_web_srv()
{
	unset _ask_web_srv

	echo "Main System Settings"
	echo "--> Configuring Web Server Credentials"
	echo

	source $_config_path_sys/wiki.cfg 

	echo "Actually Config:"
	echo "	User:  "$_apache_usr
	echo "	Group: "$_apache_grp
	echo
	echo "( Leave blank for no change )"

	while [ "$_ask_web_srv" != "y" ] && [ "$_ask_web_srv" != "exit" ] || [ "$_ask_web_srv" == "help" ]
	do
		echo -n " Web User Owner : "
		read _ask_web_srv_usr
		echo -n " Web Group Owner : "
		read _ask_web_srv_grp

		echo -n "Values are ok (y/n/exit) : "
		read _ask_web_srv
	done

	if [ "$_ask_web_srv" == "y" ]
	then
		[ ! -z "$_ask_web_srv_usr" ] && sed -i -e "s/\(_apache_usr=\).*/\1$_ask_web_srv_usr/" $_config_path_sys/wiki.cfg
		[ ! -z "$_ask_web_srv_grp" ] && sed -i -e "s/\(_apache_grp=\).*/\1$_ask_web_srv_grp/" $_config_path_sys/wiki.cfg

		source $_config_path_sys/wiki.cfg

		echo "Changes Write: "
		echo "  User:  "$_apache_usr
		echo "  Group: "$_apache_grp
		echo
	else
		echo
		echo "No changes Made"
		echo
	fi

}

config_mail_opts()
{
	unset _ask_mail_opts

	echo
	echo "Main System Settings"
	echo "--> Configuring Cyclops Mail Options"
	
	if [ -f "$_alert_mail_cfg_file" ]
	then
		source $_alert_mail_cfg_file
	else
		if [ -f "$_alert_mail_cfg_file.template" ]
		then
			cp -p $_alert_mail_cfg_file.template $_alert_mail_cfg_file
			source $_alert_mail_cfg_file
		else
			echo "ERR: NO MAIL CFG TEMPLATE NEITHER CFG FILE"
			exit 1
		fi
	fi

	[ ! -z "$_email_alert_addr" ] && _cfg_mail_list=$( echo $_email_alert_addr | tr ',' '\n' | awk '{ print "\t"NR"."$0 }' ) || _cfg_mail_list="" 

	echo
	echo "	Actually Config:"
	echo
	echo "	Mail Subject: $_email_alert_subject"
	echo "	SMTP Server: $_email_alert_smtp_ip"
	echo "	SMTP TCP Port: $_email_alert_smtp_port"
	echo "	Addresses: " 
	echo "${_cfg_mail_list}" | awk '{ print "\t"$0 }'
	echo
	echo "( Leave field in blank for no change )"

	while [ "$_ask_mail_opts" != "y" ] && [ "$_ask_mail_opts" != "exit" ]
	do
		echo -n "Mail Subject : "
		read _ask_mail_opts_sub

		[ "$_ask_mail_opts_sub" == "exit" ] && break		

		echo -n "SMTP server : "
		read _ask_mail_opts_smtp

		[ "$_ask_mail_opts_smtp" == "exit" ] && break

		echo -n "SMTP port : "
		read _ask_mail_opts_port

		[ "$_ask_mail_opts_port" == "exit" ] && break

		echo -n "Put mail number for delete address and put new address all of them comma separated : "
		read _ask_mail_opts_addr

		[ "$_ask_mail_opts_addr" == "exit" ] && break

		echo
		echo -n "Values are ok? (y/n/exit) : "
		read _ask_mail_opts
	done

	if [ "$_ask_mail_opts" == "y" ]
	then
		echo "Writing Changes: "

		[ ! -z "$_ask_mail_opts_sub" ] && sed -i -e "s/\(_email_alert_subject=\).*/\1\"$_ask_mail_opts_sub\"/" $_alert_mail_cfg_file && echo "Mail Subject : "$_ask_mail_opts_sub
		[ ! -z "$_ask_mail_opts_smtp" ] && sed -i -e "s/\(_email_alert_smtp_ip=\).*/\1\"$_ask_mail_opts_smtp\"/" $_alert_mail_cfg_file && echo "SMTP Server : "$_ask_mail_opts_smtp
		[ ! -z "$_ask_mail_opts_port" ] && sed -i -e "s/\(_email_alert_smtp_port=\).*/\1\"$_ask_mail_opts_port\"/" $_alert_mail_cfg_file && echo "SMPT TCP Port: "$_ask_mail_opts_port

		if [ ! -z "$_ask_mail_opts_addr" ] 
		then
			_chg_mail_addr=$( echo "${_cfg_mail_list}" | sed -e 's/^\t//' -e 's/\./\·/' | awk -F\· -v _ch="$_ask_mail_opts_addr" 'BEGIN { split(_ch,c,",") } { for ( i in c ) { if ( $1 == c[i] ) { _del="1" }} ; if ( _del != "1" ) { print $2 } ; _del="0" } END { for ( i in c ) { if ( c[i] !~ /^[0-9]*$/ ) { print c[i] }}}' | tr '\n' ',' | sed -e 's/,$//' -e 's/^,//' )
			sed -i -e "s/\(_email_alert_addr=\).*/\1\"$_chg_mail_addr\"/" $_alert_mail_cfg_file
			echo "Addresses: "
			echo "${_chg_mail_addr}" | sed -e 's/·/\./' | tr ',' '\n' | awk '{ print "\t"NR"."$0 }'
			echo
		fi
	else
		echo
		echo "No changes Made"
		echo
	fi
}

config_nodes()
{

	echo
	echo "Node Monitor Module"
	echo "--> Nodes Definition"
	echo

	unset _ask_cfg

	while [ "$_ask_cfg" != "y" ] && [ "$_ask_cfg" != "exit" ] 
	do

		unset _cfg_type
		unset _cfg_nodes
		unset _cfg_power
		unset _cfg_os
		unset _cfg_group
		unset _cfg_family

		while [ "$_cfg_type" != "group" ] && [ "$_cfg_type" != "family" ]
		do
			echo -n "Select config group of nodes or family of nodes (group|family|help) : "
			read _cfg_type

			_cfg_type=$( echo "$_cfg_type" | tr [:upper:] [:lower:] )

			if [ "$_cfg_type" == "help" ]
			then
				echo
				echo "	group: organizative group of nodes, like servers, operational, or different types of compute arrange of nodes"
				echo "	family: A type of nodes, with same os/hardware and other settings to assign stocks of sensors"
				echo

				_cfg_avail_nod_grp=$( cat $_type 2>/dev/null | grep -v "^#" | cut -d';' -f4 | sed '/^$/d' | sort -u )
				[ -z "$_cfg_avail_nod_grp" ] && _cfg_avail_nod_grp="none"
				_cfg_avail_mon_grp=$( cat $_mon_cfg_file 2>/dev/null | awk -F\; '$1 == "NOD" { print $5 }' | sort -u ) 
				[ -z "$_cfg_avail_mon_grp" ] && _cfg_avail_mon_grp="none"
				_cfg_avail_nod_fam=$( cat $_type 2>/dev/null | grep -v "^#" | cut -d';' -f3 | sed '/^$/d' | sort -u )
				[ -z "$_cfg_avail_nod_fam" ] && _cfg_avail_nod_fam="none"
				_cfg_avail_sens_fam=$( ls -1 $_config_path_nod/*.mon.cfg | awk -F\/ '{ print $NF }'  | sed 's/\.mon\.cfg$//' | sort -u ) 
				[ -z "$_cfg_avail_sens_fam" ] && _cfg_avail_mon_fam="none"

				paste <(echo -e "Node Assigned Groups\n--------------------\n$_cfg_avail_nod_grp") <(echo -e "Monitor Assigned Node Groups\n---------------------------\n$_cfg_avail_mon_grp") --delimiters ';' | sed 's/^\;/\ \;/' | column -s\; -t | awk '{ print "\t"$0 }'
				echo
				paste <(echo -e "Node Assigned Families\n--------------------\n$_cfg_avail_nod_fam") <(echo -e "Available Sensors Node Families\n---------------------------\n$_cfg_avail_sens_fam") --delimiters ';' | sed 's/^\;/\ \;/' | column -s\; -t | awk '{ print "\t"$0 }'
				echo
			fi
		done

		_cfg_avail_nod=$( cat $_type | awk -F\; '$0 !~ "#" { print $2 }' |  sort | tr '\n' ' ' )
		[ -z "$_cfg_avail_nod" ] && _cfg_avail_nod="none" || _cfg_avail_nod=$( node_group $_cfg_avail_nod ) 

		echo
		echo "	Existing Nodes"
		echo "	--------------"
		echo "	$_cfg_avail_nod"
		echo 

		case "$_cfg_type" in
			group)

				_cfg_nod_grp=$( cat $_type | awk -F\; '$0 !~ "#" { if ( $4 == "" ) { $4="<<unassigned>>" } ; n[$4]=n[$4]" "$2 } END { for ( i in n ) { print i";"n[i] }}' )  
				for _cfg_nod_grp_line in $( echo "${_cfg_nod_grp}" )
				do
					_cfg_nod_grp_name=$( echo $_cfg_nod_grp_line | cut -d';' -f1 )
					_cfg_nod_grp_item=$( echo $_cfg_nod_grp_line | cut -d';' -f2 )
					_cfg_nod_grp_range=$( node_group $_cfg_nod_grp_item )

					_cfg_nod_grp_output=$_cfg_nod_grp_output""$_cfg_nod_grp_name";"$_cfg_nod_grp_range"\n"
				done

				_cfg_nod_grp_output=$( echo -e "${_cfg_nod_grp_output}" | sort )

				echo "	Existing Nodes By Group"
				echo -e "Group;Node Range\n------;------\n${_cfg_nod_grp_output}" | column -s\; -t | awk '{ print "\t"$0 }' 
				echo

			;;
			family)
				_cfg_nod_fam=$( cat $_type | awk -F\; '$0 !~ "#" { if ( $3 == "" ) { $3="<<unassigned>>" } ; n[$3]=n[$3]" "$2 } END { for ( i in n ) { print i";"n[i] }}' )  
				for _cfg_nod_fam_line in $( echo "${_cfg_nod_fam}" )
				do
					_cfg_nod_fam_name=$( echo $_cfg_nod_fam_line | cut -d';' -f1 )
					_cfg_nod_fam_item=$( echo $_cfg_nod_fam_line | cut -d';' -f2 )
					_cfg_nod_fam_range=$( node_group $_cfg_nod_fam_item )

					_cfg_nod_fam_output=$_cfg_nod_fam_output""$_cfg_nod_fam_name";"$_cfg_nod_fam_range"\n"
				done

				_cfg_nod_fam_output=$( echo -e "${_cfg_nod_fam_output}" | sort )

				echo "	Existing Nodes By Family"
				echo -e "Family;Node Range\n---------;------\n${_cfg_nod_fam_output}" | column -s\; -t | awk '{ print "\t"$0 }' 
				echo
			;;
		esac	


		while [ -z "$_cfg_nodes" ]
		do
			echo -n "Range of nodes to assign ($_cfg_type config) : "
			read _cfg_nodes
			#### CHECK NODES
		done

		while [ "$_cfg_power" != "ipmi" ] && [ "$_cfg_power" != "none" ]
		do
			echo -n "Select type of power management of $_cfg_nodes range (ipmi|none|help) : "
			read _cfg_power

			_cfg_power=$( echo "$_cfg_power" | tr [:upper:] [:lower:] )

			if [ "$_cfg_power" == "help" ]
			then
				echo "ipmi: ipmitool compatible nodes"
				echo "none: without bmc/ilo management"
			fi
		done

		while [ "$_cfg_os" != "$_real_avail_os" ] || [ -z "$_cfg_os" ]
		do
			echo -n "Select sensor stock type for nodes $_cfg_nodes (help for available os) : "
			read _cfg_os

			_avail_os=$( ls -1 $_sensors_script_path )

			if [ "$_cfg_os" == "help" ]
			then
				echo
				echo -e "Available Sensor Stocks\n------------------------\n${_avail_os}" | awk '{ print "\t"$0 }'
				echo
				echo "Will be do a description for list, but now i think is enough"
				echo
			fi

			_real_avail_os=$( echo "${_avail_os}" | grep -o $_cfg_os 2>/dev/null )
		done

		if [ "$_cfg_type" == "group" ]
		then
			while [ -z "$_cfg_group" ] || [ "$_cfg_group" == "help" ] 
			do
				echo -n "Define group name for monitoring (help for existing group list) : "
				read _cfg_group

				if [ "$_cfg_group" == "help" ]
				then
					_exits_group=$( cat $_type | grep -v "^#" |  cut -d';' -f4 | sort -u )
					echo 
					[ -z "$_exits_group" ] && echo "No group configurated" || echo -e "Available Groups\n------------------\n${_exits_group}" | awk '{ print "\t"$0 }'
					echo
					echo "Choose existing group if you want or put different name for new one"
				fi 
			done
		else
			while [ -z "$_cfg_family" ] || [ "$_cfg_family" == "help" ] 
			do
				echo -n "Define family name for assign list of sensors ( help for existings family list) : "
				read _cfg_family
		
				if [ "$_cfg_family" == "help" ]
				then
					_exits_family=$( cat $_type | grep -v "^#" | cut -d';' -f3 | sort -u )
					echo
					[ -z "$_exits_family" ] && echo "No family configurated" || echo -e "Available Families\n------------------\n${_exits_family}" | awk '{ print "\t"$0 }'
					echo
					echo "Choose existing family if you want or put different name for new one"
				fi
			done
		fi

		echo
		echo "	Type of Node configure : $_cfg_type"
		echo "	Name of $_cfg_type : "$( [ "$_cfg_type" == "group" ] && echo $_cfg_group || echo $_cfg_family )
		echo "	Range of nodes : $_cfg_nodes"
		echo "	Os type : $_cfg_os"
		echo
		echo -n "Are you ok with this settings (Y/N) : "
		read _ask_cfg

		_ask_cfg=$( echo "$_ask_cfg" | tr [:upper:] [:lower:] )

	done

	_cfg_range_nodes=$( node_ungroup $_cfg_nodes | tr ' ' '\n' )

	for _node in $( echo "${_cfg_range_nodes}" )
	do
		_check_changes=$( echo -e "$_cfg_list_actions" | sed '/^$/d' | tail -n 1 | cut -d';' -f2 )

		let "_node_code=_check_changes + 1"

		_cfg_list_actions=$_cfg_list_actions""$( cat $_type | awk -F\; -v _n="$_node" -v _g="$_cfg_group" -v _f="$_cfg_family" -v _o="$_cfg_os" -v _p="$_cfg_power" -v _nc="$_node_code" '
			BEGIN { _cc="N" }
			$0 ~ ";" { 
				if ( _n == $2 ) { 
					if ( $3 != _f && _f != "" ) { _fc=_f ; _cc="C" } else { _fc=$3 } ;  
					if ( $4 != _g && _g != "" ) { _gc=_g ; _cc="C" } else { _gc=$4 } ;
					if ( $5 != _o ) { _oc=_o ; _cc="C" } else { _oc=$5 } ;
					if ( $6 != _p ) { _pc=_p ; _cc="C" } else { _pc=$6 } ;
					if ( _cc == "C" ) { _sc="drain" } else { _sc=$7 } ; 
					print _cc";"$1";"_n";"_fc";"_gc";"_oc";"_pc";"_sc"\\n" ;
					
				}}
			END { if ( _cc == "N" ) { print _cc";"_nc";"_n";"_f";"_g";"_o";"_p";drain\\n" }
			}'
		)


	done

	echo
	echo "	List of changes" 
	echo -e "Action;Index;hostname;family;group;os;power mngt;mon status\n------------;------;--------;---------;------;--;-----------;----------\n${_cfg_list_actions}" | 
		awk -F\; 'BEGIN { 
			OFS=";" 
			} { 
			if ( $1 == "N" ) { 
				$1="Add New" 
				} ; 
			if ( $1 == "C" ) { 
				$1="Record Change" 
				} ; 
			for ( i=2 ; i <=NF ; i++ ) { 
				if ( $i == "" ) { $i="n/a" }
				} ; 
			print $0 
			}'  | 
			column -s\; -t | 
			awk '{ print "\t"$0 }' 
	echo
	
	echo -n "Do you want to make changes (y/n) : "
	read _ask_do

	_ask_do=$( echo $_ask_do | tr [:upper:] [:lower:] )

	if [ "$_ask_do" == "y" ] 
	then
		for _line in $( cat $_type  ) 
		do
			_node=$( echo $_line | cut -d';' -f2 )

			_chk_changes=$( echo -e "$_cfg_list_actions" | awk -F\; -v _n=$_node '$3 == _n && $1 == "C" { print $0 }' | cut -d';' -f2- )
			[ -z "$_chk_changes" ] && _output=$_output""$( echo $_line )"\n" || _output=$_output""$( echo $_chk_changes )"\n"
		done

		_output="${_output}\n"$( echo -e "$_cfg_list_actions" | grep "^N;" | cut -d';' -f2- )

		echo
		echo "Writing Chages..."
		echo -e "${_output}" | sed '/^$/d' > $_type

		echo
		echo "Checking Family Sensors Files..."
		
		if [ -f "$_config_path_nod/name.mon.cfg.template" ] 
		then
			echo "	Sensor Family Sensors File Template Exist" 
		else
			echo "	Cyclops needs a $_config_path_nod template, create it with several sensors and name name.mon.cfg.template"
			exit 1
		fi

		echo

		for _family in $( echo -e "${_output}" | sed -e '/^$/d' -e '/#/d' | cut -d';' -f3 | sort -u ) 
		do
			if [ -f "$_config_path_nod/$_family.mon.cfg" ]
			then
				echo "	OK	: $_family Has sensors file" 
			else
				echo "	WARN	: $_family Not has sensors file, creating one with template"
				cp -p $_config_path_nod/name.mon.cfg.template $_config_path_nod/$_family.mon.cfg
			fi
		done

		echo
		echo "All checks and test finish" 
	else
		echo "No changes write"
	fi
	
}

config_nod_bmc_cred()
{
	unset _ask_cfg_nod_bmc_cred

	_cfg_nod_bmc_tc_num=0
	_cfg_nod_bmc_ch_num=0
	_cfg_nod_bmc_add_num=0

	echo
	echo "Node Monitor Module"
	echo "--> ILO/BMC Credentials"
	echo

	_cfg_nod_bmc_list_def_w=$( cat $_type | awk -F\; '$6 != "none" && $0 !~ /^#/ { _n=_n" "$2 } END { print _n }' )
	_cfg_nod_bmc_list_def_n=$( cat $_type | awk -F\; '$6 == "none" { _n=_n" "$2 } END { print _n }' )

	[ ! -z "$_cfg_nod_bmc_list_def_w" ] && _cfg_nod_bmc_list_def_w=$( node_group $_cfg_nod_bmc_list_def_w )
	[ ! -z "$_cfg_nod_bmc_list_def_n" ] && _cfg_nod_bmc_list_def_n=$( node_group $_cfg_nod_bmc_list_def_n )

	echo "Existing Nodes: "
	echo "	With power definition ($( cat $_type | awk -F\; 'BEGIN { _n=0 } $6 != "none" && $0 !~ /^#/ { _n++ } END { print _n }' )) : $( [ -z "$_cfg_nod_bmc_list_def_w" ] && echo "none" || echo $_cfg_nod_bmc_list_def_w )"
	echo "	WithOut power definition ($( cat $_type | awk -F\; 'BEGIN { _n=0 } $6 == "none" { _n++ } END { print _n }' )) : $( [ -z "$_cfg_nod_bmc_list_def_n" ] && echo "none" || echo $_cfg_nod_bmc_list_def_n )"

	while [ "$_ask_cfg_nod_bmc_cred" != "y" ] && [ "$_ask_cfg_nod_bmc_cred" != "exit" ]
	do
		echo -n "Node Range to config : "
		read _ask_bmc_cred_nod_range
		echo -n "BMC/ILO Hostname prefix ( leave blank if hostname is the same bmcname ) : "
		read _ask_bmc_cred_bmc_prefix
		echo -n "BMC/ILO User : "
		read _ask_bmc_cred_bmc_usr
		echo -n "BMC/ILO Pass : "
		read _ask_bmc_cred_bmc_pass
		echo
		echo -n "Write Changes (y/n/exit) : "
		read _ask_cfg_nod_bmc_cred
	done	

	if [ "$_ask_cfg_nod_bmc_cred" == "y" ]
	then
		for _node in $( node_ungroup $_ask_bmc_cred_nod_range )
		do
			if [ ! -z "$_ask_bmc_cred_bmc_prefix" ] 
			then
				_node_suffix=$( echo $_node | sed 's/[a-z_-]*//' )
				_bmc=$_ask_bmc_cred_bmc_prefix""$_node_suffix
			fi

			let "_cfg_nod_bmc_tc_num++"
		
			_cfg_nod_check="0"
			_cfg_nod_check=$( awk -F\; -v _n="$_node" '{ if ( _n == $1 ) { print "1" }}' $_bios_mng_cfg_file )

			if [ "$_cfg_nod_check" == "1" ] 
			then
				sed -i -e "s/$_node;.*/$_node;$_bmc;$_ask_bmc_cred_bmc_usr;$_ask_bmc_cred_bmc_pass/" $_bios_mng_cfg_file 
				let "_cfg_nod_bmc_ch_num++"
			else
				echo "$_node;$_bmc;$_ask_bmc_cred_bmc_usr;$_ask_bmc_cred_bmc_pass" >> $_bios_mng_cfg_file 
				let "_cfg_nod_bmc_add_num++"
			fi
		done

		echo
		echo "Writing Changes"
		echo "	Modified Nodes: "$_cfg_nod_bmc_ch_num
		echo "	Adding new Nodes: "$_cfg_nod_bmc_add_num
		echo "	Total Writing: "$_cfg_nod_bmc_tc_num
		echo
	else
		echo
		echo "No Changes Made"
		echo
	fi

}

config_node_sensors()
{
	unset _ask_cfg_nod_sensors

	echo
	echo "Node Monitor Module"
	echo "--> Family Sensors assignament"

	while [ "$_ask_cfg_nod_sensors" != "y" ] && [ "$_ask_cfg_nod_sensors" != "exit" ] || [ "$_ask_cfg_nod_sensors" == "help" ]
	do
		unset _ask_cfg_nod_sens_fam

		while [ -z "$_ask_cfg_nod_sens_fam" ]
		do
			echo
			echo "Available Families Sensors Definitions : "
			echo "( For new one write new name )"

			_cfg_nod_sens_fam_avail=$( ls -1 $_config_path_nod | grep "mon\.cfg$" | sed 's/\.mon\.cfg$//' )
			[ -z "$_cfg_nod_sens_fam_avail" ] && echo -e "\n	Any Available Family Sensors, create new one\n" || echo -e "\n${_cfg_nod_sens_fam_avail}\n" | sed 's/^/\t/' 

			echo -n "Family Name: "
			read _ask_cfg_nod_sens_fam
		done

		if [ -f "$_config_path_nod/$_ask_cfg_nod_sens_fam.mon.cfg" ] 
		then
			_cfg_nod_sens_fam_lst=$( cat $_config_path_nod/$_ask_cfg_nod_sens_fam.mon.cfg ) 
		else
			if [ ! -f "$_config_path_nod/name.mon.cfg.template" ] 
			then
				echo
				echo "	No template existing, creating base sensor template"
				echo
				echo -e "hostname\nmon_time\nuptime" > $_config_path_nod/name.mon.cfg.template
			fi

			_cfg_nod_sens_fam_lst=$( cat $_config_path_nod/name.mon.cfg.template )
		fi

		_cfg_nod_sens_fam_lst=$( echo -e "${_cfg_nod_sens_fam_lst}" | awk '{ print NR"."$0 }' )
		
		unset _ask_cfg_os	

		while [ -z "$_ask_cfg_os" ]  
		do
			echo
			echo "Available Sensor Stocks"
			echo "----------------------------"
			echo
			_cfg_nod_sens_fam_os=$( ls -1 $_sensors_script_path | awk '{ print "\t"NR"."$0 }' )
			echo "${_cfg_nod_sens_fam_os}"
			echo
			echo -n "Select Sensor Stock : "
			read _ask_cfg_num_os
			_ask_cfg_os=$( echo "${_cfg_nod_sens_fam_os}" | awk -F\. -v _os="$_ask_cfg_num_os" '$1 == _os || $2 == _os { print $2 }' )
			echo
			echo "Selected Sensor Stock : "$_ask_cfg_os
		done

		_ask_sensor_task="y"
		_ask_sensor_list=$_cfg_nod_sens_fam_lst

		_cfg_nod_sens_fam_sens=$( ls -1 $_sensors_script_path/$_ask_cfg_os | awk -F\. -v _as="$_ask_sensor_list" 'BEGIN { split(_as,x,"\n") } $1 == "sensor" && $NF == "sh" { for ( i in x ) { if ( x[i] ~ $2 ) { _p="no" }} ; if ( _p != "no" ) { print NR"."$2 } ; _p="yes" }' )

		echo
		paste <(echo -e "Available Sensors\n--------------------\n$_cfg_nod_sens_fam_sens") <(echo -e "Asignated Sensors to $_ask_cfg_nod_sens_fam\n---------------------------\n$_ask_sensor_list") --delimiters ';' | sed 's/^\;/\ \;/' | column -s\; -t  | awk '{ print "\t"$0 }'
		echo

		echo "IMPORTANT: Daemon generic needs the name of service to monitor, cyc ask for it"
		echo "WARNING: if you different Sensor Stocks in the same family is mandatory to use common Stocks sensors"
		echo

		while [ "$_ask_sensor_task" != "n" ]
		do
			echo -ne "Select Available Sensor Number,\nlet blank to delete Asignated sensor : "
			read _ask_sensor_num

			_cfg_sensor_item=$( echo "${_cfg_nod_sens_fam_sens}" | awk -F\. -v _it="$_ask_sensor_num" '$1 == _it { print $2 }' ) 

			if [ "$_cfg_sensor_item" == "daemon_generic" ]
			then
				echo -n "Generic Daemon Selected, please put daemon name : "
				read _cfg_sensor_item 
			fi

			echo
			echo "You can't assign or delete sensor betwen 1-3, first 3 sensors are mandatory"
			echo "With blank, you put sensor at last or delete if you let blank the previous field too"
			echo -n "Select Order Number to assignate it : "
			read _ask_sensor_ord

			if [ -z "$_cfg_sensor_item" ]
			then
				while [ -z "$_ask_sensor_ord" ]
				do
					echo -n "Need Asignated Sensor Number for delete it : "
					read _ask_sensor_ord
				done

				_ask_sensor_list=$( echo -e "${_ask_sensor_list}" | awk -F\. -v _nd="$_ask_sensor_ord" '$1 != _nd || _nd ~ /^[0-3]$/ { print $0 }' )
			else
				[ -z "$_ask_sensor_ord" ] && _ask_sensor_ord=$( echo -e "${_ask_sensor_list}" | tail -n 1 | awk -F\. '{ print $1+1 }' )
				_ask_sensor_list=$_ask_sensor_list"\n"$_ask_sensor_ord"."$_cfg_sensor_item
			fi

			_cfg_nod_sens_fam_sens=$( ls -1 $_sensors_script_path/$_ask_cfg_os | awk -F\. -v _as="$_ask_sensor_list" 'BEGIN { split(_as,x,"\n") } $1 == "sensor" && $NF == "sh" { for ( i in x ) { if ( x[i] ~ $2 ) { _p="no" }} ; if ( _p != "no" ) { print NR"."$2 } ; _p="yes" }' )

			echo
			paste <(echo -e "Available Sensors\n--------------------\n$_cfg_nod_sens_fam_sens") <(echo -e "Asignated Sensors to $_ask_cfg_nod_sens_fam\n---------------------------\n$_ask_sensor_list") --delimiters ';' | sed 's/^\;/\ \;/' | column -s\; -t  | awk '{ print "\t"$0 }'
			echo

			echo "IMPORTANT: Daemon generic needs the name of service to monitor, cyc ask for it"
			echo "WARNING: if you different Stocks in the same family is mandatory to use common Stocks sensors"
			echo

			echo -n "Another Sensor (y/n): "
			read _ask_sensor_task
			
		done

		echo
		echo "Family Sensors New Assignament -- $_ask_cfg_nod_sens_fam"
		echo
		echo -e "${_ask_sensor_list}" | awk '{ print "\t"$0 }'
		echo
		echo -n "Want to write changes? (y/n/exit) "
		read _ask_cfg_nod_sensors

	done

	if [ "$_ask_cfg_nod_sensors" == "y" ]
	then
		echo
		echo "Writing Changes"
		echo

		echo -e "${_ask_sensor_list}" | awk -F\. '{ print $2 }' > $_config_path_nod/$_ask_cfg_nod_sens_fam.mon.cfg
		chown cyclops:cyclops $_config_path_nod/$_ask_cfg_nod_sens_fam.mon.cfg

	else
		echo
		echo "No changes Made"
		echo
	fi

}

config_nod_mon()
{
	unset _ask_cfg_nod_mon

	_cfg_nod_mon_sh=$( echo $_sensors_mon_script_file | awk -F\/ '{ print $NF }' ) 

	echo 
	echo "Node Monitor Module"
	echo "--> Monitor launch Configure"
	echo

	if [ ! -f "$_mon_cfg_file" ] 
	then
		if [ -f "$_mon_cfg_file.template" ] 
		then
			echo "ERR: No monitor config file, create one from template"
			cp -p $_mon_cfg_file.template $_mon_cfg_file  
		else
			echo "ERR: No Monitor config file or template for cyclops, creating new one"
			
			echo "#MON TYPE;INDEX;NAME;SCRIPT;MON GROUP;DESTINATION" > $_mon_cfg_file
		fi
	fi
	
	while [ "$_ask_cfg_nod_mon" != "y" ] && [ "$_ask_cfg_nod_mon" != "exit" ]
	do
		_cfg_nod_mon_list=$( cat $_mon_cfg_file | awk -F\; 'BEGIN { _c=0 } $1 == "NOD" { print $0 ; _c++ } END { if ( _c == 0 ) { print "none" }}' )
		
		echo "	Actually Configurated "
		echo "${_cfg_nod_mon_list}" | awk -F\; 'BEGIN { print "Index;Name;Assignated Group" ; print "-----;----;----------------" } $1 != "none" { print $2";"$3";"$5 } $1 == "none" { print "na;na;na" } ' | column -s\; -t | awk '{ print "\t"$0 }' 
		echo
		
		echo -n "Please choose index to delete, let blank for new one : "
		read _ask_nod_mon_idx

		#_cfg_nod_mon_chk=$( echo "${_cfg_nod_mon_list}" | awk -F\. -v _i="$_ask_nod_mon_idx" '$1 == _i { print $2 }' )

		if [ -z "$_ask_nod_mon_idx" ] 
		then
			unset _cfg_nod_mon_name_chk

			while [ "$_cfg_nod_mon_name_chk" != "ok" ]
			do
				echo -n "New monitor config, write a name (without spaces) : "
				read _ask_nod_mon_name
				
				_cfg_nod_mon_name_chk=$( echo "${_ask_nod_mon_name}" | awk '$0 !~ / / && $0 != "" { print "ok" }' ) 
			done

			_cfg_nod_mon_grp=$( cat $_type | awk -F\; '$0 !~ /#/ { print $4 }' | sort -u | awk '{ print NR"."$0 }' )
			[ -z "$_cfg_nod_mon_grp" ] && _cfg_nod_mon_grp="none"

			unset _cfg_nod_mon_grp_chk

			while [ "$_cfg_nod_mon_grp_chk" != "ok" ]
			do
				echo 
				echo "	Availables Groups "
				echo "	----------------- "
				echo "${_cfg_nod_mon_grp}" | awk '{ print "\t"$0 }'
				echo

				if [ "$_cfg_nod_mon_grp" == "none" ]
				then
					echo "	You don't have any available groups"
					echo "	You need to assignate them in Nodes Deinition" 
					echo "	After you finish here"
					echo 	
					
					echo -n "New Group name (without spaces) : " 
					read _ask_nod_mon_grp

					_cfg_nod_mon_grp_chk=$( echo "${_ask_nod_mon_name}" | awk '$0 !~ / / && $0 != "" { print "ok" }' )
				else
					echo -n "New Group name or choose number of available groups : "
					read _ask_nod_mon_grp

					_ask_nod_mon_grp=$( echo $_ask_nod_mon_grp | tr [:upper:] [:lower:] ) 

					case "$_ask_nod_mon_grp" in
						[0-9]*)
							_ask_nod_mon_grp=$( echo "${_cfg_nod_mon_grp}" | awk -F\. -v _i="$_ask_nod_mon_grp" '$1 == _i { print $2 }' )
							if [ -z "$_ask_nod_mon_grp" ] 
							then
								echo "ERR: You choose bad index number: ($_ask_nod_mon_grp)"
								_cfg_nod_mon_grp_chk="fail"
							else
								_cfg_nod_mon_grp_chk="ok" 
							fi
						;;
						[a-z]*)
							_cfg_nod_mon_grp_chk="ok"
						;;
						*)
							echo "ERR: Unknown Name or index ($_ask_nod_mon_grp)"
							unset _ask_nod_mon_grp
							_cfg_nod_mon_grp_chk="fail"
						;;
					esac
				fi
			done

			if [ "$_cfg_nod_mon_list" == "none" ]
			then
				_ask_nod_mon_idx="1"

				_cfg_nod_mon_output="NOD;"$_ask_nod_mon_idx";"$_ask_nod_mon_name";"$_cfg_nod_mon_sh";"$_ask_nod_mon_grp";"$_ask_nod_mon_name
			else
				unset _ask_nod_mon_idx_chk

				while [ "$_ask_nod_mon_idx_chk" != "ok" ]
				do
					echo -n "Choose index postition ( blank for last position ) : "
					read _ask_nod_mon_idx

					[ -z "$_ask_nod_mon_idx" ] && _ask_nod_mon_idx=$( cat $_mon_cfg_file | awk -F\; '$1 == "NOD" { print $0 }' | tail -n 1 | awk -F\; '{ print $2+1 }' )

					echo "DEBUG: ($_ask_nod_mon_idx)"

					case "$_ask_nod_mon_idx" in
						[0-9]*)
							_cfg_nod_mon_output=$( cat $_mon_cfg_file | awk -F\; -v _i="$_ask_nod_mon_idx" -v _g="$_ask_nod_mon_grp" -v _n="$_ask_nod_mon_name" -v _s="$_cfg_nod_mon_sh" '
								$1 == "NOD" { 
									if ( _nc == "ok" ) { 
										_idx+=$2 
										} 
									else { _idx=$2 } ; 
									if ( $2 == _i ) { 
										print "NOD;"_i";"_n";"_s";"_g";"_n ; 
										_idx++ ;
										_nc="ok"
									} ; 
									print $1";"_idx";"$3";"$4";"$5";"$6 
								} END { 
									if ( _nc != "ok" ) { 
										print "NOD;"_i";"_n";"_s";"_g";"_n 
									}
								}' ) 
							_ask_nod_mon_idx_chk="ok"

							echo
							echo "	Monitor Index Changes: "
							echo -e "Mon Type;Index;Name;Script;Mon Group;Output File\n-------;-----;----;-------;---------;-----------\n${_cfg_nod_mon_output}" | column -s\; -t | awk '{ print "\t"$0 }'
							echo
						;;
						*)
							echo "ERR: Index String wrong, please choose number position"	
						;;
					esac
				done
			fi

			echo "You add new Monitor entry :"
			echo "	Position: $_ask_nod_mon_idx"
			echo "	Monitor name: $_ask_nod_mon_name"
			echo "	Monitor group: $_ask_nod_mon_grp"

			echo
			echo -n "Do you want to write changes (y/n/exit) :"
			read _ask_cfg_nod_mon 

		else
			_cfg_nod_mon_del_item=$( cat $_mon_cfg_file | awk -F\; -v _i="$_ask_nod_mon_idx" '$1 == "NOD" && $2 == _i { print $0 }' ) 

			if [ -z "$_cfg_nod_mon_del_item" ]
			then
				echo
				echo "ERR: This record don't exist"
				echo 
			else
				echo
				echo "You Want to delete: "
				echo -e "Mon Type;Index;Name;Script;Mon Group;Output File\n-------;-----;----;-------;---------;-----------\n${_cfg_nod_mon_del_item}" | column -s\; -t | awk '{ print "\t"$0 }'
				echo
				
				_cfg_nod_mon_output=$( cat $_mon_cfg_file | awk -F\; -v _r="$_cfg_nod_mon_del_item" '$1 == "NOD" && $0 != _r { print $0 }' )

				echo
				echo -n "Do you want to write changes (y/n/exit) :"
				read _ask_cfg_nod_mon 
			fi
		fi

	done

	if [ "$_ask_cfg_nod_mon" == "y" ] 
	then
		sed -i '/^NOD/d' $_mon_cfg_file
		echo -e "${_cfg_nod_mon_output}" >> $_mon_cfg_file 
	fi
	
}

###########################################
#               MAIN EXEC                 #
###########################################

case $_cyclops_action in
cyclops)

	[ "$_cyclops_ha" == "ENABLED" ] &&  ha_check
	mng_cyclops

;;
node_status)

	[ "$_cyclops_ha" == "ENABLED" ] &&  ha_check

	mng_node_status

;;
backup)

	[ "$_cyclops_ha" == "ENABLED" ] &&  ha_check
	echo "Backup: $_par_backup"
	debug_bkp
	echo "Finish"

;;
messages)

	[ "$_cyclops_ha" == "ENABLED" ] &&  ha_check
	mng_messages

;;
show)

	[ "$_cyclops_ha" == "ENABLED" ] &&  ha_check
	show_config

;;
esac
