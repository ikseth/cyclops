#!/bin/bash

#
#    CYC BACKUP SCRIPT
#

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

#### VARS

source /etc/cyclops/global.cfg
_bkp_count=0


#### FUNCs

cyc_script_base()
{
	if [ -d "$_script_path" ] 
	then
		$_script_path/cyclops.sh -b $_script_path -d $_name_format 		## CYCLOPS MAIN SCRIPT PATH
		_err=$?
		echo "BACKUP: $_script_path : $( [ "$_err" == "0" ] && echo OK || echo FAIL )" 
	else
		echo "ERR: $_script_path MISS"
	fi
}

cyc_monitor_dir()
{
	if [ -d "$_monitor_path" ] 
	then
		$_script_path/cyclops.sh -b $_monitor_path -d $_name_format 		## CYCLOPS MON PATH
		_err=$?
		echo "BACKUP: $_monitor_path : $( [ "$_err" == "0" ] && echo OK || echo FAIL )"
	else
		echo "ERR: $_monitor_path MISS"
	fi
}

cyc_stat_dir()
{
	if [ -d "$_stat_path" ] 
	then
		$_script_path/cyclops.sh -b $_stat_path -d $_name_format		## CYCLOPS STATs PATH
		_err=$?
		echo "BACKUP: $_stat_path : $( [ "$_err" == "0" ] && echo OK || echo FAIL )"
	else
		echo "ERR: $_stat_path MISS"
	fi
		
}

cyc_tool_dir()
{
	if [ -d "$_tool_path" ] 
	then
		$_script_path/cyclops.sh -b $_tool_path -d $_name_format		## CYCLOPS TOOLS BASE PATH
		_err=$?
		echo "BACKUP: $_tool_path : $( [ "$_err" == "0" ] && echo OK || echo FAIL )"
	else
		echo "ERR: $_tool_path MISS"
	fi
}

cyc_audit_dir()
{
	if [ -d "$_audit_path" ]
	then
		$_script_path/cyclops.sh -b $_audit_path -d $_name_format		## CYCLOPS AUDIT BASE PATH
		_err=$?
		echo "BACKUP: $_audit_path : $( [ "$_err" == "0" ] && echo OK || echo FAIL )"
	else
		echo "ERR: $_audit_path MISS"
	fi
}

cyc_wiki_dir()
{
	if [ -d "$_wiki_path" ] 
	then
		$_script_path/cyclops.sh -b $_wiki_path -d $_name_format		## CYCLOPS WWW PATH
		_err=$?
		echo "BACKUP: $_wiki_path : $( [ "$_err" == "0" ] && echo OK || echo FAIL )"
	else
		echo "ERR: $_audit_path MISS"
	fi
}

#### PAR

while getopts ":dt:h:" _optname
do
        case "$_optname" in
	"d")
		_opt_dae="yes"
		_par_typ="all"
	;;
        "t")
                _opt_typ="yes"
                _par_typ=$OPTARG
        ;;
	"h")
		case "$OPTARG" in
		"des")
			echo "$( basename "$0" ) : Cyclops Backup module, lite cyclops own backup implementation"
			echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
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
			echo "CYCLOPS BACKUP TOOL"
			echo
			echo "  -t [all|script|monitor|stat|tool|audit|wiki] can use several options separed by comma"
			echo "          all: exclusive option, launch backup of all available dirs"
			echo "          script: backup of cyclops base script dir"
			echo "          monitor: backup of cyclops monitor module dir"
			echo "          stat: backup of cyclops statistics module dir"
			echo "          tool: backup of cyclops tools dir"
			echo "          audit: backup of cyclops audit module dir"
			echo "          wiki: backup of web cyclops frontend"
			echo "  -h [|des] help is help"
			echo "		des: Detailed Command help"
			exit 0
		else
			echo "ERR: Use -h for help"
			exit 1
		fi
        ;;
        esac
done

shift $((OPTIND-1))

#### MAIN EXEC

echo "BACKUP $( date +%Y%m%d-%H%M ): START"

_name_format="none"

case "$_par_typ" in
	all)
		_name_format="day"
		cyc_script_base &
		cyc_monitor_dir &
		cyc_stat_dir &
		cyc_tool_dir &
		cyc_audit_dir &
		cyc_wiki_dir &
	;;
	script)
		cyc_script_base &
	;;
	monitor)
		cyc_monitor_dir &
	;;
	stat)
		cyc_stat_dir &
	;;
	tool)
		cyc_tool_dir &
	;;
	audit)
		cyc_audit_dir &
	;;
	wiki)
		cyc_wiki_dir &
	;;
	*)
		echo "ERR: BAD OPTION SELECTED USE -h TO SEE AVAIBLE OPTIONS"
	;;
esac
