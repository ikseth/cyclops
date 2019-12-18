#!/bin/bash

###########################################
#            DAEMON MONITORING            #
###########################################

############################################################################
#                                                                          #
#    Cyclops creator: 	Ignacio Garcia Hoyos 				   #
#			ignaciogarciahoyos@gmail.com			   #
#									   #
#    GPL License                                                           #
#    -----------                                                           #
#                                                                          #
#    This file is part of Cyclops Suit.                                    #
#                                                                          #
#    Foobar is free software: you can redistribute it and/or modify        #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation, either version 3 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    Foobar is distributed in the hope that it will be useful,             #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.       #
#                                                                          #
############################################################################

############# VARIABLES ###################


IFS="
"
_hostname=$( hostname -s )

echo $( date +%s )" BEGIN ERR LOG:" >> /opt/cyclops/logs/$_hostname.mon.err.log

_config_path="/etc/cyclops"
_mon_log_file=$_hostname".mon.log"
_debug_code="MON.GEN" # TS (nose) SM (Service Monitor) DA (Daemon) 01
_debug_prefix_msg="Daemon Monitoring: "

_debug=$_debug_code" "$_debug_prefix_msg"\n"

if [ -f $_config_path/global.cfg ] 
then
	source $_config_path/global.cfg 
else
	echo "Global config don't exits" 
	exit 1
fi

if [ -f $_config_path_sys/wiki.cfg ] 
then
	source $_config_path_sys/wiki.cfg 
else
	echo "Wiki config don't exits" 
	exit 1
fi

_par_mon="all"
_opt_daemon="no"
_tmp_daemon="/tmp/cyclops.mon.tmp"

_mon_date=$(date +%d.%m.%Y\ %H.%M.%S)

source $_color_cfg_file
source $_alert_mail_cfg_file

_pid=$( echo $$ )
_pid_file=$_lock_path"/monitor.pid"
_active_sound=""

###########################################
#              PARAMETERs                 #
###########################################


while getopts ":dh:e:" _optname
do

        case "$_optname" in
		"d")
			_opt_daemon="yes"
		;;
		"e")
			case "$OPTARG" in
				"disable")
					sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1DISABLED/' $_sensors_sot
					echo "Cyclops Monitoring System Disabled"
					exit
				;;
				"enable")
					sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1ENABLED/' $_sensors_sot
					echo "Cyclops Monitoring System Enabled"
					exit

				;; 
				"drain")
					sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1DRAIN/' $_sensors_sot
					echo "Cyclops Monitoring System Mode is Maintenance"
					echo "Disable Section Monitoring"
					echo "Disable MAIL Alerts"
					exit
				;;
				"testing")
					sed -i -e 's/\(CYC;0001;[0-9]*;\)[A-Z]*/\1TESTING/' $_sensors_sot
                                        echo "Cyclops Monitoring System Mode is Maintenance"
					echo "Disable MAIL Alerts"
                                        exit
				;;	
				"status")
					echo "Cyclops Monitoring System MODE IS: "$( awk -F\; '$1 == "CYC" && $2 == "0001" { print $4}' $_sensors_sot )
					exit
				;;
				*)
 					echo "-e [enable/disable/status] Disable/Enable Monitoring System"
		                        echo "          disable:  Disable Monitoring System"
                		        echo "          enable: Enable Monitoring System"
					echo "		drain: Enable Maintenance Mode, Only Dashboard Works"
					echo "		testing: Enable Testing Mode, MAIL Alerts Freeze"
					echo "		status: Show Monitoring Status"
					exit 1
				;;
			esac
		;;
		"h")
			case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Main Monitoring Module"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Monitoring Config path: $_config_path_mon"
				echo "		Config file: $( echo $_mon_cfg_file | awk -F\/ '{ print $NF }' )"
				echo "	System Config path: $_config_path_sys"
				echo "		HA sync excludes file: $( echo $_ha_sync_exc | awk -F\/ '{ print $NF }' )" 
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
				echo "CYCLOPS MAIN MONITOR COMMAND"
				echo
				echo "-d	daemon executing, exclusive option"
				echo "-m [node|family|type] Monitoring one node, family or type of nodes"
				echo "          options are indicated in $_type"
				echo "          all: get all nodes from all families"
				echo "-v [option] Show formated results"
				echo "          human: human readable"
				echo "          wiki:  wiki format readable"
				echo "          commas: excell readable"
				echo "-e [enable/disable] Disable/Enable Monitoring System"
				echo "		disable:  Disable Monitoring System"
				echo "		enable: Enable Monitoring System"
				echo "          drain: Enable Maintenance Mode, Only Dashboard Works"
				echo "          testing: Enable Testing Mode, MAIL Alerts Freeze"
				echo "		status: Show Monitoring Status"
				echo "-h [|des] help is help"
				echo "		des: Detailed Command help"
                	        exit 0
			else
				echo "ERR: Use -h for help"
				exit 1
			fi
                ;;
                *)
                        echo "WHATs HAPPEND?!"
                        echo $_optname" "$_OPTARG
                        exit 1
                ;;
                --)
                        echo "OPssss!!!"
                        echo $_optname" "$OPTARG
                        exit 1
                ;;
        esac

done

shift $((OPTIND-1))

echo $_pid > $_pid_file

###########################################
#                  LIBs                   #
###########################################

#### LOAD NODE GROUP LIB 

[ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh && _lib_node_group="YES"

###########################################
#               FUNCTIONs                 #
###########################################

generate_mon_output_dash ()
{

	## DASHBOARD PROCESSING ## 

        ## TOTAL FIELD CALCULATION -- 

	[ -z $_nod_mon_field_num ] && _nod_mon_field_num=0
	[ -z $_srv_mon_field_num ] && _srv_mon_field_num=0
	[ -z $_sec_mon_field_num ] && _sec_mon_field_num=0
	[ -z $_env_mon_field_num ] && _env_mon_field_num=0

        _dash_field_total=$_nod_mon_field_num

        if [ $_dash_field_total -lt $_srv_mon_field_num ]
        then
                _dash_field_total=$_srv_mon_field_num
        else
                if [ $_dash_field_total -lt $_sec_mon_field_num ]
                then
                        _dash_field_total=$_sec_mon_field_num
		else
			if [ $_dash_field_total -lt $_env_mon_field_num ]
			then
				_dash_field_total=$_env_mon_field_num
			fi
                fi
        fi

        let "_sec_mon_field_num=_dash_field_total - _sec_mon_field_num"
        let "_srv_mon_field_num=_dash_field_total - _srv_mon_field_num"
        let "_nod_mon_field_num=_dash_field_total - _nod_mon_field_num"
	let "_env_mon_field_num=_dash_field_total - _env_mon_field_num"

        _dash_title_full_text=$( echo | awk -v _t="$_dash_field_total" 'BEGIN { _t = _t + 1 } { for (i=1;i<=_t;i++) { _c=_c"|" } } END { print _c }')

        [ $_sec_mon_field_num -ne 0 ] && _sec_header_full_text=$( echo | awk -v _t="$_sec_mon_field_num" -v _p="$_color_header" 'BEGIN { _c="" } { for (i=1;i<_t;i++) { _c=_c""_p";" } } END { print ";"_c }')
        [ $_srv_mon_field_num -ne 0 ] && _srv_header_full_text=$( echo | awk -v _t="$_srv_mon_field_num" -v _p="$_color_header" 'BEGIN { _c="" } { for (i=1;i<_t;i++) { _c=_c""_p";" } } END { print ";"_c }')
        [ $_nod_mon_field_num -ne 0 ] && _nod_header_full_text=$( echo | awk -v _t="$_nod_mon_field_num" -v _p="$_color_header" 'BEGIN { _c="" } { for (i=1;i<_t;i++) { _c=_c""_p";" } } END { print ";"_c }')
	[ $_env_mon_field_num -ne 0 ] && _env_header_full_text=$( echo | awk -v _t="$_env_mon_field_num" -v _p="$_color_header" 'BEGIN { _c="" } { for (i=1;i<_t;i++) { _c=_c""_p";" } } END { print ";"_c }')

        ## DASH TABLE SIZE CALCULATION --

        let _dash_column_size=82/$_dash_field_total

        _dash_column_text=$(echo | awk -v _t="$_dash_field_total" -v _p="$_dash_column_size" 'BEGIN { _c="" } { for (i=1;i<=_t;i++) { _c=_c""_p"% " } } END { print _c }')

	## CUSTOM USER MESSAGES FACTORING --

        _messages_date=$( date +%s )

        _messages=$( awk -F\; -v _date="$_messages_date" '$1 == "INFO" && $4 > _date { $3=strftime("%d-%m-%Y %H:%M",$3); $4=strftime("%d-%m-%Y %H:%M",$4) ;  print $5";"$3";"$4";"$6 }' $_sensors_sot )
        _active_msg=$( echo "${_messages}" | wc -l )

	if [ -z "$_messages" ]
	then
		_active_msg_color=$_color_disable
		_messages_title_color=$_color_disable

		_active_msg="0"
		_messages_title="{{ :wiki:activemes_disable.png?nolink |}}"
		_messages_header=""
	else
		_messages_header="|  $_color_header priority  |  $_color_header birth  |  $_color_header death  |  $_color_header message  |\n"
		_messages=$( echo "${_messages}" | sort -t\; -k1n | sed -e "s/^[0-9][0-9][0-9]\(;.*\)/$_color_up INFO\1/" -e "s/^[1-5][0-9]\(;.*\)/$_color_fail MEDIUM\1/" -e "s/^[6-9][0-9]\(;.*\)/$_color_check LOW\1/" -e "s/^[0-9]\(;.*\)/$_color_down HIGH\1/" ) 
		_messages=$( echo "${_messages}" | sed -e 's/^/\|  /' -e 's/$/  \|/' -e 's/;/  \|  /g' )

		_messages_alert_level=$( echo "${_messages}" | egrep -o "INFO|LOW|MEDIUM|HIGH" | sort -u )

		case "$_messages_alert_level" in
		*HIGH*)
			_active_msg_color=$_color_down
			_messages_title_color=$_color_down
			_messages_title="{{ :wiki:activemes_red.gif?nolink |}}"
		;; 
		*MEDIUM*)
			_active_msg_color=$_color_fail
			_messages_title_color=$_color_fail
			_messages_title="{{ :wiki:activemes_orange.gif?nolink |}}"
		;;
		*LOW*)
			_active_msg_color=$_color_check
			_messages_title_color=$_color_check
			_messages_title="{{ :wiki:activemes.png?nolink |}}"
		;;
		*INFO*)
			_active_msg_color=$_color_up
			_messages_title_color=$_color_up	
			_messages_title="{{ :wiki:activemes.png?nolink |}}"
		;;
		*)
			_active_msg_color=$_color_unk
			_messages_title_color=$_color_unk
		;;
		esac
	fi

	## LAST EVENT LOG FACTORING --

	# _audit_last_event_log=$( cat $_last_event_log )
	
	## LAST BITACORA LOG FACTORING -- ## REFACTORY: CREATE A PG IN AUDIT COMMAND LIKE AUDIT_LAST_EVENT_LOG ##

	_audit_last_bitacora_log=$( cat $_audit_data_path/*.bitacora.txt | sort -n | tail -n 10  | awk -F\; -v _ap="$_wiki_audit_path" '
		{ 
			_date=strftime("%Y-%m-%d;%H:%M",$1) ; 
			split(_date,d,";") ;
			if ( d[1] != _do ) { 
				_do=d[1] ;
				_dp=d[1] 
			} else {
				_dp=":::"
			}
			_np="[["_ap":"$3".audit|"$3"]]" ;
			print _dp";"d[2]";"_np";"$4";"$5";"$6 ; 
		}' 2>/dev/null )

	if [ -z "$_audit_last_bitacora_log" ] 
	then
		_audit_last_bitacora_msg="NO BITACORA EVENT"
	else
		_audit_last_bitacora_msg=$( echo "${_audit_last_bitacora_log}" | sed "1 i\ $_color_header date;$_color_header time;$_color_header source;$_color_header event;$_color_header message;$_color_header state" ) 
		_audit_last_bitacora_msg=$( echo "${_audit_last_bitacora_msg}" | sed -e "s/UP/$_color_up &/g" -e "s/OK/$_color_ok &/g" -e "s/FAIL/$_color_fail &/g" -e "s/DOWN/$_color_down &/g" -e "s/ALERT/$_color_fail &/g" -e "s/INFO/$_color_up &/g" )
		_audit_last_bitacora_msg=$( echo "${_audit_last_bitacora_msg}" | sed -e "s/DRAIN/$_color_disable &/g" -e "s/REPAIR/$_color_mark &/" -e  "s/DIAGNOSE/$_color_check &/g" -e "s/STATUS/$_color_disable &/g" -e "s/CONTENT/$_color_mark &/g" )
		_audit_last_bitacora_msg=$( echo "${_audit_last_bitacora_msg}" | sed -e "s/SOLVED/$_color_ok &/g" -e "s/CLOSE/$_color_up &/" )
		_audit_last_bitacora_msg=$( echo "${_audit_last_bitacora_msg}" | sed -e "s/TESTING/$_color_check &/g" -e "s/UPGRADE/$_color_mark &/" -e "s/ENABLE/$_color_ok &/g" -e "s/INTERVENTION/$_color_mark &/g" -e "s/ISSUE/$_color_fail &/" )
		_audit_last_bitacora_msg=$( echo "${_audit_last_bitacora_msg}" | sed -e 's/^/|  /' -e 's/;/  |  /g' -e 's/$/  |/' )
		_audit_last_bitacora_msg=$( echo "${_audit_last_bitacora_msg}" | sed '1 i\|< 100% 6% 6% 8% 10% 64% 6%>|' )
	fi

	_audit_last_events=$( $_script_path/audit.nod.sh -f activity -v eventlog | awk -F\; 'BEGIN { _tn=systime() } $1 > _tn-259200 && ( $4 == "ALERT" || $4 == "REACTIVE" && $6 != "OK" ) { print $0 }' | 
				sort -t\; -n |
				tail -n 30 | 
				awk -F\; -v _co="$_color_ok" -v _cd="$_color_down" -v _cf="$_color_fail"  -v _cr="$_color_rzr" -v _cc="$_color_fail" -v _cm="$_color_mark" -v _cu="$_color_up" -v _ap="$_wiki_audit_path" -v _uk="$_color_unk" '
                BEGIN {
                        _st=systime()-86400*3
                } { 
                        _d=strftime("%Y-%m-%d;%H:%M:%S",$1) ; 
                        split(_d,d,";") ; 
                        if ( d[1] != _do ) { 
                                _do=d[1] ; 
                                _dp=d[1] 
                        } else { 
                                _dp=":::" 
                        } ; 
                        if ( $6 ~ /ALERT|FAIL/ ) { $6=_cf" "$6 }
                        if ( $6 == "DOWN" ) { $6=_cd" "$6 } 
                        if ( $6 == "DIAGNOSE" ) { $6=_cm" "$6 }
                        if ( $6 == "UP" ) { $6=_cu" "$6 }
                        if ( $6 == "OK" ) { $6=_co" "$6 }
                        if ( $6 == "CONTENT" ) { $6=_cc" "$6 }
			if ( $6 == "UNKNOWN" ) { $6=_uk" "$6 }
			if ( $6 == "REPAIR" ) { $6=_cm" "$6 }
                        if ( $4 == "ALERT" ) { $4=_cf" "$4 }
                        if ( $4 == "REACTIVE" ) { $4=_cr" "$4 }
                        print "|  "_dp"  |  "d[2]"  |  [["_ap":"$3".audit|"$3"]]  |  "$4"  |  "$5"  |  "$6"  |" 
                }' )

        ## FACTORING WIKI PAGE ##
        
        ## AUTO REFRESH PAGE -- 

        echo "<html>" 
        echo "<meta http-equiv=\"refresh\" content=\"120\">" 
        echo "</html>"

        ## DISABLE TABLE CONTENT --

        echo
        echo "~~NOTOC~~"
	echo "~~NOCACHE~~"
        echo

        ## DASHBOARD SUMARY ##

        echo
        echo '\\'
        echo

        echo "|< 100% 10% 9% 9% 9% 9% 2% 2% 2% 2% 2% 20% 24% >|"
	echo "|  $_color_title {{ :wiki:cyclops_title.png?nolink |}}  |||||||||||  $_cyclops_status_color ** <fc $_cyclops_status_font> CYCLOPS $_cyclops_status </fc> **  |"
        echo "|  $_color_header Monitor Time  |  $_color_header Cycle   |  $_color_header Active Messages  |  $_color_header Active Alerts  |  $_color_header Alerts Sent  |  $_color_header Mgt  |  $_color_header L1  |  $_color_header L2  |  $_color_header L3  |  $_color_header Oth  |  $_color_header Health  |  $_color_header Cyclops Server  |" 
        echo "|  $_mon_date  |  $_color_up $_mon_cycle  |  $_active_msg_color $_active_msg  |  $_active_msg_alerts_color $_active_msg_alerts  |  $_sent_msg_alerts_color $_sent_msg_alerts  |  $_pg_usr_adm_color $_pg_usr_adm  |  $_pg_usr_l1_color $_pg_usr_l1  |  $_pg_usr_l2_color $_pg_usr_l2  |  $_pg_usr_l3_color $_pg_usr_l3  |  $_pg_usr_other_color $_pg_usr_other  | $_nod_operative_color $_nod_operative_health  |  $_cyc_ha_color ** <fc $_cyc_ha_font> $_hostname </fc> **  |" 
	echo

	## PLUGINS  --_
	echo "|< 100% 10% 11% 11% 13% 11% 11% 11% 11% 11% >|"
	echo "|  $_color_title {{ :wiki:sysactinfo_title.png?nolink |}}     |||||||||"
	echo "|  $_color_header Productive Status  |  $_color_header $_mon_no_pg_stats_link  |  $_color_header Active Warnings  |  $_color_header $_mon_sr_pg_stats_link  |  $_color_header $_mon_nr_pg_stats_link  |  $_color_header $_mon_lu_pg_stats_link  |  $_color_header UP Record  |  $_color_header $_mon_ue_pg_max_stats_link  |  $_color_header $_mon_ue_pg_min_stats_link  |"
	echo "|  $_env_status_pg_color ** <fc white> $_env_status_pg_status </fc> **  |  $_nod_operative_color $_nod_operative_status $_zombie_brains  |  $_warning_detector_color $_warning_detector  |  $_srv_slurm_load_color $_srv_slurm_load  |  $_nod_load_color $_nod_load  |  $_login_users_color $_login_users  |  $_color_up "$_max_record"d  |  $_max_record_color "$_max_node"d  |  $_color_disable "$_min_node"d  |"
	echo


	## DASHBOARD MAIN MON --

        echo
        echo "|< 100% 10% 8% $_dash_column_text >|"
        echo "|  $_sec_color_title [[$_wiki_mon_sec_path|$_sec_image_title]]  |"$_dash_title_full_text

        if [ "$_cyclops_monsec_status" == "ENABLED" ] 
	then
        	echo "start time;elapsed time"$_sec_mon_dash_titles""$_sec_header_full_text | sed -e "s/^/|  $_color_header/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        	echo $_sec_mon_begin_dash_date";"$_sec_mon_time_elapsed""$_sec_mon_dash_values | sed -e 's/^/|  /' -e 's/$/  |/' -e 's/;/  |  /g' -e "s/UP/$_color_ok \*\* \<fc white\>  OPERATIVE \<\/fc\> \*\*/g" -e "s/FAIL/$_color_fail/g" -e "s/DOWN.[0-9]/$_color_down {{ :wiki:hb-alert.gif?nolink |}}/g" -e "s/DISABLE/$_color_disable/"
	fi
        echo "| |"

        echo "|  $_srv_color_title [[$_wiki_mon_srv_path|$_srv_image_title]]  |"$_dash_title_full_text 
        if [ "$_cyclops_monsrv_status" == "ENABLED" ] 
	then
        	echo "start time;elapsed time"$_srv_mon_dash_titles""$_srv_header_full_text | sed -e "s/^/|  $_color_header/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        	echo $_srv_mon_begin_dash_date";"$_srv_mon_time_elapsed""$_srv_mon_dash_values | sed -e 's/^/|  /' -e 's/$/  |/' -e 's/;/  |  /g' -e "s/UP/$_color_ok \*\* \<fc white\>  OPERATIVE \<\/fc\> \*\*/g" -e "s/FAIL/$_color_fail/g" -e "s/DOWN/$_color_down {{ :wiki:hb-alert.gif?nolink |}}/g" -e "s/DISABLE/$_color_disable/"
	fi
        echo "| |"

        echo "|  $_nod_color_title [[$_wiki_mon_nod_path|$_nod_image_title]]  |"$_dash_title_full_text
        if [ "$_cyclops_monnod_status" == "ENABLED" ] 
	then
		echo "start time;elapsed time"$_nod_mon_dash_titles""$_nod_header_full_text | sed -e "s/^/|  $_color_header/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
		echo $_nod_mon_begin_dash_date";"$_nod_mon_time_elapsed""$_nod_mon_dash_values | sed -e 's/^/|  /' -e 's/$/  |/' -e 's/;/  |  /g' -e "s/UP/$_color_ok \*\* \<fc white\>  OPERATIVE \<\/fc\> \*\*/g" -e "s/UNK/$_color_unk \*\* \<fc white\>  UNKNOWN \<\/fc\> \*\*/g" -e "s/FAIL/$_color_fail {{ :wiki:hb-alert_orange.gif?nolink |}}/g" -e "s/DOWN/$_color_down {{ :wiki:hb-alert.gif?nolink |}}/g" -e "s/DISABLE/$_color_disable \*\* DISABLE \*\*/" -e "s/MARK/$_color_mark \*\* \<fc green\>  OPERATIVE \<\/fc\> \*\*/g"
	fi
	echo "| |"

        echo "|  $_env_color_title [[$_wiki_mon_env_path|$_env_image_title]]  |"$_dash_title_full_text

        if [ "$_cyclops_monenv_status" == "ENABLED" ] 
	then
		echo "start time;elapsed time"$_env_mon_dash_titles""$_env_header_full_text | sed -e "s/^/|  $_color_header/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        	echo $_env_mon_begin_dash_date";"$_env_mon_time_elapsed""$_env_mon_dash_values | sed -e 's/^/|  /' -e 's/$/  |/' -e 's/;/  |  /g' -e "s/UP/$_color_ok \*\* \<fc white\>  OPERATIVE \<\/fc\> \*\*/g" -e "s/MARK/$_color_mark \*\* \<fc green\>  OPERATIVE \<\/fc\> \*\*/g" -e "s/FAIL/$_color_fail/g" -e "s/DOWN/$_color_down {{ :wiki:hb-alert.gif?nolink |}}/g" -e "s/DISABLE/$_color_disable/"
	fi
       	echo

	## CUSTOM USER MESSAGES --

	echo "|< 100% 10% 10% 10% >|"
	echo "|  $_messages_title_color $_messages_title  ||||"
	echo -e $_messages_header"${_messages}" 
	echo


	## SOUND CONTROL --

	if [ ! -z "$_active_sound" ] && [ "$_cyclops_sound_status" == "ENABLED" ] && [ "$_cyclops_status" == "ENABLED" ] 
	then
		echo "<hidden Active Sounds initialState=\"visible\">"
		echo $_env_status_pg_sound
		echo $_nod_operative_sound
		echo $_zombie_detector_sound
		echo "</hidden>" 
	fi

	## LAST BITACORA LOG ##

	echo "<hidden Last Bitacora Events>"
	echo "${_audit_last_bitacora_msg}"
	echo "</hidden>"

        echo "<hidden Last 3 Days Alerts>"
        echo "|< 100% 6% 6% 8% 10% 64% 6% >|"
	echo "|  $_color_header date  |  $_color_header  time  |  $_color_header  node  |  $_color_header event  |  $_color_header  sensor/message  |  $_color_header status  |"
	echo "${_audit_last_events}"
        echo "</hidden>"

#	echo "<hidden DEBUG TESTING OUTPUT>"
#	echo "<code>"
#	echo "</code>"
#	echo "</hidden>"

	## DASHBOARD LOG --

	echo $( date +%s )" : "$_mon_date" : CYC="$_mon_cycle" : CYC_ST="$_cyclops_status" : ACT_MSG="$_active_msg" : ACT_ALE="$_active_msg_alerts" : MAIL_MSG="$_sent_msg_alerts" : USR_ADM="$_pg_usr_adm" : USR_L1="$_pg_usr_l1" : USR_L2="$_pg_usr_l2" : USR_L3="$_pg_usr_l3" : URS_OTH="$_pg_usr_other" : CYC_HOST="$_hostname >> $_sys_dashboard_log
	echo $( date +%s )" : "$_mon_date" : CYC="$_mon_cycle" : OPER_ENV="$( echo $_nod_operative_status | grep -o "[0-9]*" )"  : ACT_WARN="$_warning_detector" : SLURM_LOAD="$( echo $_srv_slurm_load_data | grep -o "[0-9]*" )" : NOD_LOAD="$( echo $_nod_load | grep -o "[0-9]*" )" : USR_LGN="$_login_users" : MAX_UP="$_max_node" : MIN_UP="$_min_node >> $_pg_dashboard_log

}

generate_mon_output_security ()
{
        ## MONITOR DETAIL ##
	## SECTION TITLES COLORS --

        ## SECURITY MON --

	echo "<html>" 
        echo "<meta http-equiv=\"refresh\" content=\"600\">" 
        echo "</html>"

        echo
        echo '\\' 
        echo "|< 100% 75% 25% >|"
        echo "|  $_color_title {{ :wiki:cyclops_title.png?nolink }}  |  $_sec_color_title [[$_wiki_mon_sec_path|$_sec_image_title]]  |"
        echo

        for _sec_mon_files in $( cat $_mon_cfg_file | grep ^SEC | cut -d';' -f2,6 | sort -n )
        do
                _sec_file=$_mon_path"/"$( echo $_sec_mon_files | cut -d';' -f2 )".txt"
                [ -f $_sec_file ] && cat $_sec_file 2>&1 || echo "ERROR: MON RESULTS FILE FROM $_sec_mon_files NO EXIST!" 
        done
}

generate_mon_output_services ()
{

        ## MONITOR DETAIL ##
	## SECTION TITLES COLORS --

        ## SERVICES MON --

        echo "<html>" 
        echo "<meta http-equiv=\"refresh\" content=\"600\">" 
        echo "</html>"

	echo
	echo '\\' 
	echo "|< 100% 75% 25% >|"
        echo "|  $_color_title {{ :wiki:cyclops_title.png?nolink }}  |  $_srv_color_title [[$_wiki_mon_srv_path|$_srv_image_title]]  |"
	echo  

        for _srv_mon_files in $( cat $_mon_cfg_file | grep ^SRV | cut -d';' -f2,6 | sort -n )
        do
                _srv_file=$_mon_path"/"$( echo $_srv_mon_files | cut -d';' -f2 )".txt"
                [ -f $_srv_file ] && cat $_srv_file 2>&1 || echo "ERROR: MON RESULTS FILE FROM $_srv_mon_files NO EXIST!" 
        done

}

generate_mon_output_nodes ()
{
        ## MONITOR DETAIL ##
        ## SECTION TITLES COLORS -

        ## NODES MON --

        echo "<html>" 
        echo "<meta http-equiv=\"refresh\" content=\"600\">" 
        echo "</html>"

        echo
        echo '\\' 
        echo "|< 100% 75% 25% >|"
        echo "|  $_color_title {{ :wiki:cyclops_title.png?nolink }}  |  $_nod_color_title [[$_wiki_mon_nod_path|$_nod_image_title]]  |"
        echo

        for _nod_mon_files in $( cat $_mon_cfg_file | grep ^NOD | cut -d';' -f2,6 | sort -n)
        do
                _nod_file=$_mon_path"/"$( echo $_nod_mon_files | cut -d';' -f2 )".txt"
                [ -f $_nod_file ] && cat $_nod_file 2>&1 || echo "ERROR: MON RESULTS FILE FROM $_nod_mon_files NO EXIST!"
        done

}

