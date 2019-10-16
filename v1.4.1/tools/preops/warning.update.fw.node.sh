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

source $_config_path/tools/tool.b7xx.upgrade.fw.cfg

_ipmitool="/opt/BSMHW/bin/ipmitool"
_out_par=""

###########################################
#              PARAMETERs                 #
###########################################

_date=$( date +%s )

while getopts "g:f:pyn:xh" _optname
do
        case "$_optname" in
                "n")

                        _opt_nod="yes"
                        _par_nod=$OPTARG

                        _name=$( echo $_par_nod | cut -d'[' -f1 | sed 's/[0-9]*$//' )
                        _range=$( echo $_par_nod | sed -e "s/$_name\[/{/" -e 's/\([0-9]*\)\-\([0-9]*\)/\{\1\.\.\2\}/g' -e 's/\]$/\}/' -e "s/$_name\([0-9]*\)/\1/"  )
                        _values=$( eval echo $_range | tr -d '{' | tr -d '}' )
                        _long=$( echo "${_values}" | tr ' ' '\n' | sed "s/^/$_name/" )

                        [ -z $_range ] && echo "Need nodename or range of nodes" && exit 1

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

			[ ! -z "$_par_file" ] && [ -f "$_par_file" ] && source $_par_file || exit 1
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
                "h"|""|*)
			echo
			echo "CYCLOPS TOOL TO UPGRADE NODE's FIRMWARE"
			echo "This script verify:"
			echo "	1. cyclops mon status:	mandatory poweroff node, use clmctrl, halt or ipmitool to poweroff."
			echo "	2. node power status :	mandatory drain cyclops mon status, use cyclops.sh to change mon status."
			echo "	3. screen session    :	mandatory inside screen session, use screen command to get in"
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
                        echo ""
                        exit 0
                ;;
		"")
			echo hola
		;;
        esac
done

#### FUNCTIONS ####

fw_update_b7xx()
{
	echo "NODE: $_node : $_bmc : >> [ UPGRADING ]"
	[ "$_opt_par" == "yes" ] && echo "You can follow upgrade progress in $_out_par" 

	if [ ! -z "$_bios" ] && [ -f "$_bios" ] 
	then
		echo "NODE: $_node : $_bmc : BIOS update >> [ START ]" 
		$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bios BIOS 0 $_out_par
		_err=$?
		echo "NODE: $_node : $_bmc : BIOS update finish >>" $( [ "$_err" == "0" ] && echo " [ OK ]" || echo " [ FAIL ]" )
	else
		echo "NODE: $_node : $_bmc : BIOS blank or file don't exists >> [ SKIP ]"
	fi

	if [ ! -z "$_cpld_main" ] && [ -f "$_cpld_main" ] 
	then
		echo "NODE: $_node : $_bmc : CPLD MAIN update >> [ START ]"
		$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_cpld_main CPLD_MAIN 0 $_out_par
		_err=$?
		echo "NODE: $_node : $_bmc : CPLD MAIN update finish >>" $( [ "$_err" == "0" ] && echo " [ OK ]" || echo " [ FAIL ]" )
	else
		echo "NODE: $_node : $_bmc : CPLD MAIN blank or file don't exists >> [ SKIP ]"
	fi

	if [ ! -z "$_cpld_ioexp" ] && [ -f "$_cpld_ioexp" ] 
	then
		echo "NODE: $_node : $_bmc : CPLD IOEXP update >> [ START ]"
		$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_cpld_ioexp CPLD_IOEXP 0 $_out_par
		_err=$?
		echo "NODE: $_node : $_bmc : CPLD IOEXP update finish >>" $( [ "$_err" == "0" ] && echo " [ OK ]" || echo " [ FAIL ]" )
	else
		echo "NODE: $_node : $_bmc : CPLD_IOEXP blank or file don't exists >> [ SKIP ]"
	fi

	if [ ! -z "$_bios_reg" ] && [ -f "$_bios_reg" ] 
	then
		echo "NODE: $_node : $_bmc : BIOS REGION update >> [ START ]"
		$_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bios_reg BIOS_REGION 0 $_out_par
		_err=$?
		echo "NODE: $_node : $_bmc : BIOS REGION update finish >>" $( [ "$_err" == "0" ] && echo " [ OK ]" || echo " [ FAIL ]" )
	else
		echo "NODE: $_node : $_bmc : BIOS REGION blank or file don't exists >> [ SKIP ]"
	fi

	if [ ! -z "$_bmc_fw" ] && [ -f "$_bmc_fw" ]
	then
                echo "NODE: $_node : $_bmc : BMC update >> [ START ]"
                $_ipmitool -H $_bmc -U super -P pass -v bulloem upgrade $_bmc_fw MC 0 $_out_par
		_err=$?
		echo "NODE: $_node : $_bmc : BMC update finish >>" $( [ "$_err" == "0" ] && echo " [ OK ]" || echo " [ FAIL ]" )
	else
		echo "NODE: $_node : $_bmc : BMC blank or file don't exists >> [ SKIP ]"
	fi

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

	_screen_status=$( echo $STY ) 
	[ -z "$_screen_status" ] && _screen_status="1" || _screen_status="0"

	_bios_status=$( $_ipmitool -H $_bmc -U $_user -P $_pass bulloem ver all 0 )
	[ -z "$_bios_status" ] && echo "NODE: $_node : $_bmc : CAN'T GET BIOS VERSION, CANCEL RECOMENDED [ ERR ]"
}

