#!/bin/bash

_default_user="super"
_default_pass="pass"

_new_user="administrator"
_new_pass="administrator"

#### LIBS ####

	source /etc/cyclops/global.cfg

        source $_libs_path/node_group.sh
        source $_libs_path/node_ungroup.sh

#### PARAMETERS ####

while getopts ":n:u:p:U:P:h:" _optname
do

        case "$_optname" in
	"u")
		_default_user=$OPTARG
	;;
	"p")
		_default_pass=$OPTARG
	;;
	"U")
		_new_user=$OPTARG
	;;
	"P")
		_new_pass=$OPTARG
	;;
	"n")
		_opt_nod="yes"
		_par_nod=$OPTARG

		#_name=$( echo $_par_nod | cut -d'[' -f1 | sed 's/[0-9]*$//' )
		#_range=$( echo $_par_nod | sed -e "s/$_name\[/\{/" -e 's/\([0-9]*\)\-\([0-9]*\)/\{\1\.\.\2\}/g' -e 's/\]$/\}/' -e "s/$_name\([0-9]*\)/\1/"  )
		#_values=$( eval echo $_range | tr -d '{' | tr -d '}' )

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

		_values=$( node_ungroup $_par_nod | tr ' ' '\n' )
	

	;;
	"h")
		case "$OPTARG" in
		"des")
			echo "$( basename "$0" ): Tool for configure remote access to the bmc interface"
			echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
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
			echo "CYCLOPS TOOL: CONFIGURE REMOTE ACCESS FOR BMC (IPMITOOL)"
			echo
			echo "	-n bmc name or bmc range (bmc1 or bmc[1-5])"
			echo "	-u default bmc/ilo user"
			echo "	-p default bmc/ilo password"
			echo "	-U new user to create in bmc/ilo"
			echo "	-P new password to create in bmc/ilo"
			echo "	-h [|des] help is help"
			echo "		des: Detailed Command Help"
			echo
			exit 0
		else
			echo "ERR: Use -h for help"
			exit 1
		fi
			
	;;
	"*")
		echo "ERR: Use -h to see help"
		exit 1
	;;
	esac
done

shift $((OPTIND-1))

#### FUNCTIONS ####

create_action()
{

	_user_status=$( ipmitool -I lanplus -U $_default_user -P $_default_pass -H $_bmc user set name 4 $_new_user 2>&1 )
	_pass_status=$( ipmitool -I lanplus -U $_default_user -P $_default_pass -H $_bmc user set password 4 $_new_pass 2>&1 )
	_access_status=$( ipmitool -I lanplus -U $_default_user -P $_default_pass -H $_bmc channel setaccess 1 4 link=on ipmi=on callin=on privilege=4 2>&1 )
	_enable_status=$( ipmitool -I lanplus -U $_default_user -P $_default_pass -H $_bmc user enable 4 2>&1 )
	_sol_status=$( ipmitool -I lanplus -U $_default_user -P $_default_pass -H $_bmc sol payload enable 1 4 2>&1 ) 

	[ -z "$_user_status" ] && _user_status="ok" || _user_status="fail"
	[ -z "$_pass_status" ] && _pass_status="ok" || _pass_status="fail"
	[ -z "$_access_status" ] && _access_status="ok" || _access_status="fail"
	[ -z "$_enable_status" ] && _enable_status="ok" || _enable_status="fail"
	[ -z "$_sol_status" ] && _sol_status="ok" || _sol_status="fail"

	_status=$( ipmitool -I lanplus -U $_new_user -P $_new_pass -H $_bmc user list 2>/dev/null )

	[ -z "$_status" ] && _status="NO NEW USER ACCESS" || _status="ACCESS OK"

	echo "$_bmc : user status ($_user_status) : pass status ($_pass_status) : access status ($_access_status) : sol status ($_sol_status) :::: $_status"

}

_background_launch()
{
        _check_ping=$( ping -c 2 $_bmc 2>&1 >/dev/null ; echo $? ) 
        [ "$_check_ping" -eq 0 ] && create_action || echo "$_bmc : don't exits or has network down"
}

#### MAIN EXEC ####

echo "start to create ipmi user, pass and access in $1"
echo
echo "Access to bmc with user: "$_default_user
echo "Create new bmc user: "$_new_user

for _bmc in $( echo "${_values}" | tr ' ' '\n' )
do
	
	_background_launch &

done	
wait

echo
echo "finish: "$( echo "${_values}" | tr ' ' '\n' | wc -l )" nodes"
