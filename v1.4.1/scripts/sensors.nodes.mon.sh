#!/bin/bash
###########################################
#            NODE MONITORING		  #
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

###########################################
#              VARIABLES  		  #
###########################################

IFS="
"

_pid=$( echo $$ )
_debug_code="SEN.MON "
_debug_prefix_msg="Services Monitoring: "
_exit_code=0

_par_show="default"

_cyc_reactive_trigger="0"
_config_path="/etc/cyclops"

###########################################
#              LIB LOAD  		  #
###########################################

if [ -f "/etc/cyclops/global.cfg" ]
then
	source /etc/cyclops/global.cfg
	[ -f "$_color_cfg_file" ] && source $_color_cfg_file || _exit_code="116"
	[ -f "$_libs_path/node_ungroup.sh" ] && source $_libs_path/node_ungroup.sh || _exit_code="114"
	[ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
	[ ! -f "$_sensors_sot" ] && echo "ERR: Revise cyclops instalation" && _exit_code="120" 

	case "$_exit_code" in
        11[3-5])
                echo "ERR: Necesary lib file doesn't exits, please revise your cyclops installation" 1>&2
                exit $_exit_code 
        ;;
        116)
                echo "WARNING: Color file doesn't exits, you see sad data format" 1>&2
        ;;
	120)
		echo "ERR: Revise cyclops instalation" 1>&2
		exit $_exit_code 
	;;
        esac
else
        echo "ERR: Global config file don't exits" 1>&2
        exit 111
fi


## CYC GLOBAL STATUS -- 

_cyc_audit_status=$( 	awk -F\; '$1 == "CYC" && $2 == "0003" && $3 == "AUDIT" { print $4 }' $_sensors_sot 2>/dev/null )
_cyc_reactive_status=$( awk -F\; '$1 == "CYC" && $2 == "0007" && $3 == "REACTIVE" { print $4 }' $_sensors_sot 2>/dev/null )
_cyc_razor_status=$( 	awk -F\; '$1 == "CYC" && $2 == "0014" && $3 == "RAZOR" { print $4 }' $_sensors_sot 2>/dev/null )

###########################################
#              PARAMETERs  		  #
###########################################


while getopts ":m:n:v:iph:" _optname
do

	case "$_optname" in
		"m"|"n")
			_opt_mon="yes"
			_par_mon=$OPTARG

                        _ctrl_grp=$( echo $_par_mon | grep @ 2>&1 >/dev/null ; echo $? )

                        if [ "$_ctrl_grp" == "0" ]
                        then
                                _par_node_grp=$( echo "$_par_mon" | tr ',' '\n' | grep ^@ | sed 's/@//g' | tr '\n' ',' )
                                _par_node=$( echo $_par_mon | tr ',' '\n' | grep -v ^@ | tr '\n' ',' )
                                _par_node_grp=$( awk -F\; -v _grp="$_par_node_grp" '{ split (_grp,g,",") ; for ( i in g ) {  if ( $2 == g[i] || $3 == g[i] || $4 == g[i] ) { _n=_n""$2","  }}} END { print _n }' $_type )
                                _par_node_grp=$( node_group $_par_node_grp )
                                #_par_mon=$_par_mon""$_par_node_grp
				_long=$( node_ungroup $_par_node_grp | tr ' ' '\n' )

                                [ -z "$_par_mon" ] && echo "ERR: Don't find nodes in [$_par_node_grp] definited group(s)/family(s)" && exit 1
			else
				_long=$( node_ungroup $_par_mon | tr ' ' '\n' )
                        fi

		;;
		"v")
			_opt_show="yes"
			_par_show=$OPTARG
			if [ !"$_par_show" == "human" ] || [ !"$_par_show" == "wiki" ] || [ !"$_par_show" == "commas" ]
			then
				echo "-v [option] Show formated results"
				echo "		human: human readable"
				echo "		wiki:  wiki format readable"
				echo "		commas: excel readable"
				echo "		hcol: human readable column sorted"
				exit 1	
			fi
		;;
		"i")
			_opt_ia="yes"
		;;
		"p")
			_opt_par="yes"
		;;
		"h")
			case "$OPTARG" in
			"des")
				echo "$( basename "$0" ) : Node/Host monitoring module, cyclops main brick for known system status"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Config path: $_config_path_nod"
				echo "		Node Config File: $( echo $_type | awk -F\/ '{ print $NF }' )"
				echo -e "	Sensors Config Files:\n$( cat $_type | egrep -v "\#|^$" | cut -d';' -f3 | sort -u | sed -e 's/$/\.mon\.cfg/' -e 's/^/\t\t/')"
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
				echo "CYCLOPS NODE MONITOR COMMAND"
				echo
				echo "-m [node|family|type] Monitoring one node, family or type of nodes"
				echo "          options are indicated in $_type"
				echo "          all: get all nodes from all families"
				echo "-i	activate IA Sensors System"
				echo "-p Enable parallel script node monitor"
				echo "-v [option] Show formated results"
				echo "          human: human readable"
				echo "          wiki:  wiki format readable"
				echo "          commas: excell readable"
				echo "		hcol: human readable column sorted"
				echo "-h [|des]	help is help"
				echo "		des: Detailed Command help"
				echo
				exit 0
			else
				echo "ERR: Use -h for help"
				exit 1
			fi
		;;
		"")
			echo "option required, use -h for help"
			exit 1
		;;
		*)
			echo "WHATs HAPPEND?!"
			echo $_optname" "$_OPTARG
			exit 1
		;;
		--)
			echo "OPssss!!!"
			echo $_optname" "$OPTARG
			exit 1
		;;
	esac

