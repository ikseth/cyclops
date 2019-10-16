#!/bin/bash

###########################################
#            ENV MONITORING               #
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
#

IFS="
"

_pid=$( echo $$ )
_debug_code="SEN.ENVHARD "
_debug_prefix_msg="Environment Hardware Monitoring: "
_exit_code=0

_par_show="default"
_par_mon="all"
_ia_hidden_state=""

## GLOBAL --

_config_path="/etc/cyclops"

if [ ! -f $_config_path/global.cfg ]
then
        echo "Global config file don't exits"
        exit 1
else
        source $_config_path/global.cfg
fi

source $_color_cfg_file

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":m:v:ih:" _optname
do

        case "$_optname" in
                "m")
                        _opt_mon="yes"
                        _par_mon=$OPTARG
                        if [ "$_par_mon" == "all" ] || grep ";"$_par_mon";" $_dev 2>&1 >/dev/null
                        then
				echo 2>&1 >/dev/null	
                        else
                                echo "-m [device|family|type] Monitoring one node, family or type of nodes"
                                echo "          options are indicated in $_sensor_envhard_type"
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
		"h")
			case "$OPTARG" in
			"des")
				echo "$( basename "$0" ) : Cyc Monitoring Environment Device monitoring module"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Config path: $_config_path_env"
				echo "		Config file: $( echo $_dev | awk -F\/ '{ print $NF }' )"
				echo -e "	Sensors Config files:\n$( cat $_dev | egrep -v "\#|^$" | cut -d';' -f3 | sort -u | sed -e 's/$/\.env\.cfg/' -e 's/^/\t\t/')"
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
				echo "CYCLOPS ENVIRONMENT DEVICE MONITOR COMMAND"
				echo
				echo "-m [device|family|type] Monitoring one node, family or type of nodes"
				echo "          options are indicated in $_dev"
				echo "          all: get all nodes from all families"
				echo "-i        activate IA Sensors System"
				echo "-v [option] Show formated results"
				echo "          human: human readable"
				echo "          wiki:  wiki format readable"
				echo "          commas: excell readable"
				echo "-h [|des] help is help"
				echo "	des: Detailed Command help"
				echo
				exit 0
			else
				echo "ERR: Use -h for help"
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

#### FUNCTIONS DEFINITION ####
mon_ipmi_device()
{

	_dev_output=""
	_dev_state=$( echo $_dev_mng_state | tr '[:lower:]' '[:upper:]' )

	_credentials=$( cat $_bios_mng_cfg_file | grep ^$_dev_name";" | cut -d';' -f3-4 )
	_dev_user=$( echo $_credentials | cut -d';' -f1 )
	_dev_pass=$( echo $_credentials | cut -d';' -f2 )

	_sensor_ipmi_output=$( ipmitool -U $_dev_user -P $_dev_pass -H $_dev_name sensor 2>/dev/null) 

	case "$_dev_state" in
	UP)
		if [ -z "$_sensor_ipmi_output" ] 
		then
			_dev_state="FAIL err.connect"
			_exit_code=2
		else
			for _sensor_sh in $( cat $_config_path_env/$_dev_type".env.cfg" )
			do
				_sensor_sh_file=$( echo $_sensor_sh | cut -d';' -f2 )
				_dev_output=$_dev_output""$( source $_sensors_env_scripts/$_sensor_sh_file | cut -d':' -f2 )";"
			done
		fi
	
		echo "$_dev_num;$_dev_type;$_dev_name;$_dev_state;$_dev_output" | sed 's/;$//'
	;;
	DRAIN|REPAIR)
		echo "$_dev_num;$_dev_type;$_dev_name;$_dev_state"
	;;
	DIAGNOSE)
		## CAMBIAR O ANULAR ##
		echo "$_dev_num;$_dev_type;$_dev_name;$_dev_state"
		
	;;
	esac

}


