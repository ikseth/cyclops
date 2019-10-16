#!/bin/bash

#### GLOBAL VARS ####

_config_path="/etc/cyclops"

if [ -f $_config_path/global.cfg ]
then
        source $_config_path/global.cfg
else
        echo "Global config don't exits" 
        exit 1
fi

#### TOOL VARS ####

_ipmitool="/opt/BSMHW/bin/ipmitool"

_wall_nodes="nimbus[0,1]"
_msg_ok="_________OK."
_msg_fail="_______FAIL."

#### LIBS ####

        source $_libs_path/node_group.sh
        source $_libs_path/node_ungroup.sh

###########################################
#              PARAMETERs                 #
###########################################

_date=$( date +%s )

while getopts ":g:f:poyn:v:wxh:" _optname
do
        case "$_optname" in
                "n")

                        _opt_nod="yes"
                        _par_nod=$OPTARG

                        #_name=$( echo $_par_nod | cut -d'[' -f1 | sed 's/[0-9]*$//' )
                        ##_range=$( echo $_par_nod | sed -e "s/$_name\[/{/" -e 's/\([0-9]*\)\-\([0-9]*\)/\{\1\.\.\2\}/g' -e 's/\]$/\}/' -e "s/$_name\([0-9]*\)/\1/"  )
                        #_values=$( eval echo $_range | tr -d '{' | tr -d '}' )
                        #_long=$( echo "${_values}" | tr ' ' '\n' | sed "s/^/$_name/" )

                        #[ -z $_range ] && echo "Need nodename or range of nodes" && exit 1

			_ctrl_grp=$( echo $_par_nod | grep @ 2>&1 >/dev/null ; echo $? )

			if [ "$_ctrl_grp" == "0" ]
			then
				_par_node_grp=$( echo "$_par_nod" | tr ',' '\n' | grep ^@ | sed 's/@//g' | tr '\n' ',' )
				_par_node=$( echo $_par_nod | tr ',' '\n' | grep -v ^@ | tr '\n' ',' )
				_par_node_grp=$( awk -F\; -v _grp="$_par_node_grp" '{ split (_grp,g,",") ; for ( i in g ) {  if ( $2 == g[i] || $3 == g[i] || $4 == g[i] ) { _n=_n""$2","  }}} END { print _n }' $_type )
				_par_node_grp=$( node_group $_par_node_grp )
				_par_node=$_par_nod""$_par_node_grp

				[ -z "$_par_nod" ] && echo "ERR: Don't find nodes in [$_par_node_grp] definited group(s)/family(s)" && exit 1
			fi

			_long=$( node_ungroup $_par_nod | tr ' ' '\n' )
                ;;
		"y")
			_opt_ask="yes"
		;;
		"p")
			_opt_par="yes"
		;;
		"f")
			_opt_fil="yes"
			_par_fil=$OPTARG

			if [ -z "$_par_fil" ] || [ ! -f "$_par_fil" ] 
			then
				echo "ERR: Alternative fw definition don't exists" 
				exit 1
			fi

		;;
		"g")
			_opt_gen="yes"
			_par_gen=$OPTARG
			
			[ -f "$_par_gen" ] && echo "ERR: File exits, change name" && exit 1
		;;
                "x")
                        _opt_debug="yes"
                        ## DEBUGGING OPTION
                        echo "You choose hidden debug option"
                ;;
		"v")
			_opt_show="yes"
			_par_show=$OPTARG
		;;
		"w")
			_opt_wall="yes"
		;;
		"o")
			_opt_aon="yes"
		;;
		"h")
			case "$OPTARG" in
			"des")
				echo "$( basename "$0" ) : Critical Tool for upgrade B700 bull newsca hardware firmware, use carefully"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Default config path: $_config_path_too"
				exit 0
			;;
			"*")
				echo "ERR: Use -h for help"
			;;
			esac
		;;
                ":")
			if [ "$OPTARG" == "h" ]
			then
				echo
				echo "CYCLOPS TOOL: UPGRADE NODE's FIRMWARE ( BULL NEWSCA B7xx )"
				echo 
				echo "This script verify:"
				echo "	1. cyclops mon status:	mandatory poweroff node, use clmctrl, halt or ipmitool to poweroff."
				echo "	2. node power status :	mandatory drain cyclops mon status, use cyclops.sh to change mon status."
				echo "	3. screen session    :	mandatory inside screen session, use screen command to get in"
				echo "	4. upgrade status    :  tool test if node was lock from past upgrade"
				echo "If you don't want to use in interactive mode, use -g option to generate a fw upgrade script" 
				echo ""
				echo "WARNING!! : This script is actually ONLY FOR B710 Nodes, don't use with other hardware"
				echo ""
				echo "OPTIONS:"
				echo "	-n [nodename/nodename[range]"
				echo "	 	 range=[star id node]-[end id node]"
				echo " 		 Range Example script.sh -n node[5-10] // get node from node5 to node10 include nodenames between range"
				echo " 		 Range Example script.sh -n node[5,10] // only get nodes node5 and node10"
				echo " 		 You can combine both syntax like: tool.mac.extract.sh -n node[5-10,20] // get node from node5 to node10 and node20"
				echo "	-y Enable pause between updates, to be more safe"
				echo "	-p Paralellize update execution, more fast to update multiple nodes, beware, if fails.... you cry"
				echo "	-f [config file] Alternative firmware files definitions"
				echo "	-g [output file] generate script with update commands, most safe if you verify before launch"
				echo "	-v [BIOS] Show firmware version of nodes, Exclusive option."
				echo "	-o Enable auto reset bmc and auto power on nodes when upgrade finish"
				echo "	-w Alert to defined hosts about fw upgrade task on nodes with wall command"
				echo "	-h [|des] help is help"
				echo "		des: Detailed Command Help"
				echo ""
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