done

shift $((OPTIND-1))

###########################################
#              FUNCTIONS  		  #
###########################################

mon_sh_create()
{

        _node_rol=$(awk -F\; -v node="$_node_name" '$2 == node { print $4 }' $_type)
        _nodename_tag="UP"
        _sensor_pri=""

	echo "#!/bin/bash"
        echo "### "$_node_name" Monitoring Script" $( date )                    
	echo
        echo "#### variables monitoring module ####"
        [ -f "$_sensors_var_file" ] && cat $_sensors_var_file || echo "#### ERR: NO $_sensors_var_file EXISTS" 
        echo "#### variables local node ####"
        echo                                                    
        if [ -f "$_cyc_clt_etc_path/local.main.cfg" ]
        then
                awk '$1 !~ "#" && $1 ~ "=" && $1 !~ /\./ { 
                        split($1,field,"=") ; 
                        if ( field[2] !~ /[.][a-zA-Z0-9]+$/ ) { var[field[1]]=field[2] }
                        print "export "$1 ;  
                } END {
                        print "\n#### creating directories if we needed ####"
                        for ( v in var ) {
                                print "[ ! -d \"$"v"\" ] && mkdir -p $"v
                        }               
                }' $_cyc_clt_etc_path/local.main.cfg
        else
                echo "#### WRNG: NO $_cyc_clt_etc_path/local.main.cfg EXISTS"
	fi

	echo
	[ -f "$_sensors_config_path/sensors.begin.sh" ] && cat $_sensors_config_path/sensors.begin.sh || echo "#### WRNG: NO $_sensors_config_path/sensors.begin.sh MON SCRIPT BASE EXISTS" 
        echo 

	echo "#### begin cyc razor data ####"
        echo "echo \"$_node_family;$_node_group;$_node_os;$_node_power;$_node_available\" >$_cyc_clt_rzr_cfg/$_node_name.rol.cfg"

        if [ "$_cyc_razor_status" == "ENABLED" ]
        then
                echo "[ -f \"$_cyc_clt_rzr_scp\" ] && $_cyc_clt_rzr_scp -a enable"
                if [ -f "$_config_path_nod/$_node_family.rzr.lst" ]
                then
                        echo "echo -e \"$( cat $_config_path_nod/$_node_family.rzr.lst | egrep -v "^$|^#" | tr '\n' '@' | sed 's/@/\\n/g' )\" >$_cyc_clt_rzr_cfg/$_node_family.rzr.lst" 
                else
                        echo "echo >$_cyc_clt_rzr_cfg/$_node_family.rzr.lst"
                fi
        else
                echo "[ -f \"$_cyc_clt_rzr_scp\" ] && $_cyc_clt_rzr_scp -a disable"
        fi

        echo "#### end cyc razor data ####"
        echo

	echo "#### begin hardware extractors type ####"

	case "$_node_power" in
	ipmi)
		echo '#### main ipmitool sensor extractors needs ####'
		echo '_ipmi_cmd=$( which ipmitool 2>/dev/null )'	
		echo '[ ! -z "$_ipmi_cmd" ] && _ipmi_sensor=$( $_ipmi_cmd sensor )'
	;;
	none)
		echo '#### no main extractors needs #####'
	;;
	esac
	echo "#### end hardware extractros type ####"

        for _resource in $( cat $_config_path_nod/$_node_family.mon.cfg )
        do
		_daemon=$( echo "$_resource" | cut -d';' -f1 ) 
		_settings=$( echo "$_resource" | awk -F\; '{ for (i=2;i<=NF;i++) { printf " \47%s\47", $i }} END { print "" }' ) 

                echo "func_""$_daemon()"
                echo "{"
                echo "#### $_daemon monitor script ####"                

		cat $_sensors_script_path/$_node_os/sensor.$_daemon.sh |
		grep -v \#

                echo "################################" 
                echo "}"

                _sensor_func_list=$_sensor_func_list""$_daemon" "$_settings"\n"
        done

        echo "launch()"
        echo "{"
        echo -e "${_sensor_func_list}" | awk -F\: -v _op="$_opt_par" 'BEGIN { if ( _op == "yes" ) { _c="&" } else { _c="" }} $1 != "" { if ( NR > 2 ) { print "echo \""NR":$( func_"$1" ) \" "_c } else { print "echo \""NR":$( func_"$1" ) \"" }}'
        [ "$_opt_par" == "yes" ] && echo "wait"
        echo "}"

        echo "_mon_output=\$( launch )"
        echo
        echo "echo \"\${_mon_output}\" | sort -t\\: -n | cut -d':' -f2- | sed 's/@.*$/@/' "
        echo                                                            
        cat $_sensors_config_path/sensors.end.sh
}

