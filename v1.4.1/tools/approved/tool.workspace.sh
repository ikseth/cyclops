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

while getopts ":t:f:n:xa:h:" _optname
do
        case "$_optname" in
                "n")
                        _opt_nod="yes"
                        _par_nod=$OPTARG
                ;;
                "t")
                        _opt_type="yes"
                ;;
                "f")
                        _opt_fil="yes"
                        _par_fil=$OPTARG

                        if [ -z "$_par_fil" ] || [ ! -f "$_par_fil" ]
                        then
                                echo "ERR: Alternative Variable files don't exists" 
                                exit 1
                        fi

                ;;
                "x")
                        _opt_debug="yes"
                        ## DEBUGGING OPTION
                        echo "You choose hidden debug option"
                ;;
                "a")
                        _opt_act="yes"
                        _par_act=$OPTARG
                ;;
                "h")
                        case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Workspace Variable Environment Manage tool"
                                echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
                                echo "  Default config path: $_config_path_too"
				echo "  Config files: FACTORING"
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
                                echo "CYCLOPS TOOL: WORKSPACE VARIABLE ENVIRONMENT MANAGEMENT TOOL"
                                echo 
                                echo "OPTIONS:"
				echo "	-a [load|unload|show|list] Manage actions over available workspaces"
				echo "		load: enable workspace"
				echo "		unload: disable workspace"
				echo "		show: show workspace status"
				echo "		list: list available workspaces"
				echo "	-t [workspace name] Select workspace to manage it" 
                                echo "	-n [nodename/nodename[range]"
                                echo "		range=[star id node]-[end id node]"
                                echo "		Range Example script.sh -n node[5-10] // get node from node5 to node10 include nodenames between range"
                                echo "		Range Example script.sh -n node[5,10] // only get nodes node5 and node10"
                                echo "		You can combine both syntax like: tool.mac.extract.sh -n node[5-10,20] // get node from node5 to node10 and node20"
                                echo "	-f [config file] Alternative enviroment variable file"
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

list_ava_ws()
{
	for _file in $( ls -1 $_config_path_too/*.ws.cyc )
	do
		$_config_path_too/$_file list	
	done
}

load_ws()
{

	_ws_file=$_config_path_too"/"$_par_type".ws.cyc"

	if [ -f "$_ws_file" ] 
	then
		_CYC_WORKSPACE=$_par_type	
		export $_CYC_WORKSPACE
		source $_ws_file load 
		[ -z "$_par_nod" ] && nodes_ws load
	else
		echo "ERR: File NOT Exists" 
		exit 1
	fi

}

unload_ws()
{

	if [ ! -z "$_CYC_WORKSPACE" ] && [ "$_par_type" == "$_CYC_WORKSPACE" ] && [ "$_CYC_WORKSPACE" != "ONLYNODES" ] 
	then
		_ws_file=$_config_path_too"/"$_CYC_WORKSPACE".ws.cyc"
		source $_ws_file unload
		[ ! -z "$_CYC_NODES" ] && nodes_ws unload
	else
		echo "ERR: Undefined yes" 
		exit 1	
	fi
	

}

show_ws()
{
	if [ "$_par_type" == "$_CYC_WORKSPACE" ]
	then
		_ws_file=$_config_path_too"/"$_CYC_WORKSPACE".ws.cyc"
		source $_ws_file show
		[ ! -z "$_CYC_NODES" ] && nodes_ws show
	else
		echo "ERR: $_par_type workspace is not loaded"
		exit 1
	fi
}

nodes_ws()
{

	_nodes_act=$1

	echo "DEBUG: $_nodes_act"

	case "$_nodes_act" in
	load)
		echo "LOAD: NODE WORKSPACE VARs"
		source $_config_path_too"/nodes.ws.cyc" load $_par_nod
		export _CYC_NODE_RANGE _CYC_NODE_PREFIX _CYC_NODE_SUFIX _CYC_NODE_LIST
	;;
	unload)
		echo "UNLOAD: NODE WORKSPACE VARs"
		source $_config_path_too"/nodes.ws.cyc" unload
	;;
	show)
	;;
	list)
	;;
	esac

}

#### MAIN EXEC ####

	if [ ! -z "$_opt_type" ] 
	then
		echo "DEBUG: $_opt_type"

		case "$_par_act" in
		load)
		;;
		unload)
		;;
		show)
		;;
		list)
			list_ava_ws
		;;
		"*")
			echo "FACTORY"
		;;
		esac
	else

		echo "DEBUG: $_opt_act"

		if [ "$_opt_nod" == "yes" ] 
		then
			_CYC_WORKSPACE="ONLYNODES"
			export $_CYC_WORKSPACE
			nodes_ws $_par_act 
		else
			echo "ERR: Use -h for help"
			exit 1
		fi
	fi


	