#### FUNCTIONS ####

node_group_old()
{
	_nodelist=$1

	echo "${_nodelist}" | tr ' ' '\n' | sed -e '/^$/d' -e 's/[0-9]*$/;&/' | sort -t\; -k2,2n -u | awk -F\; '
		{ if ( NR == "1" ) { _sta=$2 ; _end=$2  ; _string=$1"[" }
		else {
		    if ( $2 == _end + 1 ) {
			_sep="-" ;
			_end=$2 }
			else
			{
			    if ( _sep == "-" ) { 
				_string=_string""_sta"-"_end"," }
				else {
				    _string=_string""_sta"," }
			    _sep="," ;
			    _sta=$2 ;
			    _end=$2 ;
			}
		    }
		}

		END {
			if ( _sep == "-" ) { 
				_string=_string""_sta"-"_end }
			else {
				_string=_string""_sta","_end }
			print _string"]" }'

 
}

fw_update_b7xx()
{
	_out_par=$_mon_log_path"/fw.update."$_bmc"."$( date +%Y%m%dT%H%M )".log"
	echo "DATE $( date )" >$_out_par
	echo "NODE: $_node : $_bmc : LOG OUTPUT UPGRADE TOOL : 		______START." >>$_out_par

	echo "NODE: $_node : $_bmc : FIRMWARE 				__UPGRADING."

	touch $_lock_path/$_node.fwup.lock

        if [ ! -z "$_bmc_fw" ] 
	then
		if [ -f "$_bmc_fw" ]
        	then    
			echo "NODE: $_node : $_bmc : BMC update :			______START."
			$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bmc_fw MC 0 >>$_out_par
			_err=$?
			[ "$_err" == "0" ] && _msg_status=$_msg_ok || _msg_status=$_msg_fail
			echo "NODE: $_node : $_bmc : BMC update finish :		$_msg_status"
			sleep 5s
			[ "$_err" == "0" ] && echo "NODE: $_node : $_bmc : BMC COLD RESET wait 120s :		_______WAIT." && $_ipmitool -H $_bmc -U super -P pass mc reset cold &>>$_out_par
			sleep 120s
			[ "$_err" == "0" ] && echo "NODE: $_node : $_bmc : BMC COLD RESET :			"$( [ "$_err" == "0" ] && echo $_msg_ok || echo $_msg_fail ) 
			[ "$_err" == "0" ] && echo "NODE: $_node : $_bmc : NODE POWER :			________OFF." && $_ipmitool -H $_bmc -U $_user -P $_pass power off &>>$_out_par
			sleep 10s 
			$_script_path/audit.nod.sh -i event -e upgrade -s ok -m "BMC firmware" -n $_node 2>/dev/null
        	else    
                	echo "NODE: $_node : $_bmc : BMC file don't exists :		_______SKIP."
		fi
        fi


	if [ ! -z "$_bios" ] 
	then
		if [ -f "$_bios" ] 
		then
			echo "NODE: $_node : $_bmc : BIOS update : 			______START." 
			$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bios BIOS 0 &>>$_out_par
			_err=$?
			[ "$_err" == "0" ] && _msg_status=$_msg_ok || _msg_status=$_msg_fail
			echo "NODE: $_node : $_bmc : BIOS update finish :		$_msg_status"
			sleep 5s
			$_script_path/audit.nod.sh -i event -e upgrade -s ok -m "BIOS firmware" -n $_node 2>/dev/null
		else
			echo "NODE: $_node : $_bmc : BIOS file don't exists :		_______SKIP."
		fi
	fi

	if [ ! -z "$_cpld_main" ] 
	then
		if [ -f "$_cpld_main" ] 
		then
			echo "NODE: $_node : $_bmc : CPLD MAIN update : 		______START."
			$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_cpld_main CPLD_MAIN 0 >>$_out_par
			_err=$?
			[ "$_err" == "0" ] && _msg_status=$_msg_ok || _msg_status=$_msg_fail
			echo "NODE: $_node : $_bmc : CPLD MAIN update finish :		$_msg_status"
			sleep 5s
			$_script_path/audit.nod.sh -i event -e upgrade -s ok -m "CPLD MAIN firmware" -n $_node 2>/dev/null
		else
			echo "NODE: $_node : $_bmc : CPLD MAIN file don't exists :	_______SKIP."
		fi
	fi

	if [ ! -z "$_cpld_ioexp" ] 
	then
		if [ -f "$_cpld_ioexp" ] 
		then
			echo "NODE: $_node : $_bmc : CPLD IOEXP update :		______START."
			$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_cpld_ioexp CPLD_IOEXP 0 >>$_out_par
			_err=$?
			[ "$_err" == "0" ] && _msg_status=$_msg_ok || _msg_status=$_msg_fail
			echo "NODE: $_node : $_bmc : CPLD IOEXP update finish :		$_msg_status"	
			sleep 5s
			$_script_path/audit.nod.sh -i event -e upgrade -s ok -m "CPLD IOEXP firmware" -n $_node 2>/dev/null
		else
			echo "NODE: $_node : $_bmc : CPLD_IOEXP file don't exists :	_______SKIP."
		fi
	fi

	if [ ! -z "$_bios_reg" ] 
	then
		if [ -f "$_bios_reg" ] 
		then
			echo "NODE: $_node : $_bmc : BIOS REGION update : 		______START."
			$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bios_reg BIOS_REGION 0 &>>$_out_par
			_err=$?
			[ "$_err" == "0" ] && _msg_status=$_msg_ok || _msg_status=$_msg_fail
			echo "NODE: $_node : $_bmc : BIOS REGION update finish :	$_msg_status"
			sleep 5s
			$_script_path/audit.nod.sh -i event -e upgrade -s ok -m "BIOS REGION firmware" -n $_node 2>/dev/null
		else
			echo "NODE: $_node : $_bmc : BIOS REGION file don't exists :	_______SKIP."
		fi
	fi


	if [ "$_err" == "0" ] && [ "$_opt_aon" == "yes" ]
	then
		[ "$_err" == "0" ] && echo "NODE: $_node : $_bmc : FINAL BMC COLD RESET wait 120s :	_______WAIT." && $_ipmitool -H $_bmc -U super -P pass mc reset cold &>>$_out_par
		sleep 120s
		[ "$_err" == "0" ] && echo "NODE: $_node : $_bmc : BMC COLD RESET :			"$( [ "$_err" == "0" ] && echo $_msg_ok || echo $_msg_fail ) 
		sleep 10s
		[ "$_err" == "0" ] && echo "NODE: $_node : $_bmc : NODE POWER :			_________ON." && $_ipmitool -H $_bmc -U $_user -P $_pass power off &>>$_out_par
	fi

	[ -f "$_lock_path/$_node.fwup.lock" ] && rm $_lock_path/$_node.fwup.lock

}