mon_check_status()
{

	case "$_node_available" in
	up)
		_admin_status="up"

		case "$_node_power" in
		ipmi)
                        _bios_data=$( grep "^$_node_name;" $_bios_mng_cfg_file )
                        _bios_host=$( echo $_bios_data | cut -d';' -f2 )
			_bios_user=$( echo $_bios_data | cut -d';' -f3 )
			_bios_pass=$( echo $_bios_data | cut -d';' -f4 )

			_ipmicmd=$( which ipmitool 2>/dev/null )
			[ -z "$_ipmicmd" ] && _power_status="Error: no ipmi cmd" || _power_status=$( $_ipmicmd -I lanplus -N 3 -R 2 -U $_bios_user -P $_bios_pass -H $_bios_host power status 2>&1 )

			case "$_power_status" in
			*"Chassis Power is on")

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
				chmod 775 $_sensors_data/$_node_name.mon.sh

				mon_node
			
			;;
			*"Chassis Power is off")
				_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime: DOWN power off@\n" )
				_nodename_tag="DOWN"

				echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/\@\ [a-z_]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
			;;
			*"Error: Unable to establish LAN session"*)
				_admin_status="up_bmc_down"

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
				chmod 775 $_sensors_data/$_node_name.mon.sh

				mon_node
			;;
			"Authentication type NONE not supported"*)
				_admin_status="bmc_auth"

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
                                chmod 775 $_sensors_data/$_node_name.mon.sh

                                mon_node
			;;
			*"Get Session Challenge command failed"*)
				_admin_status="bmc_session"

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
				chmod 775 $_sensors_data/$_node_name.mon.sh

				mon_node
			;;
			*"Unable to establish IPMI v2 / RMCP+ session"*)
				_admin_status="bmc_session"

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
                                chmod 775 $_sensors_data/$_node_name.mon.sh

                                mon_node
			;;
			"Password: Address lookup for power failed"*)
				_admin_status="bmc_session"
				
				mon_sh_create > $_sensors_data/$_node_name.mon.sh
                                chmod 775 $_sensors_data/$_node_name.mon.sh

                                mon_node
			;;
			"Error: no ipmi cmd")
				_admin_status="bmc_no_cmd"

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
				chmod 775 $_sensors_data/$_node_name.mon.sh

				mon_node
			;;
			*)

				_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime: UNKNOWN bmc err.$(echo -n $_power_status | tr '[:upper:]' '[:lower:]' | tr -d '\n' | sed -e 's/;//g' )@\n" )
				_nodename_tag="UNKN"

				echo "$( date +%s ) : ERR: ipmitool fail ($_power_status)" >> /opt/cyclops/logs/$HOSTNAME.mon.err.log

				echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/\@\ [a-z_]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
			;;
			esac
		;;
		none)

			mon_sh_create > $_sensors_data/$_node_name.mon.sh
                        chmod 775 $_sensors_data/$_node_name.mon.sh

                        mon_node
		;;
		*)

			mon_sh_create > $_sensors_data/$_node_name.mon.sh
			chmod 775 $_sensors_data/$_node_name.mon.sh

			mon_node
		;;
		esac
	;;
	onrevalue)
		_admin_status=$_node_available
		_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )

		_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime:$_nodename_tag\n" )

		echo $_node_ia |  sed -e "s/hostname:/DISABLE /" -e 's/\@\ [a-z_]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/"
	;;
	drain)
		_admin_status=$_node_available

		case "$_node_power" in
                ipmi)
                        _bios_data=$( grep "^$_node_name;" $_bios_mng_cfg_file )
                        _bios_host=$( echo $_bios_data | cut -d';' -f2 )
                        _bios_user=$( echo $_bios_data | cut -d';' -f3 )
                        _bios_pass=$( echo $_bios_data | cut -d';' -f4 )

			_ipmicmd=$( which ipmitool 2>/dev/null )
			[ -z "$_ipmicmd" ] && _power_status="no ipmi cmd" || _power_status=$( $_ipmicmd -I lanplus -N 3 -R 2 -U $_bios_user -P $_bios_pass -H $_bios_host power status 2>&1 )

                        case "$_power_status" in
                        *"Chassis Power is on")
				_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
				chmod 775 $_sensors_data/$_node_name.mon.sh

				mon_node

				if [ "$_cyc_razor_status" == "ENABLED" ] 
				then
					ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name "$_cyc_clt_rzr_scp -a enable ; echo \"$_node_family;$_node_group;$_node_os;$_node_power;$_node_available\" >$_cyc_clt_rzr_cfg/$_node_name.rol.cfg" 2>/dev/null 
				else
					ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a disable 2>/dev/null 
				fi
                        ;;
			*"Chassis Power is off")
				_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )
				_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime:$_nodename_tag\n" )

				echo $_node_ia |  sed -e "s/hostname:/DISABLE /" -e 's/\@\ [a-z_]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/"
			;;
                        *)
				_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )
				_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime:$_nodename_tag\n" )

				echo $_node_ia |  sed -e "s/hostname:/DISABLE /" -e 's/\@\ [a-z_]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/"
                        ;;
                        esac
                ;;
                none)
			_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )

			mon_sh_create > $_sensors_data/$_node_name.mon.sh
			chmod 775 $_sensors_data/$_node_name.mon.sh

			mon_node

			if [ "$_cyc_razor_status" == "ENABLED" ] 
			then
				ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name "$_cyc_clt_rzr_scp -a enable ; echo \"$_node_family;$_node_group;$_node_os;$_node_power;$_node_available\" >$_cyc_clt_rzr_cfg/$_node_name.rol.cfg" 2>/dev/null 
			else
				ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a disable 2>/dev/null 
			fi

                ;;
                *)
			_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )

			mon_sh_create > $_sensors_data/$_node_name.mon.sh
			chmod 775 $_sensors_data/$_node_name.mon.sh

			mon_node

			if [ "$_cyc_razor_status" == "ENABLED" ] 
			then
				ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name "$_cyc_clt_rzr_scp -a enable ; echo \"$_node_family;$_node_group;$_node_os;$_node_power;$_node_available\" >$_cyc_clt_rzr_cfg/$_node_name.rol.cfg" 2>/dev/null 
			else
				ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a disable 2>/dev/null 
			fi
                ;;
                esac
	;;
	diagnose|content|link|unlink|repair)
		_admin_status=$_node_available

		case "$_node_power" in
                ipmi)
                        _bios_data=$( grep "^$_node_name;" $_bios_mng_cfg_file )
                        _bios_host=$( echo $_bios_data | cut -d';' -f2 )
                        _bios_user=$( echo $_bios_data | cut -d';' -f3 )
                        _bios_pass=$( echo $_bios_data | cut -d';' -f4 )

			_ipmicmd=$( which ipmitool 2>/dev/null )
			[ -z "$_ipmicmd" ] && _power_status="Error: no ipmi cmd" || _power_status=$( $_ipmicmd -I lanplus -N 3 -R 2 -U $_bios_user -P $_bios_pass -H $_bios_host power status 2>&1 )

                        case "$_power_status" in
                        *"Chassis Power is on"|"Error:"*)
				_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )

				mon_sh_create > $_sensors_data/$_node_name.mon.sh
				chmod 775 $_sensors_data/$_node_name.mon.sh

				mon_node
                        ;;
                        *)
				_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )
				_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime:DISABLE $_nodename_tag\n" )

				echo $_node_ia |  sed -e "s/hostname:/MARK /" -e 's/\@\ [a-z_]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/"
                        ;;
                        esac
                ;;
                none)
			_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )

			mon_sh_create > $_sensors_data/$_node_name.mon.sh
			chmod 775 $_sensors_data/$_node_name.mon.sh

			mon_node
                ;;
                *)
			_nodename_tag=$( echo $_node_available | tr '[:lower:]' '[:upper:]' )

			mon_sh_create > $_sensors_data/$_node_name.mon.sh
			chmod 775 $_sensors_data/$_node_name.mon.sh

			mon_node
                ;;
                esac
	;;
	ignore)
		echo "" 2>&1 /dev/null
	;;
	*)
		_admin_status="unknown"

		_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime: UNKN ($_node_available) state\n" )
		_nodename_tag="UNKN"

		echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/\@\ [a-z_]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/"
	;;

	esac

}

