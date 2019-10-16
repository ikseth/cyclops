#!/bin/bash

#### THIS SCRIPT TEST CRITICAL ENVIRONMENT, DEFINED IN /etc/cyclops/critical.res.cfg ####
#### VERSION 2.0 ####

############# VARIABLES ###################
#

IFS="
"

_pid=$( echo $$ )
_exit_code=0

_par_show="human"

## GLOBAL --

_config_path="/etc/cyclops"

if [ ! -f $_config_path/global.cfg ] 
then
	echo "Global config file don't exits ( $_config_path ) " 
	exit 1 
else
	source $_config_path/global.cfg
fi

if [ ! -f "$_color_cfg_file" ] || [ -z "$_color_cfg_file" ]
then
	echo "Color Config file don't exits ( $_color_cfg_file ) " 
	exit 1 
else
	source $_color_cfg_file
fi

if [ ! -f "$_critical_res" ] || [ -z "$_critical_res" ]
then
	echo "Critical Environment config file don't exits ( $_critical_res ) " 
	exit 1
fi

_par_type="pasive" ## TEMP , WITH TIME WE FINISH

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":t:v:h:" _optname
do

        case "$_optname" in
		"t")
			_opt_type="yes"
			_par_type=$OPTARG
			if [ "$_par_type" != "active" ] && [ "$_par_type" != "pasive" ]
			then
				echo "-t [option] Select Analisys Type"
				echo "		active: launch a new monitoring task to analisys"
				echo "		pasive:	use a existing monitoring results to analisys"
				exit 1
			fi
		;;
                "v")
                        _opt_show="yes"
                        _par_show=$OPTARG
                        if [ !"$_par_show" == "human" ] || [ !"$_par_show" == "commas" ] || [ !"$_par_show" == "simple" ] || [ !"$_par_show" == "debug" ]
                        then
                                echo "-v [option] Show formated results"
                                echo "          human: human readable"
                                echo "          commas: excel readable"
                                echo "          simple: minimal status info"
                                exit 1
                        fi
                ;;
		"h")
			case "$OPTARG" in
			"des")
				echo "$( basename "$0" ) : Check tool to know status of critical resources for users produtive environment"
				echo "	Default path: $( pwd )"
				echo "	Config file: $_critical_res"
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
				echo "-t [option] Select Analisys Type"
				echo "		active: launch a new monitoring task to analisys"
				echo "		pasive: use a existing monitoring results to analisys"	
				echo "-v [option] Show formated results"
				echo "		human: human readable"
				echo "		commas: excel readable"
				echo "		simple: minimal status info"
				echo "-h help is help"
				exit 0
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
#               FUNCTIONs                 #
###########################################