node_status()
{

	_power_status=$( $_ipmitool -H $_bmc -U $_user -P $_pass power status 2> /dev/null )
	case "$_power_status" in 
                        *"Chassis Power is off")
				_power_status="0"
                        ;;
                        *)
				_power_status="1"
			;;
	esac

	_cyclops_status=$( cat $_type | awk -F\; -v _n="$_node" '$2 == _n { if ( $7 == "drain" ) { print 0 } else { print 1 }}' )

	_lock_status=$( [ -f "$_lock_path/$_node.fwup.lock" ] && echo "1" || echo "0" )

	_bios_status=$( $_ipmitool -H $_bmc -U $_user -P $_pass bulloem ver all 0 2>/dev/null )
	[ -z "$_bios_status" ] && echo "NODE: $_node : $_bmc : CAN'T GET BIOS VERSION, CANCEL RECOMENDED :		 ________ERR."
}

main_update()
{

	_ds=$( date +%s )

	for _node in $( echo "${_long}" )
	do
		_bmc=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $2 }' )
		_user=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $3 }' )
		_pass=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $4 }' )

		if [ -z "$_bmc" ] || [ -z "$_user" ] || [ -z "$_user" ]
		then
			echo "NODE: $_node : $_bmc : NO DATA ERR : 		_______SKIP."
		else
			if [ "$_opt_gen" != "yes" ] 
			then
				node_status
			fi
	

			if [ "$_power_status" == "0" ] && [ "$_cyclops_status" == "0" ] && [ "$_lock_status" == "0" ]
			then
				_node_ok_status=$_node_ok_status""$_node" "	
				echo "NODE: $_node : $_bmc : STATUS FOR UPGRADE :		_______GOOD."
				[ "$_opt_debug" == "yes" ] && echo "BIOS NODE ACTUAL VER: " && echo "${_bios_status}" | sed 's/^/	/'

				[ "$_opt_ask" == "yes" ] && read -p "PRESS ANY KEY TO CONTINUE OR CTRL+C TO CANCEL ALL PROCESS... " -n1 -s && echo 

				if [ "$_opt_par" == "yes" ]
				then
					fw_update_b7xx & 
				else
					fw_update_b7xx	
				fi
			else
				if [ "$_opt_gen" == "yes" ]
				then
					echo "NODE: $_node : $_bmc : 	GENERATING SCRIPT."
					gen_script >> $_par_gen
				else
					_node_bad_status=$_node_bad_status""$_node","
					echo "NODE: $_node : $_bmc : STATUS FOR UPGRADE :		________BAD."
					echo "NODE: $_node : $_bmc : 	STATUS > POWER :		"$( [ "$_power_status" == "0" ] && echo -n "________OFF." || echo -n "_________ON." )
					echo "NODE: $_node : $_bmc : 	STATUS > CYCLOPS :		"$( [ "$_cyclops_status" == "0" ] && echo -n "______DRAIN." || echo -n "__OPERATIVE." )
					echo "NODE: $_node : $_bmc :	STATUS > FILE LOCK :		"$( [ "$_lock_status" == "0" ] && echo -n "_______FREE." || echo -n "_______LOCK." )
					echo "NODE: $_node : $_bmc : FIRMWARE UPGRADE :			_______SKIP."
				fi
			fi
		fi
	done
	wait

	_df=$( date +%s )
	let "_time=(_df-_ds)/60"

	[ -z "$_node_ok_status" ] && _node_ok_status="none" || _node_ok_status=$( node_group $_node_ok_status ) 
	[ -z "$_node_bad_status" ] && _node_bad_status="none" || _node_bad_status=$( node_group $_node_bad_status ) 

	echo
	echo "UPDATED NODES:	$_node_ok_status"
	echo "SKIP NODES:	$_node_bad_status"
	echo
	echo "TIME ELAPSED: $_time mins"
	[ "$_opt_aon" == "yes" ] && echo "VERIFY POWER STATUS AND CORRECT FW VERSION" || echo "COULD BE NECESARY TO PUT NODEs IN CHASSIS POWER STANDBYOFF MODE AND AFTER IT, PUT THEM ON POWERON MODE TO GET CHANGES"
	echo

}

