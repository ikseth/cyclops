#!/bin/bash

###########################################
#         SLURM QUEUE MONITORING          #
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

## VARIABLES ##

_config_path="/etc/cyclops"
_pid=$( echo $$ ) 

## GLOBAL --

if [ -f "$_config_path/global.cfg" ] 
then
	source $_config_path/global.cfg 
else
	echo "Global config file don't exits" 
	exit 1 
fi

source $_libs_path/node_ungroup.sh
source $_color_cfg_file

## LOCAL --

_ia_temp_file="$_cyclops_temp_path/slurm.queue.ia.tmp"
_slurm_cfg_file="/etc/slurm/slurm.conf"
_slurm_cluster_name="local"
_par_mon="all"
_par_show="default"
_ctl_main_node="localhost"
_ctl_bkp_node=""
_exit_code=0

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":n:f:v:ih:" _optname
do

        case "$_optname" in
                "n")
                        _opt_mon="yes"
                        _par_mon=$OPTARG
                        if [ "$_par_mon" == "all" ] || grep ";"$_par_mon";" $_type 2>&1 >/dev/null
                        then
				echo 2>&1 >/dev/null
                        else
                                echo "-n [node|family|type] Monitoring one node, family or type of nodes"
                                echo "          options are indicated in $_type"
                                echo "          all: get all nodes from all families"
                                exit 1
                        fi
                ;;
                "v")
                        _opt_show="yes"
                        _par_show=$OPTARG
                        if [ !"$_par_show" == "human" ] || [ !"$_par_show" == "wiki" ] || [ !"$_par_show" == "commas" ]
                        then
                                echo "-v [option] Show formated results"
                                echo "          human: human readable"
                                echo "          wiki:  wiki format readable"
                                echo "          commas: excell readable"
                                exit 1
                        fi
                ;;
                "i")
                        _opt_ia="yes"
                ;;
		"f")
			_opt_cfg="yes"
			_par_cfg=$OPTARG

			if [ -f $_par_cfg ]
			then
				source $_par_cfg
				_ia_temp_file="$_cyclops_temp_path/slurm.queue.ia.$_slurm_cluster_name.tmp"
			else
				echo "Slurm job module config file don't exits"
	
				echo "-f [path/file] config file with slurm control nodename and slurm control backup nodename if exits"
			fi
		;;
		"h")
                        case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Slurm Monitoring Module"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Daemon Config path: $_config_path_srv"
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
				echo "CYCLOPS SLURM MONITORING MODULE"
				echo
				echo "-n [node|family|type] Monitoring one node, family or type of nodes"
				echo "          options are indicated in $_type"
				echo "          all: get all nodes from all families"
				echo "-f [path/file] config file with slurm control nodename and slurm control backup nodename if exits"
				echo "-i        activate IA Sensors System"
				echo "-v [option] Show formated results"
				echo "          human: human readable"
				echo "          wiki:  wiki format readable"
				echo "          commas: excell readable"
				echo "-h [|des] help is help"
				echo "		des: Detailed Command Help"
				echo
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

#### FUNCTIONS ####

active_jobs()
{

	_node_list=$( cat "${2}" | awk '$1 ~ "NodeName" && $1 !~ "#" { print $1 }' | sed -e 's/,\([0-9]\)/@\1/g' -e 's/,/\n/g' | awk '$1 ~ "[0-9]@[0-9]" { split($1,n,"=") ; split(n[2],pref,"[") ; if ( n[2] ~ "@" ) { _spl=split(n[2],spl,"@") ; for ( i in spl ) { if ( i == 1 ) { print spl[i]"]" } ; if ( i > 1 && i < _spl ) { print pref[1]"["spl[i]"]" } ; if ( i == _spl ) { print pref[1]"["spl[i] } } }} $1 !~ "[0-9]@[0-9]" { gsub("NodeName=","",$1) ; print $1 }'  | sed -e 's/\([0-9]\)\-\([0-9]\)/\1..\2/' -e 's/\[/\{/' -e 's/\]/\}/' -e 's/{\([0-9]*\)}/\1/' ) 
	_node_list=$( eval echo $_node_list | tr ' ' '\n' )

        [ "$1" == "all" ] && _find_nodes=$_node_list || _find_nodes=$( echo "${_node_list}" |  grep $1 )

	for _nodes in $( echo "${_find_nodes}" )
	do
		squeue -w $_nodes -o "%P;%A;$_nodes;%.8j;%u;%D;%M;%t;%r" | sort -t\; -k1,1 -k2,2 | grep -v "^PARTITION"

	done 

}


waiting_jobs()
{

	squeue -o "%P;%A;%B;%.8j;%u;%D;%M;%t;%r" | sed -e 's/n\/a/waiting/' -e 's/$/\\n/' | grep waiting | sort -t\; -k1,1 -k2,2 | grep -v "^PARTITION"

}