generate_mon_output_env ()
{
        ## MONITOR DETAIL ##
        ## SECTION TITLES COLORS -

	## ENVIRONMENT MON --

        echo "<html>" 
        echo "<meta http-equiv=\"refresh\" content=\"600\">" 
        echo "</html>"

        echo
        echo '\\' 
        echo "|< 100% 75% 25% >|"
        echo "|  $_color_title {{ :wiki:cyclops_title.png?nolink }}  |  $_env_color_title [[$_wiki_mon_env_path|$_env_image_title]]  |"
        echo

	for _env_mon_files in $( cat $_mon_cfg_file | grep ^ENV | cut -d';' -f2,6 | sort -n)
	do
		_env_file=$_mon_path"/"$( echo $_env_mon_files | cut -d';' -f2 )".txt"
		[ -f $_env_file ] && cat $_env_file 2>&1 || echo "ERROR: MON RESULTS FILE FROM $_env_mon_files NO EXITS!"
	done
}

generate_mon_output ()
{
	## MONITOR DETAIL ##

	## SECURITY MON --


        [  "$(echo $_sec_mon_dash_values | grep "DOWN" | wc -l )" -ne 0 ] && _sec_color_title=$_color_down ||  [ ! -z "$_sec_mon_dash_values" ] && _sec_color_title=$_color_up
        [  "$_sec_color_title" == "$_color_down" ] && _sec_image_title="{{ :wiki:securitystatus_red.gif |}}" || _sec_image_title="{{ :wiki:securitystatus_green.png |}}"

	_sec_print=$(generate_mon_output_security)

	## SERVICES MON --


        [  "$(echo $_srv_mon_dash_values | grep "DOWN" | wc -l )" -ne 0 ] && _srv_color_title=$_color_down ||  [ ! -z "$_srv_mon_dash_values" ] && _srv_color_title=$_color_up
        [  "$_srv_color_title" == "$_color_down" ] && _srv_image_title="{{ :wiki:servicesstatus_red.gif |}}" || _srv_image_title="{{ :wiki:servicesstatus_green.png |}}"

	_srv_print=$(generate_mon_output_services)

	## NODES MON --


	[  "$(echo $_nod_mon_dash_values | grep "DOWN" | wc -l )" -ne 0 ] && _nod_color_title=$_color_down ||  [ ! -z "$_nod_mon_dash_values" ] && _nod_color_title=$_color_up
        [  "$_nod_color_title" == "$_color_down" ] && export _nod_image_title="{{ :wiki:nodestatus_red.gif |}}" || export _nod_image_title="{{ :wiki:nodestatus_green.png |}}"

	_nod_print=$(generate_mon_output_nodes)

	## ENVIRONMENT MON --


        [  "$(echo $_env_mon_dash_values | grep "DOWN" | wc -l )" -ne 0 ] && _env_color_title=$_color_down ||  [ ! -z "$_env_mon_dash_values" ] && _env_color_title=$_color_up
        [  "$_env_color_title" == "$_color_down" ] && _env_image_title="{{ :wiki:envstatus_red.gif |}}" || _env_image_title="{{ :wiki:envstatus_green.png |}}"

	_env_print=$(generate_mon_output_env)

	## DASHBOARD PLUGINS --

	pre_processing_plugins	#-- PRE-PROCESSING PLUGINS

        ## DASHBOARD PROCESSING ## 

        _dash_print=$(generate_mon_output_dash)

	## GENERATE FILES ##

	echo "${_dash_print}" >$_mon_path/dashboard.txt
	echo "${_sec_print}" >$_mon_path/monsec.txt
	echo "${_srv_print}" >$_mon_path/monsrv.txt
	echo "${_nod_print}" >$_mon_path/monnod.txt
	echo "${_env_print}" >$_mon_path/monenv.txt

	echo "${_dash_print}" "${_sec_print}" "${_srv_print}" "${_nod_print}" "${_env_print}" >$_tmp_daemon


}

mon_section_security_background()
{

	$_script_path/$_sec_mon_script -v $_opt_show -i -m $_sec_mon_parameters > $_sensors_temp_path/$_sec_mon_wiki_dst.txt 
        echo $_sec_mon_field_num";"$? >> $_sensors_temp_path/$_sec_mon_script.$_pid.tmp
	cp $_sensors_temp_path/$_sec_mon_wiki_dst.txt $_mon_path/$_sec_mon_wiki_dst.txt

}

mon_section_security() 
{

	_sec_mon_begin_date=$(date +%s)	
	_sec_mon_begin_dash_date=$(date -d @$_sec_mon_begin_date +%H.%M.%S)

	for _sec_mon in $( cat $_mon_cfg_file | grep ^SEC | sort -n )
        do
		let "_sec_mon_field_num++"

                _sec_mon_pos=$( echo $_sec_mon | cut -d';' -f2 )
                _sec_mon_name=$( echo $_sec_mon | cut -d';' -f3 )
                _sec_mon_script=$( echo $_sec_mon | cut -d';' -f4 )
                _sec_mon_parameters=$( echo $_sec_mon | cut -d';' -f5 )
                _sec_mon_wiki_dst=$( echo $_sec_mon | cut -d';' -f6 )

		_sec_mon_dash_titles=$_sec_mon_dash_titles";** [[.:"$_sec_mon_wiki_dst"|"$( echo $_sec_mon_name | tr '[:lower:]' '[:upper:]' )"]] **"

		[ -z "$_sec_mon_parameters" ] && _sec_mon_parameters="all"

		mon_section_security_background &

        done
	wait

        _sec_mon_status=";"$( cat $_sensors_temp_path/$_sec_mon_script.$_pid.tmp | sort -t\; -k1,1n | cut -d';' -f2 | tr '\n' ';' )
        [ -f $_sensors_temp_path/$_sec_mon_script.$_pid.tmp ] && rm $_sensors_temp_path/$_sec_mon_script.$_pid.tmp

	_sec_mon_end_date=$(date +%s)

	let "_sec_mon_time_elapsed=_sec_mon_end_date - _sec_mon_begin_date"
	_sec_mon_time_elapsed=$( date -d @$_sec_mon_time_elapsed +%M.%S)
	#[ "$_sec_mon_time_elapsed" == "00.00" ] && _sec_mon_time_elapsed="DOWN mon.err"

        _sec_mon_dash_values=$( echo -e $_sec_mon_status | sed -e 's/;0/;UP/g' -e 's/\;\([0-9]\)/;DOWN\.\1/g' -e 's/;$//' )

}

mon_section_services_background()
{

	## BEWARE WITH OTHER SCRIPTS , PARAMETERS ARE AJUST FOR SLURM MON JOB SCRIPT
	## IA PARAMETER DISABLE, FAILS AND DONT WORK PROPERLY

	case "$_srv_mon_script" in
	service.slurm.sh)
		$_script_path/$_srv_mon_script -v $_opt_show -f $_config_path_srv/$_srv_mon_parameters > $_sensors_temp_path/$_srv_mon_wiki_dst.txt 
        	echo $_srv_mon_field_num";"$? >> $_sensors_temp_path/$_srv_mon_script.$_pid.tmp
	;;
	service.quota.sh)
		$_script_path/$_srv_mon_script -v $_opt_show -n $_srv_mon_parameters > $_sensors_temp_path/$_srv_mon_wiki_dst.txt
        	echo $_srv_mon_field_num";"$? >> $_sensors_temp_path/$_srv_mon_script.$_pid.tmp
	;;
	esac

	cp $_sensors_temp_path/$_srv_mon_wiki_dst.txt $_mon_path/$_srv_mon_wiki_dst.txt

}

mon_section_services() 
{
	_srv_mon_begin_date=$(date +%s)
	_srv_mon_begin_dash_date=$(date -d @$_srv_mon_begin_date +%H.%M.%S)

	_srv_mon_ctrl=$( cat $_mon_cfg_file | grep ^SRV | wc -l )

        if [ "$_srv_mon_ctrl"  -eq 0 ]
        then
                _srv_mon_time_elapsed="DISABLE not configured"
		_srv_color_title=$_color_disable
        else

	        for _srv_mon in $( cat $_mon_cfg_file | grep ^SRV | sort -n )
		do
			let "_srv_mon_field_num++"

               		_srv_mon_pos=$( echo $_srv_mon | cut -d';' -f2 )
                	_srv_mon_name=$( echo $_srv_mon | cut -d';' -f3 )
                	_srv_mon_script=$( echo $_srv_mon | cut -d';' -f4 )
                	_srv_mon_parameters=$( echo $_srv_mon | cut -d';' -f5 )
                	_srv_mon_wiki_dst=$( echo $_srv_mon | cut -d';' -f6 )

			_srv_mon_dash_titles=$_srv_mon_dash_titles";** [[.:"$_srv_mon_wiki_dst"|"$( echo $_srv_mon_name | tr '[:lower:]' '[:upper:]' )"]] **"

			[ -z "$_srv_mon_parameters" ] && _srv_mon_parameters="all"

			mon_section_services_background &

        	done
		wait

        	_srv_mon_status=";"$( cat $_sensors_temp_path/service.*.$_pid.tmp | sort -t\; -k1,1n | cut -d';' -f2 | tr '\n' ';' )

		for _file in $( ls -1 $_sensors_temp_path/service.*.$_pid.tmp ) 
		do
        		[ -f $_file ] && rm $_file 
		done

		_srv_mon_end_date=$(date +%s)

		let "_srv_mon_time_elapsed=_srv_mon_end_date - _srv_mon_begin_date"
       		_srv_mon_time_elapsed=$( date -d @$_srv_mon_time_elapsed +%M.%S)

        	_srv_mon_dash_values=$( echo -e $_srv_mon_status | sed -e 's/;0/;UP/g' -e 's/\;\([1-9]\)/;DOWN/g' -e 's/;$//' ) 
	fi

}

mon_section_nodes_background()
{

	$_script_path"/"$_nod_mon_script -p -i -v $_opt_show -m $_nod_mon_parameters > $_sensors_temp_path/$_nod_mon_wiki_dst.txt	## PARALLEL MON LAUNCH
	#$_script_path"/"$_nod_mon_script -i -v $_opt_show -m $_nod_mon_parameters > $_sensors_temp_path/$_nod_mon_wiki_dst.txt		## SERIAL MON LAUNCH
	echo $_nod_mon_field_num";"$? >> $_sensors_temp_path/$_nod_mon_script.$_pid.tmp
	cp $_sensors_temp_path/$_nod_mon_wiki_dst.txt  $_mon_path/$_nod_mon_wiki_dst.txt

}

mon_section_nodes() 
{
	_nod_mon_begin_date=$(date +%s)
	_nod_mon_begin_dash_date=$(date -d @$_nod_mon_begin_date +%H.%M.%S)

        for _nod_mon in $( cat $_mon_cfg_file | grep ^NOD | sort -n )
        do
		let "_nod_mon_field_num++"

                _nod_mon_pos=$( echo $_nod_mon | cut -d';' -f2 )
                _nod_mon_name=$( echo $_nod_mon | cut -d';' -f3 )
                _nod_mon_script=$( echo $_nod_mon | cut -d';' -f4 )
                _nod_mon_parameters=$( echo $_nod_mon | cut -d';' -f5 )
                _nod_mon_wiki_dst=$( echo $_nod_mon | cut -d';' -f6 )

		#_nod_mon_dash_titles=$_nod_mon_dash_titles";"$_nod_mon_name  ## TITLES WITHOUT LINKS
		_nod_mon_dash_titles=$_nod_mon_dash_titles";** [[.:"$_nod_mon_wiki_dst"|"$( echo $_nod_mon_name | tr '[:lower:]' '[:upper:]' )"]] **"

		[ -z "$_nod_mon_parameters" ] && _nod_mon_parameters="all"

		mon_section_nodes_background & 

        done 
	wait


	#_nod_mon_status=";"$( cat $_sensors_temp_path/$_nod_mon_script.$_pid.tmp | sort -t\; -k1,1n | cut -d';' -f2 | tr '\n' ';' )
        #_nod_mon_dash_values=$( echo -e $_nod_mon_status | sed -e 's/;0/;UP/g' -e 's/\;\([0-9]\)/;DOWN\.\1/g' -e 's/;$//' )

	_nod_mon_dash_values=$( 
		cat $_sensors_temp_path/$_nod_mon_script.$_pid.tmp | 
		sort -t\; -k1,1n | 
		awk -F\; '
			$2 == "0" || $2 == "00" { _out=_out";UP" } 
			$2 == "2" || $2 == "10" { _out=_out";DOWN" } 
			$2 == "11" { _out=_out";FAIL" } 
			$2 == "90" { _out=_out";UNK" } 
			$2 == "12" { _out=_out";MARK" } 
			END { print _out }' 
			)
	[ -z "$_nod_mon_dash_values" ] && _nod_mon_dash_values=";DISABLE"

	### DEBUG
	#echo "${_nod_mon_dash_values}" > $_cyclops_temp_path/ik.debug.monitoring.txt
	### DEBUG

	[ -f $_sensors_temp_path/$_nod_mon_script.$_pid.tmp ] && rm $_sensors_temp_path/$_nod_mon_script.$_pid.tmp


	_nod_mon_end_date=$(date +%s)
        let "_nod_mon_time_elapsed=_nod_mon_end_date - _nod_mon_begin_date"
        _nod_mon_time_elapsed=$( date -d @$_nod_mon_time_elapsed +%M.%S)
	! [[ "$_nod_mon_time_elapsed" =~ 0[0-2].[0-5][0-9] ]] && _nod_mon_time_elapsed="FAIL exceded mon time ($_nod_mon_time_elapsed)"
	[ "$_nod_mon_time_elapsed" == "00.00" ] && _nod_mon_time_elapsed="DOWN mon.err"

}

mon_section_env_background()
{

        $_script_path"/"$_env_mon_script -i -v $_opt_show -m $_env_mon_parameters > $_sensors_temp_path/$_env_mon_wiki_dst.txt 
        echo $_env_mon_field_num";"$? >> $_sensors_temp_path/$_env_mon_script.$_pid.tmp
	cp $_sensors_temp_path/$_env_mon_wiki_dst.txt $_mon_path/$_env_mon_wiki_dst.txt

}

