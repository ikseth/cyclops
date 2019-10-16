#!/bin/bash

#### IA ENVIRONMENT SCRIPT ####

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

if [ -z $_config_path/global.cfg ]
then
        echo "Global config file don't exits"
        exit 1
else
        source $_config_path/global.cfg
fi

_system_status="OK"
_rules_detected=0

_ia_codes=""

_audit_status=$( awk -F\; '$1 == "CYC" && $2 == "0003" && $3 == "AUDIT" { print $4 }' $_sensors_sot )

#### FUNCTIONS ####

alerts_gen()
{

	#echo "DEBUG: START ## $( date +%s ) " 2>&1 >>/opt/cyclops/logs/envia.debug 
	#echo "${_dev_err}" | grep -v ";[1-3]$"  2>&1 >>/opt/cyclops/logs/envia.debug 
	#echo "DEBUG: START ## $( date +%s ) " 2>&1 >>/opt/cyclops/logs/envia.debug

	for _alert_incidence in $( echo "${_dev_err}" ) # | grep -v ";[1-3]$" )
	do
		_alert_dev=$( echo $_alert_incidence | cut -d';' -f1 )
		_alert_fail=$( echo $_alert_incidence | cut -d';' -f2 )
		_alert_sens_id=$( echo $_alert_incidence | cut -d';' -f3 )
		_alert_sens_ms=$( echo $_alert_incidence | cut -d';' -f4 )
		_alert_family=$( awk -F\; -v _dev="$_alert_dev" '$2 == _dev { print $3 }' $_dev )

		[ ! -z "$_alert_sens_ms" ] && _alert_sens_ms="["$_alert_sens_ms"]"

		#_alert_sens=$( cat $_config_path_env/$_alert_family.env.cfg | awk -F\; -v _id="$_alert_sens_id" '{ _line++ ; if ( _id == _line ) {  print $1 }}'  )
		_alert_sens=$( awk -F\; -v _id="$_alert_sens_id" 'NR == _id { print $1 }' $_config_path_env"/"$_alert_family".env.cfg" )
		_alert_id=$( awk -F\; 'BEGIN { _id=0 } $1 == "ALERT" { if ( $3 > _id ) { _id=$3 }} END { _id++ ; print _id }' $_sensors_sot )

		_alert_status=$( awk -F\; -v _dev="$_alert_dev" -v _sens="$_alert_sens" 'BEGIN { _c=0 } { gsub(/ \[.*\]/,"",$5) } $4 == _dev && $5 == _sens { _c++ } END { print _c }' $_sensors_sot )

		[ "$_alert_status" == "0" ] && echo "ALERT;ENV;$_alert_id;$_alert_dev;$_alert_sens $_alert_sens_ms;$( date +%s );0" >> $_sensors_sot 

                # AUDIT LOG TRACERT
                if [ "$_audit_status" == "ENABLED" ] && [ "$_alert_status" == "0" ]
                then
                        [ -z "$_alert_sens" ] && _alert_sens="NULL"
                        [ -z "$_alert_fail" ] && _alert_fail="MARK" || _audit_alert=$( echo $_alert_fail | sed -e 's/^F$/FAIL/' -e 's/^D$/DOWN/' -e 's/^U$/UNKNOWN/' -e 's/^K$/UP/' )
                        if [ -z "$_alert_host" ] 
			then
				_alert_host="NULL" 
			else
				$_script_path/audit.nod.sh -i event -e alert -m "$_alert_sens $_alert_sens_ms" -s $_audit_alert -n $_alert_dev 2>>$_mon_log_path/audit.log
			fi
                fi
	done

}

alerts_del()
{


	for _alert_ok_dev in $( echo "${_dev_ok}" | cut -d';' -f1 )
	do
		_alert_ok_status=$( awk -F\; -v _dev="$_alert_ok_dev" 'BEGIN { _count=0 } $4 == _dev { _count++ } END { print _count }' $_sensors_sot )
	
		[ "$_alert_ok_status" -ne 0 ] && sed -i -e "/^ALERT;ENV;[0-9]*;$_alert_ok_dev;.*;3/d" -e "s/\(^ALERT;ENV;[0-9]*;$_alert_ok_dev;.*;\)[01]$/\12/" $_sensors_sot	
	done
 
}