main_update()
{
	for _node in $( echo "${_long}" )
	do
		_bmc=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $2 }' )
		_user=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $3 }' )
		_pass=$( cat $_bios_mng_cfg_file | awk -F\; -v _n="$_node" '$1 == _n { print $4 }' )

		if [ -z "$_bmc" ] || [ -z "$_user" ] || [ -z "$_user" ]
		then
			echo "ERR: NO DATA FOR $_node : >> [ SKIP ]"
		else
			if [ "$_opt_gen" != "yes" ] 
			then
				node_status
				[ "$_screen_status" == "1" ] && echo "NODE: $_node : $_bmc : Not inside screen session, use screen command or generation option of this script to use it >> [ ERR ]" && exit 1
			fi
	

			if [ "$_power_status" == "0" ] && [ "$_cyclops_status" == "0" ]
			then
				
				echo 
				echo "NODE: $_node : $_bmc : RIGHT STATUS FOR UPGRADE >> [ START ]"
				echo "BIOS NODE ACTUAL VER: "
				echo "${_bios_status}" | sed 's/^/	/'

				[ "$_opt_ask" == "yes" ] && read -p "PRESS ANY KEY TO CONTINUE OR CTRL+C TO CANCEL ALL PROCESS... " -n1 -s && echo 

				if [ "$_opt_par" == "yes" ]
				then
					_out_par="&>> "$_cyclops_temp_path"/fw.update."$_bmc"."$( date +%Y%m%d )".log"
					fw_update_b7xx & 
				else
					fw_update_b7xx	
				fi
			else
				if [ "$_opt_gen" == "yes" ]
				then
					echo "NODE: $_node : $_bmc >> [ GENERATING SCRIPT ]"
					gen_script >> $_par_gen
				else
					echo "NODE: $_node : $_bmc : BAD STATUS FOR UPGRADE >> [ SKIP ]"
					echo "NODE: $_node : $_bmc : POWER >> "$( [ "$_power_status" == "0" ] && echo -n "[ OFF ]" || echo -n "[ ON ]" )
					echo "NODE: $_node : $_bmc : CYCLOPS >> "$( [ "$_cyclops_status" == "0" ] && echo -n "[ DRAIN ]" || echo -n "[ OPERATIVE ]" )
				fi
			fi
		fi
	done
	wait

	echo
	echo "DON'T FORGET PUT NODEs IN CHASSIS POWER STANDBYOFF MODE AND AFTER ON POWERON MODE TO GET CHANGES"
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
	
	if [ "$_opt_gen" == "yes" ] 
	then
		[ "$_opt_par" == "yes" ] && _opt_par="gen"
		[ "$_opt_ask" == "yes" ] && _opt_ask="gen"

		echo "#!/bin/bash" > $_par_gen
		echo "echo \"AUTO GENERATED FIRMWARE UPGRADE FILE: $_par_gen\"" >> $_par_gen
		echo "AUTO GENERATED FIRMWARE UPGRADE FILE: $_par_gen"
	fi

	main_update

	[ "$_opt_gen" == "yes" ] && echo "${_long}" | sed "s/$/ $( [ "$_opt_par" == "gen" ] && echo -n "\&" ) # Delete line to disable node update/" >> $_par_gen