mon_launch_active()
{
	for _family in $( cat $_critical_res | grep -v ^\# | cut -d';' -f4 )  
	do
		let "_mon_index++"
		_mon[$_mon_index]=$( $_sensors_mon_script_file -v wiki -m $_family ) & 
#		_mon[$_mon_index]=$( cat /opt/cyclops/tools/testing/temp.mon.$_family.txt )
	done
	wait

}

mon_launch_pasive()
{
	_mon[1]=$( cat $_mon_path/monnod.txt 2>/dev/null )
}

mon_analisys()
{
        _mon_nod_input=$( echo "${_mon[*]}" | tr '|' ';' | awk -F\; 'NF > 5 { print $0 }' | sed -e 's/ //g' -e "s/$_color_up/UP /g" -e "s/$_color_fail/FAIL /g" -e "s/$_color_ok/OK /g" -e "s/$_color_down/DOWN /g" -e 's/@#[0-9A-F]*\://g' -e 's/^;//' -e 's/ ;/;/g' -e 's/;$//' )
        _env_status_pg_status="OPERATIVE"
	_env_status_pg_global="OPERATIVE"
        _env_status_pg_alert=0
	

        for _env_status_pg_line in $( cat $_critical_res | grep -v ^\# )
        do
		let "_analisys_index++"
                _env_status_pg_total_nod=$( echo $_env_status_pg_line | cut -d';' -f2 )
                _env_status_pg_min_nod=$(   echo $_env_status_pg_line | cut -d';' -f3 )
                _env_status_pg_family=$(    echo $_env_status_pg_line | cut -d';' -f4 )
                _env_status_pg_res_list=$(  echo $_env_status_pg_line | cut -d';' -f5- )
		_env_status_pg_total_real=$( awk -F\; -v _f="$_env_status_pg_family" 'BEGIN { _count=0 } $3 == _f || $4 == _f { _count++ } END { print _count }' $_type )

                _env_status_pg_input=$(  echo "${_mon_nod_input}" | grep -B 1 "^$_env_status_pg_family;" )
                _env_status_pg_filter=$( echo "${_env_status_pg_input}" | awk -F\; -v cols="$_env_status_pg_res_list" 'BEGIN { OFS=";" ; split(cols,out,";") } NR==1 { for (i=1;i<=NF;i++) ix[$i]=i } NR>1 { for (i in out) printf "%s%s", $ix[out[i]], OFS ; print "" }' )
                _env_status_pg_health=$( echo "${_env_status_pg_filter}" | awk -F\; 'BEGIN { _node=0 } { if ( $0 ~ /FAIL|DOWN|DIAGNOSE|MAINTENANCE|CONTENT|REPAIR/ ) _node++ } END { print _node }' )

                if [ "$_env_status_pg_health" -ne 0 ]
                then
                        _env_status_pg_alert=1
                        let "_env_status_pg_total=_env_status_pg_total_real - _env_status_pg_health"

                        if [ "$_env_status_pg_total" -lt "$_env_status_pg_min_nod" ]
			then
                                _env_status_pg_status="NOT OPERATIVE"
				if [ "$_env_status_pg_global" == "OPERATIVE" ] || [ "$_env_status_pg_global" == "OPERATIVE WITH WARNINGS" ] 
				then
					_env_status_pg_global="NOT OPERATIVE"
				fi
			else
				if [ "$_env_status_pg_total" -lt "$_env_status_pg_total_nod" ]
				then
					_env_status_pg_status="OPERATIVE WITH WARNINGS"
					[ "$_env_status_pg_global" == "0" ] && _env_status_pg_global="OPERATIVE WITH WARNINGS"
				else
					_env_status_pg_status="OPERATIVE"
				fi
			fi
		else
			_env_status_pg_status="OPERATIVE"
                fi

		_env_array_health[$_analisys_index]="$_env_status_pg_family;$_env_status_pg_status"
        done

        [ "$_env_status_pg_status" == "OPERATIVE" ] && [ "$_env_status_pg_alert" -ne 0 ] && _env_status_pg_color=$_color_fail

}

print_output()
{
	[ "$_par_type" == "pasive" ] && echo "analisys type;PASIVE"
	[ "$_par_type" == "active" ] && echo "analisys type;ACTIVE"
	echo "${_env_array_health[*]}"
	echo "final result;$_env_status_pg_global"
	
}

###########################################
#              MAIN EXECs                 #
###########################################


	case "$_par_type" in
	"pasive")
		_date=$( stat -c %Y $_mon_path/dashboard.txt )
		mon_launch_pasive
	;;
	"active")
		_date=$( date +%s )
		mon_launch_active
	;;
	esac

	mon_analisys

	case "$_par_show" in
	"commas")
		echo "date;$_date"
		print_output
	;;
	"human")
		echo
		echo "critical environment analisys"
		echo "-----------------------------"
		echo 
		print_output | awk -F\; -v idate="$_date" 'BEGIN { date=strftime("%m-%d-%Y",idate) ; time=strftime("%H:%M",idate) } { if ( $1 == "analisys type" ) { print $0 ; print "source date;"date ; print "time;"time ; print "@" ; print "detailed results" ; print "-----------------------------" } else if ( $1 == "final result" ) { print "-----------------------------" ; print "@" ; print toupper ( $0 ) } else { print $0 }}' | column -s\; -t | sed 's/@//'
		echo
	;;
	"simple")
		print_output | grep "^final result;" | sed "s/^/$( date -d @$_date +%m-%d-%Y\;%H:%M );/"
	;;
	esac