ia_analisis()
{

for _ia_file in $(ls -1 $_sensors_env_ia | sort -nr | grep rule$ | grep -v template )
do

        _priority=`echo $_ia_file | cut -d'.' -f1`
        _ia_code=`echo $_ia_file | cut -d'.' -f2`

        _ia_code_level=0
        _var_line_level=0
        _ia_code_max=$( cat $_sensors_env_ia/$_ia_file 2>/dev/null | egrep -v "\#|^$" | awk -F\; 'BEGIN { _total=0 } { _total=_total + ( $1 * $2 ) } END { if ( _total != 0 ) { print _total } else { print "1" } }' )

        _dev_list=""
        _dev_quantity=0

	#echo "DEBUG: $_ia_file" >> /opt/cyclops/logs/DEBUG.env.err.log
	#echo "${_dev_err}" | sed "s/^/$( date +%s ) : /" >> /opt/cyclops/logs/DEBUG.env.err.log

        for _line in $(echo "${_dev_err}" )
        do
                _dev_name=$( echo $_line | cut -d';' -f1 )
                _dev_family=$( awk -F\; -v _dev=$_dev_name '$2 == _dev { print $3 }' $_dev)
                _service_num=$( echo $_line | cut -d';' -f3 ) 
                _service_name=$( awk -F\; '{ print NR";"$1 }' $_config_path_env/$_dev_family.env.cfg | awk -F\; -v _num=$_service_num '$1 == ( _num - 2 ) { print $2 }')

		#echo "DEBUG: Line: "$_dev_name" : "$_dev_family" : "$_service_num" : "$_service_name >> /opt/cyclops/logs/DEBUG.env.err.log

                _var_line_level=$( cat $_sensors_env_ia/$_ia_file 2>/dev/null | 
			egrep -v "\#|^$" | 
			awk -F\; -v _name="$_dev_name" -v _service="$_service_name" '
				BEGIN { 
					_total=0 
				} $3 == _name || $3 == "" { 
					for ( i=4 ; i<=NF ; i++ ) { 
						if ( $i == _service ) { 
							_total+=$1 
						} 
					} 
				} END { 
					print _total 
				}'
				)

                if [ ! -z "$_var_line_level" ]
                then
                        let "_rules_detected++"
                        let "_ia_code_level=_ia_code_level + _var_line_level"

                        if [ $(echo $_dev_list | grep $_dev_name | wc -l) == "0" ]
                        then
                                _dev_list=$_dev_list" "$_dev_name
                                let "_dev_quantity++"
                        fi
                fi

		#echo "CALC: "$_ia_code_level" : "$_rules_detected" : "$_dev_list >> /opt/cyclops/logs/DEBUG.env.err.log

        done


        [ -z "$_ia_code_level" ] && _ia_code_level=0
        [ "$_ia_code_level" -ne 0 ] && let "_ia_code_percent=(($_ia_code_level * 100) / $_ia_code_max) / $_dev_quantity " || _ia_code_percent=0

        [ -z "$_ia_code_percent" ] && _ia_code_percent=0

        if [ "$_ia_code_percent" -ge 1 ] && [ "$_ia_code_level" -ne 0 ]
        then
                _ia_code_des=$(cat $_sensors_ia_codes_file 2>/dev/null | grep $_ia_code | cut -d';' -f2)

                [ -z "$_ia_code_des" ] && _ia_code_des="No Description"

                #_ia_codes=$_ia_codes';'$_priority';'$_ia_code_percent'%;'$_ia_code';'$_ia_code_des';'$_dev_quantity';'$_dev_list';\n'
		_ia_codes=$_ia_codes$( echo "$_priority;$_ia_code_percent%;$_ia_code;$_ia_code_des($_ia_code_level:$_ia_code_max:$_dev_quantity);$_dev_quantity;$_dev_list" )"\n"

		#echo "$_priority;$_ia_code_percent%;$_ia_code;$_ia_code_des($_ia_code_level:$_ia_code_max:$_dev_quantity);$_dev_quantity;$_dev_list" >> /opt/cyclops/logs/DEBUG.env.err.log
        fi

done

[ -z "$_ia_codes" ] && _ia_codes="UNKNOWN;UNKNOWN;UNKNOWN($_ia_code);No relevant procedure rules detected (must be more than 40% success to considerate it);$_dev_quantity;$( [ -z "$_dev_list" ] && echo show detail table below || echo $_dev_list)"

let "_level=$_err_detected + $_rules_detected"

#echo ";DOWN NODE STATUS - IA ALERT;$_level;\n"

if [ "$_rules_detected" != "0" ]
then
        echo "PRIORITY@PROBABILITY@CODE@DESCRIPTION@HOST QTY@HOST(s) NAME"
        #echo -e "${_ia_codes}" | sort -t\; -k1,2n | sed 's/;$/;\\n/'
	echo -e "${_ia_codes}" | sed '/^$/d' | sort -t\; -k2,2nr -k1,1n
else
        echo "UNKNOWN ERRORS DETECTED;$_err_detected;;;;"
fi

}

#### MAIN EXEC ####

_dev_ok=$( cat $_sensors_ia_tmp_path/$_parent_pid"."$_sensors_ia_tmp_name | awk -F\; '$2 == "K" { print $0 }' )
_dev_err=$( cat $_sensors_ia_tmp_path/$_parent_pid"."$_sensors_ia_tmp_name | awk -F\; '$2 != "K" && $2 != "M" { print $0 }' )
_sot_active_alerts=$( cat $_sensors_sot | grep "^ALERT;ENV" | wc -l )


if [ ! -z "$_dev_err" ]
then
	alerts_gen
	ia_analisis
fi

[ "$_sot_active_alerts" -ne 0 ] && alerts_del

rm -f $_sensors_ia_tmp_path"/"$_parent_pid"."$_sensors_ia_tmp_name

#### END ####