check_cyc_client()
{
	_fs_path=$1
	_dir_path=$2

	if [ ! -d "$_fs_path" ] 
	then
		mkdir -p $_fs_path
		_chk_memfs=$( mount | awk 'BEGIN { _c=1 } $1 == "cyclops_mon" { _c=0 } END { print _c }' )
		[ "$_chk_memfs" == "1" ] && mount -t tmpfs -o size=10m cyclops_mon $_fs_path 
		[ ! -d "$_dir_path" ] && mkdir -p $_dir_path
	else
		if [ ! -d "$_dir_path" ] 
		then
			_chk_memfs=$( mount | awk 'BEGIN { _c=1 } $1 == "cyclops_mon" { _c=0 } END { print _c }' ) 
			[ "$_chk_memfs" == "1" ] && mount -t tmpfs -o size=10m cyclops_mon $_fs_path
			[ ! -d "$_dir_path" ] && mkdir -p $_dir_path 
		fi
	fi
}

mon_node()
{

	_err=$( ssh -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name  "$(typeset -f);check_cyc_client" $_base_path $_sensor_remote_path 2>/dev/null >/dev/null ; echo $? )
	[ "$_err" == "0" ] && _err=$( scp -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_sensors_data"/"$_node_name".mon.sh" "$_node_name":"$_sensor_remote_path"/ 2>/dev/null >/dev/null ; echo $? )

	case "$_err" in
	0)
                scp "$_sensors_config_path/torquemada.sensor.sh" "$_node_name":"$_sensor_remote_path"/ 2>/dev/null >/dev/null
                _status_conf_files=$( ls -1 $_sensors_config_path | grep $_node_name | wc -l )

                [ "$_status_conf_files" != "0" ] && scp -r "$_sensors_config_path/$_node_name"* "$_node_name":"$_sensor_remote_path"/ 2>&1 >/dev/null

                _node_remote_exec=$( ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_sensor_remote_path"/"$_node_name".mon.sh" 2>/dev/null )
                _node_ia=$(echo $_node_remote_exec | sed -e 's/@$//')

                [ $(echo $_node_ia | grep FAIL 2>/dev/null | wc -l ) -ne 0 ] && _nodename_tag="FAIL"
                [ $(echo $_node_ia | grep DOWN 2>/dev/null | wc -l ) -ne 0 ] && _nodename_tag="DOWN"
	;;
	1)
                _node_ia=`echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime:FAIL not send@"`
                _node_err="3"
                _nodename_tag="FAIL"	
	;;
	126)
		_node_ia="hostname:"$_node_name";"$(date +%H.%M.%S)"@ uptime:FAIL send denied@\n"
		_nodename_tag="FAIL"
	;;
	255)
		_node_ia="hostname:"$_node_name";"$(date +%H.%M.%S)"@ uptime:FAIL send timeout@\n"
		_nodename_tag="FAIL"
	;;
	*)
		_node_ia=`echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime:FAIL send err.$_err@"`
		_node_err="3"
                _nodename_tag="FAIL"
	;;
	esac

	case "$_admin_status" in
                drain)
                        _nodename_tag="MARK"
			_field_tag="DISABLE"
			echo "${_node_ia}" | awk -F":" -v _f="$_node_family" -v _i="$_output_line" -v _nt="$_nodename_tag" -v _ft="$_field_tag" -v _err="$_err" '
				BEGIN {
					RS="@" ; 
					_line=_i";"_f ; 
				} { 
					if ( $1 == "hostname" ) { $2=_nt" "$2} else { gsub("^[A-Z]+",_ft,$2) } ; 
					if ( $1 ~ "uptime" ) { $2="DRAIN" } ;
					_line=_line";"$2 ; 
				} END { 
					print _line 
				}'
                ;;
		diagnose)
			_nodename_tag="CHECKING"
			_node_ia=$( echo $_node_ia | tr '[:upper:]' '[:lower:]' )
			echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/@ uptime:\([0-9a-z ]*\)@/;MARK DIAGNOSE @/' -e 's/\@\ [0-9a-z_-]*\:/; CHECKING /g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
		;;
		content)
			_nodename_tag="FAIL"
			_node_ia=$( echo $_node_ia | tr '[:upper:]' '[:lower:]' )
                        #echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/@ uptime:\([0-9a-z ]*\)@/;UNKN CONTENT (( node waiting for admin diagnose ))@/' -e 's/\@\ [0-9a-z_-]*\:/; CHECKING /g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
			echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/@ uptime:\([0-9a-z ]*\)@/;FAIL CONTENT @/' -e 's/\@\ [0-9a-z_-]*\:/; CHECKING /g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
		;;
		up_bmc_down)
			if [ "$_node_err" == "3" ]
			then
				_nodename_tag="DOWN"
				_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime: DOWN really power off @\n" )
				echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/\@\ [a-z_-]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//' 
			else
				echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/@ uptime:[A-Z]* [0-9]*d@/;MARK bmc lan err @/' -e 's/@ uptime:/;DOWN bmc err/' -e 's/\@\ [0-9a-z_-]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
			fi
			
		;;
		bmc_auth)
			echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/@ uptime:[A-Z]* [0-9]*d@/;MARK bmc auth err @/' -e 's/\@\ [0-9a-z_-]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
		;;
		bmc_no_cmd)
			echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/@ uptime:[A-Z]* [0-9]*d@/;MARK bmc no cmd @/' -e 's/\@\ [0-9a-z_-]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
		;;
		bmc_session)
			if [ "$_node_err" == "3" ] 
			then
				_nodename_tag="DOWN"
				_node_ia=$( echo "hostname:$_node_name;$(date +%H.%M.%S)@ uptime: DOWN really power off @\n" )
				echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/\@\ [a-z_-]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//' 
			else
				echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/@ uptime:[A-Z]* [0-9]*d@/;MARK bmc session err @/' -e 's/\@\ [0-9a-z_-]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
			fi
		;;
		link|unlink|repair)

			_ctrl_rzr_active=$( echo $_node_ia | tr '@' '\n' | sed -e 's/^ //' -e '/^$/d' | awk -F\: 'BEGIN { _ctrl=0 } $1 == "rzr" && $2 ~ "[0-9]+" { _ctrl=1 } END { print _ctrl }' )

			if [ "$_cyc_razor_status" == "ENABLED" ] && [ "$_err" == "0" ] && [ "$_ctrl_rzr_active" == "1" ]  
			then
				reactive_func &
			fi

			_nodename_tag="CHECKING"
			_node_ia=$( echo $_node_ia | tr '[:upper:]' '[:lower:]' )
			_node_action_status=$( echo $_admin_status | tr '[:lower:]' '[:upper:]' )
			echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e "s/@ uptime:\([0-9a-z ]*\)@/;MARK $_node_action_status @/" -e 's/\@\ [0-9a-z_-]*\:/; CHECKING /g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'

		;;
		*)

			_ctrl_rzr_active=$( echo $_node_ia | tr '@' '\n' | sed -e 's/^ //' -e '/^$/d' | awk -F\: 'BEGIN { _ctrl=0 } $1 == "rzr" && $2 ~ "[0-9]+" { _ctrl=1 } END { print _ctrl }' )

			echo $_node_ia |  sed -e "s/hostname:/$_nodename_tag /" -e 's/\@\ [0-9a-z_-]*\:/;/g' -e "s/^/$_node_family\;/" -e "s/^/$_output_line;/" -e 's/@//'
			if [ "$_cyc_razor_status" == "ENABLED" ] && [ "$_cyc_reactive_status" == "ENABLED" ] && [ "$_err" == "0" ] && [ "$_ctrl_rzr_active" == "1" ] 
			then
				case "$_nodename_tag" in
				FAIL|DOWN)
					reactive_func & 
				;;
				esac
			fi
		;;
	esac

}

