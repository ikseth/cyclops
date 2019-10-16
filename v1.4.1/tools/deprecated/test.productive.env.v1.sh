#!/bin/bash

#### THIS SCRIPT TEST ONLY A LUSTRE+SLURM+INFINIBAND ENVIRONMENT ####

############# VARIABLES ###################
#

IFS="
"

_pid=$( echo $$ )
_debug_code="SEN.ENVHARD "
_debug_prefix_msg="Environment Hardware Monitoring: "
_exit_code=0

_par_show="human"
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

_par_type="active" ## TEMP , WITH TIME WE FINISH

###########################################
#              PARAMETERs                 #
###########################################

while getopts "t:v:ih" _optname
do

        case "$_optname" in
                "v")
                        _opt_show="yes"
                        _par_show=$OPTARG
                        if [ !"$_par_show" == "human" ] || [ !"$_par_show" == "wiki" ] || [ !"$_par_show" == "commas" ] || [ !"$_par_show" == "simple" ] || [ !"$_par_show" == "debug" ]
                        then
                                echo "-v [option] Show formated results"
                                echo "          human: human readable"
                                echo "          wiki:  cyclops format readable"
                                echo "          commas: excel readable"
				echo "		simple: minimal status info"
                                exit 1
                        fi
		;;
		"t")
			_opt_type="yes"
			_par_type=$OPTARG
			if [ !"$_par_show" == "active" ] || [ !"$_par_show" == "pasive" ]
			then
				echo "-t [option] Launch test with active or pasive monitoring"
				echo "		active: Script Launch Real Time Mon to Generate Report about Environment"
				echo "		pasive: Script use last existing Mon to Generate Environment Report" 
				exit 1
			fi
		;;
		"h")
			echo
			echo "Script to test Productive Environment"
			echo "-v [option] Show formated results"
			echo "	human: (default) human readable"
			echo "	wiki:  cyclops format readable"
			echo "	commas: excel readable"
			echo "	simple: minimal status info"
                        echo "-t [option] Launch test with active or pasive monitoring"
                        echo "	active: (default) Script Launch Real Time Mon to Generate Report about Environment"
                        echo "	pasive: Script use last existing Mon to Generate Environment Report"
			echo "-h help is help"
			echo
			exit 0
		;;
	esac
done

###########################################
#              FUNCTIONs                  #
###########################################

test_env()
{
	case "$_par_type" in 
		"active")
			_environment=$( /opt/cyclops/scripts/sensors.nodes.mon.sh -v commas | sed '/^$/d' ) ## CHANGE WITH VARIABLE
		;;
		"pasive")
			_environment=$( cat $_mon_path/monnod.txt | tr '|' ';' | awk -F\; 'NF > 5 { print $0 }' | sed -e 's/ //g' -e "s/$_color_up/UP /g" -e "s/$_color_fail/FAIL /g" -e "s/$_color_ok/OK /g" -e "s/$_color_down/DOWN /g" -e 's/@#[0-9A-F]*\://g' -e 's/^;//' -e 's/ ;/;/g' -e 's/;$//' ) 
		;;
	esac 
}

test_customize()
{
	echo "WE ARE WORKING ON IT"
}

test_infiniband()
{

	echo "WE ARE WORKING ON IT"
}

