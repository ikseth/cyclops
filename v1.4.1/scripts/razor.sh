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
	_command_opts=$( echo "$@" | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^m/ ) { gsub(/^[a-z] /,"&@",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' )
	_command_name=$( basename "$0" )
	_command_dir=$( dirname "${BASH_SOURCE[0]}" )
	_command="$_command_dir/$_command_name $_command_opts"

	[ -f "/etc/cyclops/global.cfg" ] && source /etc/cyclops/global.cfg || _exit_code="111"

	[ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
	[ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
	[ -f "$_libs_path/node_ungroup.sh" ] && source $_libs_path/node_ungroup.sh || _exit_code="114"

	source $_color_cfg_file

	case "$_exit_code" in
	111)
		echo "Main Config file doesn't exists, please revise your cyclops installation"
		exit 1
	;;
	112)
		echo "HA Control Script doesn't exists, please revise your cyclops installation"
		exit 1
	;;
	11[3-4])
		echo "Necesary libs files doesn't exits, please revise your cyclops installation"
		exit 1
	;;
	esac

#
	_par_typ="status"
	_par_act="all"

	_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

	#### MAX TRIES ####

	_nodetrymax=3

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":a:idn:v:h:" _optname
do
        case "$_optname" in
		"a")
			_opt_act="yes"
			_par_act=$OPTARG
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

		;;
		"d")
			_opt_dae="yes"

			export _sh_action="daemon"
		;;
		"i")
			# INITIALIZATE $_razordb
			_opt_init="yes"
		;;
		"v")
			_opt_shw="yes"
			_par_shw=$OPTARG
		;;
                "h")
                        _opt_help="yes"
                        _par_help=$OPTARG

                        case "$_par_help" in
                                        "des")
                                                echo "$( basename "$0" ) : Cyclops Global Razor Command"
                                                echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
                                                echo "  Global config path : $_config_path"
                                                echo "          Global config file: global.cfg"
                                                echo

                                                exit 0
			esac
		;;
               ":")
                        case "$OPTARG" in
                        "h")
				echo
				echo "CYCLOPS GLOBAL RAZOR COMMAND"
				echo "	Cyclops Razor and Reactive Control Command"
				echo
				echo "-a [option] Razor Action to launch"
				echo "	check: test host"
				echo "	up: put host in operative mode"
				echo "	[un]link: [eject or] inset host in the system"
				echo "	diagnose: put host in diagnose mode"
				echo "	drain: put host in mainteinance mode"
				echo "	reboot: reset host from razor shield system"
				echo "	init: initialize host"
				echo "	info: show host information"
				echo "	enable|disable: host razor system"
				echo "	status: check razor status in host"
				echo "	sync: syncronize razor modules and files"
				echo
				echo "-i initializate razor" 
				echo
				echo "-d Daemon Option"
				echo 
				echo "-n [node|node range] node filter"
				echo "	You can use @[group or family name] to define range node"
				echo "	and you can use more than one group/family comma separated"
				echo
				echo "-h [|des] help is help"
				echo "	des: detailed help about this command"
				echo
			
				exit 0
			;;
			esac
		;;
	esac
done

shift $((OPTIND-1))

############### FUNCTIONS ##################

razor_daemon()
{
	_now_nod_status=$( awk -F\; '$1 !~ "^#" { print $2";"$7 }' $_type )
	_nod_change_status=$( awk -F\; -v _nl="$_now_nod_status" 'BEGIN { split(_nl,n,"\n") } { for ( i in n ) { split(n[i],nf,";") ; if ( nf[1] == $2 ) { if ( nf[2] != $3 ) { print nf[1]";"nf[2]";"$4";"$5";"$6 } ; break }}}' $_razordb_file )

	if [ -z "$_nod_change_status" ]
	then
		echo "DEBUG: NO CHANGES"
	else
		for _nod_list in $( echo "${_nod_change_status}" ) 
		do
			echo "DEBUG: LAUNCH: [$_nod_list]"
			node_status_action $_nod_list &
		done
		wait
	fi
}

razor_manual()
{
	_fields=$( awk -F\; -v _n="$1" -v _s="$2" '$2 == _n { print _n";"_s";"$4";"$5";"$6 }' $_razordb_file ) 
	
	node_status_action $_fields
}

