#!/bin/bash

###########################################
#            MON HISTORY SCRIPT           #
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
_debug_code="CYCLOPS "
_debug_prefix_msg="Cyclops Main: "
_exit_code=0
_hostname=$( hostname -s )

## GLOBAL --

_config_path="/etc/cyclops"

if [ ! -f $_config_path/global.cfg ] 
then
	echo "Global config file don't exits" 
	exit 1 
else
	source $_config_path/global.cfg
fi

if [ ! -f $_color_cfg_file ] 
then
	echo "Color config file don't exits" 
	exit 1 
else
	source $_color_cfg_file
fi

if [ ! -f $_config_path_sys/wiki.cfg ] 
then
	echo "Dokuwiki config file don't exits" 
	exit 1 
else
	source $_config_path_sys/wiki.cfg
fi

## CYCLOPS OPTION STATUS CHECK

_audit_status=$( awk -F\; '$1 == "CYC" && $2 == "0003" && $3 == "AUDIT" { print $4 }' $_sensors_sot )
_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )


#### FACTORY INFO ####

## 1. COMPACT DATA FILES FOR DUPLICATE POSIBILITY

#### END FACTORY INFO ####

###########################################
#              PARAMETERs                 #
###########################################

_command_opts=$@

while getopts ":dbh:ily:m:" _optname
do

        case "$_optname" in
                "d")
			_opt_daemon="yes"
		;;
		"m")
			_opt_month="yes"
			_par_month=$( date -d $OPTARG +%m )

			[ "$?" -ne 0 ] && echo "Date err: month setting wrong, please give it in other format" && exit 1 
		;;
		"y")
			_opt_year="yes"
			_par_year=$( date -d $OPTARG +%Y )

			[ "$?" -ne 0 ] && echo "Date err: year setting wrong, please give it in other format" && exit 1

		;;
		"i")
			_opt_index="yes"

		;;
		"l")
			_opt_link="yes"
		;;
		"b")
			_opt_bkp="yes"
		;;
		"h")
			case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops module for storage and processing old monitoring screens"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Config path: $_config_path_sys"
				echo "		Apache config path: wiki.cfg"
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
				echo "CYCLOPS MON HISTORY MANAGEMENT"
				echo "	monitoring history management script"
				echo 
				echo "	NOTE: some options not available yet"
				echo "	-d daemon option"
				echo "	-i generate index wiki for history, can use -y and -m to indicate year or month respectively"
				echo "  -l generate wiki link for history, can use -y and -m to indicate year or month respectively"
				echo "	-y [date] indicate a year for generate data entries "
				echo "  -m [month] indicate a month for generate data entries "
				echo "	-b backup older files"
				echo "	-h [|des] help is help"
				echo "		des: Detailed Command Help"
			else
				echo "ERR: Use -h for help"
				exit 1
			fi
		;;
		"*")
			echo "ERR: Use -h for help"
			exit 1
		;;
	esac
done

shift $((OPTIND-1))

###########################################
#             FUNCTIONS                   #
###########################################