test_lustre()
{

	_lustre_global_status=$( echo "${_environment}" | awk -F\; 'BEGIN { _field=0 } { if ( NF > 9 ) {  if ( $1 == "family" ) { for(i=1;i<=NF;i++) if ( $i == "lustre_fs1" ) { _field=i }} else if ( _famold == $1 ) { if ( $_field ~ "UP" || $_field ~ "OK" ) { _ok++ } else { _bad++ }} else { if ( $_field ~ "UP" || $_field ~ "OK" ) { _ok++ } else { _bad++ } ; print _famold";"_ok";"_bad ; _famold=$1 ; _ok=0 ; _bad=0 }}} END { if ( $_field ~ "UP" || $_field ~ "OK" ) { _ok++ } else { _bad++ } ; print _famold";"_ok";"_bad }' | sed '/^;1;$/d' ) 

	_lustre_main_srv=$( cat $_type | awk -F\; '$3 == "lustre" { _c++ } END { print _c }' )
	_lustre_login_srv=$( cat $_type | awk -F\; '$3 == "login" { _c++ } END { print _c }' )
	_lustre_io_srv=$( cat $_type | awk -F\; '$3 == "io" { _c++ } END { print _c }' )
	#_lustre_compute_srv=$( cat $_type | awk -F\; '$4 == "compute" { _c++ } END { print _c }' )
	_lustre_compute_srv=$( cat $_type | awk -F\; '$3 == "air" { _c++ } END { print _c }' )
	
	_lustre_main_srv_ok=$( echo "${_lustre_global_status}" | awk -F\; '$1 == "lustre" { print $2 }' )
	_lustre_login_srv_ok=$( echo "${_lustre_global_status}" | awk -F\; '$1 == "login" { print $2 }' )
	_lustre_io_srv_ok=$( echo "${_lustre_global_status}" | awk -F\; '$1 == "io" { print $2 }' )
	#_lustre_compute_srv_ok=$( echo "${_lustre_global_status}" | awk -F\; '$1 == "air" || $1 ~ "water" { _c=_c+$2 } END { print _c }' )
	_lustre_compute_srv_ok=$( echo "${_lustre_global_status}" | awk -F\; '$1 == "air" { _c=_c+$2 } END { print _c }' )

	[ -z "$_lustre_main_srv_ok" ] && _lustre_main_status="U" || let "_lustre_main_status=( _lustre_main_srv_ok * 100 ) / _lustre_main_srv"
	[ -z "$_lustre_login_srv_ok" ] && _lustre_login_status="U" || let "_lustre_login_status=( _lustre_login_srv_ok * 100 ) / _lustre_login_srv"
	[ -z "$_lustre_io_srv_ok" ] && _lustre_io_status="U" || let "_lustre_io_status=( _lustre_io_srv_ok * 100 ) / _lustre_io_srv"
	[ -z "$_lustre_compute_srv_ok" ] && _lustre_compute_status="U" || let "_lustre_compute_status=( _lustre_compute_srv_ok * 100 ) / _lustre_compute_srv"

	case "$_lustre_main_status" in
	#	100)
	#		_lustre_main_msg="FULL OPERATIVE($_lustre_main_status%)"
	#		_lustre_main_status="40"
	#	;;
		75)
			_lustre_main_msg="FULL OPERATIVE"
			_lustre_main_status="40"
		;;
		[0-6][0-9]|7[0-4])
			_lustre_main_msg="NO OPERATIVE($_lustre_main_status%)"
			_lustre_main_status="0"
		;;
	esac

	case "$_lustre_login_status" in
		100)
			_lustre_login_msg="FULL ACCESS"
			_lustre_login_status="3"
		;;
		50)
			_lustre_login_msg="PARTIAL ACCESS"
			_lustre_login_status="1"
		;;
		[0-4][0-9])
			_lustre_login_msg="NO ACCESS"
			_lustre_login_status="0"
		;;
	esac

	case "$_lustre_io_status" in
		100)
			_lustre_io_msg="FULL ACCESS"
			_lustre_io_status="3"
		;;
		50)
			_lustre_io_msg="FULL ACCESS WITH ONE NODE"
			_lustre_io_status="1"
		;;
		[0-4][0-9])
			_lustre_io_msg="NO ACCESS"
			_lustre_io_status="0"
		;;
	esac

	case "$_lustre_compute_status" in
		100)
			_lustre_compute_msg="FULL RESOURCES AVAILABLE"
			_lustre_compute_status="20"
		;;
		75)
                       _lustre_compute_msg="PARTIAL RESOURCES AVAILABLE ($_lustre_compute_status%)"
                       _lustre_compute_status="10"
		;;
		50)
                       _lustre_compute_msg="MINIMUN RESOURCES AVAILABLE ($_lustre_compute_status%)"
                       _lustre_compute_status="5"
		;;	
		[0-9]|1[0-9]|2[0-5])
			_lustre_compute_msg="NO ENOUGHT RESOURCES AVAILABLE ($_lustre_compute_status%)"
			_lustre_compute_status="0"
		;;