razordb_init()
{

	if [ ! -f "$_razordb_file" ]
	then
		_header="INDEX;NODENAME;FAMILY;GROUP;OS;POWER PROFILE TYPE;MON STATUS"

		awk -F\; -v _h="$_header" 'BEGIN { print _h } { print $1";"$2";"$7";0;"systime()";YES" }' $_type > $_razordb_file 
	else
		echo "ERR: $_razordb_file EXISTS please force command to overwrite it"
		exit 1
	fi
}

node_status_action()
{

	_nodename=$(   echo "$1" | cut -d';' -f1 )
	_nodestatus=$( echo "$1" | cut -d';' -f2 ) 
	_nodetry=$(    echo "$1" | cut -d';' -f3 )
	_nodetime=$(   echo "$1" | cut -d';' -f4 )
	_nodesucc=$(   echo "$1" | cut -d';' -f5 )

	case "$_nodestatus" in
	up)
		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a check 2>/dev/null ; echo $? )
		if [ "$_node_rzr_status" != "0" ] && [ "$_node_rzr_status" != "21" ]	
		then
			$_script_path/cyclops.sh -a link -n $_nodename -c 2>&1 > /dev/null
		else
			$_script_path/audit.nod.sh -i event -e info -m "up action" -s OK -n $_nodename 2>>$_mon_log_path/audit.log	
		fi
	;;
	link)
		if [ "$_nodetry" -lt "$_nodetrymax" ]
		then
			echo "DEBUG: [$_nodename] [010000] TRY: [$_nodetry] < [$_nodetrymax]"
	
			_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a check 2>/dev/null ; echo $? )
			if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]	
			then
				echo "DEBUG: [$_nodename] [010100] RZR: CHECK: OK: [$_node_rzr_status]"

				$_script_path/cyclops.sh -a up -n $_nodename -c 2>&1 > /dev/null
				$_script_path/audit.nod.sh -i event -e reactive -m "link action" -s OK -n $_nodename 2>>$_mon_log_path/audit.log	

				#### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
				sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
			else
				echo "DEBUG: [$_nodename] [010200] RZR: CHECK: BAD: [$_node_rzr_status]"

				_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a $_nodestatus 2>/dev/null ; echo $? )

				if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]
				then
					echo "DEBUG: [$_nodename] [010201] RZR: CHANGE: OK: [$_node_rzr_status]"

					$_script_path/cyclops.sh -a up -n $_nodename -c 2>&1 > /dev/null
					$_script_path/audit.nod.sh -i event -e reactive -m "link action" -s OK -n $_nodename 2>>$_mon_log_path/audit.log	

					#### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
					sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
				else
					echo "DEBUG: [$_nodename] [010202] RZR: CHANGE: BAD: [$_node_rzr_status]"

					#### CHANGE $_razordb TRY 
					let "_nodetry=_nodetry+1"
					sed -i "s/\(^[0-9]*;$_nodename;[a-z]*\);[0-9];\(.*\)/\1;$_nodetry;\2/" $_razordb_file
				fi	
			fi
		else
			echo "DEBUG: [$_nodename] [020000] TRY: [$_nodetry] >= [$_nodetrymax]"
			#### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
			sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );NO/" $_razordb_file

			$_script_path/cyclops.sh -a repair -n $_nodename -c 2>&1 > /dev/null
			$_script_path/audit.nod.sh -i event -e reactive -m "link action" -s FAIL -n $_nodename 2>>$_mon_log_path/audit.log
		fi
	;;
	unlink)
		echo "DEBUG: [$_nodename] [010000] TRY: [$_nodetry] < [$_nodetrymax]"

		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a $_nodestatus 2>/dev/null ; echo $? )

		if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]
		then
			echo "DEBUG: [$_nodename] [010201] RZR: CHANGE: OK: [$_node_rzr_status]"

			_msg_insert="unlink action ok"
			$_script_path/cyclops.sh -a drain -n $_nodename -c 2>&1 > /dev/null
			$_script_path/audit.nod.sh -i event -e info -m $_msg_insert -s OK -n $_nodename 2>>$_mon_log_path/audit.log
                                        
			#### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
			sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
		else
			echo "DEBUG: [$_nodename] [010202] RZR: CHANGE: BAD: [$_node_rzr_status]"

			#### CHANGE $_razordb TRY 
			let "_nodetry=_nodetry+1"
			sed -i "s/\(^[0-9]*;$_nodename;[a-z]*\);[0-9];\(.*\)/\1;$_nodetry;\2/" $_razordb_file
		fi      
	;;
	repair)
                if [ "$_nodetry" -lt "$_nodetrymax" ]
                then
                        echo "DEBUG: [$_nodename] [010000] TRY: [$_nodetry] < [$_nodetrymax]"

                        _node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a check 2>/dev/null ; echo $? )
                        if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]
                        then
                                echo "DEBUG: [$_nodename] [010100] RZR: CHECK: OK: [$_node_rzr_status]"

                                _msg_insert="node is ok, no repair action, please change to up if status is ok"
                                $_script_path/cyclops.sh -a diagnose -n $_nodename -c 2>&1 > /dev/null
                                $_script_path/audit.nod.sh -i event -e reactive -m $_msg_insert -s UP -n $_nodename 2>>$_mon_log_path/audit.log
                                
                                #### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
                                sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
                        else
                                echo "DEBUG: [$_nodename] [010200] RZR: CHECK: BAD: [$_node_rzr_status]"

                                _node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a $_nodestatus 2>/dev/null ; echo $? )

                                if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]
                                then
                                        echo "DEBUG: [$_nodename] [010201] RZR: CHANGE: OK: [$_node_rzr_status]"

                                        _msg_insert="repair action ok, please change to up if status is ok"
                                        $_script_path/cyclops.sh -a diagnose -n $_nodename -c 2>&1 > /dev/null
                                        $_script_path/audit.nod.sh -i event -e reactive -m $_msg_insert -s UP -n $_nodename 2>>$_mon_log_path/audit.log
                                        
                                        #### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
                                        sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
                                else
                                        echo "DEBUG: [$_nodename] [010202] RZR: CHANGE: BAD: [$_node_rzr_status]"

                                        #### CHANGE $_razordb TRY 
                                        let "_nodetry=_nodetry+1"
                                        sed -i "s/\(^[0-9]*;$_nodename;[a-z]*\);[0-9];\(.*\)/\1;$_nodetry;\2/" $_razordb_file
                                fi      
                        fi
                else
                        echo "DEBUG: [$_nodename] [020000] TRY: [$_nodetry] >= [$_nodetrymax]"
                        #### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
                        sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );NO/" $_razordb_file

                        _msg_insert="repair action fail, please change to drain if status is bad and productive environment is ok"
                        $_script_path/cyclops.sh -a content -n $_nodename -c 2>&1 > /dev/null
                        $_script_path/audit.nod.sh -i event -e reactive -m $_msg_insert -s FAIL -n $_nodename 2>>$_mon_log_path/audit.log
                fi
	;;
	check)
		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a check 2>/dev/null ; echo $? )
	;;
	drain)
		echo "DEBUG: [$_nodename] [010000] TRY: [$_nodetry] < [$_nodetrymax]"

		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a $_nodestatus 2>/dev/null ; echo $? )

		if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]
		then
			echo "DEBUG: [$_nodename] [010201] RZR: CHANGE: OK: [$_node_rzr_status]"

			_msg_insert="drain action ok"
			$_script_path/audit.nod.sh -i event -e info -m $_msg_insert -s OK -n $_nodename 2>>$_mon_log_path/audit.log
                                        
			#### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
			sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
		else
			echo "DEBUG: [$_nodename] [010202] RZR: CHANGE: BAD: [$_node_rzr_status]"

			#### CHANGE $_razordb TRY 
			let "_nodetry=_nodetry+1"
			sed -i "s/\(^[0-9]*;$_nodename;[a-z]*\);[0-9];\(.*\)/\1;$_nodetry;\2/" $_razordb_file
		fi      
	;;
	info)
		echo "working on it"
		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a check 2>/dev/null ; echo $? )
	;;
	content)
		echo "DEBUG: [$_nodename] [010000] TRY: [$_nodetry] < [$_nodetrymax]"

		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a $_nodestatus 2>/dev/null ; echo $? )

		if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]
		then
			echo "DEBUG: [$_nodename] [010201] RZR: CHANGE: OK: [$_node_rzr_status]"

			_msg_insert="content action ok"
			$_script_path/audit.nod.sh -i event -e reactive -m $_msg_insert -s OK -n $_nodename 2>>$_mon_log_path/audit.log
                                        
			#### CHANGE $_razordb TRY_FIELD & CHANGE_STATUS_FIELD & DATE_FIELD & STATUS_FIELD 
			sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
		else
			echo "DEBUG: [$_nodename] [010202] RZR: CHANGE: BAD: [$_node_rzr_status]"

			#### CHANGE $_razordb TRY 
			let "_nodetry=_nodetry+1"
			sed -i "s/\(^[0-9]*;$_nodename;[a-z]*\);[0-9];\(.*\)/\1;$_nodetry;\2/" $_razordb_file
		fi      
	;;
	diagnose)
		sed -i "s/$_nodename;.*/$_nodename;$_nodestatus;0;$( date +%s );YES/" $_razordb_file
	;;
	sync)
		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a disable 2>/dev/null ; echo $? )

		[ "$_node_rzr_status" == "0" ] && _node_rzr_status=$( scp -r $_cyc_clt_rzr_dat $_nodename:$_cyc_clt_rzr_dat 2>&1 >/dev/null ; echo $? )
		[ "$_node_rzr_status" == "0" ] && _node_rzr_status=$( scp -r $_cyc_clt_scp_path $_nodename:$_cyc_clt_scp_path 2>&1 >/dev/null ; echo $? )
		if [ "$_node_rzr_status" == "0" ] 
		then
			$_script_pat/audit.nod.sh -i event -e info -m "razor sync module" -s OK -n $_nodename 2>>$_mon_log_path/audit.log
			_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a enable 2>/dev/null ; echo $? )
		else
			$_script_pat/audit.nod.sh -i event -e info -m "razor sync module fail: razor disable" -s FAIL -n $_nodename 2>>$_mon_log_path/audit.log
		fi
	;;
	enable)
		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a status 2>/dev/null ; echo $? )
		case "$_node_rzr_status" in
		21)
			_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a enable 2>/dev/null ; echo $? )
			[ "$_node_rzr_status" == "0" ] && _node_rzr_enable="OK" || _node_rzr_enable="FAIL" 
			$_script_pat/audit.nod.sh -i event -e info -m "razor module enable" -s $_node_rzr_enable -n $_nodename 2>>$_mon_log_path/audit.log
		;;
		1)
			_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a disable 2>/dev/null ; echo $? )
			[ "$_node_rzr_status" == "0" ] && _node_rzr_enable="OK" || _node_rzr_enable="FAIL" 
			$_script_pat/audit.nod.sh -i event -e info -m "razor module corrupt, force to disable it" -s $_node_rzr_enable -n $_nodename 2>>$_mon_log_path/audit.log
		;;
		esac
	;;
	disable)
		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a status 2>/dev/null ; echo $? )
		case "$_node_rzr_status" in
		0)
			_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a disable 2>/dev/null ; echo $? )
			[ "$_node_rzr_status" == "0" ] && _node_rzr_enable="OK" || _node_rzr_enable="FAIL" 
			$_script_pat/audit.nod.sh -i event -e info -m "razor module disable" -s $_node_rzr_enable -n $_nodename 2>>$_mon_log_path/audit.log
		;;
		1)
			_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a disable 2>/dev/null ; echo $? )
			[ "$_node_rzr_status" == "0" ] && _node_rzr_enable="OK" || _node_rzr_enable="FAIL" 
			$_script_pat/audit.nod.sh -i event -e info -m "razor module corrupt, force to disable it" -s $_node_rzr_enable -n $_nodename 2>>$_mon_log_path/audit.log
		;;
		esac
	;;
	status)
		_node_rzr_status=$( ssh  -o ConnectTimeout=6 -o StrictHostKeyChecking=no $_nodename $_cyc_clt_rzr_scp -a enable 2>/dev/null ; echo $? )
	;;
	esac

	#echo "$_nodename;$_nodestatus;$_nodetry;...;..."
}

node_link()
{
	_link_nname=$1
	_link_try=$2
}

node_unlink()
{
	echo "WORKING ON IT"
}

node_repair()
{
	echo "WORKING ON IT"
}

node_check()
{
	echo "WORKING ON IT"
}

node_drain()
{
	echo "WORKING ON IT"
}

###########################################
#               MAIN EXEC                 #
###########################################

############### HA CHECK ##################

[ "$_cyclops_ha" == "ENABLED" ] && ha_check $_command

############### LAUNCHING ##################

	[ ! -f "$_razordb_file" ] && razordb_init 

	if [ "$_opt_dae" == "yes" ] 
	then
		echo "DEBUG: DAEMON LAUNCH"
		razor_daemon 
	else
		echo "nodename;newstatus;trycount;timestamp;success"
		for _node in $( node_ungroup $_par_node | tr ' ' '\n' )  
		do
			razor_manual $_node $_par_act &
		done
		wait
	fi




