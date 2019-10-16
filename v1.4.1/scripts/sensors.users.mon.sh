#!/bin/bash

###########################################
#     CONNECTED USERS MONITORING          #
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

_config_path="/etc/cyclops"
_ia_temp_file="/tmp/connected.users.ia.tmp"

_exit_code=0

# --------------- GLOBAL -----------------#

if [ ! -f "$_config_path/global.cfg" ]
then
        echo "Global config file don't exits"
        exit 1
else
        source $_config_path/global.cfg
	source $_color_cfg_file
fi

# -------------- SCRIPT ------------------#

###########################################
#              PARAMETERs                 #
###########################################

_debug_prefix_msg="DEBUG: Services Monitoring: Parameters:"

while getopts ":m:v:ih:" _optname
do

        case "$_optname" in
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
		"m")
			# FUTURE OPTION
			_opt_monitor="yes"
		;;
		"h")
			case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops User Monitoring Module"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Config path: $_config_path_sec"
				echo "		Configure file: $( echo $_sensors_usr_login_srv_list | awk -F\/ '{ print $NF }' )"
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
				echo "CYCLOPS USERS MONITOR COMMAND"
				echo
				echo "-i        activate IA Sensors System"
				echo "-v [option] Show formated results"
				echo "          human: human readable"
				echo "          wiki:  wiki format readable"
				echo "          commas: excell readable"
				echo "-h [|des] help is help"
				echo "		des: Detailed Command Help"
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

###########################################
#              MAIN EXEC                  #
###########################################

_user_status_output=""

for _node in $(cat $_sensors_usr_login_srv_list | grep -v \# | cut -d';' -f1)
do


	_user_status=$(ssh -o ConnectTimeout=6 $_node w -su 2>/dev/null)
	_err_user_status=$?

	[ "$_err_user_status" == "0" ] && _user_status=$( echo "${_user_status}" | tr -s ' ' | egrep -v "load average|USER" | sed -e "s/^/$_node\;/" -e 's/ /;/' -e 's/ /;/' -e 's/ /;/' -e 's/ /;/' | sed 's/;/ /3' ) || _user_status=$_node";connection problem;;;"

	[ -z "$_user_status" ] && _user_status=$_node";no activity;;;"

	_user_status_output=$_user_status_output"\n"$_user_status

done


### IA ###

if [ "$_opt_ia" == "yes" ]
then
	echo -e "${_user_status_output}" | sed -e '/^$/d' > $_sensors_ia_users_tmp_file
	_ia_users=$($_sensors_users_ia_script_file)
	_ia_alert=$( echo "${_ia_users}" | cut -d';' -f1,2 | egrep -v 'UP' )
	_user_status_output=$_ia_users
	if [ -z "$_ia_alert" ] 
	then
		_ia_header="OK USER STATUS - OPERATIVE" 
		_ia_hidden_state="" 
	else
		_ia_header="DOWN USER STATUS - ERR;"$( echo "${_ia_alert}" | wc -l ) 
		_ia_hidden_state="initialState=\"visible\""
		_exit_code=101
	fi
fi

echo "${_user_status_output}" > /tmp/debug.users.tmp

case "$_par_show" in
	"human")
		[ "$_opt_ia" == "yes" ] && echo -e $_ia_header"\nhost;user\n${_ia_alert}\n" | column -s\; -t ; echo
		echo -e "${_user_status_output}" | sed -e '/^$/d' | sort | awk -F";" 'BEGIN { print "host;user;source;idle_time;command" ; field1="fea"; field2="feo" } { if ( $1 == field1 ) if ( $2 == field2 ) { print " ; ;"$3";"$4";"$5} else { field2=$2 ; print " ;"$2";"$3";"$4";"$5} else { print $1";"$2";"$3";"$4";"$5 ; field1=$1; field2=$2 }}' | column -s\; -t 
	;;
	"wiki")
		if [ "$_opt_ia" == "yes" ] 
		then
			echo '|< 25% 20% 10% >|'
			echo -e $_ia_header | sed -e 's/^/\|\ \ /' -e 's/$/\ \ \|/' -e 's/;/\ \ \|\ \ /g' -e 's/DOWN/\@\#FA5858\:/g' -e 's/OK/\@\#A5DF00\:/g'
			echo
			if [ ! -z "$_ia_alert" ]
			then
				echo '|< 35% 40% 60% >|'
				echo -e "|  $_color_title host  |  $_color_title user  |"
				echo -e "${_ia_alert}" | sort -u | sed -e 's/^ //' -e 's/@$/;/' -e "s/@/;$_color_title /g" -e 's/^/\|\ \ /' -e 's/$/\ \ \|/' -e 's/;/\ \ \|\ \ /g' -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/UNKNOWN/$_color_unknow &/" -e "s/MARK/$_color_mark/g"
			echo
			fi
		fi
		
		echo "<hidden Users Status $_ia_hidden_state>"
		echo "|< 100% 10% 10% 15% 10% >|"
		echo "|  $_color_title host  |  $_color_title user  |  $_color_title source  |  $_color_title idle_time  |  $_color_title command  |"
		echo -e "${_user_status_output}" | sort | awk -F";" -v _cu="$_color_up" '
			BEGIN { 
				field1="fea"; 
				field2="feo" 
			} { 
				if ( $1 == field1 ) if ( $2 == field2 ) { 
							print ":::;:::;"$3";"_cu":"$4";"_cu" "$5
						} else { 
							field2=$2 ; 
							print ":::;"$2";"$3";"_cu" "$4";"_cu" "$5
						} else { 
							print $1";"$2";"$3";"_cu" "$4";"_cu" "$5 ; field1=$1; field2=$2 
						}
			}'  | 
				sed -e 's/|/\%\%\|\%\%/g' -e "s/^/|  /" -e "s/$/  |/" -e "s/;/  |  /g" -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/FAIL/$_color_fail/g" -e "s/UNKN/$_color_unk/g" -e "s/MARK/$_color_mark/g"
		echo "</hidden>"
	;;
	"commas")
		[ "$_opt_ia" == "yes" ] && echo -e $_ia_header"\n\nhost;user\n${_ia_alert}\n"
		echo -e "host;user;source;idle_time;command\n${_user_status_output}" | sed -e '/^$/d'
	;;
	*)
		echo $_user_status_output
	;;
esac

exit $_exit_code