#		100) 
#			_lustre_compute_msg="FULL RESOURCES AVAILABLE ($_lustre_compute_status%) "
#			_lustre_compute_status="20"
#		;;
#		[5-9][0-9])
#			_lustre_compute_msg="PARTIAL RESOURCES AVAILABLE ($_lustre_compute_status%)"
#			_lustre_compute_status="10"
#		;;
#		[2-4]|[0-9])
#			_lustre_compute_msg="MINIMUN RESOURCES AVAILABLE ($_lustre_compute_status%)"
#			_lustre_compute_status="5"
#		;;	
#		[0-1][0-9])
#			_lustre_compute_msg="TOO POOR RESOURCES AVAILABLE ($_lustre_compute_status%)"
#			_lustre_compute_status="3"
#		;;
#		0)
#			_lustre_compute_msg="NO RESOURCES AVAILABLE ($_lustre_compute_status%)"
#			_lustre_compute_status="0"
#		;;
		*)
			_lustre_compute_msg="UNKNOWN STATUS ($_lustre_compute_msg)"
			_lustre_compute_status="1"
		;;
	esac
	
	if [ $_lustre_main_status -eq 0 ]
	then
		_lustre_status=0
	else
		let "_lustre_status=_lustre_main_status + _lustre_login_status + _lustre_io_status + _lustre_compute_status"
	fi

	case "$_lustre_status" in
		66)
			_lustre_status_msg="FULL OPERATIVE"
			_lustre_status=15
		;;
		6[0-4]|5[0-9])
			_lustre_status_msg="OPERATIVE WITH WARNINGS"
			_lustre_status=5
		;;
		4[6-9])
			_lustre_status_msg="OPERATIVE BUT DANGEROUS STATE"
			_lustre_status=5
		;;
		[0-9]|[1-3][0-7]|4[0-5])
			_lustre_status_msg="NOT OPERATIVE"
			_lustre_status=0
		;;
	esac
		

		
}

