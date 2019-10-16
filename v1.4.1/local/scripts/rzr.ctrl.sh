#!/bin/bash

###########################################
####      CYCLOPS LOCAL HOST CTRL      ####
####      HOST CTRL RAZOR SCRIPT       ####
####     ACTIONS FOR MNGT RESOURCE     ####
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

source /opt/cyclops/local/etc/local.main.cfg

_hostname=$( hostname -s )

_rsc_rzr_output="119"

############ PARAMETERS #############

while getopts ":a:r:t:h:x" _optname
do

        case "$_optname" in
                "a")
			## ACTION TO DO ## MANDATORY
                        _opt_rzr_act="yes"
                        _par_rzr_act=$OPTARG
                ;;
		"r")
			## RESOURCE TO CTRL ## MANDATORY
			_opt_rzr_rsc="yes"
			_par_rzr_rsc=$OPTARG
		;;
		"t")
			## TYPE OF RZR STOCK ( OLD OS ) ## MANDATORY
			_opt_rzr_stk="yes"
			_par_rzr_stk=$OPTARG
		;;
                "h")
                        case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Host Controol Local Resources"
                                echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
                                echo "  Data path: ## FAULT INCLUDE ##"
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
				echo " -r [resource name] Name of resource to control"
				echo " -t [resource type of stock ] STOCK/OS type of resource"
				echo
				echo " -a [boot|link|unlink|start|stop|check|drain|diagnose|content|up] Action for ctrl resource"
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
				echo "	info: show avaible actions for a resource"
                        fi
                ;;
        esac
done

shift $((OPTIND-1))

################ LIBS #####################

###########################################
#              FUNCTIONs                  #
###########################################

###########################################
#              MAIN EXEC                  #
###########################################

_rsc_rzr_file=$_cyc_clt_rzr_dat"/"$_par_rzr_stk"/"$_par_rzr_rsc".rzr.sh"

[ ! -f "$_rsc_rzr_file" ] && exit $_rsc_rzr_output

case "$_par_rzr_act" in
	check)
		_rsc_rzr_output=$( $_rsc_rzr_file $_par_rzr_act 2>&1 >/dev/null ; echo $? )
		[ "$_rsc_rzr_output" != "0" ] && [ -z "$_rsc_rzr_output" ] && _rsc_rzr_output=21
	;;
	boot)
		_rsc_rzr_output=$( $_rsc_rzr_file $_par_rzr_act 2>&1 >/dev/null ; echo $? )
		[ "$_rsc_rzr_output" != "0" ] && [ -z "$_rsc_rzr_output" ] && _rsc_rzr_output=21
	;;
	stop|unlink|drain|content)
		_rsc_rzr_output=$( $_rsc_rzr_file check 2>&1 >/dev/null ; echo $? )
		[ "$_rsc_rzr_output" == "0" ] && _rsc_rzr_output=$( $_rsc_rzr_file $_par_rzr_act 2>&1 >/dev/null ; echo $? ) || _rsc_rzr_output="0"
	;;
	start|up|link|repair)
		_rsc_rzr_output=$( $_rsc_rzr_file check 2>&1 >/dev/null ; echo $? )
		if [ "$_rsc_rzr_output" != "0" ] && [ "$_rsc_rzr_output" != "21" ] 
		then
			_rsc_rzr_output=$( $_rsc_rzr_file $_par_rzr_act 2>&1 >/dev/null ; echo $? )
			[ "$_rsc_rzr_output" != "0" ] && _rsc_rzr_output=$( $_rsc_rzr_file start 2>&1 >/dev/null ; echo $? )	

			if [ "$_rsc_rzr_output" == "0" ] || [ "$_rsc_rzr_output" == "21" ]
			then
				_rsc_rzr_output=$( $_rsc_rzr_file check 2>&1 >/dev/null ; echo $? )
			fi
		fi
	;;
	diagnose|info)
		_rsc_rzr_output=$( $_rsc_rzr_file $_par_rzr_act 2>&1 >/dev/null ; echo $? )
		[ "$_rsc_rzr_output" != "0" ] && [ -z "$_rsc_rzr_output" ] && _rsc_rzr_output=21
	;;
esac

echo "$( date +%s ) : CYC : RZR : $_hostname : $_par_rzr_act: $_par_rzr_rsc : $_par_rzr_stk : status ($_rsc_rzr_output)" >> $_cyc_clt_local_log

exit $_rsc_rzr_output