mon_section_env()
{
        _env_mon_begin_date=$(date +%s)
        _env_mon_begin_dash_date=$(date -d @$_env_mon_begin_date +%H.%M.%S)

	_env_mon_ctrl=$( cat $_mon_cfg_file | grep ^ENV | wc -l )

	if [ "$_env_mon_ctrl"  -eq 0 ]
	then
		_env_mon_time_elapsed="DISABLE not configured"
		_env_color_title=$_color_disable
	else
	        for _env_mon in $( cat $_mon_cfg_file | grep ^ENV | sort -n )
        	do
                	let "_env_mon_field_num++"

       		        _env_mon_pos=$( echo $_env_mon | cut -d';' -f2 )
                	_env_mon_name=$( echo $_env_mon | cut -d';' -f3 )
                	_env_mon_script=$( echo $_env_mon | cut -d';' -f4 )
               		_env_mon_parameters=$( echo $_env_mon | cut -d';' -f5 )
                	_env_mon_wiki_dst=$( echo $_env_mon | cut -d';' -f6 )

                	_env_mon_dash_titles=$_env_mon_dash_titles";** [[.:"$_env_mon_wiki_dst"|"$( echo $_env_mon_name | tr '[:lower:]' '[:upper:]' )"]] **"

                	[ -z "$_env_mon_parameters" ] && _env_mon_parameters="all"

                	mon_section_env_background &

        	done
        	wait

	        #_env_mon_status=";"$( cat $_sensors_temp_path/$_env_mon_script.$_pid.tmp | sort -t\; -k1,1n | cut -d';' -f2 | tr '\n' ';' )

	        _env_mon_end_date=$(date +%s)
	        let "_env_mon_time_elapsed=_env_mon_end_date - _env_mon_begin_date"
    	    	_env_mon_time_elapsed=$( date -d @$_env_mon_time_elapsed +%M.%S)
	        ! [[ "$_env_mon_time_elapsed" =~ 0[0-2].[0-5][0-9] ]] && _env_mon_time_elapsed="FAIL exceded mon time ($_env_mon_time_elapsed)"
	        [ "$_env_mon_time_elapsed" == "00.00" ] && _env_mon_time_elapsed="DOWN mon.err"

       		#_env_mon_dash_values=$( echo -e $_env_mon_status | sed -e 's/;0/;UP/g' -e 's/\;\([0-9]\)/;DOWN\.\1/g' -e 's/;$//' )
		_env_mon_dash_values=$( 
			cat $_sensors_temp_path/$_env_mon_script.$_pid.tmp | 
			sort -t\; -k1,1n | 
			awk -F\; '
				$2 == "0" || $2 == "00" { _out=_out";UP" } 
				$2 == "2" || $2 == "10" { _out=_out";DOWN" } 
				$2 == "11" { _out=_out";FAIL" } 
				$2 == "90" { _out=_out";UNK" } 
				$2 == "12" { _out=_out";MARK" } 
				END { print _out }' 
				)
      		[ -f $_sensors_temp_path/$_env_mon_script.$_pid.tmp ] && rm $_sensors_temp_path/$_env_mon_script.$_pid.tmp
		[ -z "$_env_mon_dash_values" ] && _env_mon_dash_values=";DISABLE"
	fi
}

alert_mail_sender()
{
	unset _alert_mail_msg_act
	unset _alert_mail_msg_dis

	for _alert_waiting in $( awk -F\; '$1 == "ALERT" && $7 !~ "[13]" {$6=strftime("%d-%m-%Y %H:%M",$6 ); print $4";"$5";"$6";"$7 }' $_sensors_sot  )
	do
		_alert_mail_status=$( echo $_alert_waiting | cut -d';' -f4 )  
		_alert_mail_host=$( echo $_alert_waiting | cut -d';' -f1 )
		_alert_mail_data=$( echo $_alert_waiting | cut -d';' -f2 )
		_alert_mail_date=$( echo $_alert_waiting | cut -d';' -f3 )

		case "$_alert_mail_status" in
		0)
			_alert_mail_msg_act=$_alert_mail_msg_act"\t$_alert_mail_date: Host: $_alert_mail_host: Sensor: $_alert_mail_data - Alert Active\n"
			[ -z "$_alert_mail_host_list_act" ] && _alert_mail_host_list_act=$_alert_mail_host || _alert_mail_host_list_act=$_alert_mail_host_list_act","$_alert_mail_host
			sed -i -e 's/\(^ALERT;.*;\)0$/\11/' $_sensors_sot 2>/dev/null
		;;
		2)
			_alert_mail_msg_dis=$_alert_mail_msg_dis"\t$_alert_mail_date: Host: $_alert_mail_host: Sensor: $_alert_mail_data - Alert disable\n"
			[ -z "$_alert_mail_host_list_dis" ] && _alert_mail_host_list_dis=$_alert_mail_host || _alert_mail_host_list_dis=$_alert_mail_host_list_dis","$_alert_mail_host
                        sed -i -e 's/\(^ALERT;.*;\)2$/\13/' $_sensors_sot 2>/dev/null
		;;
		esac
	done

	if [ ! -z "$_alert_mail_msg_act" ] 
	then
		[ "$_lib_node_group" == "YES" ] && _alert_mail_hosts_list_act=$( node_group $_alert_mail_host_list_act ) || _alert_mail_host_list_act="One or Many hosts" 
		_alert_mail_num_hosts_act=$( echo -e $_alert_mail_msg_act | wc -l )
		_alert_mail_msg_act="Cyclops System Detect this system alerts active:\n\n$_alert_mail_msg_act"
		_alert_mail_sub_act="$_email_alert_subject_prefix : ACTIVE ALERT(s) : $_alert_mail_num_hosts_act : Host List : $_alert_mail_hosts_list_act" 
		echo -e "${_alert_mail_msg_act}" | mail -r $_email_from_addr -s $_alert_mail_sub_act -S smtp="$_email_alert_smtp_ip:$_email_alert_smtp_port" $_email_alert_addr
	fi

	if [ ! -z "$_alert_mail_msg_dis" ] 
	then
		[ "$_lib_node_group" == "YES" ] && _alert_mail_hosts_list_dis=$( node_group $_alert_mail_host_list_dis ) || _alert_mail_host_list_dis="One or Many hosts" 
		_alert_mail_num_hosts_dis=$( echo -e $_alert_mail_msg_dis | wc -l )
		_alert_mail_msg_dis="Cyclops System Detect this system alerts has been disable:\n\n$_alert_mail_msg_dis"
		_alert_mail_sub_dis="$_email_alert_subject_prefix : ACTIVE ALERT(s) : $_alert_mail_num_hosts_dis : Host List : $_alert_mail_hosts_list_dis" 
		echo -e "${_alert_mail_msg_dis}" | mail -r $_email_from_addr -s $_alert_mail_sub_dis -S smtp="$_email_alert_smtp_ip:$_email_alert_smtp_port" $_email_alert_addr
	fi
}

msg_mail_sender()
{
	for _msg_waiting in $( awk -F\; '$1 == "INFO" && $7 == 0 {$3=strftime("%d-%m-%Y %H:%M",$3) ; $4=strftime("%d-%m-%Y %H:%M",$4); print $3";"$4";"$5";"$6 }' $_sensors_sot )
	do
		_msg_mail_birth=$( echo $_msg_waiting | cut -d';' -f1 )
		_msg_mail_death=$( echo $_msg_waiting | cut -d';' -f2 )
		_msg_mail_priority=$( echo $_msg_waiting | cut -d';' -f3 | sed -e 's/^100$/INFO/' -e 's/^80$/LOW/' -e 's/^30$/MEDIUM/' -e 's/^5$/HIGH/' )
		_msg_mail_data=$( echo $_msg_waiting | cut -d';' -f4 )

		_msg_mail_sub="$_msg_mail_priority CYCLOPS MESSAGE: $_msg_mail_birth"
		_msg_mail_msg="Cyclops Message:\n$_msg_mail_data\n\nThis Message will be destroy at $_msg_mail_death\n\nRegards\nCyclops Team\n"

		echo -e $_msg_mail_msg | mail -r $_email_from_addr -s $_msg_mail_sub -S smtp="$_email_alert_smtp_ip:$_email_alert_smtp_port" $_email_alert_addr 2>/dev/null
                _mail_err=$?
                [ "$_mail_err" -eq 0 ] && sed -i -e 's/\(^INFO;.*;\)0$/\11/' $_sensors_sot

	done

}

ha_check()
{

	_ha_status_ctrl=0
	_ha_role=$( cat $_ha_role_file 2>/dev/null )
	[ -z "$_ha_role" ] && echo SLAVE > $_ha_role_file && _ha_role="SLAVE"

	for _ha_line in $( cat $_ha_cfg_file | egrep -v "^#|$_hostname" )
	do
		_ha_type=$( echo $_ha_line | cut -d';' -f1 )
		_ha_string=$( echo $_ha_line | cut -d';' -f2 )

		case "$_ha_type" in
		IP)
			_ha_check_res=$( /sbin/ip addr | grep " $_ha_string\/" 2>&1 >/dev/null ; echo $? ) 
			[ "$_ha_check_res" -ne 0 ] && let "_ha_status_ctrl++"
		;;
		FS)
			_ha_check_res=$( mount | grep $_ha_string 2>&1 >/dev/null ; echo $? )
			[ "$_ha_check_res" -ne 0 ] && let "_ha_status_ctrl++"
		;;
		SV)
			_ha_check_res=$( service $_ha_string status 2>&1 >/dev/null ; echo $? )
			[ "$_ha_check_res" -ne 0 ] && let "_ha_status_ctrl++" 
		;;
		ND)
			_ha_master_mirror=$_ha_string
			[ ! -z $_ha_master_mirror ] && _ha_check_mirror=$( ssh -o ConnectTimeout=10 $_ha_master_mirror "[ -f $_ha_role_file ] && cat $_ha_role_file || echo \"NOFILE\"" 2>/dev/null )
		;;
		esac
	done

	case "$_ha_role" in
	MASTER)
		if [ "$_ha_status_ctrl" == "0" ] 
		then
			_ha_role_active=$_hostname 
			_cyc_ha_master_node=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $5}' $_sensors_sot )

			[ "$_cyc_ha_master_node" != "$_hostname" ] && sed -i "s/\(CYC;0006;HA;ENABLED;\).*/\1$_hostname/" $_sensors_sot

			case "$_ha_check_mirror" in
			"MASTER")
				#### FORCE MIRROR TO SLAVE ####
				echo "$( date +%s );$_hostname;SPLIT MASTER, FORCE SLAVE" >> $_mon_log_path/$_mon_log_file
				ssh -o ConnectTimeout=10 $_ha_master_mirror "echo SLAVE > $_ha_role_file" 2>&1 >/dev/null

				_cyc_ha_color=$_color_mark
				_cyc_ha_font="red"
			;;
			"SLAVE")
				echo "$( date +%s );$_hostname;GOLD STATUS, STILL STATUS" >> $_mon_log_path/$_mon_log_file
				echo "$( date +%s );$_hostname;	SYNC CYC OPTIONS STATUS TO SLAVE" >> $_mon_log_path/$_mon_log_file

				scp $_sensors_sot $_ha_master_mirror:$_sensors_sot 2>> $_mon_log_path/$_mon_log_file

				_cyc_ha_color=$_color_ok
				_cyc_ha_font="white"
			;;
			"NOFILE")
				echo "$( date +%s );$_hostname;SLAVE NOT CONFIG, FORCE SLAVE CONFIG" >> $_mon_log_path/$_mon_log_file

				ha_master_sync &

				_cyc_ha_color=$_color_check
				_cyc_ha_font="green"
			;;
			"")
				echo "$( date +%s );$_hostname;SLAVE CONNECTING ERROR, WAITING RESPONSE" >> $_mon_log_path/$_mon_log_file

				_cyc_ha_color=$_color_mark
				_cyc_ha_font="green"

			;;
			*)
				_cyc_ha_color=$_color_unk
				_cyc_ha_font="white"
			;;
			esac
		else
			case "$_ha_check_mirror" in
			"MASTER")
				echo "$( date +%s );$_hostname;LOST RESOURCES, GOING SLAVE" >> $_mon_log_path/$_mon_log_file
				ha_get_slave

				_cyc_ha_color=$_color_up
				_cyc_ha_font="black"
			;;
			"SLAVE")
				echo "$( date +%s );$_hostname;MASTER NO RESOURCES, SLAVE , QUORUM ACTIONS FOR BREAK" >> $_mon_log_path/$_mon_log_file
				echo $_ha_status_ctrl > $_ha_role_file

				_cyc_ha_color=$_color_disable
				_cyc_ha_font="black"
			;;
			"NOFILE")
				_cyc_ha_color=$_color_mark
				_cyc_ha_font="red"
				echo "$( date +%s );$_hostname;SLAVE NOT OR MISS CONFIGURATED, FORCE MASTER" >> $_mon_log_path/$_mon_log_file
				ha_get_master
				ha_master_sync &
			;;
			[0-9])
				_cyc_ha_color=$_color_mark
				_cyc_ha_font="black"
				echo "$( date +%s );$_hostname;MON NO MASTER, SLAVE TIE, QUORUM ACTIONS FOR BREAK" >> $_mon_log_path/$_mon_log_file

				[ "$_ha_role" -lt "$_ha_check_mirror" ] && ha_get_master
				[ "$_ha_role" -gt "$_ha_check_mirror" ] && ha_get_slave

				if [ "$_ha_role" -eq "$_ha_check_mirror" ]
				then
					_ha_break_tie=$( grep ^ND $_ha_cfg_file | cut -d';' -f2 | head -n 1 )
					[ "$_ha_break_tie" == "$_hostname" ] && ha_get_master || ha_get_slave
				fi
			;;
			"")
				_cyc_ha_color=$_color_mark
				_cyc_ha_font="black"
                                echo "$( date +%s );$_hostname;SLAVE CONNECTING ERROR, WAITING RESPONSE" >> $_mon_log_path/$_mon_log_file
                                echo $_ha_status_ctrl > $_ha_role_file
			;;
			*)
				_cyc_ha_color=$_color_unk
				_cyc_ha_font="white"
                                echo "$( date +%s );$_hostname;SLAVE UNKNOWN STATUS, WAITING RESPONSE" >> $_mon_log_path/$_mon_log_file
			;;
			esac
		fi
	;;
	SLAVE)
		if [ "$_ha_status_ctrl" == "0" ] 
		then
			echo "$( date +%s );$_hostname;WIN RESOURCES, GOING MASTER" >> $_mon_log_path/$_mon_log_file
			_cyc_ha_color=$_color_up
			_cyc_ha_font="black"
			ha_get_master
		else
			case "$_ha_check_mirror" in
			"MASTER") 
				echo "$( date +%s );$_hostname;NOT RESOURCES, STILL SLAVE" >> $_mon_log_path/$_mon_log_file
				_ha_role_active=$_ha_master_mirror
				ha_slave_actions &
			;;
			"SLAVE")
				echo "$( date +%s );$_hostname;MON NO MASTER, SLAVE TIE, QUORUM ACTIONS FOR BREAK" >> $_mon_log_path/$_mon_log_file
				echo $_ha_status_ctrl > $_ha_role_file
			;;
			"NOFILE")
				_cyc_ha_color=$_color_mark
				_cyc_ha_font="red"
				echo "$( date +%s );$_hostname;SLAVE NOT OR MISS CONFIGURATED, FORCE MASTER" >> $_mon_log_path/$_mon_log_file
				ha_get_master
				ha_master_sync &
			;;
			[0-9])
				echo "$( date +%s );$_hostname;MON NO MASTER, SLAVE TIE, QUORUM ACTIONS FOR BREAK" >> $_mon_log_path/$_mon_log_file
				echo $_ha_status_ctrl > $_ha_role_file
			;;
			"")
				_cyc_ha_color=$_color_mark
				_cyc_ha_font="red"
				ha_get_master
			;;
			esac
		fi
	;;
	[0-9])
		if [ "$_ha_status_ctrl" == "0" ]
		then
			echo "$( date +%s );$_hostname;RESOURCES MINE, GOING MASTER" >> $_mon_log_path/$_mon_log_file
			_cyc_ha_color=$_color_up
			_cyc_ha_font="black"
			ha_get_master
		else
			case "$_ha_check_mirror" in
			"MASTER")
				echo "$( date +%s );$_hostname;LOST QUORUM, GOING SLAVE" >> $_mon_log_path/$_mon_log_file
				_ha_role_active=$_ha_master_mirror
				ha_get_slave
			;;
			"SLAVE")
				echo "$( date +%s );$_hostname;WIN QUORUM, FORCE MASTER" >> $_mon_log_path/$_mon_log_file
				_cyc_ha_color=$_color_up
				_cyc_ha_font="black"
				ha_get_master
			;;
			"NOFILE")
				echo "$( date +%s );$_hostname;SLAVE NOT OR MISS CONFIGURED, FORCE MASTER" >> $_mon_log_path/$_mon_log_file
				ha_get_master	
				ha_master_sync &
			;;
			[0-9])
				echo "$( date +%s );$_hostname;MON NO MASTER, SLAVE TIE, QUORUM ACTIONS FOR BREAK" >> $_mon_log_path/$_mon_log_file

				_cyc_ha_color=$_color_mark
				_cyc_ha_font="black"

				[ "$_ha_role" -lt "$_ha_check_mirror" ] && ha_get_master
				[ "$_ha_role" -gt "$_ha_check_mirror" ] && ha_get_slave
				
				if [ "$_ha_role" -eq "$_ha_check_mirror" ]
				then
					_ha_break_tie=$( grep ^ND $_ha_cfg_file | cut -d';' -f2 | head -n 1 )
					[ "$_ha_break_tie" == "$_hostname" ] && ha_get_master || ha_get_slave
				fi
			;;
			"")
				echo "$( date +%s );$_hostname;QUORUM WIN NOT SLAVE RESPONSE, FORCE MASTER" >> $_mon_log_path/$_mon_log_file
				_cyc_ha_color=$_color_mark
				_cyc_ha_font="red"
				ha_get_master
			;;
			esac	
		fi
	;;
	esac
}