test_slurm()
{

        _slurm_global_status=$( echo "${_environment}" | awk -F\; 'BEGIN { _field=0 } { if ( NF > 9 ) {  if ( $1 == "family" ) { for(i=1;i<=NF;i++) if ( $i == "slurm_node_status" ) { _field=i }} else if ( _famold == $1 ) { if ( $_field ~ "idle" || $_field ~ "working" ) { _ok++ } else { _bad++ }} else { if ( $_field ~ "UP" || $_field ~ "OK" ) { _ok++ } else { _bad++ } ; print _famold";"_ok";"_bad ; _famold=$1 ; _ok=0 ; _bad=0 }}} END { if ( $_field ~ "UP" || $_field ~ "OK" ) { _ok++ } else { _bad++ } ; print _famold";"_ok";"_bad }' | sed '/^;1;$/d' )


	_slurm_mng_status=$( haresl listprefs 2>/dev/null | grep slurm )
	_slurm_ctrl_status=$( echo "${_slurm_mng_status}" | awk '$1 == "slurm" { print $0 }' | grep "running on" 2>&1 >/dev/null ; echo $?  )
	_slurm_db_status=$( echo "${_slurm_mng_status}" | awk '$1 == "slurmdbd" { print $0 }' | grep "running on" 2>&1 >/dev/null ; echo $? )

        #_slurm_compute_srv=$( cat $_type | awk -F\; '$4 == "compute" { _c++ } END { print _c }' )
	_slurm_compute_air=$( cat $_type | awk -F\; '$3 ~ "air" { _c++ } END { print _c }' )
	_slurm_compute_water=$( cat $_type | awk -F\; '$3 ~ "water" { _c++ } END { print _c }' )
        #_slurm_compute_srv_ok=$( echo "${_slurm_global_status}" | awk -F\; '$1 == "air" || $1 ~ "water" { _c=_c+$2 } END { print _c }' )
	_slurm_compute_air_ok=$( echo "${_slurm_global_status}" | awk -F\; '$1 == "air" { _c=_c+$2 } END { print _c }' )
	_slurm_compute_water_ok=$( echo "${_slurm_global_status}" | awk -F\; '$1 ~ "water" { _c=_c+$2 } END { print _c }' )

        #let "_slurm_compute_status=( _slurm_compute_srv_ok * 100 ) / _slurm_compute_srv"
	
	let "_slurm_compute_air_status=( _slurm_compute_air_ok * 100 ) / _slurm_compute_air"
	let "_slurm_compute_water_status=( _slurm_compute_water_ok * 100 ) / _slurm_compute_water"


	case "$_slurm_ctrl_status" in
		"0")
			_slurm_ctrl_msg="FULL OPERATIVE"
			_slurm_ctrl_status="50"	
		;;
		"")
			_slurm_ctrl_msg="NO OPERATIVE"
			_slurm_ctrl_status="0"	
		;;
	esac

	case "$_slurm_db_status" in
                "0")
                        _slurm_db_msg="FULL OPERATIVE"
                        _slurm_db_status="40"
                ;;
                "")
                        _slurm_db_msg="NO OPERATIVE"
                        _slurm_db_status="0"
                ;;
        esac

	case "$_slurm_compute_air_status" in
		100)
                        _slurm_compute_air_msg="FULL RESOURCES AVAILABLE ($_slurm_compute_air_status%)"
                        _slurm_compute_air_status="30"
		;;
		7[5-9]|[8-9][0-9])
                        _slurm_compute_air_msg="MINIMAL RESOURCES AVAILABLE ($_slurm_compute_air_status%)"
                        _slurm_compute_air_status="20"
		;;
		[0-9]|[0-6][0-9]|7[0-4])
                        _slurm_compute_air_msg="NO ENOUGHT RESOURCES AVAILABLE ($_slurm_compute_air_status%)"
                        _slurm_compute_air_status="0"
		;;
		*)
                        _slurm_compute_air_msg="UNKNOWN STATUS"
                        _slurm_compute_air_status="1"
		;;
	esac

        case "$_slurm_compute_water_status" in
		*)
			### DELETE THIS OPTION WHEN WATER COMPUTE NODE WILL BE GOING PRODUCTION TASK 
                        _slurm_compute_water_msg="RESOURCES NOT NECESARY YET, AVAILABLE ($_slurm_compute_water_status%)"
                        _slurm_compute_water_status="10"
		;;
                100)
                        _slurm_compute_water_msg="FULL RESOURCES AVAILABLE ($_slurm_compute_water_status%)"
                        _slurm_compute_water_status="10"
                ;;
                7[5-9]|[8-9][0-9])
                        _slurm_compute_water_msg="MINIMAL RESOURCES AVAILABLE ($_slurm_compute_water_status%)"
                        _slurm_compute_water_status="5"
                ;;
                [0-9]|[0-6][0-9]|7[0-4])
                        _slurm_compute_water_msg="NO ENOUGHT RESOURCES AVAILABLE ($_slurm_compute_water_status%)"
                        _slurm_compute_water_status="0"
                ;;
                *)
                        _slurm_compute_water_msg="UNKNOWN STATUS"
                        _slurm_compute_water_status="1"
                ;;
        esac

        if [ $_slurm_ctrl_status -eq 0 ] || [ $_slurm_compute_air_status -eq 0 ] || [ $_slurm_db_status -eq 0 ]
        then
                _slurm_status=0
        else
                let "_slurm_status=_slurm_ctrl_status + _slurm_db_status + _slurm_compute_air_status + _slurm_compute_water_status"
        fi

        case "$_slurm_status" in
                130)
                        _slurm_status_msg="FULL OPERATIVE"
			_slurm_status=15
                ;;
		125|115)
			_slurm_status_msg="OPERATIVE WITH WARNINGS"
			_slurm_status=5
		;;
		121|120|111|110)
			_slurm_status_msg="OPERATIVE WITH WATER WARNING STATUS"
			_slurm_status=5
		;;
		[0-9]|[0-9][0-9]|10[0-1])
			_slurm_status_msg="NO OPERATIVE"
			_slurm_status=0
		;;
        esac

}

ia_env()
{
	let "_env_status=_slurm_status + _lustre_status"

	case "$_env_status" in 
		30)
			_env_status_msg="FULL OPERATIVE"
			_env_status_code="0"
		;;
		1[0-9]|2[0-9])
			_env_status_msg="OPERATIVE WITH WARNINGS"
			_env_status_code="2"
		;;
		[0-9])
			_env_status_msg="NOT OPERATIVE"
			_env_status_code="1"
		;;
		*)
			_env_status_msg=$_env_status
			_env_status_code="3"
		;;
	esac

}