relocate_files()
{
	#_relocate_date=$( date +%s )

	_count=0
	[ "$_opt_daemon" != "yes" ] && echo -e "BEGIN:\n"

	for _file in $( find $_mon_history_path/noindex/ -name "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].txt" 2>/dev/null | awk -F\/ '{ print $NF }' )
	do
		let "_count++"
		[ "$_opt_daemon" != "yes" ] && echo -ne $_count"\r"

		_file_date=$( echo $_file | cut -d'.' -f1 )
		_file_year=$( date -d @$_file_date +%Y )
		_file_month=$( date -d @$_file_date +%m )
		_file_day=$( date -d @$_file_date +%d )

		[ ! -d "$_historic_data/$_file_year" ] && mkdir -p $_historic_data/$_file_year
		[ ! -d $_mon_history_path/$_file_year/$_file_month/$_file_day ] && mkdir -p $_mon_history_path/$_file_year/$_file_month/$_file_day

		_file_content=$( cat $_mon_history_path/noindex/$_file | tr '|' ';' | grep ";" | sed -e 's/\ *;\ */;/g' -e '/^$/d' -e '/\<fc/d' -e '/:wiki:/d' -e "s/$_color_unk/UNKNOWN/g" -e "s/$_color_up/UP/g" -e "s/$_color_down/DOWN/g" -e "s/$_color_mark/MARK/g" -e "s/$_color_fail/FAIL/g" -e "s/$_color_check/CHECK/g" -e "s/$_color_ok/OK/g" | awk -F\; 'NF > 4 && $2 ~ /[a-z]/ && $2 !~ " " { print $0 }' | egrep -v "$_color_title|$_color_header" )

		_mon_err_down=$(  echo "${_file_content}" | grep -o DOWN | wc -l )	
		_mon_err_fail=$(  echo "${_file_content}" | grep -o FAIL | wc -l )
		_mon_err_mark=$(  echo "${_file_content}" | grep -o MARK | wc -l )
		_mon_err_unk=$(   echo "${_file_content}" | grep -o UNKNOWN | wc -l )
		_mon_err_check=$( echo "${_file_content}" | grep -o CHECK | wc -l )

		echo "$_file_date;$_mon_err_down;$_mon_err_fail;$_mon_err_mark;$_mon_err_unk;$_mon_err_check" >>$_historic_data/$_file_year/$_file_year.$_file_month.history.data.txt

		mv $_mon_history_path/noindex/$_file $_mon_history_path/$_file_year/$_file_month/$_file_day
		sed -i -e 's/<html>//' -e 's/<meta http-equiv=\"refresh\" content=\"[0-9]*\">//' -e 's/<\/html>//' $_mon_history_path/$_file_year/$_file_month/$_file_day/$_file

		chown -R $_apache_usr:$_apache_grp $_mon_history_path/$_file_year
		chmod -R o-rwx $_mon_history_path/$_file_year
	done

}

generate_month_index()
{

	echo 
	echo "|< 100% >|"
	echo "|  $_color_title {{ :wiki:cyclops_title.png?nolink }}  |"
	echo "|  $_color_header ** HISTORIC MONITOR DATA **  |"
	echo 
	echo "|< 100% >|" 
	echo "|  $_color_header Last Update   |  $_color_header Files Processed  |" 
	echo "|  $( date +%d-%m-%Y\ %H\.%M )  |  ## TAG_1 ##                     |" 
	echo 

	_ctrl_hid=0

	for _index_file in $( find $_historic_data/ -name '*.history.data.txt' | awk -F\/ '$NF ~ "^[0-9][0-9][0-9][0-9].[0-9][0-9].history.data.txt$" { print $0 }' | sort -n  ) 
	do
		let "_ctrl_hid++"	

		sort $_index_file | uniq -u > $_cyclops_temp_path/$_index.file.purge.dup.tmp
		cp -p $_cyclops_temp_path/$_index.file.purge.dup.tmp $_index_file

		_index_year=$(  echo $_index_file | awk -F\/ '{ print $NF }' | cut -d'.' -f1 )
		_index_month=$( echo $_index_file | awk -F\/ '{ print $NF }' | cut -d'.' -f2 )

		_index_days=$( cat $_index_file | awk -F\; 'BEGIN { _day="" ; _d = 0 ; _f = 0 ; _u = 0  } {
				 _newday=strftime("%d",$1) ; if ( NR == 1 ) { _day=_newday ; if ( _newday != "01" ) { _newday=_newday+0 ; for ( i=1; i < _newday ; i++) { if ( i ~ "[0-9][0-9]" ) { _data=i } else { _data="0"i } ;  _line=_line";DISABLE "_data } } }
				 if ( _day == _newday ) { 
                                        _d += $2 ;
                                        _f += $3 ;
                                        _u += $5 ; 
				} else {
				 	if ( _d == 0 ) {
					 	if  ( _f == 0 ) {
							 if ( _u == 0 ) {
								 _line=_line";UP "_day ; 
							} else {
								 _line=_line";UNK "_day ; 
								} 
						} else {
							 _line=_line";FAIL "_day ;
						} 
					} else { 
						_line=_line";DOWN "_day ;
					}
                                        _day=_newday ;
                                        _d = $2 ;
                                        _f = $3 ;
                                        _u = $5 ;

				} 
				} END { 
				if ( _d == 0 ) {
                                                if  ( _f == 0 ) {
                                                         if ( _u == 0 ) {
                                                                 _line=_line";UP "_day ; 
                                                        } else {
                                                                 _line=_line";UNK "_day ; 
                                                                } 
                                                } else {
                                                         _line=_line";FAIL "_day ;
                                                } 
                                        } else { 
                                                _line=_line";DOWN "_day ;
                                        }
				print _line ;
				} ' |  
				sed -e "s/[0-9][0-9]/ \*\*\ \[\[ $_wiki_history_path:$_index_year:$_index_month:&:$_index_year$_index_month&|& \]\]\ \*\*/g" -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/UNK/$_color_unk/g" -e "s/FAIL/$_color_fail/g" -e "s/DISABLE/$_color_disable/g" -e 's/;/\ \ |\ \ /g' )


		if [ "$_index_year" != "$_test_year" ] 
		then
			[ "$_ctrl_hid" -ne 1 ] && echo "</hidden>"  
			echo 
			echo "<hidden $_index_year>"
			echo "|< 100% 10% >|"
		fi
	
		echo "|  $_color_header ** $( date -d $_index_year-$_index_month-01 +%B ) ** $_index_days  |" 

		[ "$_index_year" != "$_test_year" ] && _test_year=$_index_year 

	done 

	echo "</hidden>"

}

