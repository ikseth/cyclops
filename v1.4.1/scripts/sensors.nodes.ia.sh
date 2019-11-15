#!/bin/bash

#### IA SENSORS SCRIPT ####

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

IFS="
"

[ -z "$1" ] && exit 1 || _parent_pid=$1


_config_path="/etc/cyclops"

if [ -f $_config_path/global.cfg ]
then
        source $_config_path/global.cfg
	[ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
        case "$_exit_code" in
        11[3-5])
                echo "ERR: Necesary lib file doesn't exits, please revise your cyclops installation" 1>&2
                exit $_exit_code
        ;;
        esac
else
	echo "ERR: Global config file don't exits" 1>&2
        exit 111
fi

_system_status="OK"
_rules_detected=0

_ia_codes=""

_audit_status=$( awk -F\; '$1 == "CYC" && $2 == "0003" && $3 == "AUDIT" { print $4 }' $_sensors_sot )

#### FUNCTIONS ####

alerts_gen()
{

	for _alert_incidence in $( echo "${_nodes_err}" | awk -F\; '$3 !~ "^[1-3]$" { print $0 }' )
	do
		_alert_host=$( echo $_alert_incidence | cut -d';' -f1 )
		_alert_fail=$( echo $_alert_incidence | cut -d';' -f2 )
		_alert_sens_id=$( echo $_alert_incidence | cut -d';' -f3 )
		_alert_sens_ms=$( echo $_alert_incidence | cut -d';' -f4 )
		_alert_family=$( awk -F\; -v _node="$_alert_host" '$2 == _node { print $3 }' $_type )

		[ ! -z "$_alert_sens_ms" ] && _alert_sens_ms="["$_alert_sens_ms"]"

		_alert_sens=$( awk -F\; -v _id="$_alert_sens_id" '{ _line++ ; if ( _id == _line ) {  if ( $2 != "" ) { print $1"_"$2 } else { print $1 } }}' $_config_path_nod/$_alert_family.mon.cfg )
		_alert_id=$( awk -F\; 'BEGIN { _id=0 } $1 == "ALERT" { if ( $3 > _id ) { _id=$3 }} END { _id++ ; print _id }' $_sensors_sot )

		_alert_status=$( awk -F\; -v _node="$_alert_host" -v _sens="$_alert_sens" 'BEGIN { _c=0 } { gsub(/ \[.*\]/,"",$5) } $4 == _node && $5 == _sens { _c++ } END { print _c }' $_sensors_sot )

		[ "$_alert_status" == "0" ] && echo "ALERT;NOD;$_alert_id;$_alert_host;$_alert_sens $_alert_sens_ms;$( date +%s );0" >> $_sensors_sot 

		# AUDIT LOG TRACERT
		if [ "$_audit_status" == "ENABLED" ] && [ "$_alert_status" == "0" ] 
		then
			[ -z "$_alert_sens" ] && _alert_sens="NULL"
			[ -z "$_alert_fail" ] && _alert_fail="MARK" || _audit_alert=$( echo $_alert_fail | sed -e 's/^F$/FAIL/' -e 's/^D$/DOWN/' -e 's/^U$/UNKNOWN/' -e 's/^K$/UP/' )
			[ -z "$_alert_host" ] && _alert_host="NULL" || $_script_path/audit.nod.sh -i event -e alert -m "$_alert_sens $_alert_sens_ms" -s $_audit_alert -n $_alert_host 2>>$_mon_log_path/audit.log
		fi
	done

}

alerts_del()
{


	for _alert_ok_host in $( echo "${_nodes_ok}" | cut -d';' -f1 )
	do
		_alert_ok_status=$( awk -F\; -v _node="$_alert_ok_host" 'BEGIN { _count=0 } $4 == _node { _count++ } END { print _count }' $_sensors_sot )
	
		[ "$_alert_ok_status" -ne 0 ] && sed -i -e "/^ALERT;NOD;[0-9]*;$_alert_ok_host;.*;3/d" -e "s/\(^ALERT;NOD;[0-9]*;$_alert_ok_host;.*;\)[01]$/\12/" $_sensors_sot	
		
		# AUDIT LOG TRACERT 
		# [ "$_audit_status" == "ENABLE" ] && echo "$( date +%s );NOD;system health;host sensors recovery;OK"  >> $_audit_data_path/$_alert_ok_host.activity.txt ### REFACTORING PLEASE
	done
 
}