print_output()
{
	case "$_par_show" in 
	human)
        	echo "SYSTEM STATUS - ANALISYS REPORT"
		echo "============================================="
	        echo "LUSTRE STATUS  : $_lustre_status_msg "
		echo "---------------------------------------------"
	        echo "MAIN SERVERS   : $_lustre_main_msg"
		echo "COMPUTE NODES  : $_lustre_compute_msg"
	        echo "IO SERVERS     : $_lustre_io_msg"
	        echo "LOGIN SERVERS  : $_lustre_login_msg"
	        echo 
		echo "SLURM STATUS   : $_slurm_status_msg "
		echo "---------------------------------------------"
		echo "CONTROL SERVERS: $_slurm_ctrl_msg"
		echo "DATABASE       : $_slurm_db_msg"
		echo "COMPUTE AIR    : $_slurm_compute_air_msg" 
		echo "COMPUTE WATER  : $_slurm_compute_water_msg"
		echo
		echo "PRODUCTIVE ENVIRONMENT STATUS:"
		echo "---------------------------------------------"
		echo $_env_status_msg
		echo
	;;
	commas)
		echo "SYSTEM STATUS;ANALISYS REPORT;$_env_status_msg"
		echo "LUSTRE;STATUS;$_lustre_status_msg"
		echo "LUSTRE;MAIN SERVERS;$_lustre_main_msg"
		echo "LUSTRE;COMPUTE NODES;$_lustre_compute_msg"
		echo "LUSTRE;IO SERVERS;$_lustre_compute_msg"
		echo "LUSTRE;LOGIN SERVERS;$_lustre_login_msg"
		echo "SLURM;STATUS;$_slurm_status_msg"
		echo "SLURM;CONTROL SERVERS;$_slurm_ctrl_msg"
		echo "SLURM;DATABASE;$_slurm_db_msg"
		echo "SLURM;COMPUTE AIR;$_slurm_compute_air_msg"
		echo "SLURM;COMPUTE WATER;$_slurm_compute_water_msg"
	;;
	simple)
		echo $_env_status_code
	;;
	wiki)
		echo "WE WORKING ON IT ;)"
	;;
	debug)
		echo 
		echo "DEBUG DATA"
		echo "========================================"
		echo "========================================"
		echo 
		echo "lustre"
		echo 
		echo "${_lustre_global_status}" | sed 's/^/1: /'
		echo "${_lustre_main_srv}" | sed 's/^/2: /'
		echo "${_lustre_login_srv}" | sed 's/^/3: /'
		echo "${_lustre_io_srv}" | sed 's/^/4: /'
		echo "${_lustre_compute_srv}" | sed 's/^/5: /'
		echo "${_lustre_main_srv_ok}" | sed 's/^/6: /'
		echo "${_lustre_login_srv_ok}" | sed 's/^/7: /'
		echo "${_lustre_io_srv_ok}" | sed 's/^/8: /'
		echo "${_lustre_compute_srv_ok}" | sed 's/^/9: /'
		echo 
		echo "slurm"
		echo
		echo "${_slurm_global_status}" | sed 's/^/1: /'
		echo "${_slurm_ctrl_status}" | sed 's/^/2: /'
		echo "${_slurm_db_status}" | sed 's/^/3: /'
		echo "${_slurm_compute_status}" | sed 's/^/4: /'
	;;
	esac
}

###########################################
#              MAIN EXEC                  #
###########################################

	[ ! "$_par_show" == "simple" ] && echo "1: GETTING DATA FROM CYCLOPS MONITORING"

	test_env	
	
	[ ! "$_par_show" == "simple" ] && echo "2: ANALYZING LUSTRE DATA"

	test_lustre

	[ ! "$_par_show" == "simple" ] && echo "3: ANALYZING SLURM DATA"

	test_slurm

	[ ! "$_par_show" == "simple" ] && echo "4: PROCESSING FINAL DATA"

	ia_env

	[ ! "$_par_show" == "simple" ] && echo -e "5: SHOW RESULTS\n"

	print_output

	exit $_env_status_code