gen_script()
{

	echo "$_node()"
	echo "{"
	echo
	echo "echo \"$_node with bmc name $_bmc upgrading\""
	[ "$_opt_ask" == "gen" ] && echo "read -p \"PRESS ANY KEY TO CONTINUE OR CTRL+C TO CANCEL ALL PROCESS... \" -n1 -s"
	echo "$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bios BIOS 0" 	
	echo "$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_cpld_main CPLD_MAIN 0" 		
	echo "$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_cpld_ioexp CPLD_IOEXP 0"
	echo "$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bios_reg BIOS_REGION 0"
	echo "$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bmc_fw MC 0"
	echo 
	echo "}"
}

show_ver()
{
	for _node in $( echo "${_long}" ) 
	do
		_bmc=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $2 }' )
		_user=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $3 }' )
		_pass=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $4 }' )

		_ver=$( $_ipmitool -H $_bmc -U $_user -P $_pass bulloem ver $_par_show 0 2>/dev/null )
		
		[ -z "$_ver" ] && _ver="ERR: NO DATA"

		echo "NODE: $_node : $_bmc : $_par_show : $_ver " 

	done
	exit 0
}

debug()
{
	echo
	echo "	DEBUG: $_node : $_ipmitool : $_bmc : $_user : $_pass : $_bios"
	echo "	DEBUG: $_node : $_ipmitool : $_bmc : $_user : $_pass : $_cpld_main"
	echo "	DEBUG: $_node : $_ipmitool : $_bmc : $_user : $_pass : $_cpld_ioexp"
	echo "	DEBUG: $_node : $_ipmitool : $_bmc : $_user : $_pass : $_bios_reg"
	echo "	DEBUG: $_node : $_ipmitool : $_bmc : $_user : $_pass : $_bmc_fw"
}