ha_slave_actions()
{
	_rsync_pid_file_slave=$_cyclops_temp_path"/mon_rsync_slave.pid"

	if [ ! -z "$_base_path" ]
	then
		if [ -f "$_rsync_pid_file_slave" ]
		then
			_rsync_pid_slave=$( cat $_rsync_pid_file_slave )
			_rsync_pid_state=$( ps -eFl | awk -v _p="$_rsync_pid_slave" 'BEGIN { _s="AVAIL" } $4 == _p { _s="SYNC" } END { print _s }' ) 
			echo "$(date +%s);$_hostname;MON PREVIOUS SYNC PID FILE EXISTING [$_rsync_pid_slave] STATUS [$_rsync_pid_state] ( ME:$_ha_role )" >> $_mon_log_path/$_mon_log_file
			if [ "$_rsync_pid_state" == "AVAIL" ]
			then
				echo "$(date +%s);$_hostname;MON END LOCAL SYNC FROM [$_rsync_pid_slave] $_ha_master_mirror ( ME:$_ha_role )" >> $_mon_log_path/$_mon_log_file
				rm -f $_rsync_pid_file_slave
				echo "$(date +%s);$_hostname;MON START LOCAL SYNC FROM $_ha_master_mirror ( ME:$_ha_role )" >> $_mon_log_path/$_mon_log_file
				rsync --delete -auz --exclude-from $_ha_sync_exc $_ha_master_mirror:$_base_path/ $_base_path/ 2> $_mon_log_path/$( date +%H%M ).rsync.$_hostname".sync.err.log" > $_mon_log_path/$( date +%H%M ).rsync.$_hostname".sync.log" &
				echo $! > $_rsync_pid_file_slave 
			else
				echo "$(date +%s);$_hostname;MON STALL LOCAL SYNC FROM [$_rsync_pid_slave] $_ha_master_mirror ( ME:$_ha_role ) WAITING FOR LAST SYNC" >> $_mon_log_path/$_mon_log_file
			fi
		else
			echo "$(date +%s);$_hostname;MON START LOCAL SYNC FROM $_ha_master_mirror ( ME:$_ha_role )" >> $_mon_log_path/$_mon_log_file
			rsync --delete -auz --exclude-from $_ha_sync_exc $_ha_master_mirror:$_base_path/ $_base_path/ 2> $_mon_log_path/$( date +%H%M ).rsync.$_hostname".sync.err.log" > $_mon_log_path/$( date +%H%M ).rsync.$_hostname".sync.log" &
			echo $! > $_rsync_pid_file_slave
		fi
		scp $_ha_master_mirror:$_sensors_sot $_sensors_sot 2>> $_mon_log_path/$_mon_log_file
		echo "$(date +%s);$_hostname;CYCLOPS WORKSTATUS FILE SYNC EXIT: [$?]" >> $_mon_log_path/$_mon_log_file 
	else
		echo "$(date +%s);$_hostname;ERR BASE PATH VARIABLE EMPTY ( ME:$_ha_role )" >> $_mon_log_path/$_mon_log_file
	fi
}

ha_master_sync()
{
	echo "$(date +%s);$_hostname;MON SLAVE START SYNC TO $_ha_master_mirror ( $_ha_role )" >> $_mon_log_path/$_mon_log_file
	rsync -auz --exclude-from $_ha_sync_exc $_base_path/ $_ha_master_mirror:$_base_path/ 2>> $_mon_log_path/$_mon_log_file
	#rsync -auc --exclude-from $_ha_sync_exc $_sensors_sot $_ha_master_mirror:$_sensors_sot 2>> $_mon_log_path/$_mon_log_file
	scp $_sensors_sot $_ha_master_mirror:$_sensors_sot 2>> $_mon_log_path/$_mon_log_file
	echo "$(date +%s);$_hostname;MON SLAVE END SYNC TO $_ha_master_mirror ( $_ha_role )" >> $_mon_log_path/$_mon_log_file
}

ha_get_master()
{
	echo MASTER > $_ha_role_file
	sed -i "s/\(CYC;0006;HA;ENABLED;\).*/\1$_hostname/" $_sensors_sot
	_ha_role_active=$_hostname
	_ha_role="MASTER"
}

ha_get_slave()
{
	echo SLAVE > $_ha_role_file
	_ha_role="SLAVE"
}

mon_enabled()
{

	echo "$( date +%s );$_hostname;MON LAUNCH ( $_ha_role )" >> $_mon_log_path/$_mon_log_file

	[ "$_cyclops_monsec_status" == "ENABLED" ] && mon_section_security || _sec_color_title=$_color_disable
	[ "$_cyclops_monsrv_status" == "ENABLED" ] && mon_section_services || _srv_color_title=$_color_disable 
	[ "$_cyclops_monnod_status" == "ENABLED" ] && mon_section_nodes || _nod_color_title=$_color_disable
	[ "$_cyclops_monenv_status" == "ENABLED" ] && mon_section_env || _env_color_title=$_color_disable

	if [ "$_cyclops_mail_status" == "ENABLED" ]
	then
		alert_mail_sender &
		msg_mail_sender &
	fi


	generate_mon_output

	allocate_mon_files

	post_processing_plugins
}


mon_testing()
{
	echo "$( date +%s );$_hostname;MON LAUNCH ( $_ha_role ) TESTING MODE" >> $_mon_log_path/$_mon_log_file

	[ "$_cyclops_monsec_status" == "ENABLED" ] && mon_section_security || _sec_color_title=$_color_disable
	[ "$_cyclops_monsrv_status" == "ENABLED" ] && mon_section_services || _srv_color_title=$_color_disable 
	[ "$_cyclops_monnod_status" == "ENABLED" ] && mon_section_nodes || _nod_color_title=$_color_disable
	[ "$_cyclops_monenv_status" == "ENABLED" ] && mon_section_env || _env_color_title=$_color_disable

	generate_mon_output
	allocate_mon_files

	#post_processing_plugins
}

mon_intervention()
{
	echo "$( date +%s );$_hostname;MON LAUNCH ( $_ha_role ) INTERVENTION MODE" >> $_mon_log_path/$_mon_log_file
	
	[ "$_cyclops_monsec_status" == "ENABLED" ] && mon_section_security || _sec_color_title=$_color_disable
	[ "$_cyclops_monsrv_status" == "ENABLED" ] && mon_section_services || _srv_color_title=$_color_disable 
	[ "$_cyclops_monnod_status" == "ENABLED" ] && mon_section_nodes || _nod_color_title=$_color_disable
	[ "$_cyclops_monenv_status" == "ENABLED" ] && mon_section_env || _env_color_title=$_color_disable

	generate_mon_output
	allocate_mon_files

}

mon_drain()
{
	echo "$( date +%s );$_hostname;MON LAUNCH ( $_ha_role ) DRAIN MODE" >> $_mon_log_path/$_mon_log_file

	generate_mon_output
        allocate_mon_files
}


pre_processing_plugins()
{
	#### Convert MON WIKI output to COMMAS output

	[ "$_cyclops_monnod_status" == "ENABLED" ] && _nod_commas_output=$( echo "${_nod_print}" | tr '|' ';' | grep ";" | sed -e 's/\ *;\ */;/g' -e '/^$/d' -e '/:wiki:/d' -e "s/$_color_unk/UNK/g" -e "s/$_color_up/UP/g" -e "s/$_color_down/DOWN/g" -e "s/$_color_mark/MARK/g" -e "s/$_color_fail/FAIL/g" -e "s/$_color_check/CHECK/g" -e "s/$_color_ok/OK/g" -e "s/$_color_disable/DISABLE/g" -e "s/$_color_title//g" -e "s/$_color_header//g" -e 's/^;//' -e 's/;$//' -e '/</d' -e 's/((.*))//' -e '/:::/d' | awk -F\; 'BEGIN { OFS=";" ; _print=0 } { if ( $1 == "family" ) { _print=1 } ; if ( $2 == "name" ) { _print=0 } ; if ( _print == 1 ) { print $0 }}' )
	[ "$_cyclops_monsec_status" == "ENABLED" ] && _sec_commas_output=$( echo "${_sec_print}" | tr '|' ';'  | sed -e 's/; */;/g' -e 's/ *;/;/g' -e '/\[/d' -e '/>/d' -e '/^$/d' )
	[ "$_cyclops_monenv_status" == "ENABLED" ] && _env_commas_output=$( echo "${_env_print}" | tr '|' ';' | grep ";" | sed -e 's/\ *;\ */;/g' -e '/^$/d' -e '/:wiki:/d' -e "s/$_color_unk/UNK/g" -e "s/$_color_up/UP/g" -e "s/$_color_down/DOWN/g" -e "s/$_color_mark/MARK/g" -e "s/$_color_fail/FAIL/g" -e "s/$_color_check/CHECK/g" -e "s/$_color_ok/OK/g" -e "s/$_color_disable/DISABLE/" -e "s/$_color_title//g" -e "s/$_color_header//g" -e 's/^;//' -e 's/;$//' -e '/</d' -e 's/((.*))//' -e '/:::/d' ) 

	mon_node_running_pg     #-- SHOW CPU AVERAGE FROM ALL NODES (TOTAL NODE AVERAGE TOO)
        mon_node_operative_pg   #-- SHOW FULL OPERATING NODES PERCENTAGE (IF ONE SENSORS FAILS NODE IS NOT FULL OPERATING)
        mon_slurm_running_pg    #-- SHOW ACTIVE COMPUTE NODES (SLURM JOBS)
	mon_uptime_edges_pg     #-- SHOW UPTIMES LOWEST AND HIGHEST WITH HISTORY HIGHEST (DISABLE REFACTORING WITH NEW VERSION)
        mon_login_users_pg      #-- SHOW EXTERNAL USERS LOGIN IN THE SYSTEM
        mon_active_alerts_pg    #-- SHOW ALERTS FROM SOT FILE (USED IT FOR MAIL WARNINGS)
        mon_sent_alerts_pg      #-- SHOW SENT ALERTS FROM ACTIVE SOT FILE ALERTS (MAIL WARNING)
#	mon_zombie_pg           #-- SHOW ZOMBIE EATING BRAINS WHEN ZOMBIE PROCESS STATUS HAPPENS IN ANY NODE >> LINK WITH mon_node_operative_pg ## DISABLE SINCE CHANGE DIRECTIVE (FAIL > MARK)
        mon_warnings_pg         #-- SHOW ACTIVE WARNINGS ALARMS IN ENVIRONMENT AND NODE MONITORING
	mon_env_status_pg	#-- SHOW STATUS OF PRODUCTIVE ENVIRONMENT (defined in /etc/cyclops/critical.res.cfg )
	mon_usr_ctrl_pg		#-- SHOW ADMINISTRATIVE USERS ACTIVE IN THE SYSTEM ( defined in /etc/cyclops/monitor/plugin.users.ctrl.cfg ) ## FACTORING
#	mon_motd_info_pg	#-- SHOW SYSTEM INFO AT MOTD IN LOGIN NODES !!! FACTORING !!! 

	[ "$_cyclops_monnod_status" == "ENABLED" ] && mon_log_node		#-- STORAGE LOG NODE INFORMATION
	[ "$_cyclops_monenv_status" == "ENABLED" ] && mon_log_env		#-- STORAGE LOG ENVIRONMENT DEVICE INFORMATION


}

