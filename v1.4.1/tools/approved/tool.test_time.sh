#!/bin/bash

	_start=$( date +%s )

while getopts ":t:f:h:" _optname
do

        case "$_optname" in
        "t")
                _opt_typ="yes"
                _par_typ=$OPTARG
        ;;
	"f")
		_opt_fil="yes"
		_par_fil=$OPTARG
	;;
        "h")
                case "$OPTARG" in
                "des")
                        echo "$( basename "$0" ): Tool for test time lost in exec things"
                        echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
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
                        echo "  -t [ievent|isensor] type of test" 
			echo "		ievent: ipmitool events"
			echo "		isensor: ipmitool sensors"
			echo "	-f [file] if you want to test a remote script"
                        echo "  -h [|des] help is help"
                        echo "          des: Detailed Command Help"
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


### FUNCT ####

ievent()
{
	_ipmievents=$( ipmitool sel elist 2>/dev/null )
	_test=$_ipmievents
}

isensor()
{
	_ipmisensors=$( ipmitool sensor 2>/dev/null )
	_test=$_ipmisensors
}

remotesh()
{
	_remotetest=$( $_par_type 2>/dev/null )
	_test=$_remotetest
}

### MAIN ###


	case "$_par_typ" in 
	ievent)
		ievent
	;;
	isensor)
		isensor
	;;
	*)
		if [ "$_opt_fil" != "yes" ]
		then
			[ -z "$_par_type" ] && _par_type="none" || _par_type="not exists"
			_test="NONE"	
		else
			_par_type="remotesh"
			[ -f "$_par_fil" ] && remotesh || _par_type="remote sh not exits" 
		fi
	;;
	esac

	_end=$( date +%s )

	let "_diff=_end-_start"

	echo "TEST: $_par_typ : SPENT TIME: $_diff segs"