script_ia()
{
	echo -e "${_output}" | sed -e 's/^ //' | sed -e '/^$/d' >$_ia_temp_file

	_ia_alert_output=$($_sensors_slurm_ia_script_file $_pid $_ia_temp_file $_slurm_cluster_name )
	_exit_ia_code=$?

	if [ "$_exit_ia_code" != 0 ]
	then
		_exit_code=2
		_ia_alert=";DOWN SLURM QUEUE - ERROR(s) DETECTED;"$( echo "${_ia_alert_output}" | egrep "DOWN|FAIL" | awk -F\; '{ print $3 }' )";"
		_ia_hidden_state="initialState=\"visible\""
	else
		_ia_alert=";OK SLURM QUEUE STATUS - OPERATIVE;"
		_ia_hidden_state=""
	fi

	_output=$_ia_alert_output

}

extract_node_list()
{
	for _group in $( cat $_slurm_cfg_file | grep ^NodeName | cut -d' ' -f 1 | cut -d'=' -f2 | sed -e 's/\-/../' -e 's/\[/\{/' -e 's/\]/\}/' ) 
	do
		eval echo $_group  
	done
}

format_output()
{
	_title=$( echo "partition;id;node;name;user;nodes;time;state;reason\n" )

	if [ -z "$_output" ]
	then
		_output="No assigned jobs"
		_output_title="" 
	else
		_output_title=$_title
	fi

	if [ -z "$_output_wait" ] 
	then
		_output_wait="No waiting jobs" 
		_output_title_wait="" 
	else
		_output_title_wait=$_title
	fi

	case $_par_show in
        "commas")

                echo -e "${_output_title}${_output}\n${_output_wait}" | sed -e 's/^ //' | sed -e '/^$/d'
        ;;
        "human")
                echo -e "${_output_title}${_output}" | 
			awk -F\; '
				NR  == 1  { 
					_title=$0 
				} NR > 1 { 
					_str=$2";"$4";"$5";"$6";"$7";"$8";"$8";"$9";"$10  ; 
					_par[$1]=_par[$1]";"_str"\n" 
				} END { 
					print _title  ; 
					for ( a in _par ) { 
						print a" "_par[a] 
					}
				}'  | 
			column -t -s\;
		
                echo ""

                echo -e "${_output_title}${_output_wait}" | 
			awk -F\; '
				NR  == 1  { 
					_title=$0 
				} NR > 1 { 
					_str=$2";"$4";"$5";"$6";"$7";"$8";"$8";"$9";"$10  ; 
					_par[$1]=_par[$1]";"_str"\n" 
				} END { 
					print _title  ; 
					for ( a in _par ) { 
						print a" "_par[a] 
					}
				}'  | 
			column -t -s\; 
        ;;
        "wiki")

		## PROCESING REPORT DATA --

		_if_var_ava_compute_nodes=$( echo -e "${_output}" | sed '/^$/d' | egrep -v "$_output_title|No assigned jobs|No waiting jobs" | cut -d';' -f3 | sort -u | wc -l )
		_if_var_run_jobs=$( echo -e "${_output}" | sed '/^$/d' | egrep -v "$_output_title|No assigned jobs|No waiting jobs" | cut -d';' -f2 | sort -u | wc -l )
		_if_var_users=$( echo -e "${_output}" | sed '/^$/d' | egrep -v "$_output_title|No assigned jobs|No waiting jobs" | cut -d';' -f5 | sort -u | wc -l )
		_if_var_wait_jobs=$( echo -e "${_output_wait}" | sed '/^$/d' | egrep -v "$_output_title|No assigned jobs|No waiting jobs" | wc -l )
		_if_var_date=$( date +%H\.%M\.%S )
	
		case "$_exit_code" in
		0) 
			_slurm_state_color=$_color_ok
			_slurm_title_color=$_color_up
			_slurm_status="UP"
			_output_ia=""
		;;
		2)
			_slurm_state_color=$_color_down
			_slurm_title_color=$_color_red
			_slurm_status="DOWN"
		;;
		3)
			_slurm_state_color=$_color_fail
			_slurm_title_color=$_color_fail
			_ia_alert=";DOWN SLURM CONTROLLERS NOT RESPONDING;"
			_slurm_status="FAIL"
		;;
		"*")
                        _slurm_state_color=$_color_unk
                        _slurm_title_color=$_color_unk
			_slurm_status="UNKNOWN"
		;;
		esac

		## PRINT LOG --

		_node_total=$( node_ungroup $_node_total | tr ' ' '\n' | sort -u | wc -l )
		_per_nodes=$( echo "${_node_total}" | awk -v _r="$_if_var_ava_compute_nodes" '$1 ~ "[0-9]+" { _s=$1 } END { if ( _s != 0 ) { print int(( _r * 100 ) / _s) } else { print _s }}' )
		_slurm_source=$( echo "$_slurm_cluster_name" | tr [:upper:] [:lower:] ) 
		echo "$( date +%s ) : $_slurm_source : $_slurm_status : mon_time=$_if_var_date : master=$_ctl_main_node : backup=$_ctl_bkp_node : tnodes=$_node_total : running=$_if_var_ava_compute_nodes : pernodes=$_per_nodes% : jobs=$_if_var_run_jobs : wjobs=$_if_var_wait_jobs : users=$_if_var_users" >> $_srv_slurm_logs/$_slurm_source.sl.mon.log 

		## PRINT OUTPUT --	

		echo '\\'
		 
		echo "|< 100% 15% 10% 10% 10% 10% 10% 15% 15% >|"
		echo "|  $_slurm_state_color ** <fc white> SLURM: $_slurm_cluster_name </fc> **  |  $_slurm_title_color Mon Time  |  $_slurm_title_color Master Control Node  |  $_slurm_title_color Backup Control Node  |  $_slurm_title_color Running Compute Nodes  |  $_slurm_title_color Running Jobs  |  $_slurm_title_color Waiting Jobs  |  $_slurm_title_color Active Users  |"
		echo "| ::: |  $_if_var_date            |  $_ctl_main_color ** <fc $_ctl_main_font > $_ctl_main_node </fc> **  |  $_ctl_bkp_color ** <fc $_ctl_bkp_font > $_ctl_bkp_node </fc> **  |  $_if_var_ava_compute_nodes            |  $_if_var_run_jobs            |  $_if_var_wait_jobs           |  $_if_var_users               |"

		if [ "$_exit_code" -ne 0 ]
		then
			echo
			echo  -e "|< 35% 20% 10% >|" 
			echo $_ia_alert | sed -e 's/^;/\|\ \ /' -e 's/;$/\ \ \|/' -e 's/;/\ \ \|\ \ /g' -e "s/DOWN/$_color_down/g" -e "s/FAIL/$_color_fail/g" -e "s/OK/$_color_ok/g" -e "s/UNKNOWN/$_color_unk&/" 
			echo 
		fi


                echo "<hidden Jobs Assigned $_ia_hidden_state>"
                echo

                echo -e "|< 100% >|"
                echo -e $_output_title | sed -e '/^$/d' -e "s/^/\|\ \ $_color_title\ /" -e 's/$/\ \ \|/' -e "s/;/\ \ \|\ \ $_color_title\ /g"
                echo -e "${_output}" |
                        sed -e '/^$/d' -e 's/^ //' |
                        sort -t\; -k1,1 -k2,2n |
                        awk -F";" 'BEGIN {
                                        part="fea"; job="feo" 
                                } 
                                { 
                                        if ( $1 == part ) 
                                                if ( $2 == job ) 
                                                        { print ":::;:::;"$3";:::;:::;:::;:::;:::;:::"} 
                                                else 
                                                        { job=$2 ; print ":::;"$2";"$3";"$4";"$5";"$6";"$7";"$8";"$9} 
                                        else 
                                                { print $0; part=$1; job=$2 }
                                }' |
                        sed -e 's/^/\|\ \ /' -e 's/$/\ \ \|/' -e 's/\;/\ \ \|\ \ /g' -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/MARK/$_color_mark/g" -e "s/UNK/$_color_unk/g"

                echo "</hidden>"
                echo 

                echo "<hidden Jobs waiting>"            
                echo -e "|< 100% >|" 
                echo -e $_output_title_wait | sed -e '/^$/d' -e "s/^/\|\ \ $_color_title\ /" -e 's/$/\ \ \|/' -e "s/;/\ \ \|\ \ $_color_title\ /g"
                echo -e "${_output_wait}" |
                        sed -e '/^$/d' -e 's/^ //' |
                        sort -t\; -k1,1 |
                        awk -F\; 'BEGIN {
                                part="fea"
                                }
                                {
                                        if ( $1 == part )
                                                { print ":::;"$2";"$3";"$4";"$5";"$6";"$7";"$8";"$9}
                                        else
                                                { print $0; part=$1 }
                                }' |
                        sed -e 's/^/\|\ \ /' -e 's/$/\ \ \|/' -e 's/\;/\ \ \|\ \ /g' -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/MARK/$_color_mark/g" -e "s/UNK/$_color_unk/g"

                echo
                echo "</hidden>"
                echo

        ;;
        *)
                echo -e "${_output_title}"
		echo -e "${_output}"
		echo -e "${_output_wait}"
        ;;
	esac
}