mon_launch()
{
	_dev_family_old="old"

	for _dev_line in $( cat $_dev | grep $_par_mon | sort -t\; -k3,1 )
	do
		_dev_id=$( echo $_dev_line | cut -d';' -f1 )
		_dev_name=$( echo $_dev_line | cut -d';' -f2 )
		_dev_type=$( echo $_dev_line | cut -d';' -f3 )
		_dev_family=$( echo $_dev_line | cut -d';' -f4 )
		_dev_sh_type=$( echo $_dev_line | cut -d';' -f5 )
		_dev_mng_state=$( echo $_dev_line | cut -d';' -f6 )

		if [ "$_dev_family" != "$_dev_family_old" ] 
		then
			cat $_config_path_env/$_dev_type".env.cfg"| cut -d';' -f1 | tr '\n' ';' | sed -e 's/;$//' -e "s/^/$_dev_family\_0;family;name;state;/" | sed 's/;/;@/g'
			echo 
			_dev_family_old=$_dev_family
		fi
	
		case "$_dev_sh_type" in	
		ipmi)
			let "_num++"
			_dev_num=$_dev_family"_"$_num
			mon_ipmi_device & 
		;;
		telnet)
		;;
		*)
		;;
		esac

	done | sort 
	wait
}

check_output()
{
	echo "${_output}" | egrep "DOWN|FAIL|UNKNOWN" 2>&1 >/dev/null
	if [ $? -eq 0 ]
	then
		_ia_hidden_state="initialState=\"visible\""
		_exit_code=1
	fi
}

print_output()
{
        case "$_par_show" in
        human)
		echo
		echo -e $_ia_alert | column -t -s\;  
		echo 
                echo "${_output}" | cut -d';' -f2- | sed 's/@//g' | column -t -s\;
		echo
        ;;
        wiki)
		wiki_format_output
        ;;
        commas)
		echo
		echo -e $_ia_alert
		echo
                echo "${_output}" | cut -d';' -f2- | sed 's/@//g'
		echo
        ;;
        *)
		echo "${_ia_alert}"
                echo "${_output}"
        ;;
        esac
}


ia_processing_old()
{

        echo "${_output}" | sort -n | tr '@' ';' | sed -e '/^$/d' | cut -d';' -f3- |
                awk -F\; '$0 ~ "OK" || $0 ~ "UP" || $0 ~ "DOWN" || $0 ~ "FAIL" || $0 ~ "UNKN" { _err=0 ; for (i=1;i<=NF;i++) { if ($i ~ "DOWN") { _err=1 ; print $1";D;"(i-2) } else ;if ($i ~ "FAIL") { _err=1 ; print $1";F;"(i-2)} else ;if ($i ~ "UNKN") { _err=1 ; print $1";U;"(i-2)}} ; if ( _err == 0 ) { print $1";K;0"}} ' |
                cut -d' ' -f2- > $_sensors_ia_tmp_path/$_pid"."$_sensors_ia_tmp_name

        _ia_alert=$($_sensors_ia_env_script_file $_pid)

        if [ ! -z "$_ia_alert" ]
        then
                _exit_code=2
                _ia_hidden_state="initialState=\"visible\""

                ## Generating alert --

                _file_mail=$_sensors_alerts_path"/$PPID.nodes.mail."$(date +%Y%m%dt%H%M%S )".txt"
                #echo -e $_ia_alert | sed -e 's/--//' > $_file_mail     
        else
                _ia_alert=";OK NODE STATUS - OPERATIVE;"
                _ia_hidden_state=""
        fi
}