generate_day_index()
{

	for _index_file in $( find $_historic_data/ -name '*.history.data.txt' | awk -F\/ '$NF ~ "^[0-9][0-9][0-9][0-9].[0-9][0-9].history.data.txt$" { print $0 }' | sort -n ) 
	do

		cat $_index_file | awk -F\; 'BEGIN { OFS=";" } { _date=strftime("%Y;%m;%d;%H;%M;%S",$1); print _date";"$0 }' | 
			awk -F\; -v _p="$_mon_history_path" -v _wp="$_wiki_history_path" -v _ct="$_color_title" -v _ch="$_color_header" -v _cd="$_color_down" -v _cf="$_color_fail" -v _cu="$_color_up" -v _cn="$_color_unk" -v _cm="$_color_mark" -v _cc="$_color_check" '{
				_hs="" ; _hsb=""
				if ( $8 == 0 ) { $8=_cu" "$8" " } else { $8=_cd" <fc white> "$8" </fc>" ; _hs=_cc ; _hsb=" ** " } ; 	
				if ( $9 == 0 ) { $9=_cu" "$9" " } else { $9=_cf" <fc white> "$9" </fc>" ; _hs=_cc ; _hsb=" ** " } ;
				if ( $10 == 0 ) { $10=_cu" "$10" " } else { $10=_cm" "$10" " ; _hs=_cc ; _hsb=" ** " } ;
				if ( $11 == 0 ) { $11=_cu" "$11" " } else { $11=_cn" <fc white> "$11" </fc>" ; _hs=_cc ; _hsb=" ** " } ;
				 if ( $3 != _day ) {
					 _year=$1 ;
					 _month=$2 ;
					 _day=$3 ;
					 if ( NR != "1" ) { print "</hidden>" >> _file; } 
					 _file=_p"/"_year"/"_month"/"_day"/"_year""_month""_day".txt";
					 _hour=$4 ;

					 print "" > _file ;
					 print "|< 100% >|" >> _file;
					 print "|  "_ct" {{ :wiki:cyclops_title.png?nolink }}  |" >> _file ; 
					 print "|  "_ch" ** HISTORIC MONITOR DATA **  |" >>_file ;
					 print "" >> _file; 
					 print "|< 100% >|" >> _file;
					 print "|  "_ch" Date  |  "$1"-"$2"-"$3"  |" >> _file;
					 print "" >> _file;
					 print "<hidden HOUR: "$4" >" >> _file ;
					 print "|< 100% 25% 15% 15% 15% 15% 15% >|" >> _file;
					 print "|  "_ch"  File  |  "_ch" Down Errs  |  "_ch" Fail Errs  |  "_ch" Warnings  |  "_ch" Unknown Errs  |  "_ch" Other Msgs  |" >> _file; 
					 print "|  "_hs" "_hsb"[[ "_wp":"_year":"_month":"_day":"$7"| "$4":"$5":"$6" ]] "_hsb" |  "$8"  |  "$9"  |  "$10"  |  "$11"  |  "$12"   |" >> _file ;

				} else if ( $4 != _hour ) { 
						_hour=$4 ;
						 print "</hidden>" >> _file;
						 print "" >> _file;
					 	 print "<hidden HOUR: "$4" >" >> _file ;
					 	 print "|< 100% 25% 15% 15% 15% 15% 15% >|" >> _file;
					 	 print "|  "_ch"  File  |  "_ch" Down Errs  |  "_ch" Fail Errs  |  "_ch" Warnings  |  "_ch" Unknown Errs  |  "_ch" Other Msgs  |" >> _file; 
						 print "|  "_hs" "_hsb"[[ "_wp":"_year":"_month":"_day":"$7"| "$4":"$5":"$6" ]] "_hsb" |  "$8"  |  "$9"  |  "$10"  |  "$11"  |  "$12"   |" >> _file ; 
					 } else {
						 print "|  "_hs" "_hsb"[[ "_wp":"_year":"_month":"_day":"$7"| "$4":"$5":"$6" ]] "_hsb" |  "$8"  |  "$9"  |  "$10"  |  "$11"  |  "$12"   |" >> _file ;
						}
				}
				END {
					print "</hidden>" >> _file;
			}' 2>/dev/null

	done

}