check_ctl_status()
{
	case "$_ctl_main_node" in 
	"localhost"|$HOSTNAME|"127.0.0.1")
		_ctl_status=$( scontrol ping 2>/dev/null | head -n 1 | tr ' ' '\n' | sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c1";" ; print _c2";" }' )
	;;
	*)
		_ctl_status=$( ssh -o ConnectTimeout=5 $_ctl_main_node scontrol ping 2>/dev/null | head -n 1 | tr ' ' '\n' | sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c1";" ; print _c2";" }' )
	;;
	esac

	if [ -z "$_ctl_status" ]
	then
		case "$_ctl_bkp_node" in  
		"localhost"|$HOSTNAME|"127.0.0.1")
			_ctl_status=$( scontrol ping 2>/dev/null | head -n 1 | tr ' ' '\n' | sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c1";" ; print _c2";" }' )
		;;
		*)
			_ctl_status=$( ssh -o ConnectTimeout=5 $_ctl_bkp_node scontrol ping 2>/dev/null | head -n 1 | tr ' ' '\n' | sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c1";" ; print _c2";" }' )
			
		;;
		esac

		if [ -z "$_ctl_status" ]
		then
			_ctl_main_status="DOWN"
			_ctl_bkp_status="DOWN"
		else
			_ctl_main_status=$( echo "${_ctl_status}" | awk -F\; '$2 == "primary" { print $4 }' )
			_ctl_bkp_status=$(  echo "${_ctl_status}" | awk -F\; 'if ( $2 == "backup" && $3 != "NULL" ) { print $4 } else { print "UP" }'  )
		fi
			
	else
		_ctl_main_status=$( echo "${_ctl_status}" | awk -F\; '$2 == "primary" { print $4 }' )
		_ctl_bkp_status=$(  echo "${_ctl_status}" | awk -F\; '$2 == "backup"  { print $4 }' )

	fi

	if [ "$_ctl_main_status" == "DOWN" ] && [ "$_ctl_bkp_status" == "DOWN" ] 
	then
                        _output=""
                        _output_wait=""
                        _ctl_main_color=$_color_mark
			_ctl_main_font="gray"
			_ctl_bkp_color=$_color_mark
			_ctl_bkp_font="gray"
	else
                        if [ "$_ctl_main_status" == "UP" ] 
			then
				_ctl_main_color=$_color_ok 
		
				case "$_ctl_main_node" in
        			"localhost"|$HOSTNAME|"127.0.0.1")
					_node_total=$( sinfo -shl | awk '$2 == "up" { _o=_o""$NF"," } END { print _o}' | sed 's/,$//' )
                        		_output=$( active_jobs $_par_mon $_slurm_cfg_file  )
                        		_output_wait=$( waiting_jobs 2>/dev/null )
        			;;
       				 *)
					_node_total=$( ssh -o ConnectTimeout=10 $_ctl_main_node sinfo -shl | awk '$2 == "up" { _o=_o""$NF"," } END { print _o}' | sed 's/,$//' )
					_output=$( ssh -o ConnectTimeout=10 $_ctl_main_node "$(typeset -f);active_jobs" $_par_mon $_slurm_cfg_file 2>/dev/null )
                                	_output_wait=$( ssh -o ConnectTimeout=10 $_ctl_main_node "$(typeset -f);waiting_jobs " 2>/dev/null )
        			;;
        			esac

				if [ "$_ctl_bkp_status" == "UP" ]
				then
					_ctl_bkp_color=$_color_ok 
				else
					_ctl_bkp_color=$_color_mark
					_ctl_bkp_font="gray"
				fi
			else

				_ctl_main_color=$_color_mark
				_ctl_main_font="gray"
				_ctl_bkp_color=$_color_up

                                case "$_ctl_bkp_node" in
                                "localhost"|$HOSTNAME|"127.0.0.1")
					_node_total=$( sinfo -shl | awk '$2 == "up" { _o=_o""$NF"," } END { print _o}' | sed 's/,$//' )
                                        _output=$( active_jobs $_par_mon $_slurm_cfg_file  )
                                        _output_wait=$( waiting_jobs 2>/dev/null )
                                ;;
                                 *)
					_node_total=$( ssh -o ConnectTimeout=10 $_ctl_bkp_node sinfo -shl | awk '$2 == "up" { _o=_o""$NF"," } END { print _o}' | sed 's/,$//' )
                                        _output=$( ssh -o ConnectTimeout=10 $_ctl_bkp_node "$(typeset -f);active_jobs" $_par_mon $_slurm_cfg_file 2>/dev/null )
                                        _output_wait=$( ssh -o ConnectTimeout=10 $_ctl_bkp_node "$(typeset -f);waiting_jobs " 2>/dev/null )
                                ;;
                                esac

			fi


                        [ "$_opt_ia" == "yes" ] && script_ia
	fi

}


#### MAIN EXEC ####

	_ctl_bkp_font="white"
	_ctl_main_font="white"

	check_ctl_status

	format_output

	exit $_exit_code