#### MAIN EXEC ####

	[ -z "$_opt_nod" ] && echo "ERR: Needs node or node range" && exit 1
	[ "$_opt_fil" == "yes" ] && source $_par_fil || source $_config_path/tools/tool.b7xx.upgrade.fw.cfg

	[ "$_opt_show" == "yes" ] && show_ver	
	
	if [ "$_opt_gen" == "yes" ] 
	then
		[ "$_opt_par" == "yes" ] && _opt_par="gen"
		[ "$_opt_ask" == "yes" ] && _opt_ask="gen"

		echo "#!/bin/bash" > $_par_gen
		echo "echo \"AUTO GENERATED FIRMWARE UPGRADE FILE: $_par_gen\"" >> $_par_gen
		echo "AUTO GENERATED FIRMWARE UPGRADE FILE: $_par_gen"
	else

		_screen_status=$( echo $STY )
		[ -z "$_screen_status" ] && _screen_status="1" || _screen_status="0"

		echo 
		echo "INFO: CHECK FW UPGRADE OPTIONS:"
		echo "INFO: 	PARALLEL EXEC:		$( [ "$_opt_par" == "yes" ] && echo "YES" || echo "NO" )"
		echo "INFO:	ASK BEFORE:    		$( [ "$_opt_ask" == "yes" ] && echo "YES" || echo "NO" )"
		echo "INFO:	ALTERNATIVE FILE:	$( [ -z "$_par_fil" ] && echo "NO" || echo $_par_fil )"
		echo "INFO:	WALL MESSAGE:		$( [ "$_opt_wall" == "yes" ] && echo "YES" || echo "NO" )"
		echo "INFO:	AUTO POWER ON:		$( [ "$_opt_aon" == "yes" ] && echo "YES" || echo "NO" )"
		echo "INFO:	SCREEN SESSION		$( [ "$_screen_status" == "0" ] && echo "YES" || echo "NO" )"
		echo "INFO:	NODE RANGE:		$_par_nod"
		echo
		echo "INFO: You can follow detailed fw update in $_mon_log_path/fw.update.[BMC HOSTNAME].[DATE YYYYMMDDTHHMM].log"
		echo

		[ "$_screen_status" == "1" ] && echo "ERR: Use screen command to make session for launch fw upgrade" && exit 1

		read -p "PRESS ANY KEY TO START FW UPGRADE OR CTRL+C TO CANCEL ALL PROCESS... " -n1 -s && echo
		$_script_path/cyclops.sh -m "Start Firmware upgrade, nodes $_par_nod" -l
		[ "$_opt_wall" == "yes" ] && pdsh -w $_wall_nodes "wall \"INTERVENTION: Nodes $_par_nod will be upgraded now, DON'T TOUCH THEM!\""
	fi

	main_update

	[ "$_opt_gen" == "yes" ] && echo "${_long}" | sed "s/$/ $( [ "$_opt_par" == "gen" ] && echo -n "\&" ) # Delete line to disable node update/" >> $_par_gen
