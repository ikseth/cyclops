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


###########################################
#              PARAMETERs                 #
###########################################

_date=$( date +%s )

while getopts "n:dh" _optname
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
                "h")
                        echo "-n [nodename/nodename[range]"
                        echo "  range=[star id node]-[end id node]"
                        echo "  Range Example tool.mac.extract.sh -n node[5-10] // get node from node5 to node10 include nodenames between range"
                        echo "  Range Example tool.mac.extract.sh -n node[5,10] // only get nodes node5 and node10"
                        echo "  You can combine both syntax like: tool.mac.extract.sh -n node[5-10,20] // get node from node5 to node10 and node20"
                        echo
                        exit 0
                ;;
                "d")
                        _opt_debug="yes"
                        ## DEBUGGING OPTION
                        echo "You choose hidden debug option"
                ;;
        esac
done

#### FUNCTIONS ####

debug_name_range()
{

	echo "NAME: ${_name}"
	echo 
	echo "RANGE: ${_range}"
	echo
	echo "VALUES: ${_values}"
	echo
	echo "LONG:" 
	echo "${_long}"

}

node_regroup()
{       
        _nodelist=$1
        
        echo "${_nodelist}" | tr ' ' '\n' | sed 's/[0-9]*$/;&/' | sort -t\; -k2,2n -u | awk -F\; '
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

                END { if ( $2 == _end + 1 ) {
                        _sep="-" ;
                        _end=$2 }
                        else
                        {
                            if ( _sep == "-" ) { 
                                _string=_string""_sta"-"_end }
                                else {
                                    _string=_string""_sta }
                            _sep="," ;
                            _sta=$2 ;
                            _end=$2 ;
                        }
                        print _string"]" }'

 
}

#### MAIN EXEC ####

	debug_name_range
