#!/bin/bash

#### GLOBAL VARIABLES ####

_config_path="/etc/cyclops"

if [ -f $_config_path/local.cfg ]
then
        source $_config_path/local.cfg
	source $_config_path/autolink.cfg
else
        echo "Local Cyclops config don't exits" 
        exit 1
fi

_local_log=$_cyc_local_log_path"/cyc.autolink.nodes.err.log"

###########################################
#              PARAMETERs                 #
###########################################

_date=$( date +%s )

while getopts "da:h" _optname
do
        case "$_optname" in
		"d")
			_opt_dae="yes"
		;;
		"a")
			_opt_chk="yes"
			_par_chk=$OPTARG
		;;
                "h")
			echo "CYCLOPS AUTOLINK TOOL"
			echo "ACTION DAEMON WORK:"
			echo "	A. Check autolink enable|disable"
			echo "	B: if pass A. > Config checks:"
			echo "		1. Put client in temporal drain mode"
			echo "		2. Check Resources and services config files"
			echo "	C: if pass B. > Exec"
			echo "		1. activate configured resources and services"
			echo "		2. check client"
			echo "	D: if pass C. > Exec"
			echo "		1. Put Client in up mode" 
			echo 
			echo "OPTIONS:"
			echo "	-d Daemon option, launch on boot with automatic settings enable"
			echo "	-a [check|link|disable|enable] Tool Actions"
			echo "		check: launch check options"
			echo "		link: activate configurated resources and services , implies check"
			echo "		enable:	enable autolink on boot" 
			echo "		disable: disable autolink on boot"
                        echo
                        exit 0
                ;;
        esac
done

###########################################
#              FUNCTIONs                  #
###########################################

sleep 10s
echo -e "\n\rCYCLOPS: AUTO LINK NODES TO OPERATIVE ENVIRONMENT\n\r"
[ -f "$_disable_file" ] && echo -ne "AUTOLINK DISABLE: delete $_disable_file to enabled\n\r" && exit 0

check_config()
{


	_slurm_conf="/etc/slurm/slurm.conf"
	_ib_main_dev="ib0"
	_nfs_server="nfs-ib-server.bullx"
	_lustre_fs=$( shine list | grep -v mgs )
	_cyclops_mng="yes"
	_disable_file="/root/disable.autolink"

	echo -ne "Checking configs\n\r"

if [ -f "$_slurm_conf" ]
then
	echo -ne "CHECK OK: slurm.conf available\n\r"
	_slurm_main_server=$( cat $_slurm_conf | grep ^ControlMachine | cut -d'=' -f2 | cut -d',' -f1 )
	_slurm_bkp_server=$(  cat $_slurm_conf | grep ^ControlMachine | cut -d'=' -f2 | cut -d',' -f2 )
	_slurm_init=$( scontrol update nodename=$HOSTNAME state=drain reason="Initializating safe stop: $_status" 2>&1 >/dev/null ; echo $? )
	[ "$_slurm_init" == "0" ] && echo -ne "SLURM SAFE INIT EJECT NODE: OK\n\r" || echo -ne "SLURM SAFE EJECT NODE: FAIL\n\r"
else
	_status="101"
	echo -ne "ERR: slurm.conf not exist\n\r"
	echo "ERR: $_status" >> $_local_log
	exit $_status
fi

if [ -z "$_slurm_main_server" ] && [ -z "$_slurm_bkp_server" ] 
then
	_status="102"
	echo -ne "ERR: ctl slurm server not find\n\r"	
	echo "ERR: $_status" >> $_local_log
	exit $_status
else
	echo -ne "CHECK OK: ctl slurm available\n\r"
fi

if [ -z "$_lustre_fs" ]
then
	_status="103"
	echo -ne "ERR: not find lustre fs\n\r"
	echo "ERR: $_status" >> $_local_log
	exit $_status
else
	echo -ne "CHECK OK: lustre fs available\n\r"
fi
}


echo -ne "\n\rWait 20s for lazy daemons\n\r"