reactive_func()
{
	let "_cyc_msg_date=$( date +%s ) + 3600"

	case "$_admin_status" in
	up)
		$_script_path/cyclops.sh -a repair -n $_node_name -c 2>&1 > /dev/null 
		$_script_path/audit.nod.sh -i event -e reactive -m "change to repair" -s REPAIR -n $_node_name 2>>$_mon_log_path/audit.log
	;;
	link)
		if [ "$_nodename_tag" == "FAIL" ] || [ "$_nodename_tag" == "DOWN" ]
		then

			_node_rzr_status=$( ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a check ; echo $? )

			if [ "$_node_rzr_status" != "0" ] && [ "$_node_rzr_status" != "21" ] 
			then
				_node_rzr_status=$( ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a $_admin_status ; echo $? )

				if [ "$_node_rzr_status" != "0" ] && [ "$_node_rzr_status" != "21" ]
				then
					$_script_path/cyclops.sh -a repair -n $_node_name -c 2>&1 > /dev/null 
					$_script_path/audit.nod.sh -i event -e reactive -m "link action" -s FAIL -n $_node_name 2>>$_mon_log_path/audit.log
				else
					$_script_path/cyclops.sh -a up -n $_node_name -c 2>&1 > /dev/null 
					$_script_path/audit.nod.sh -i event -e reactive -m "link action" -s OK -n $_node_name 2>>$_mon_log_path/audit.log
					
				fi
			else
				$_script_path/cyclops.sh -a diagnose -n $_node_name -c 2>&1 > /dev/null				
				$_script_path/audit.nod.sh -i event -e reactive -m "link action" -s UP -n $_node_name 2>>$_mon_log_path/audit.log
			fi
		else
			$_script_path/cyclops.sh -a up -n $_node_name -c 2>&1 >/dev/null 
			$_script_path/audit.nod.sh -i event -e reactive -m "link action" -s OK -n $_node_name 2>>$_mon_log_path/audit.log
		fi
	;;
	repair)
		if [ "$_nodename_tag" == "FAIL" ] || [ "$_nodename_tag" == "DOWN" ]
		then
			_node_rzr_status=$( ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a check ; echo $? )
			if [ "$_node_rzr_status" != "0" ] && [ "$_node_rzr_status" != "21" ]
			then
				_node_rzr_status=$( ssh  -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_node_name $_cyc_clt_rzr_scp -a repair ; echo $? )

				if [ "$_node_rzr_status" == "0" ] || [ "$_node_rzr_status" == "21" ]
				then
					_msg_insert="repair action ok, please change to up if status is ok"
					$_script_path/cyclops.sh -a diagnose -n $_node_name -c 2>&1 >/dev/null	
					$_script_path/audit.nod.sh -i event -e reactive -m $_msg_insert -s UP -n $_node_name 2>>$_mon_log_path/audit.log
					$_script_path/cyclops.sh -p medium -m $_node_name" : "$_msg_insert -l
				else
					_msg_insert="repair action fail, please change to drain if status is bad and productive environment is ok"
					$_script_path/cyclops.sh -a content -n $_node_name -c 2>&1 >/dev/null 
					$_script_path/audit.nod.sh -i event -e reactive -m $_msg_insert -s CONTENT -n $_node_name 2>>$_mon_log_path/audit.log
					$_script_path/cyclops.sh -p high -m $_node_name" : "$_msg_insert -l
				fi
			else
				$_script_path/cyclops.sh -a content -n $_node_name -c 2>&1 > /dev/null	
				$_script_path/audit.nod.sh -i event -e reactive -m "razor check ok, inconsistency with monitoring module, manually check node status" -s CONTENT -n $_node_name 2>>$_mon_log_path/audit.log
			fi
		else
			$_script_path/cyclops.sh -a up -n $_node_name -c 2>&1 >/dev/null 
			$_script_path/audit.nod.sh -i event -e reactive -m "repair action" -s OK -n $_node_name 2>>$_mon_log_path/audit.log
		fi
	;;
	unlink)
		$_script_path/cyclops.sh -a drain -n $_node_name -c 2>&1 >/dev/null 
		$_script_path/audit.nod.sh -i event -e reactive -m "change to drain" -s DRAIN -n $_node_name 2>>$_mon_log_path/audit.log
	;;
	*)
		#### EXTEND CASES ####
		$_script_path/cyclops.sh -a repair -n $_node_name -c 2>&1 > /dev/null 
		$_script_path/audit.nod.sh -i event -e reactive -m "$_admin_status , generic procedure, change to repair" -s REPAIR -n $_node_name 2>>$_mon_log_path/audit.log
	;;
	esac
}