post_processing_plugins()
{

        ## PLUGINS POST PROCESSING
	## !!! ACTUALLY DISABLED 

	#mon_cyclops_cron_pg	#-- EXEC PROGRAMING TASK LINK TO CYCLOPS 

	## DEPRECATED SCRIPT TO DETECT AND SOLVE PERSISTENT CG STATUS
	#[ -f /root/cyclops/monitor/scripts/tool.slurm.cg.status.sh ] && /root/cyclops/monitor/scripts/tool.slurm.cg.status.sh 2>&1 >/dev/null
	## END PLUGIN 
	echo 2>&1 >/dev/null 
}

allocate_mon_files()
{

	cp -f $_sensors_mon_general_file $_mon_history_path/noindex/$(date +%s).txt 2>&1 >/dev/null
        cp -f $_tmp_daemon $_sensors_mon_general_file 2>&1 >/dev/null

        chown $_apache_usr:$_apache_grp $_mon_path/*.txt 2>/dev/null
        chmod u-x,g-wx,o-wx $_mon_path/*.txt 2>/dev/null

        chmod 444 $_sensors_mon_general_file 2>&1 >/dev/null
        chown $_apache_usr:$_apache_grp $_sensors_mon_general_file 2>&1 >/dev/null
}


###########################################
#       SPECIAL FUNCTIONS (PLUGINS)       #
###########################################


mon_node_running_pg()
{
	_nod_load_field=$( echo "${_nod_commas_output}" | awk -F\; -v cols="cpu" 'BEGIN { OFS=";" ; split(cols,out,";") } $0 ~ "family" { for (i=1;i<=NF;i++) ix[$i]=i } $0 !~ "family" { for (i in out) printf "%s%s", $ix[out[i]], OFS ; print "" }' | sed 's/;$//' ) 
	_nod_load=$( echo "${_nod_load_field}" | awk 'BEGIN { cpu=0 } $2 ~ "[0-9]" { cpu=cpu+$2 ; linea++ } END { total=cpu/linea ; printf ("%d", total) ; print "" }' )	

        case "$_nod_load" in
        [0-9]|[1-4][0-9])
                _nod_load_color=$_color_up
                _nod_load=$_nod_load"%"
        ;;
        [5-6][0-9])
                _nod_load_color=$_color_ok
                _nod_load="** <fc white> $_nod_load% </fc> **"
        ;;
        100|[7-9][0-9])
                _nod_load_color=$_color_check
                _nod_load="** $_nod_load% **"
        ;;
        "")
                _nod_load_color=$_color_disable
                _nod_load="** no data **"
        ;;
        *)
                _nod_load_color=$_color_unk
                _nod_load="** <fc white> unknown data </fc> **"
        ;;
        esac

	#### NEW Stats Pluging ####

        _mon_nr_pg_stats_fil="cpu_load_avg_pg_stats"
        _mon_nr_pg_stats_link="** {{popup>:operation:monitoring:"$_mon_nr_pg_stats_fil"?[keepOpen] |Sys CPU Load Avg}} **"


        _mon_nr_pg_stats_hour=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 3600 { _time=strftime("%Y-%m-%dT%H.%M",$1) ; split($7,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'T' -f2 )
        _mon_nr_pg_stats_day=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\:  'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 86400 { _time=strftime("%Y-%m-%d %H",$1) ; split($7,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | sort -t\- -n | awk '{ print $2 }' )
        _mon_nr_pg_stats_week=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 604800 { _time=strftime("%Y-%m-%d",$1) ; split($7,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'-' -f2- )
        _mon_nr_pg_stats_month=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 2592000 { _time=strftime("%Y-%m-%d",$1) ; split($7,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'-' -f3- )
        _mon_nr_pg_stats_6m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 15552000 { _time=strftime("%Y-%m",$1) ; split($7,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START )
        _mon_nr_pg_stats_12m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 31104000 { _time=strftime("%Y-%m",$1) ; split($7,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START  )

        _mon_nr_pg_stats_ouput=$( 
		echo "<html>" 
		echo "<meta http-equiv=\"refresh\" content=\"300\">" 
		echo "</html>"
                echo 
                echo "== HISTORIC STATS - PERCENT SYSTEM CPU LOAD AVG ACTIVITY =="
		echo "//Last Update: $_mon_date//"
                echo
		echo "|< 100% 50% 50% >|"
                echo "|  $_color_title LAST HOUR  |  $_color_title LAST 24H  |"
                echo "|  <gchart 600x350 line @#A5DF00 #FFFFFF center>"
                echo "${_mon_nr_pg_stats_hour}"
                echo "</gchart>  |  <gchart 600x350 line @#A5DF00 #FFFFFF center>"
                echo "${_mon_nr_pg_stats_day}"
                echo "</gchart>  |"     
                echo "|  $_color_title LAST SEVEN DAYS  |  $_color_title LAST 30 DAYs  |"
                echo "|<gchart 600x350 line @#A5DF00 #FFFFFF center>"
                echo "${_mon_nr_pg_stats_week}"
                echo "</gchart>  |  <gchart 600x350 line @#A5DF00 #FFFFFF center>"
                echo "${_mon_nr_pg_stats_month}"
                echo "</gchart>  |"
                echo "|  $_color_title LAST 6 MONTH  |  $_color_title LAST 12 MONTH  |"
                echo "|<gchart 600x350 line @#A5DF00 #FFFFFF center>"
                echo "${_mon_nr_pg_stats_6m}"
                echo "</gchart>  |  <gchart 600x350 line @#A5DF00 #FFFFFF center>"
                echo "${_mon_nr_pg_stats_12m}"
                echo "</gchart>  |"
                echo 
        )

        echo "${_mon_nr_pg_stats_ouput}" > $_mon_path"/"$_mon_nr_pg_stats_fil".txt"

}

mon_node_operative_pg()
{
	_nod_operative_field=$( echo "${_nod_commas_output}" | awk -F\; -v cols="hostname" 'BEGIN { OFS=";" ; split(cols,out,";") } $0 ~ "family" { for (i=1;i<=NF;i++) ix[$i]=i } $0 !~ "family" { for (i in out) printf "%s%s", $ix[out[i]], OFS ; print "" }' | sed 's/;$//' )
        _nod_operative=$( echo "${_nod_operative_field}" | grep -v hostname | awk 'BEGIN { _t=0 } $1 == "UP" { _t++ } END { print _t++ }' )
        _nod_total=$( cat $_type | wc -l )

	let "_nod_operative_status=( _nod_operative * 100 ) / _nod_total"

	case "$_nod_operative_status" in
	[0-9]|[1-3][0-9])
                _nod_operative_color=$_color_fail
		_nod_operative_health="{{ :wiki:hb-alert_orange.gif?nolink }}"
                _nod_operative_status="CRITICAL $_nod_operative_status%"
		_active_sound="yes"
                _nod_operative_sound="{{mp3play>:wiki:craking_system.mp3?autostart&loop}}" ### REFACTORING: CHANGE SOUND

		_msg_insert="Monitoring: Critical resources level, probably not enought for operation"
        ;;
	[4-6][0-9])
                _nod_operative_color=$_color_mark
		_nod_operative_health="{{ :wiki:pg_noh_1.gif?nolink }}"
                _nod_operative_status="DANGEROUS $_nod_operative_status%"
		_active_sound="yes"
                _nod_operative_sound="{{mp3play>:wiki:craking_system.mp3?autostart&loop}}"

		_msg_insert="Monitoring: Warning resources level so low"
        ;;	
	7[0-9])
                _nod_operative_color=$_color_check
		_nod_operative_health="{{ :wiki:pg_noh_2.gif?nolink }}"
                _nod_operative_status="$_nod_operative_status%"
        ;;
        [8-9][0-9])
                _nod_operative_color=$_color_up
		_nod_operative_health="{{ :wiki:pg_noh_3.gif?nolink }}"
                _nod_operative_status="$_nod_operative_status%"
        ;;
        100)
                _nod_operative_color=$_color_ok
		_nod_operative_health="{{ :wiki:pg_noh_4.gif?nolink }}"
                _nod_operative_status="** <fc white> $_nod_operative_status% </fc> **"
        ;;
        "")
                _nod_operative_color=$_color_disable
		_nod_operative_health="<fc white>no data</fc>"
                _nod_operative_status="err.no data"
        ;;
        *)
                _nod_operative_color=$_color_disable
		_nod_operative_health="plugin fails"
                _nod_operative_status="plugin fails ($_nod_total,$_nod_operative_status)"
        ;;
	esac

	#### NEW Stats Pluging ####

        _mon_no_pg_stats_fil="available_op_nodes_pg_stats"
        _mon_no_pg_stats_link="** {{popup>:operation:monitoring:"$_mon_no_pg_stats_fil"?[keepOpen] |Full Operative Nodes}} **"

        _mon_no_pg_stats_hour=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 3600 { _time=strftime("%Y-%m-%dT%H.%M",$1) ; split($4,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'T' -f2 )
        _mon_no_pg_stats_day=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\:  'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 86400 { _time=strftime("%Y-%m-%d:%H",$1) ; split($4,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t+=d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | sort -t\- -n | cut -d':' -f2- ) 
        _mon_no_pg_stats_week=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 604800 { _time=strftime("%Y-%m-%d",$1) ; split($4,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t+=d[2] ; a++ }} END { print _to"="t/a }' | grep -v START )
        _mon_no_pg_stats_month=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 2592000 { _time=strftime("%Y-%m-%d",$1) ; split($4,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t+=d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'-' -f3- )
        _mon_no_pg_stats_6m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 15552000 { _time=strftime("%Y-%m",$1) ; split($4,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START )
        _mon_no_pg_stats_12m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 31104000 { _time=strftime("%Y-%m",$1) ; split($4,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START  )


        _mon_no_pg_stats_ouput=$( 
		echo "<html>" 
		echo "<meta http-equiv=\"refresh\" content=\"300\">" 
		echo "</html>"
                echo 
                echo "== HISTORIC STATS - PERCENT AVAILABLE OPERATIVE NODES =="
		echo "//Last Update: $_mon_date//"
                echo
		echo "|< 100% 50% 50% >|"
                echo "|  $_color_title LAST HOUR  |  $_color_title LAST 24H  |"
                echo "|  <gchart 600x350 value bar @#A5DF00 #FFFFFF center>"
                echo "${_mon_no_pg_stats_hour}"
                echo "</gchart>  |  <gchart 600x350 value bar @#A5DF00 #FFFFFF center>"
                echo "${_mon_no_pg_stats_day}"
                echo "</gchart>  |"     
                echo "|  $_color_title LAST SEVEN DAYS  |  $_color_title LAST 30 DAYs  |"
                echo "|<gchart 600x350 value bar @#A5DF00 #FFFFFF center>"
                echo "${_mon_no_pg_stats_week}"
                echo "</gchart>  |  <gchart 600x350 value bar @#A5DF00 #FFFFFF center>"
                echo "${_mon_no_pg_stats_month}"
                echo "</gchart>  |"
                echo "|  $_color_title LAST 6 MONTH  |  $_color_title LAST 12 MONTH  |"
                echo "|<gchart 600x350 value bar @#A5DF00 #FFFFFF center>"
                echo "${_mon_no_pg_stats_6m}"
                echo "</gchart>  |  <gchart 600x350 value bar @#A5DF00 #FFFFFF center>"
                echo "${_mon_no_pg_stats_12m}"
                echo "</gchart>  |"
                echo 
        )

        echo "${_mon_no_pg_stats_ouput}" > $_mon_path"/"$_mon_no_pg_stats_fil".txt"

}

mon_env_status_pg()
{
        _mon_nod_input=$( echo "${_nod_print}" | tr '|' ';' | awk -F\; 'NF > 5 { print $0 }' | sed -e 's/ //g' -e "s/$_color_up/UP /g" -e "s/$_color_fail/FAIL /g" -e "s/$_color_ok/OK /g" -e "s/$_color_down/DOWN /g" -e 's/@#[0-9A-F]*\://g' -e 's/^;//' -e 's/ ;/;/g' -e 's/;$//' ) 
        _env_status_pg_global="21"
        _env_status_pg_alert=0
        
        for _env_status_pg_line in $( cat $_critical_res | grep -v ^\# )
        do      
                _env_status_pg_total_nod=$(  echo $_env_status_pg_line | cut -d';' -f2 )
                _env_status_pg_min_nod=$(    echo $_env_status_pg_line | cut -d';' -f3 )
                _env_status_pg_family=$(     echo $_env_status_pg_line | cut -d';' -f4 )
                _env_status_pg_res_list=$(   echo $_env_status_pg_line | cut -d';' -f5- )
                _env_status_pg_total_real=$( awk -F\; -v _f="$_env_status_pg_family" 'BEGIN { _count=0 } $3 == _f || $4 == _f { _count++ } END { print _count }' $_type )
                
                _env_status_pg_input=$(  echo "${_mon_nod_input}" | grep -B 1 "^$_env_status_pg_family;" )
                _env_status_pg_filter=$( echo "${_env_status_pg_input}" | awk -F\; -v cols="$_env_status_pg_res_list" 'BEGIN { OFS=";" ; split(cols,out,";") } NR==1 { for (i=1;i<=NF;i++) ix[$i]=i } NR>1 { for (i in out) printf "%s%s", $ix[out[i]], OFS ; print "" }' )
                _env_status_pg_health=$( echo "${_env_status_pg_filter}" | awk -F\; 'BEGIN { _node=0 } { if ( $0 ~ /FAIL|DOWN|DIAGNOSE|MAINTENANCE|CONTENT|REPAIR/ ) _node++ } END { print _node }' )
                
                if [ "$_env_status_pg_health" -ne 0 ] && [ "$_env_status_pg_global" != "2" ]
                then    
                        let "_env_status_pg_total=_env_status_pg_total_real - _env_status_pg_health"
                        
                        if [ "$_env_status_pg_total" -lt "$_env_status_pg_min_nod" ]
                        then    
                                _env_status_pg_global=2
                        else    
                                if [ "$_env_status_pg_total" -lt "$_env_status_pg_total_nod" ] 
                                then    
                                        _env_status_pg_global=1
				else
					[ "$_env_status_pg_global" != "1" ] && _env_status_pg_global=0
                                fi
                        fi
		else
			[ "$_env_status_pg_global" != "1" ] && _env_status_pg_global=0
                fi
        done
        
        case "$_env_status_pg_global" in
        "0")      
                _env_status_pg_status="OPERATIVE"
                _env_status_pg_color=$_color_ok
        ;;
        "1")      
                _env_status_pg_status="OPERATIVE"
                _env_status_pg_color=$_color_fail
                _active_sound="yes"
                _env_status_pg_sound="{{mp3play>:wiki:high_alert.mp3?autostart&loop}}"
        ;;
        "2")      
                _env_status_pg_status="NOT OPERATIVE"
                _env_status_pg_color=$_color_down
                _active_sound="yes"
                _env_status_pg_sound="{{mp3play>:wiki:alarm.mp3?autostart&loop}}"
        ;;
	"21")
                _env_status_pg_status="DISABLE"
                _env_status_pg_color=$_color_disable
	;;
        *)
                _env_status_pg_status="UNKNOWN"
                _env_status_pg_color=$_color_unk
        ;;
        esac
}


mon_slurm_running_pg()
{
	#-- NOTE: DISABLE IT IF NO SLURM_STATUS SENSOR ACTIVE IN THE SYSTEM --#

	_srv_slurm_active_field=$( echo "${_nod_commas_output}" | awk -F\; -v cols="slurm_status" 'BEGIN { OFS=";" ; split(cols,out,";") } $0 ~ "family" { for (i=1;i<=NF;i++) ix[$i]=i } $0 !~ "family" { for (i in out) printf "%s%s", $ix[out[i]], OFS ; print "" }' | sed 's/;$//' )
	_srv_slurm_active=$( echo "${_srv_slurm_active_field}" | grep "working" | wc -l )
	_srv_slurm_total_nodes=$( echo "${_nod_commas_output}" | awk -F\; -v _sen="slurm_status" 'BEGIN { _c=0 } $0 ~ "family" { for (i=1;i<=NF;i++) { if ( $i == _sen ) { _pos="yes" } else { _pos="no" }}} $0 !~ "family" && _pos="yes" { _c++ } END { print _c }' )
	#_srv_slurm_total_nodes=$( cat $_type | grep "compute" | wc -l ) ## DEPRECATED, DELETE IF LINE BEFORE WORKS FINE

	let "_srv_slurm_load_data=( _srv_slurm_active * 100 ) / _srv_slurm_total_nodes"

	_srv_slurm_load_color=$_color_up

	case "$_srv_slurm_load_data" in
	0)
		if [ "$_srv_slurm_active" -ne 0 ]
		then
			_srv_slurm_load="{{ :wiki:pg_sr0.gif?nolink }}"
			_srv_slurm_load_data=0.5
		else
			_srv_slurm_load_color=""
			_srv_slurm_load="{{ :wiki:hb-zzz-gen.gif?nolink }}"
		fi

	;;
       	[1-9]|1[0-9]) 
		_srv_slurm_load="{{ :wiki:pg_sr0.gif?nolink }}"	
	;;
	[2-3][0-9])
		_srv_slurm_load="{{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }}"	
	;;
	[4-5][0-9])
		_srv_slurm_load="{{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }}"
        ;;
        [6-7][0-9])
		_srv_slurm_load="{{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }}"
        ;;
        [8-9][0-9]|100)
		_srv_slurm_load="{{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }} {{:wiki:pg_sr0.gif?nolink }}"
        ;;
        "")
                _srv_slurm_load_color=$_color_disable
                _srv_slurm_load="no data"
        ;;
        *)
                _srv_slurm_load_color=$_color_unk
                _srv_slurm_load="** <fc white> unknown data </fc> **"
        ;;
	esac

	#### NEW Stats Pluging ####

	_mon_sr_pg_stats_fil="slurm_pg_stats"
	_mon_sr_pg_stats_link="** {{popup>:operation:monitoring:"$_mon_sr_pg_stats_fil"?[keepOpen] |Active Compute Nodes}} **"
	

	_mon_sr_pg_stats_day=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\:  'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 86400 { _time=strftime("%Y-%m-%d %H",$1) ; split($6,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | awk '{ print $2 }' )
	_mon_sr_pg_stats_hour=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 3600 { _time=strftime("%Y-%m-%dT%H.%M",$1) ; split($6,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'T' -f2 )
	_mon_sr_pg_stats_week=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 604800 { _time=strftime("%Y-%m-%d",$1) ; split($6,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START ) 
	_mon_sr_pg_stats_month=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 2592000 { _time=strftime("%Y-%m-%d",$1) ; split($6,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'-' -f3- )
        _mon_sr_pg_stats_6m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 15552000 { _time=strftime("%Y-%m",$1) ; split($6,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START )
        _mon_sr_pg_stats_12m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 31104000 { _time=strftime("%Y-%m",$1) ; split($6,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START  )

	_mon_sr_pg_stats_ouput=$( 
		echo "<html>" 
		echo "<meta http-equiv=\"refresh\" content=\"300\">" 
		echo "</html>"
		echo 
		echo "== HISTORIC STATS - PERCENT SLURM NODES ACTIVITY =="
		echo "//Last Update: $_mon_date//"
		echo
		echo "|< 100% 50% 50% >|"
		echo "|  $_color_title LAST HOUR  |  $_color_title LAST 24H  |"
		echo "|  <gchart 600x350 line @#0040FF #FFFFFF center>"
		echo "${_mon_sr_pg_stats_hour}"
		echo "</gchart>  |  <gchart 600x350 line @#0040FF #FFFFFF center>"
		echo "${_mon_sr_pg_stats_day}"
		echo "</gchart>  |"	
		echo "|  $_color_title LAST SEVEN DAYS  |  $_color_title LAST 30 DAYs  |"
		echo "|<gchart 600x350 line @#0040FF #FFFFFF center>"
		echo "${_mon_sr_pg_stats_week}"
		echo "</gchart>  |  <gchart 600x350 line @#0040FF #FFFFFF center>"
		echo "${_mon_sr_pg_stats_month}"
		echo "</gchart>  |"
                echo "|  $_color_title LAST 6 MONTH  |  $_color_title LAST 12 MONTH  |"
                echo "|<gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_sr_pg_stats_6m}"
                echo "</gchart>  |  <gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_sr_pg_stats_12m}"
                echo "</gchart>  |"
		echo 
	)

	echo "${_mon_sr_pg_stats_ouput}" > $_mon_path"/"$_mon_sr_pg_stats_fil".txt"


}

mon_uptime_edges_pg()
{

	_node_edges=$( echo "${_nod_commas_output}" | awk -F\; -v cols="hostname;uptime" 'BEGIN { OFS=";" ; split(cols,out,";") } $0 ~ "family" { for (i=1;i<=NF;i++) ix[$i]=i } $0 !~ "family" { for (i in out) printf "%s%s", $ix[out[i]], OFS ; print "" }' | grep "d;$" | sed 's/[A-Z]*\ //g' | sort -t\; -k2,1n )

        _node_edges=$( echo "${_node_edges}" | awk -F\; '
                BEGIN { 
                        _max=0 ; 
                        _min=9999 ; 
                        _nod_max="none" ; 
                        _nod_min="none" ; 
                } $2 ~ "[0-9]+d" { 
                        gsub("[A-Z]+ ","",$1) ; 
                        match($2,"[0-9]+",a) ; 
                        if ( a[0] >= _max ) { _max=a[0] ; _nod_max=$1 } ; 
                        if ( a[0] <= _min ) { _min=a[0] ; _nod_min=$1 } ; 
                } END { 
                        print "max:"_nod_max";"_max ; print "min:"_nod_min";"_min ; 
                }' )

        _max_node=$( echo "${_node_edges}" | grep "^max:" | sed -e 's/^max://' -e 's/;/ \- /' )
        _min_node=$( echo "${_node_edges}" | grep "^min:" | sed -e 's/^min://' -e 's/;/ \- /' )

	_max_now_node=$( echo $_max_node | cut -d'-' -f1 | sed 's/\ //g' )
	_max_now=$( echo $_max_node | awk -F" - " '{ print $2 + 0 }' )
	_max_record=$( cat $_sensors_sot | awk -F\; '$1 == "CYC" && $2 == "0002" { print $4 }' )
	_max_record_node=$( cat $_sensors_sot | awk -F\; '$1 == "CYC" && $2 == "0002" { print $3 }' )

	if [ "$_max_now" -ge "$_max_record" ]
	then
		_max_record_color=$_color_up
 
		[ "$_max_now" -gt "$_max_record" ] && sed -i "s/^\(CYC;0002;\).*\(;UPTIME_RECORD$\)/\1$_max_now_node;$_max_now\2/" $_sensors_sot
	else
		_max_record_color=$_color_disable
	fi

        #### NEW Stats Pluging ####

        _mon_ue_pg_min_stats_fil="min_uptime_pg_stats"
        _mon_ue_pg_min_stats_link="** {{popup>:operation:monitoring:"$_mon_ue_pg_min_stats_fil"?[keepOpen] |min UP Node}} **"

        _mon_ue_pg_max_stats_fil="max_uptime_pg_stats"
        _mon_ue_pg_max_stats_link="** {{popup>:operation:monitoring:"$_mon_ue_pg_max_stats_fil"?[keepOpen] |MAX UP Node}} **"

	_mon_ue_pg_min=$( cat $_pg_dashboard_log | awk -F\: '$4 ~ /100/ { split($10,u,"=") ; split(u[2],d," - ") ;  if ( n[d[1]] <= d[2] ) n[d[1]]=d[2] } END { for ( i in n ) { if ( n[i] != "0" ) { print i"="n[i] }}}' | sort -t\= -k2,2nr | head -n 20 )
	_mon_ue_pg_max=$( cat $_pg_dashboard_log | awk -F\: '$4 ~ /100/ { split($9,u,"=") ; split(u[2],d," - ") ;  if ( n[d[1]] <= d[2] ) n[d[1]]=d[2] } END { for ( i in n ) { print i"="n[i]  }}' | sort -t\= -k2,2nr | head -n 20 )

	_mon_ue_pg_min_output=$(
		echo "<html>" 
		echo "<meta http-equiv=\"refresh\" content=\"300\">" 
		echo "</html>"
		echo 
		echo "== HISTORIC STATS - MAX MINIMAL LIFE TOP 20 NODES =="
		echo "//Last Update: $_mon_date//"
		echo "  * <fc green> INFO: </fc> Only cyclops get data  when system is at 100% of health"
		echo
		echo "|< 100% >|" 
		echo "|  $_color_title MAX MINIMAL LIFE TOP 20 NODES  |"
		echo "|  <gchart 600x350 hbar value #A5DF00 #FFFFFF center>"
		echo "${_mon_ue_pg_min}"
		echo "</gchart>  |"
		echo 
	)

	echo "${_mon_ue_pg_min_output}" > $_mon_path"/"$_mon_ue_pg_min_stats_fil".txt"

        _mon_ue_pg_max_output=$(
                echo "<html>" 
                echo "<meta http-equiv=\"refresh\" content=\"300\">" 
                echo "</html>"
                echo 
                echo "== HISTORIC STATS - MAX LIFE TOP 20 NODES =="
                echo "//Last Update: $_mon_date//"
                echo "  * <fc green> INFO: </fc> Only cyclops get data when system is at 100% of health"
                echo
                echo "|< 100% >|" 
                echo "|  $_color_title MAX LIFE TOP 20 NODES  |"
                echo "|  <gchart 600x350 hbar value #A5DF00 #FFFFFF center>"
                echo "${_mon_ue_pg_max}"
                echo "</gchart>  |"
                echo 
        )

        echo "${_mon_ue_pg_max_output}" > $_mon_path"/"$_mon_ue_pg_max_stats_fil".txt"
}

mon_cyclops_cycles_pg()
{
	_last_mon_cycle=$( cat $_sensors_sot | awk -F\; '$1 == "CYC" && $2 == "0001" { print $3 }' )
	let "_mon_cycle=_last_mon_cycle + 1"

	sed -i "s/^\(CYC;0001;\)[0-9]*\(;.*\)/\1$_mon_cycle\2/" $_sensors_sot

}

mon_login_users_pg()
{
	#-- SECURITY CONTROL USERS REQUIRED ( monitoring login users in the system ) --#

	_login_users=$( echo "${_sec_print}" | awk -F\| 'BEGIN { _info=0 ; _user=0 } { if ( $2 ~ "host" ) { _info++ } ; if ( _info >= 1 ) { if ( $3 !~ ":::" && $0 !~ "hidden" && $0 !~ "user" && $0 !~ "no activity" ) { _user++ }}} END { print _user }' )

	[ "$_login_users" -eq 0 ] && _login_users_color=$_color_ok || _login_users_color=$_color_up


        #### NEW Stats Pluging ####

        _mon_lu_pg_stats_fil="login_usr_pg_stats"
        _mon_lu_pg_stats_link="** {{popup>:operation:monitoring:"$_mon_lu_pg_stats_fil"?[keepOpen] |External Users}} **"

        _mon_lu_pg_stats_day=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\:  'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 86400 { _time=strftime("%Y-%m-%d %H",$1) ; split($8,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | awk '{ print $2 }' )
        _mon_lu_pg_stats_hour=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 3600 { _time=strftime("%Y-%m-%dT%H.%M",$1) ; split($8,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'T' -f2 )
        _mon_lu_pg_stats_week=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 604800 { _time=strftime("%Y-%m-%d",$1) ; split($8,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START )
        _mon_lu_pg_stats_month=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 2592000 { _time=strftime("%Y-%m-%d",$1) ; split($8,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START | cut -d'-' -f3-)
        _mon_lu_pg_stats_6m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 15552000 { _time=strftime("%Y-%m",$1) ; split($8,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START )
        _mon_lu_pg_stats_12m=$( cat $_pg_dashboard_log | sed -e 's/ //g'  -e 's/\%//' | awk -F\: 'BEGIN { _to="START" ; _ts=systime() ; t=0 ; a=1 } $1 > _ts - 31104000 { _time=strftime("%Y-%m",$1) ; split($8,d,"=") ;if ( _to != _time ) { print _to"="t/a ; _to=_time ; t=d[2] ; a=1  } else { t=t+d[2] ; a++ }} END { print _to"="t/a }' | grep -v START  )

        _mon_lu_pg_stats_ouput=$( 
		echo "<html>" 
		echo "<meta http-equiv=\"refresh\" content=\"300\">" 
		echo "</html>"
                echo 
                echo "== HISTORIC STATS - EXTERNAL USERS ACTIVITY =="
                echo "//Last Update: $_mon_date//"
                echo
		echo "|< 100% 50% 50% >|"
                echo "|  $_color_title LAST HOUR  |  $_color_title LAST 24H  |"
                echo "|  <gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_lu_pg_stats_hour}"
                echo "</gchart>  |  <gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_lu_pg_stats_day}"
                echo "</gchart>  |"     
                echo "|  $_color_title LAST SEVEN DAYS  |  $_color_title LAST 30 DAYs  |"
                echo "|<gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_lu_pg_stats_week}"
                echo "</gchart>  |  <gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_lu_pg_stats_month}"
                echo "</gchart>  |"
                echo "|  $_color_title LAST 6 MONTH  |  $_color_title LAST 12 MONTH  |"
                echo "|<gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_lu_pg_stats_6m}"
                echo "</gchart>  |  <gchart 600x350 line @#0040FF #FFFFFF center>"
                echo "${_mon_lu_pg_stats_12m}"
                echo "</gchart>  |"
                echo 
        )

        echo "${_mon_lu_pg_stats_ouput}" > $_mon_path"/"$_mon_lu_pg_stats_fil".txt"

}

mon_active_alerts_pg()
{
	_active_msg_alerts=$( awk -F\; 'BEGIN { _count=0 } $1 == "ALERT" && $7 ~ "[01]"  { _count++ } END { print _count }' $_sensors_sot )

	if [ "$_active_msg_alerts" -eq 0 ] 
	then
		_active_msg_alerts_color=$_color_up 
	else
		_active_msg_alerts_color=$_color_check
	fi

}

mon_sent_alerts_pg()
{
	if [ "$_cyclops_mail_status" == "ENABLED" ]
	then
		_sent_msg_alerts=$( awk -F\; 'BEGIN { _count=0 } $1 == "ALERT" && $7 == 1 { _count++ } END { print _count }' $_sensors_sot )
	
		if [ "$_active_msg_alerts" -eq "$_sent_msg_alerts" ]
		then
			[ "$_sent_msg_alerts" -eq 0 ] && _sent_msg_alerts_color=$_color_up || _sent_msg_alerts_color=$_color_check
		else
			_sent_msg_alerts_color=$_color_fail
		fi
	else
		_sent_msg_alerts_color=$_color_disable
		_sent_msg_alerts="disable"
	fi

}

mon_zombie_pg()
{
	_zombie_detector=$( echo "${_nod_print}" | tr '|' ';' | sed -e 's/@#[0-9A-F]*://g' -e 's/ //g' | awk -F\; 'BEGIN { _zfield=0 } { if ( NF > 9 ) {  if ( $2 == "family" ) { for(i=1;i<=NF;i++) if ( $i == "z" ) { _zfield=i }} else if ( $_zfield != "" ) { _z=_z+$_zfield }}} END { print _z }' ) 

	[ -z "$_zombie_detector" ] && _zombie_detector=0

	if [ "$_zombie_detector" -gt 0 ] 
	then
		_active_sound="yes"
		_zombie_brains="{{ :wiki:zombie.gif?nolink|}}" 
		_zombie_detector_sound="{{mp3play>:wiki:zombi_brain.mp3?autostart&loop}}"
	else
		_zombie_brains=""
		_zombie_detector_sound=""
	fi
}

mon_warnings_pg()
{
	_warning_detector=$( echo -e "${_nod_print}\n${_env_print}" | tr '|' ';' | sed -e 's/ //g' | awk -F\; 'BEGIN { _c=0 } { for(i=1;i<=NF;i++) if ( $i ~  "@#FFFF00:") { _c++}} END { print _c }' )
	[ "$_warning_detector" -eq 0 ] && _warning_detector_color=$_color_up || _warning_detector_color=$_color_mark
 
}

mon_cyclops_cron_pg()
{

	#### FACTORY: MON SCRIPT WORKS BY CYCLES , NOW CYCLE = 3m ALL CYC CRON TASK WITH MINs FAILS IF MINS != 3m or MULTIPLO OF 3
	#### RE-THINKING 

	for _cyc_cron_line in $( cat $_config_path_mon/plugin.cron.cfg )
	do

		_cron_time=$(      echo $_cyc_cron_line | cut -d';' -f1 )
		_cron_script=$(    echo $_cyc_cron_line | cut -d';' -f2 )
		_cron_sh_output=$( echo $_cyc_cron_line | cut -d';' -f3 )

		[ -z "$_cron_sh_output" ] && _cron_sh_ouput="2>&1 >/dev/null"

		case "$_cron_time" in
		"[0-2][0-9]h")
			_cron_now=$( date +%H%M )
		;;
		"[0-5][0-9]m")
			_cron_now=$( date +%M )
		;;
		"[0-2][0-9]:[0-5][0-9]")
			_cron_now=$( date +%H:%M )
		;;
		"[YYYY]-[MM]-[DD]t[0-2][0-9]:[0-6][0-9]")
			_cron_now=$( date +%Y-%m-%dt%H:%M )
		;;
		esac

	done

}

mon_usr_ctrl_pg()
{
	#### FACTORING

	#### CONFIGURE FILE FOR THIS PLUGIN WITH DEFINITED USERS AND THEIR ROLS
	source $_config_path_mon/plugin.users.ctrl.cfg

	_pg_usr_ctrl_list=$( echo "${_sec_commas_output}" | cut -d';' -f3  | sort -u )

	_pg_usr_adm=$( echo "${_pg_usr_ctrl_list}" | awk -F\; -v _adm="$_pg_usr_ctrl_admin" '{ split(_adm,a,",") ; for ( i in a ) { if ( a[i] == $1 ) { _ad++ } }} END { print _ad}' )
	_pg_usr_l1=$( echo "${_pg_usr_ctrl_list}" | awk -F\; -v _l1="$_pg_usr_ctrl_l1" '{ split(_l1,a,",") ; for ( i in a ) { if ( a[i] == $1 ) { _ad++ } }} END { print _ad}' )
	_pg_usr_l2=$( echo "${_pg_usr_ctrl_list}" | awk -F\; -v _l2="$_pg_usr_ctrl_l2" '{ split(_l2,a,",") ; for ( i in a ) { if ( a[i] == $1 ) { _ad++ } }} END { print _ad}' )
	_pg_usr_l3=$( echo "${_pg_usr_ctrl_list}" | awk -F\; -v _l3="$_pg_usr_ctrl_l3" '{ split(_l3,a,",") ; for ( i in a ) { if ( a[i] == $1 ) { _ad++ } }} END { print _ad}' )
	_pg_usr_other=$( echo "${_pg_usr_ctrl_list}" | awk -F\; -v _o="$_pg_usr_ctrl_other" '{ split(_o,a,",") ; for ( i in a ) { if ( a[i] == $1 ) { _ad++ } }} END { print _ad}' )

	[ -z "$_pg_usr_adm" ] && _pg_usr_adm_color=$_color_disable ||_pg_usr_adm_color=$_color_ok
	[ -z "$_pg_usr_l1" ] && _pg_usr_l1_color=$_color_up || _pg_usr_l1_color=$_color_mark
	[ -z "$_pg_usr_l2" ] && _pg_usr_l2_color=$_color_up || _pg_usr_l2_color=$_color_fail
	[ -z "$_pg_usr_l3" ] && _pg_usr_l3_color=$_color_up || _pg_usr_l3_color=$_color_down
	[ -z "$_pg_usr_other" ] && _pg_usr_other_color=$_color_disable || _pg_usr_other_color=$_color_mark

}

mon_log_node()
{
	
	echo "${_nod_commas_output}" | awk -F\; -v _lp="$_mon_log_path" '
		$1 == "family" { 
			split($0,t,";") 
		} $1 != "family" { 
			for ( i in t ) { 
				if ( t[i] == "hostname" ) { 
					split($i,n," ") ; 
					_node=n[2] ; 
				} else {
					_log=_log" : "t[i]"="$i ; 
				}
				if ( t[i] == "uptime" ) {
					split($i,u," ") ; 
					if ( u[2] ~ "^[A-Z]+$" ) { 
						_status=u[2] ; 
					} else {
						_status="UP" ;
					}
				} 
			}  
			if ( _node != "" ) { print systime()" : "_node" : "_status""_log >> _lp"/"_node".pg.mon.log" } ; 
			_log="" 
		}' 2>/dev/null
}

mon_log_env()
{
	
	echo "${_env_commas_output}" | awk -F\; -v _lp="$_mon_log_path" '
		$1 == "family" { 
			split($0,t,";") 
		} $1 != "family" { 
			for ( i in t ) { 
				if ( t[i] == "name" ) { 
					_dev=$i ; 
				} else {
					if ( t[i] == "state" ) {
						_status=$i ; 
					} else {
						_log=_log" : "t[i]"="$i ;
					}
				 
				}
			} ; 
			print systime()" : "_dev" : "_status""_log >> _lp"/"_dev".pg.mon.log" ; 
			_log="" 
		}' 2>/dev/null

}

###########################################
#               MAIN EXEC                 #
###########################################

_cyclops_status_font="black"
_cyc_ha_font="black"

_cyclops_status=$( awk -F\; '$1 == "CYC" && $2 == "0001" { print $4 }' $_sensors_sot )  
_cyclops_mail_status=$( awk -F\; '$1 == "CYC" && $2 == "0004" { print $4 }' $_sensors_sot )
_cyclops_sound_status=$( awk -F\; '$1 == "CYC" && $2 == "0005" { print $4 }' $_sensors_sot )
_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

_cyclops_monsec_status=$( awk -F\; '$1 == "CYC" && $2 == "0010" { print $4 }' $_sensors_sot )
_cyclops_monsrv_status=$( awk -F\; '$1 == "CYC" && $2 == "0011" { print $4 }' $_sensors_sot )
_cyclops_monnod_status=$( awk -F\; '$1 == "CYC" && $2 == "0012" { print $4 }' $_sensors_sot )
_cyclops_monenv_status=$( awk -F\; '$1 == "CYC" && $2 == "0013" { print $4 }' $_sensors_sot )

if [ "$_opt_daemon" == "yes" ]
then

        mon_cyclops_cycles_pg   #-- ADD CYCLE

	case $_cyclops_status in
	DISABLED)
		sed -i "s/@#[A-Z0-9]*\: \*\* <[a-z ]*> \(CYCLOPS\) [A-Z]*/$_color_down ** <fc white> \1 DISABLED/" $_mon_path/dashboard.txt   2>/dev/null
		sed -i "s/@#[A-Z0-9]*\: \*\* <[a-z ]*> \(CYCLOPS\) [A-Z]*/$_color_down ** <fc white> \1 DISABLED/" $_sensors_mon_general_file 2>/dev/null
	;;
	ENABLED)
                _opt_mon="all"
                _opt_show="wiki"

		_cyclops_status_color=$_color_ok
		_cyclops_status_font="white"


		if [ "$_cyclops_ha" == "ENABLED" ]
		then
			ha_check		

			[ "$_ha_role" == "MASTER" ] && mon_enabled
		else
			_ha_role="ALONE"
			mon_enabled
		fi
	;;
	DRAIN)
                _opt_mon="all"
                _opt_show="wiki"

		_cyclops_status_color=$_color_disable
		_cyclops_status_font="black"

                if [ "$_cyclops_ha" == "ENABLED" ]
                then
                        ha_check

                        if [ "$_ha_role" == "MASTER" ] && [ "$_ha_role_active" == "$_hostname" ] 
			then
				mon_drain
			fi
                else
			_ha_role="ALONE"
			mon_drain
                fi
	;;
	TESTING)
                _opt_mon="all"
                _opt_show="wiki"

		_cyclops_status_color=$_color_mark
		_cyclops_status_font="red"

                if [ "$_cyclops_ha" == "ENABLED" ]
                then
                        ha_check

                        [ "$_ha_role" == "MASTER" ] && [ "$_ha_role_active" == "$_hostname" ] && mon_testing

                else
			_ha_role="ALONE"
                        mon_testing
                fi

	;;
	INTERVENTION)
		_opt_mon="all"
		_opt_show="wiki"

		_cyclops_status_color=$_color_mark
		_cyclops_status_font="black"

		if [ "$_cyclops_ha" == "ENABLED" ]
		then
			ha_check
			
			[ "$_ha_role" == "MASTER" ] && [ "$_ha_role_active" == "$_hostname" ] && mon_intervention
		else
			_ha_role="ALONE"
			mon_intervention
		fi
	;;
	SIMULACRE)
		_cyclops_status_color=$_color_unknown
		_cyclops_status_font="white"
	;;
	REPAIRING)
                _opt_mon="all"
                _opt_show="wiki"

                _cyclops_status_color=$_color_mark
		_cyclops_status_font="black"

                if [ "$_cyclops_ha" == "ENABLED" ]
                then
                        ha_check

                        [ "$_ha_role" == "MASTER" ] && [ "$_ha_role_active" == "$_hostname" ] && mon_testing

                else
			_ha_role="ALONE"
                        mon_testing
                fi

	;;
	esac
fi

