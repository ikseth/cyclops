 #!/bin/bash

_config_path="/etc/cyclops"

if [ -f $_config_path/global.cfg ]
then
        source $_config_path/global.cfg
else
        echo "Global config don't exits" 
        exit 1
fi

_ipmitool="/opt/BSMHW/bin/ipmitool"

###########################################
#              PARAMETERs                 #
###########################################

_date=$( date +%s )

while getopts ":o:n:dh:" _optname
do
        case "$_optname" in
                "n")
                        _opt_nod="yes"
                        _par_nod=$OPTARG

			_name=$( echo $_par_nod | cut -d'[' -f1 | sed 's/[0-9]*$//' )
			_range=$( echo $_par_nod | sed -e "s/$_name\[/{/" -e 's/\([0-9]*\)\-\([0-9]*\)/\{\1\.\.\2\}/g' -e 's/\]$/\}/' -e "s/$_name\([0-9]*\)/\1/"  )
			_values=$( eval echo $_range | tr -d '{' | tr -d '}' ) 

			[ -z $_range ] && echo "Need nodename or range of nodes" && exit 1

		;;
		"o")
			_opt_out="yes"
			_par_out=$OPTARG
		;;
		"h")
			case "$OPTARG" in
			"des")
				echo "$( basename "$0" ) : Extract tool for get macs from dhcp log, it use ipmitool"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Optional Output path: $_cyclops_temp_path"
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
				echo "CYCLOPS TOOL: MAC EXTRACTOR FROM DHCP LOGS"
				echo 
				echo "-n [nodename/nodename[range]"
				echo "	range=[star id node]-[end id node]"
				echo "	Range Example tool.mac.extract.sh -n node[5-10] // get node from node5 to node10 include nodenames between range"
				echo "	Range Example tool.mac.extract.sh -n node[5,10] // only get nodes node5 and node10"
				echo "  You can combine both syntax like: tool.mac.extract.sh -n node[5-10,20] // get node from node5 to node10 and node20"
				echo "-o [clusterdb|commas]"
				echo "	clusterdb: generate script with clusterdb update format in $_cyclops_temp_path/tool.ext.macs.cdb."$_date".sh"	
				echo "	commas: default output"
				echo
				echo "-h [|des] help is help"
				echo "	des: Detailed Command Help"
				echo
				exit 0
			else
				echo "ERR: Use -h for help"
			fi
		;;
		"d")
			_opt_debug="yes"
			## DEBUGGING OPTION
			echo "You choose hidden debug option"
		;;	
	esac
done

shift $((OPTIND-1))

#### FUNCTIONS ####

debug()
{

	echo "VAR: _opt_nod: $_opt_nod"
	echo "VAR: _par_nod: $_par_nod"
	echo
	echo "VAR: _name: $_name"
	echo "VAR: _range: $_range"
	echo "VAR: _values: $_values"
	echo 
	echo "${_values}" | tr ' ' '\n'

}

get_data()
{

	_node_status=$( $_ipmitool -I lanplus -U administrator -P administrator -H $_bmc chassis power status 2>/dev/null | awk '{print $NF}' )
	if [ "$_node_status" == "on" ]
	then 
		echo $_node" : ON -> RESTARTING NODE"
		$_ipmitool -I lanplus -U administrator -P administrator -H $_bmc chassis power reset 2>&1 >/dev/null
	else
		echo $_node" : OFF -> POWER ON NODE"
		$_ipmitool -I lanplus -U administrator -P administrator -H $_bmc chassis power on 2>&1 >/dev/null
	fi

	_time_on=$( date +%s )
	let _time_off=$_time_on+80
	sleep 80s

	for _lookfor in $( seq $_time_on $_time_off ) 
	do

		_mac=$( cat /var/log/syslog | grep "^$_lookfor" | grep dhcp | fgrep 192.168.5. | grep PXECLIENT | grep -o ..:..:..:..:..:.. | sort -u)
		[ ! -z "$_mac" ] && _node_mac=$( echo "${_mac}" | sort -u )

	done

	$_ipmitool -I lanplus -U administrator -P administrator -H $_bmc chassis power off 2>&1 >/dev/null

	if [ -z "$_node_mac" ] 
	then
		echo "$_node : no mac detected" 
	else
		echo "$_node : $_node_mac" 
		case "$_par_out" in
			"clusterdb")
				echo "cdbm-equipment update port hwaddr=$_node_mac --filter 'node=$_node and interface=eth0'" >> $_cyclops_temp_path"/tool.ext.macs.cdb."$_date".sh"
			;;
			"*")
				echo "$_node;$_node_mac" >> $_cyclops_temp_path/tool.ext.eth1.$_date.txt
			;;
		esac

	fi

	echo $_node" : POWER OFF NODE"
}

launch_tool()
{
	for _nid in $( echo "${_values}" | tr ' ' '\n' )
	do
		_node=$( echo "$_name""$_nid" )
		_bmc=$(  echo "bmc$_nid" )
		_mon_status=$( /opt/cyclops/scripts/cyclops.sh -a status -n $_node | awk -v _node="$_node" '$2 == _node { print $7 }' )

		if [ "$_mon_status" == "repair" ] || [ "$_mon_status" == "drain" ]
		then
			echo "$_node : IN $_mon_status MODE, VALID FOR RECOVERY NODE MAC TASK"
			_slurm_status=$( ssh -o ConnectTimeout=4 $_node squeue -h -w $_node 2>/dev/null )
			if [ -z "$_slurm_status" ]
			then
				echo "$_node : SLURM INACTIVE LAUNCH MAC RECOVERY PROCESS" 
				get_data
			else
				echo "$_node : ACTIVE NODE"
			fi
		else
			echo "$_node : IN $_mon_status MONITOR STATUS SKIPING"
	fi
	done

}

#### MAIN EXEC ####

	if [ "$_opt_debug" == "yes" ] 
	then
		debug 
	else
		if [ "$_opt_nod" == "yes" ] 
		then
			launch_tool
			echo "FINISH: mac data in $_cyclops_temp_path/tool.ext.macs.cdb."$_date".sh"
		else
			echo "Options Required, use -h for help"
		fi
	fi 