ia_processing()
{
        _ctrl_err=$( echo -e "${_output}" | sort -n | tr '@' ';' | sed -e '/^$/d' -e 's/CHECKING //g' | cut -d';' -f3- | 
                awk -F\; '
                        $0 ~ "OK" || $0 ~ "UP" || $0 ~ "DOWN" || $0 ~ "FAIL" || $0 ~ "UNKN" || $0 ~ "MARK" { 
                                _err=0 ; 
                                for (i=1;i<=NF;i++) { 
                                        _lmsg=split($i,msg," ") ;
                                        if ( msg[1] ~ /DOWN|FAIL|UNKN/ ) {
                                                _msg=msg[2]
                                                if ( _lmsg > 2 ) { 
                                                        for (m=3;m<=_lmsg;m++) { 
                                                                _msg=_msg" "msg[m] 
                                                        }
                                                }
                                        }
                                        if ( msg[1] == "DOWN" ) { _err=1 ; print $1";D;"i";"_msg }
                                        if ( msg[1] == "FAIL" ) { _err=1 ; print $1";F;"i";"_msg }
                                        if ( msg[1] ~ "UNKN" )  { _err=1 ; print $1";U;"i";"_msg }
                                        if ( msg[1] == "MARK" ) { _err=1 ; print $1";M;"i";"_msg }
                                }
                                if ( _err == 0 ) { print $1";K;0;"}
                        } ' | 
                cut -d' ' -f2- )
        echo "${_ctrl_err}" > $_sensors_ia_tmp_path/$_pid"."$_sensors_ia_tmp_name

        _exit_code=$( echo "${_ctrl_err}" | awk -F\; '
                BEGIN { _x="0" } 
                $2 == "M" { _m++ } 
                $2 == "U" { _u++ } 
                $2 == "F" { _f++ } 
                $2 == "D" { _d++ } 
                END { 
                        if ( _d != 0 ) { print "10" } 
                                else if ( _f != 0 ) { print "11" } 
                                        else if ( _u != 0 ) { print "90" } 
                                                else if ( _m != 0 ) { print "12" } 
                                                        else { print "00" } 
                }' )

        _ia_alert=$($_sensors_ia_env_script_file $_pid)

        if [ ! -z "$_ia_alert" ]
        then
		_exit_code=2
                _ia_hidden_state="initialState=\"visible\""

                ## Generating alert --

                _file_mail=$_sensors_alerts_path"/$PPID.nodes.mail."$(date +%Y%m%dt%H%M%S )".txt"
        else
                _ia_header=";OK NODE STATUS - OPERATIVE;"
                _ia_hidden_state=""
        fi
}

wiki_format_output()
{

        ## PRE-PROCESSING OUTPUT --

        if [ "$_exit_code" -eq 0 ] || [ "$_exit_code" -eq 12 ]
        then
                _family_status=$_color_ok
                _title_status=$_color_up
                _family_font_color="white"
        else
                _family_status=$_color_down
                _title_status=$_color_red
                _family_font_color="white"
        fi

        _total_dev=$( echo -e "${_output}" | grep -v \@ | cut -d';' -f3 | wc -l )

        _active_dev=$( echo -e "${_output}" | grep -v \@ | cut -d';' -f4 | grep ^UP | wc -l )
        [ "$_active_dev" -eq "$_total_dev" ] && _active_dev_color=$_color_up || _active_dev_color=$_color_mark

        _sensor_alerts=$( echo -e "${_output}" | grep -v \@ | awk -F ";" '{ linea=0 ; for ( a=2 ; a <= NF ; a++ ) { if ( $a ~ /FAIL|DOWN/ ) linea++ } ; if ( linea == 2 ) { linea=1 } ; sensor=sensor+linea } END { print sensor }' )
        [ "$_sensor_alerts" -eq 0 ] && _sensor_alerts_color=$_color_up || _sensor_alerts_color=$_color_fail

        _warnings_active=$( echo -e "${_output}" | grep -v \@ | awk -F ";" '{ linea=0 ; for ( a=2 ; a <= NF ; a++ ) { if ( $a ~ /MARK/ ) linea++ } ; sensor=sensor+linea } END { print sensor }' )
        [ "$_warnings_active" -eq 0 ] && _warnings_color=$_color_up || _warnings_color=$_color_mark

        _maxup_node=$( echo -e "${_output}" | cut -d';' -f3,5 | grep "d$" | sed 's/.*\ \(.*\);.*\ \([0-9]*d\)/\2 \1/' | sort  -k1,1n  | tail -n 1 )
        _minup_node=$( echo -e "${_output}" | cut -d';' -f3,5 | grep "d$" | sed 's/.*\ \(.*\);.*\ \([0-9]*d\)/\2 \1/' | sort  -k1,1n  | head -n 1 )

        [ -z "$_maxup_node" ] && _maxup_node="none" && _maxup_color=$_color_disable || _maxup_color=$_color_up
        [ -z "$_minup_node" ] && _minup_node="none" && _minup_color=$_color_disable || _minup_color=$_color_up

        ## DRAWING OUTPUT --

        echo ~~NOCACHE~~
        echo 
        echo "|< 100% 15% 10% >|"
        echo "|  $_family_status ** <fc $_family_font_color > $( echo $_par_mon | tr [:lower:] [:upper:] ) </fc> **  |  $_title_status Time  |  $_title_status Total Devices  |  $_title_status Active Devices  |  $_title_status Sensor Alerts  |  $_title_status Warnings  |" 
        echo "|  :::  |  $( date +%H.%M.%S )  |  $_total_dev              |  $_active_dev_color $_active_dev  |  $_sensor_alerts_color $_sensor_alerts  |  $_warnings_color $_warnings_active  |" 

        if [ "$_exit_code" -ne 0 ] && [ "$_exit_code" -ne 12 ]
        then
                echo
                echo -e "|< 100% 10% 10% 10% 10% 25% 5% 30% >|"
                echo -e "${_ia_alert}"  | head -n 1 | sed -e "s/@/\ \ \|\ \ \ $_color_red /g" -e "s/^/\|\ \ $_color_red /" -e 's/$/\ \ \|/' -e "s/^/|  $_color_down {{ :wiki:rules_detected.gif?nolink |}}  /"
                echo -e "${_ia_alert}"  | sed -e '1d' -e "s/;\([A-Z][A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9]\);/; ** {{popup>$_wiki_procedures_path:\1?[%100x700%]\&[keepOpen]|\1}} **;/" -e 's/^/|\ \ /' -e 's/$/\ \ \|/' -e 's/;/\ \ \|\ \ /g' -e "s/DOWN/$_color_down/g" -e "s/UP/$_color_up/g" -e "s/OK/$_color_ok/g" -e "s/UNKNOWN/$_color_unk&/g" -e 's/^/|  :::  /'
        fi

        echo
        echo "<hidden $_par_mon $_ia_hidden_state>"
        echo -e "${_output}" | sort -n | cut -d';' -f2- |
                sed '/^$/d' |
sed -e "s/@/$_color_title/g" -e "s/family/$_color_title&/" -e 's/^/\|\ \ /' -e 's/$/\ \ \|/' -e 's/\;/\ \ \|\ \ /g' -e "s/UPTIME/$_color_up/" -e "s/TIME/$_color_up/" -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/FAIL/$_color_fail/g" -e 's/none//g' -e "s/UNKNOWN/$_color_unk/g" -e "s/UNKN/$_color_unk/g" -e "s/REPAIR/$_color_mark &/" -e "s/MARK/$_color_mark/g" -e "s/CHECKING/$_color_check/g" -e "s/DISABLE/$_color_disable/g" -e "s/LOADED/$_color_loaded/g" -e "s/DRAIN/$_color_disable MAINTENANCE/" -e "s/POWEROFF/$_color_poweroff power off/" -e "s/DEAD/$_color_dead/g" |
                sed -e '/family/ i\
' -e '/family/ i\
|< 100% 6% 6% 6% >|'

        echo "</hidden>"
	echo '\\'

}


#### MAIN EXEC ####

	if [ "$_par_mon" == "all" ]
	then
		for _family in $( cat $_dev | egrep -v "^$|#|unknown" | cut -d';' -f4 | sort -u )
		do
			_par_mon=$_family
			_output=$(mon_launch)

			[ "$_opt_ia" == "yes" ] && ia_processing

			print_output
			
		done
	else
		_output=$(mon_launch)
		#check_output

		[ "$_opt_ia" == "yes" ] && ia_processing

		print_output

	fi



	exit $_exit_code