family_processing()
{

	_output_line=0

	_node_data=$( awk -F\; -v _nl="${_long}" '
		BEGIN { 
			split(_nl,ln,"\n") 
		} { 
			for ( i in ln ) { 
				if ( $2 == ln[i] ) {  
					family[$3]=family[$3]"\n"$2";"$3";"$4";"$5";"$6";"$7 
				} 
			} 
		} END { 
			_fl=asorti(family, famidx) ; 
			for (a=1;a<=_fl;a++) { 
				_t=famidx[a] ; 
				print family[_t] 
			}
		}' $_type | sed '/^$/d' )

	if [ ! -z "$_node_data" ]
	then
		for _node_list in $( echo "${_node_data}" )
		do
			#_node_list=$( awk -F\; -v _n="$_node_name" '$2 == _n { print $3";"$4";"$5";"$6";"$7 }' $_type ) 

			_node_name=$( echo $_node_list | cut -d';' -f1 )
			_node_family=$( echo $_node_list | cut -d';' -f2 )
			_node_group=$( echo $_node_list | cut -d';' -f3 )
			_node_os=$( echo $_node_list | cut -d';' -f4 )
			_node_power=$( echo $_node_list | cut -d';' -f5 )
			_node_available=$( echo $_node_list | cut -d';' -f6 )

			if [ "$_family_old" != "$_node_family" ]
			then
				let "_output_line++"    
				awk -F\; -v _ol="$_output_line" 'BEGIN { _head=_ol";family@" } { if ( $2 != "" ) { _head=_head""$1"_"$2"@" } else { _head=_head""$1"@" }} END { gsub("@$","",_head) ; print _head }' $_config_path_nod/$_node_family.mon.cfg
				_family_old=$_node_family
			fi

			let "_output_line++" 
		
			mon_check_status &
		done  
		wait
	fi
}

wiki_format()
{
	###### PRE-PROCESSING OUTPUT ------

	if [ "$_exit_code" -eq 0 ] || [ "$_exit_code" -eq 12 ] 
	then
		_family_status=$_color_ok  
		_title_status=$_color_up
		_family_font_color="white"
	else
		_family_status=$_color_down
		_title_status=$_color_red
		_family_font_color="white"
	fi

	if [ "$_par_mon" == "all" ]
	then
		_total_nodes=$( cat $_type | wc -l )
	else
		_total_nodes=$( echo "${_long}" | wc -l )	
	fi

	_active_nodes=$( echo -e "${_output}" | grep -v \@ | cut -d';' -f3 | grep ^UP | wc -l )
	[ "$_active_nodes" -eq "$_total_nodes" ] && _active_nodes_color=$_color_up || _active_nodes_color=$_color_mark

	_sensor_alerts=$( echo -e "${_output}" | grep -v \@ | awk -F ";" '{ linea=0 ; for ( a=2 ; a <= NF ; a++ ) { if ( $a ~ /FAIL|DOWN/ ) linea++ } ; if ( linea == 2 ) { linea=1 } ; sensor=sensor+linea } END { print sensor }' )
	[ "$_sensor_alerts" -eq 0 ] && _sensor_alerts_color=$_color_up || _sensor_alerts_color=$_color_fail

	_warnings_active=$( echo -e "${_output}" | grep -v \@ | awk -F ";" '{ linea=0 ; for ( a=2 ; a <= NF ; a++ ) { if ( $a ~ /MARK/ ) linea++ } ; sensor=sensor+linea } END { print sensor }' )
	[ "$_warnings_active" -eq 0 ] && _warnings_color=$_color_up || _warnings_color=$_color_mark

	_maxup_node=$( echo -e "${_output}" | cut -d';' -f3,5 | grep " [0-9]*d$" | sed 's/.*\ \(.*\);.*\ \([0-9]*d\)/\2 \1/' | sort  -k1,1n  | tail -n 1 )
	_minup_node=$( echo -e "${_output}" | cut -d';' -f3,5 | grep " [0-9]*d$" | sed 's/.*\ \(.*\);.*\ \([0-9]*d\)/\2 \1/' | sort  -k1,1n  | head -n 1 )

	[ -z "$_maxup_node" ] && _maxup_node="none" && _maxup_color=$_color_disable || _maxup_color=$_color_up
	[ -z "$_minup_node" ] && _minup_node="none" && _minup_color=$_color_disable || _minup_color=$_color_up

	###### DRAWING OUTPUT ------

	echo "."
	echo "."
	echo ~~NOCACHE~~ 
	echo "	" 
	echo 
	echo "|< 100% 15% 11% 11% 11% 11% 11% 15% 15% >|"
	echo "|  $_family_status ** <fc $_family_font_color > $( echo $_par_mon | tr [:lower:] [:upper:] | tr -d '@' ) </fc> **  |  $_title_status Time  |  $_title_status Total Nodes  |  $_title_status Active Nodes  |  $_title_status Sensor Alerts  |  $_title_status Warnings  |  $_title_status Max Uptime  |  $_title_status Min Uptime    |"
	echo "|  :::  |  $( date +%H.%M.%S )  |  $_total_nodes              |  $_active_nodes_color $_active_nodes  |  $_sensor_alerts_color $_sensor_alerts  |  $_warnings_color $_warnings_active  |  $_maxup_color $_maxup_node  |  $_minup_color $_minup_node  |"

	if [ "$_exit_code" -ne 0 ] && [ "$_exit_code" -ne 12 ] 
	then
		echo
		echo -e "|< 100% 10% 10% 10% 10% 25% 5% 30% >|"
		echo -e "${_ia_alert}"  | head -n 1 | sed -e "s/@/\ \ \|\ \ \ $_color_red /g" -e "s/^/\|\ \ $_color_red /" -e 's/$/\ \ \|/' -e "s/^/|  $_color_down {{ :wiki:rules_detected.gif?nolink }}  /"  
		echo -e "${_ia_alert}"  | sed -e '1d' -e "s/;\([A-Z][A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9]\);/;{{:wiki:proc_code.gif }} {{popup>$_wiki_procedures_path:\1?[%100x700%]\&[keepOpen] |\1}};/" -e 's/^/|\ \ /' -e 's/$/\ \ \|/' -e 's/;/\ \ \|\ \ /g' -e "s/DOWN/$_color_down/g" -e "s/UP/$_color_up/g" -e "s/OK/$_color_ok/g" -e "s/UNKNOWN/$_color_unk&/g" -e 's/^/|  :::  /'
	fi

	echo
	echo "<hidden $( echo $_par_mon | tr -d '@' ) $_ia_hidden_state>"
	### REFACTORING NEXT LINE ( awk -F\; -v _awp="$_audit_wiki_path" -v _wfp="$_wiki_audit_path" 'BEGIN { OFS=";" } $3 != "" { split ($3,a," ") ; if( system( "[ -f "_awp"/"a[2]".audit.txt ] " )  == 0 ) { $3=a[1]" {{popup>"_wfp":"a[2]".audit?[%100x700%]&[keepOpen] |"a[2]"}}" }} { print $0 }' ) ## INSERT AUDIT LINK TO NODE MON
	echo -e "${_output}" | sort -n | cut -d';' -f2- |
		sed '/^$/d' |
sed -e "s/@/;$_color_title/g" -e "s/family/$_color_title&/" -e 's/^/\|\ \ /' -e 's/$/\ \ \|/' -e 's/\;/\ \ \|\ \ /g' -e "s/UPTIME/$_color_up/" -e "s/TIME/$_color_up/" -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/FAIL/$_color_fail/g" -e 's/none//g' -e "s/UNKNOWN/$_color_unk/g" -e "s/UNKN/$_color_unk/g" -e "s/UNLINK/KICKOUT/" -e "s/MARK/$_color_mark/g" -e "s/CHECKING/$_color_check/g" -e "s/DISABLE/$_color_disable/g" -e "s/LOADED/$_color_loaded/g" -e "s/DRAIN/$_color_disable MAINTENANCE/" -e "s/POWEROFF/$_color_poweroff power off/" -e "s/DEAD/$_color_dead/g" |
		sed -e '/family/ i\
' -e '/family/ i\
|< 100% 8% 8% 8% 8% >|'

	echo "</hidden>"

}

###########################################
#              MAIN EXEC                  #
###########################################

[ -z "$_par_mon" ] && _par_mon=$( awk -F\; '$1 ~ "^[0-9]+$" { print $2 }' $_type )

###### MONITOR LAUNCH -------

_output=$(family_processing)

###### IA PROCESSING --------

if [ "$_opt_ia" == "yes" ]
then

	_ctrl_err=$( echo -e "${_output}" | sort -n | tr '@' ';' | sed -e '/^$/d' -e 's/CHECKING //g' | cut -d';' -f3- | 
		awk -F\; '
			$0 ~ "OK" || $0 ~ "UP" || $0 ~ "DOWN" || $0 ~ "FAIL" || $0 ~ "UNKN" || $0 ~ "MARK" { 
				_err=0 ; 
				for (i=1;i<=NF;i++) { 
					_lmsg=split($i,msg," ") ;
					if ( msg[1] ~ /DOWN|FAIL|UNKN/ ) {
						_msg=msg[2]
						if ( _lmsg > 2 ) { 
							for (m=3;m<=_lmsg;m++) { 
								_msg=_msg" "msg[m] 
							}
						}
					}
					if ( msg[1] == "DOWN" ) { _err=1 ; print $1";D;"i";"_msg }
					if ( msg[1] == "FAIL" ) { _err=1 ; print $1";F;"i";"_msg }
					if ( msg[1] ~ "UNKN" )  { _err=1 ; print $1";U;"i";"_msg }
					if ( msg[1] == "MARK" ) { _err=1 ; print $1";M;"i";"_msg }
				}
				if ( _err == 0 ) { print $1";K;0;"}
			} ' | 
		cut -d' ' -f2- )
	echo "${_ctrl_err}" > $_sensors_ia_tmp_path/$_pid"."$_sensors_ia_tmp_name

	_exit_code=$( echo "${_ctrl_err}" | awk -F\; '
		BEGIN { _x="0" } 
		$2 == "M" { _m++ } 
		$2 == "U" { _u++ } 
		$2 == "F" { _f++ } 
		$2 == "D" { _d++ } 
		END { 
			if ( _d != 0 ) { print "10" } 
				else if ( _f != 0 ) { print "11" } 
					else if ( _u != 0 ) { print "90" } 
						else if ( _m != 0 ) { print "12" } 
							else { print "00" } 
		}' )

	_ia_alert=$($_sensors_ia_script_file $_pid)

	if [ ! -z "$_ia_alert" ]
	then
		_ia_header="DOWN NODE STATUS - RULES DETECTED"
		_ia_hidden_state="initialState=\"visible\""

		## Generating alert --

		_file_mail=$_sensors_alerts_path"/$PPID.nodes.mail."$(date +%Y%m%dt%H%M%S )".txt"
	else
		_ia_header=";OK NODE STATUS - OPERATIVE;"
		_ia_hidden_state=""
	fi

fi

###### VISUAL FORMATING ------

case $_par_show in
	"commas")
		[ "$_opt_ia" == "yes" ] && echo "MON IA ENABLED"
		echo 
		echo "IA ANALISIS REPORT:"
		echo -e $_ia_header
		echo -e "${_ia_alert}" | sed -e 's/--//' -e 's/@/;/g'
		echo -e "${_output}" | sort -n | cut -d';' -f2- | tr '@' ';' | sed -e '/^$/d' -e '/family/ i\
'
	;;
	"human")
		echo -e "${_ia_header}"
		echo -e "${_ia_alert}" | sed -e 's/^ //' -e 's/@/;/g' -e 's/^;//' -e 's/;$//' | column -s\; -t
		echo -e "${_output}" | sort -n -t\; | cut -d';' -f2- | tr '@' ';' | column -s\; -t | sed -e '/^$/d' -e '/family/ i\
'
		echo
	;;
	"hcol")
		if [ -z "${_ia_header}" ]
		then
			echo "IA ANALISIS REPORT:"
			echo -e "${_ia_header}"
			echo -e "${_ia_alert}" | sed -e 's/--//' -e 's/@/;/g'
		fi
		echo -e "${_output}" | sort -n | cut -d';' -f2- | tr '@' ';' | sed -e '/^$/d' | awk -F\; 'BEGIN { _s=0 } $1 == "family" { _s=1 ; split($0,h,";") } $1 != "family" && _s=1 { for ( i in h ) { h[i]=h[i]";"$i }} END { for ( a in h ) { print a";"h[a] }}' | sort -n -t\; | cut -d';' -f2- | column -t -s\; 
	;;
	"wiki")
		wiki_format

	;;
	*)
		echo "IA ANALISIS"
		echo
		echo "${_ia_alert}"
		echo
		echo "MON OUTPUT"
		echo 
		echo -e "${_output}"
		echo
	;;
esac

exit $_exit_code