ia_analisis()
{

	for _ia_file in $(ls -1 $_sensors_ia_path | sort -nr | grep rule$ )
	do

		_priority=`echo $_ia_file | cut -d'.' -f1`
		_ia_code=`echo $_ia_file | cut -d'.' -f2`

		_ia_code_level=0
		_var_line_level=0
		_ia_code_max=`awk -F\; '$1 ~ "^[0-9]+$" { total=total + ( $1 * $2 ) } END { print total }' $_sensors_ia_path/$_ia_file` 

		_host_list=""
		_host_quantity=0

		unset _erroutput
		unset _errflag

		for _line in $(echo "${_nodes_err}" )
		do
			_node_name=$(    echo $_line | cut -d';' -f1 )
			_node_family=$(  awk -F\; -v _node=$_node_name '$2 == _node { print $3 }' $_type)
			_service_num=$(  echo $_line | cut -d';' -f3 )
			_service_name=$( awk -F\; -v _sn="$_service_num" 'NR == _sn { if ( $2 != "" ) { print $1"_"$2 } else { print $1 }}' $_config_path_nod/$_node_family.mon.cfg )

			_var_line_level=$( awk -F\; -v _name="$_node_name" -v _service="$_service_name" '
				BEGIN { 
					_nf=0
					_t=0
				} $1 ~ "^[0-9]+$" && ( $3 == "" || $3 == _name ) {
					split($4,s,",") ;
					for ( i in s ) { 
						if ( _service == s[i] ) {
							_t=_t+($1/$2)
						} 
					}
				} END {
					print _t
				}' $_sensors_ia_path/$_ia_file )

			if [ "$_var_line_level" -gt 0 ]
			then
				_errflag="yes"
				_erroutput=$_erroutput""$_node_name";"$_var_line_level"\n"
			fi

		done

		if [ "$_errflag" == "yes" ]
		then
			_err_ia=$( echo -e "${_erroutput}" | sed '/^$/d' | awk -F\; -v _iacm="$_ia_code_max" '
				{
					node[$1]=node[$1]+$2
				} END {
					for ( i in node ) {
						_m=int(( node[i]*100 )/_iacm )
						if ( _m > 35 ) { print i";"_m }
					}
				}' ) 

			if [ ! -z "$_err_ia" ] 
			then
				_ia_code_des=$( cat $_sensors_ia_codes_file 2>/dev/null | grep $_ia_code | cut -d';' -f2 )
				[ -z "$_ia_code_des" ] && _ia_code_des="No Description"
				_ia_codes=$_ia_codes""$( echo "${_err_ia}" | awk -F\; -v _p="$_priority" -v _iac="$_ia_code" -v _iad="$_ia_code_des" '
					{ 
						per[$2]=per[$2]","$1
						c[$2]++
					} END {
						for ( i in per ) {
							print _p";"i"%;"_iac";"_iad";"c[i]";"per[i]
						}
					}' )"\n"
			fi
		fi

	done

	_ia_codes=$( echo "${_ia_codes}" | sed '/^$/d' )
	_rules_detected=$( echo "${_ia_codes}" | wc -l )

	if [ -z "$_ia_codes" ] 
	then
		_ia_codes=$( echo "UNKNOWN;UNKNOWN;UNKNOWN;No relevant procedure rules detected (must be more than 40% success to considerate it);$_host_quantity;show detail table below" )
	else
		for _line in $( echo -e "${_ia_codes}" )
		do
			_line_pri=$( echo "$_line" | cut -d';' -f1 )
			_line_pro=$( echo "$_line" | cut -d';' -f2 )
			_line_cod=$( echo "$_line" | cut -d';' -f3 )
			_line_des=$( echo "$_line" | cut -d';' -f4 )
			_line_qty=$( echo "$_line" | cut -d';' -f5 )
			_line_hst=$( echo "$_line" | cut -d';' -f6 )
			_line_rng=$( node_group $_line_hst )

			_ia_codes_new=$_ia_codes_new""$_line_pri";"$_line_pro";"$_line_cod";"$_line_des";"$_line_qty";"$_line_rng"\n"
		done

		_ia_codes=$( echo -e "${_ia_codes_new}" )
	fi

	if [ "$_rules_detected" != "0" ]
	then
		echo "PRIORITY@PROBABILITY@CODE@DESCRIPTION@HOST QTY@HOST(s) NAME"
		echo -e "${_ia_codes}" | sed '/^$/d' | sort -t\; -k1,2n 
	else
		echo "UNKNOWN ERRORS DETECTED;;;;;"
	fi

}

#### MAIN EXEC ####

_nodes_ok=$( cat $_sensors_ia_tmp_path/$_parent_pid"."$_sensors_ia_tmp_name | awk -F\; '$2 == "K" || $2 == "M" { print $0 }' )
_nodes_err=$( cat $_sensors_ia_tmp_path/$_parent_pid"."$_sensors_ia_tmp_name | awk -F\; '$2 != "K" && $2 != "M" { print $0 }' )
_sot_active_alerts=$( cat $_sensors_sot | grep "^ALERT;NOD" | wc -l )


if [ ! -z "$_nodes_err" ]
then
	alerts_gen
	ia_analisis
fi

[ "$_sot_active_alerts" -ne 0 ] && alerts_del

rm -f $_sensors_ia_tmp_path"/"$_parent_pid"."$_sensors_ia_tmp_name

#### END ####