check_ib_dev()
{
	_check_available_dev=$( ibstat | grep Physical\ state | grep -o LinkUp 2>&1 >/dev/null ; echo $? )
		
	[ "$_check_available_dev" == "0" ] && _check_available_ip_dev=$( ip addr show dev ib0 | grep inet\  | grep -o [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\/[0-9]* 2>&1 >/dev/null ; echo $? )
	[ "$_check_available_ip_dev" == "0" ] && _check_ib_dev="0" || _status="201"

}

check_nfs()
{

	_check_nfs=$( ping -q -c 4 $_nfs_server 2>&1 >/dev/null ; echo $? )

	[ "$_check_nfs" != "0" ] && _status="301"

}

check_lustre()
{

	_lustre_MDT=$( shine -O %type";"%servers config | grep MDT | cut -d';' -f2 | head -n1 )
	_lustre_OST=$( shine -O %type";"%servers config | grep OST | cut -d';' -f2 | head -n1 )

	_check_lustre_MDT=$( shine -O %type";"%servers";"%status -H status -n $_lustre_MDT 2>/dev/null | grep "^MDT" | sort -u | grep -o ";online$" 2>&1 >/dev/null ; echo $? ) 

	[ "$_check_lustre_MDT" == "0" ] && _check_lustre_OST=$( shine -O %type";"%servers";"%status -H status -n $_lustre_OST 2>/dev/null | grep "^OST" | sort -u | grep -o ";online$" 2>&1 >/dev/null ; echo $? )
	if [ "$_check_lustre_OST" == "0" ] 
	then
		_check_lustre="0" 
	else
		_status="301" 
		_check_lustre="1"
	fi

}

check_slurm()
{

	_check_slurm_main=$( scontrol ping 2>/dev/null | head -n 1 | tr ' ' '\n' | sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c1 }' | grep -o ";UP$" 2>&1 >/dev/null ; echo $? ) 
	_check_slurm_bkp=$(  scontrol ping 2>/dev/null | head -n 1 | tr ' ' '\n' | sed -e 's/Slurmctld.\(.*\).$/\1/' -e '2 d' -e '4 d' | awk -F\/ '{ _c1=_c1";"$1 ; _c2=_c2";"$2 } END { print _c2 }' | grep -o ";UP$" 2>&1 >/dev/null ; echo $? ) || _check_slurm=0

	if [ "$_check_slurm_main" == "0" ] || [ "$_check_slurm_bkp" == "0" ] 
	then
		_check_slurm="0" 
	else
		_status="401" 
		_check_slurm="1"
	fi

}

check_cyclops()
{

	### FACTORY ####	
	echo "FACTORY:" >/dev/null

}

do_main()
{

	do_nfs
	[ "$_do_nfs" == "0" ] && do_lustre || do_nothing 
	[ "$_do_lustre" == "0" ] && do_slurm || do_nothing
	[ "$_do_slurm" == "0" ] && _check_do="0" || do_nothing 
	
}

do_nfs()
{
	
	_do_nfs="0"

	for _nfs in $( cat /etc/fstab | awk '$3 == "nfs" { print $2 }' ) 
	do
		mount $_nfs 
		[ "$?" != "0" ] && _do_nfs="1"
	done

}

do_lustre()
{

	_do_lustre=$( shine -O %fsname";"%status -H mount -n $HOSTNAME 2>/dev/null | sed '/^$/d' | grep ";" | awk -F\; 'BEGIN { _fail=0 } { if ( $2 != "mounted" ) { _fail=1 }} END { print _fail }' )

}

do_slurm()
{


	_do_slurm=$( scontrol update nodename=$HOSTNAME state=idle 2>&1 >/dev/null ; echo $? )

}

do_cyclops()
{

	### FACTORY ###
	echo "FACTORY:" >/dev/null

}

do_nothing()
{


	_do_nothing=$( scontrol update nodename=$HOSTNAME state=drain reason="Initializating node problem: $_status" 2>&1 >/dev/null ; echo $? )

	if [ "$_do_nothing" == "0" ] 
	then
		echo -ne "EJECT NODE FROM SLURM\n\r"
	else
		_srv_slurm=$( service slurm stop 2>&1 >/dev/null ; echo $? )
		if [ "$_srv_slurm" == "0" ]
		then
			echo -ne "EJECT FAIL -> STOPPING SLURM SERVICE OK\n\r"
		else
			echo -ne "EJECT AND STOP SERVICE FAIL: DISABLE NODE AND REBOOT IT\n\r"
			touch $_disable_file
			reboot
		fi
			
	fi

}

 
#### MAIN EXEC ####

	_do_or_not="no"
	_step=1

	echo -ne "\n\rChecking Available Resources (5)\n\r"

	while [ "$_step" -le 5 ] && [ "$_do_or_not" == "no" ]	
	do
		sleep 20s 
		check_ib_dev

		[ "$_check_ib_dev" == "0" ] && check_nfs 
		[ "$_check_nfs" == "0" ] && check_lustre 
		[ "$_check_lustre" == "0" ] && check_slurm

		echo -ne "TRY $_step : $( [ ! -z "$_check_ib_dev" ] && echo -n "IB_DEV: $_check_ib_dev >>") $( [ ! -z "$_check_nfs" ] && echo -n "NFS: $_check_nfs >>") $( [ ! -z "$_check_lustre" ] && echo -n "LUSTRE: $_check_lustre >>" ) $( [ ! -z "$_check_slurm" ] && echo -n  "SLURM: $_check_slurm >>" ) $( [ "$_check_slurm" == "0" ] && echo -n "OK" || echo -n "FAIL" ) \n\r"

		if [ "$_check_ib_dev" == "0" ] && [ "$_check_nfs" == "0" ] && [ "$_check_lustre" == "0" ] && [ "$_check_slurm" == "0" ] 
		then
			_step=6 
			_do_or_not="yes"
		else
			let "_step=_step+1"
		fi
	done


	if [ "$_do_or_not" == "yes" ] 
	then
		echo -e "\n\rALL CHECK OK\n\r"
		do_main 
	else
		echo -e "\n\rALL TRIES FAILS, NODE UNLINK\n\r"
		do_nothing
	fi

	echo -ne "\nFINAL STATUS: NFS: $( [ -z "$_do_nfs" ] && echo -n NA || echo -n $_do_nfs )  >> LUSTRE: $( [ -z "$_do_lustre" ] && echo -n NA || echo -n $_do_lustre ) >> SLURM: $( [ -z "$_do_slurm" ] && echo -n NA || echo -n $_do_slurm )\n\r"
	echo "$( date +%s ) : IB_DEV: $_check_ib_dev >> NFS: $_check_nfs >> LUSTRE: $_check_lustre >> SLURM: $_check_slurm" >> $_local_log
	echo "$( date +%s ) : FINAL STATUS: NFS: $_do_nfs >> LUSTRE: $_do_lustre >> SLURM: $_do_slurm" >> $_local_log

	exit $_status