backup_old_history()
{

	echo "Thinking in progress"


}

ha_check()
{

        _ha_master_host=$( cat $_sensors_sot | grep "^CYC;0006;HA" | cut -d';' -f5 )
        _ha_role_me=$( cat $_ha_role_file )

        if [ "$_hostname" != "$_ha_master_host" ]
        then
                if [ "$_ha_role_me" == "SLAVE" ]
                then
                        echo "WARNING: HA CONFIG ENABLED"
                        echo "$_hostname in SLAVE mode" 
                        echo "Trying to execute command on master node ($_ha_master_host)"
                        echo

			_ha_check_master=$( ssh -o ConnectTimeout=5 $_ha_master_host cat $_ha_role_file )

                        if [ "$_ha_check_master" == "MASTER" ] 
			then
				ssh $_ha_master_host $_script_path/historic.mon.sh $_command_opts
                        	exit_code=$?
			else
				echo "MASTER SEEMS DOWN, NO EXEC REMOTE COMMAND"
				exit_code=1
			fi

                        [ "$_exit_code" -ne 0 ] && echo "ERROR ($_exit_code): please connect to $_ha_master_host to exec the command"
                fi
        else
                if [ "$_ha_role_me" == "MASTER" ]
                then
			echo "ALL OK: EXEC DAEMON"
			daemon_exec 
		else
                        echo -e "WARNING: HA CONFIG ON POSIBLE SPLIT BRAIN SITUATION force MASTER on UPDATER node" 
			_exit_code="1"
                fi
        fi
}

daemon_exec()
{
	relocate_files
	generate_month_index > $_mon_history_path/start.txt

	chmod o-rwx $_mon_history_path/start.txt
	chown $_apache_usr:$_apache_grp $_mon_history_path/start.txt

	generate_day_index
}

###########################################
#               MAIN EXEC                 #
###########################################

	if [ "$_opt_daemon" == "yes" ] 
	then
		if [ "$_cyclops_ha" == "ENABLED" ] 
		then
			ha_check 2>/dev/null 
		else
			daemon_exec	
		fi
	fi

	exit $_exit_code
