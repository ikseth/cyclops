#!/bin/bash

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

IFS="
"

_config_path="/etc/cyclops"

if [ -f $_config_path/global.cfg ]
then
        source $_config_path/global.cfg
	source $_libs_path/ha_ctrl.sh
else
        echo "Global config don't exits" 
        exit 1
fi

_stat_slurm_data=$( cat $_stat_main_cfg_file | awk -F\; '$2 == "slurm" { print $0 }' | head -n 1 )
_stat_slurm_cfg_file=$_config_path_sta"/"$( echo $_stat_slurm_data | cut -d';' -f3 )
_stat_slurm_data_dir=$_stat_data_path"/"$( echo $_stat_slurm_data | cut -d';' -f4 ) 

_script_start=$( date +%s ) 

_command_opts=$( echo "$@" | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^m/ ) { gsub(/^[a-z] /,"&@",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' )
_command_name=$( basename "$0" )
_command_dir=$( dirname "${BASH_SOURCE[0]}" )
_command="$_command_dir/$_command_name $_command_opts"

_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

###########################################
#              PARAMETERs                 #
###########################################

_date_now=$( date +%s )

while getopts ":cn:s:o:mde:v:f:b:h:" _optname
do
        case "$_optname" in
		"c")
			_opt_cmp="yes"
			_sh_action="compact"
		;;
		"s")
			_opt_src="yes"
			_par_src=$OPTARG

#			[ -z "$_par_src" ] && _par_src="localhost"	
		;;
		"o")
			_opt_dst="yes"
			_par_dst=$OPTARG
		;;
		"d")
			_sh_action="daemon"
			_opt_daemon="yes"
		;;
		"m")
			_sh_action="manual"
			_opt_manual="yes"
		;;
		"e")
			_sh_action="extractor"
			_opt_xtr="yes"
			_par_xtr=$OPTARG

			if [ "$_par_xtr" == "help" ] 
			then
				sed -e '1 iindex;extractor;source;destination;fields' -e '/\#/d' $_stat_slurm_cfg_file | column -s\; -t
				exit
			fi

			#### SELECT MAIN EXTRACTOR OR SUB SCRIPT TO GENERATE STATS FROM MAIN DATA ####
			
		;;
		"v")
			_sh_action="show"
			_opt_shw="yes"
			_par_shw=$OPTARG
		;;
		"f")
			_opt_date_end="yes"
			_par_date_end=$OPTARG
		;;
		"b")
			_opt_date_start="yes"
			_par_date_start=$OPTARG
		;;
		"h")
			case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Slurm database extractor module"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Config file: $_stat_slurm_cfg_file" 
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
				echo "CYCLOPS SLURM STATISTICS EXTRACTOR"
				echo
				echo "EXTRACTED FIELDS:"
				echo "	Start,JobID,User,Partition,JobName,ReqCPUS,ReqMem,NNodes,NTasks,ConsumedEnergy,Elapsed,State,Nodelist"
				echo "PROCESSED FIELDS:"
				echo "	ConsumedEnergy(K,Julius),ConsumedEnergy(KWh),Elapsed(Seconds)"
				echo "HOLD DATA FORMAT"
				echo "	Job Start Time;Job ID;user;partition;Job Name;Req Cores;Req Memory;Req Nodes;Req Task;Consumed Energy (KJ);Consumed Energy (Kwh);WTF_jsec;Elapsed Time;Job State;Node Range"
				echo
				echo "-s [nodename/IP] Slurm DB source"
				echo "-o [string] destination prefix for data extration"
				echo "-d Daemon mode for main slurm data extraction"
				echo "-m Manual mode for main slurm data extraction"
				echo "-c Compact Data, use with -o option, use -e to see existing data prefix"
				echo "-e [extrator|help] all configurated extrators, main for all data, use help to see -s -o -e options"
				echo "-v [human|commas|wiki] Data Show, only read, mandatory option, dont use if you want to extrat data to files"
				echo "-b [YYYY-MM-DD] Start Date for extract or show info, if not use get today date"
				echo "-f [YYYY-MM-DD] End Date for extract or show info, if not use get today date"
				echo "-h [|des] help is help"
				echo "	des: Detailed Command Help"
				echo
				exit 0
			else
				echo "ERR: Use -h for help"
				exit 1
			fi
                ;;
        esac
done

shift $((OPTIND-1))

#### FUNCTIONS ####

main_extractor()
{

	sacct  --format 'Start,JobID,User,Partition,JobName,ReqCPUS,ReqMem,NNodes,NTasks,ConsumedEnergy,Elapsed,State,Nodelist' -P -S $1 -E $2 -n | tr '|' ';'

}

process_extract()
{
	[ ! -z "$_extract_tmp_file" ] && awk -F\; '$12 != "RUNNING" && $12 != "PENDING" && $5 != "sleep" {
		split($2,j,".") ;
		if ( NR == 1 ) { _job=j[1] ; _job=j[1] ; _user=$3 ; _part=$4 ; _jobn=$5 ; _rmem=$7 ; _nnod=$8 ;  _stat=$12 ; _et=$11 ; _nod=$13 } ;
		if ( j[1] != _job ) {
			gsub(/T|:|-/," ",$1) ;
			gsub(/ by [0-9]+/,"",_stat) ;
			_jstart=mktime($1) ;
			print _jstart";"_job";"_user";"_part";"_jobn";"_rcor";"_rmem";"_nnod";"_ntask";"_jl";"_wh";"_jsec";"_et";"_stat";"_nod ;
			_job=j[1] ; _user=$3 ; _part=$4 ; _jobn=$5 ; _rmem=$7 ; _nnod=$8 ;  _stat=$12 ; _nod=$13 ; 
			_ener=0 ;
		} else {
			if ( $5 == "sleep" ) { _rcor=$6 ; _ntask=$9 };
			if ( $5 == "batch" ) {
				_jl=$10
				_et=$11
				split($11,t,"-") ;
				if ( t[1] != "" && t[2] != "" ) { split(t[2],tt,":") ; _jsec=t[1]*24*60*60+tt[1]*60*60+tt[2]*60+tt[3] ; } else { split(t[1],tt,":") ; _jsec=tt[1]*60*60+tt[2]*60+tt[3] };
				if ( $10 !~ /[A-Z]/ ) { _jl=$10/1000 } ;
				if ( $10 ~ /K/ ) { sub(/K/,"", $10) ; _jl=$10 ; } ;
				if ( $10 ~ /M/ ) { sub(/M/,"", $10) ; _jl=$10*1000 ; } ;
				if ( $10 ~ /G/ ) { sub(/G/,"", $10) ; _jl=$10*1000*1000 ; } ;
				if ( $10 ~ /T/ ) { sub(/T/,"", $10) ; _jl=$10*1000*1000*1000 ; } ;
				if ( $10 == "" ) { _jl=0  } ;
				_wh=_jl/3600
			}
		}
	}
	END { print _jstart";"_job";"_user";"_part";"_jobn";"_rcor";"_rmem";"_nnod";"_ntask";"_jl";"_wh";"_jsec";"_et";"_stat";"_nod }'  $_extract_tmp_file > $_process_tmp_file && rm -f $_extract_tmp_file
}

main_action()
{
	[ "$_sh_action" != "daemon" ] && echo "LINK TO DB $_par_src TO EXTRACT DATA"
	[ -f "$_extract_tmp_file" ] && echo "ERR: ANOTHER EXTRACT INSTANCE OPEN, PLEASE WAIT OR DELETE $_extract_tmp_file IF YOU ARE SURE NO OTHER EXTRACT RUNNING" && exit 1
	ssh -o ConnectTimeout=10 $_par_src "$(typeset -f);main_extractor" $_par_date_start $_par_date_end >$_extract_tmp_file 2>/dev/null

	[ "$_sh_action" != "daemon" ] && echo -e "EXTRACT: $( wc -l $_extract_tmp_file | awk '{ print $1 }' ) REGISTERs\n"
	[ "$_sh_action" != "daemon" ] && echo -e "PROCESS TEMP FILE DATA $_extract_tmp_file"
	process_extract
	[ "$_sh_action" != "daemon" ] && echo -e "PROCESSED: $( wc -l $_process_tmp_file | awk '{ print $1 }' ) REGISTERs\n"
	[ "$_sh_action" != "daemon" ] && echo -e "WRITE EXTRATED DATA TO FILE IN $_main_output_path/$_par_dst"	
	_main_output_path=$_stat_slurm_data_dir"/"$_par_dst
	[ ! -d "$_main_output_path" ] && mkdir -p $_main_output_path
	[ ! -z "$_process_tmp_file" ] && awk -F\; -v _p="$_main_output_path" -v _sh="$_sh_action" '{ _y=strftime("%Y",$1); _m=strftime("%m",$1) ; print $0 >> _p"/"_y"."_m".main.data.txt" }  END {  if ( _sh != "daemon" ) { print "NUMBER OF REG PROCESSED:"NR  }}' $_process_tmp_file #&& rm -f $_process_tmp_file

}

main_compact_data()
{

	for _file in $( ls -1 $_stat_slurm_data_dir/$_par_dst/*.txt )
	do
		_compact_total=$( cat $_file | wc -l )
		_compact_dup=$( sort $_file | uniq -d | wc -l ) 
		_filename=$( echo $_file | awk -F\/ '{ print $NF }' )

		echo -n "PROCESSING: $_filename : TOTAL REG: $_compact_total"

		if [ "$_compact_dup" == "0" ]
		then
			echo -n " : NO DUPLICATES"
		else
			echo -n " : DUPLICATES: $_compact_dup" #techo "PROCESSING: $_filename : Total Reg: $_compact_total : Duplicate Reg: $_compact_dup"
			sort -u $_file | awk -F\; '$2 ~ "[0-9]" { print $0 }'  > $_cyclops_temp_path/$_filename.purge.dup.tmp
			[ "$?" == "0" ] && cp -p $_cyclops_temp_path/$_filename.purge.dup.tmp $_file
		fi

		_purge_bad_reg=$( awk -F\; 'BEGIN { _c=0 } $3 == "" { _c++ } END { print _c }' $_file )
		if [ "$_purge_bad_reg" == "0" ]
		then
			[ "$_sh_action" != "daemon" ] && echo -n " : NO BAD REGISTERS" 
		else
			echo -n " : BAD REGISTERS: $_purge_bad_reg : PROCESSING" 
			_purge_bad_reg=$( awk -F\; '$3 == "" { print $0 }' $_file )
			for _line in $( echo "${_purge_bad_reg}" )
			do
				_numjob=$( echo $_line | cut -d';' -f1 )
				sed -i "/^$_numjob;.*;;/d" $_file 2>/dev/null
				[ "$?" != "0" ] && echo -e "\n\t::BAD REGISTER CLEAN ERROR: LINE: ($_line)"
			done
		fi
	
		echo " : FINISH FILE"
		
	done

}


#### MAIN EXEC ####

export _sh_action

[ "$_cyclops_ha" == "ENABLED" ] && ha_check $_command

case "$_sh_action" in
	daemon)
		_process_tmp_file=$_cyclops_temp_path/$_par_dst".slurm.process.tmp"
		_par_date_end=$(   date -d @$_date_now +%Y-%m-%dT%H:%M:%S )

		echo "$( date +%s ) : STAT_SLURM_CFG_FILE: "$_stat_slurm_cfg_file >> $_mon_log_path/$_hostname.$_command_name.log

		#_sh_action="debug"

		for _line in $( cat $_stat_slurm_cfg_file  | grep -v "^\#" | sed '/^$/d' )
		do
			_par_xtr=$( echo $_line | cut -d';' -f2 )
			_par_src=$( echo $_line | cut -d';' -f3 )
			_par_dst=$( echo $_line | cut -d';' -f4 )
			
			_extract_tmp_file=$_cyclops_temp_path/$_par_dst".slurm.extract.tmp"

			_last_file=$( ls -1 $_stat_slurm_data_dir/$_par_dst/*.txt 2>/dev/null | tail -n 1 )
			if [ -z "$_last_file" ] 
			then
				_par_date_start=$( date +%Y )"-01-01" 
			else
				_par_date_start=$( awk -F\; 'BEGIN { _out="FAIL" } $1 ~ "^[0-9]+$" { _out=$1 } END { print _out }' $_last_file ) 
				if [ "$_par_date_start" != "FAIL" ] 
				then
					_par_date_start=$( date -d @$_par_date_start +%Y-%m-%dT%H:%M:%S )
				else
					[ -f "$_last_file" ] && rm $_last_file
					echo "$( date +%s ) : SLURM EXTRACT DATA, GET DATE: [FAIL]"  >> $_mon_log_path/$_hostname.$_command_name.log
					exit
				fi
			fi

			echo "$( date +%s ) : PROCESSING: $_par_xtr : $_par_src : $_par_dst : FROM: $_par_date_start END: $_par_date_end" >> $_mon_log_path/$_hostname.$_command_name.log
			
			main_action
			main_compact_data
	
		done

		echo "$( date +%s ) : FINISH" >> $_mon_log_path/$_hostname.$_command_name.log
	;;
	manual)
		_process_tmp_file=$_cyclops_temp_path/$_par_dst".slurm.process.tmp"
		_par_date_end=$(   date -d @$_date_now +%Y-%m-%dT%H:%M:%S )

		echo "$( date +%s ) : STAT_SLURM_CFG_FILE: $_stat_slurm_cfg_file : MANUAL MODE" >> $_mon_log_path/$_hostname.$_command_name.log

		#_sh_action="debug"

		for _line in $( cat $_stat_slurm_cfg_file  | grep -v "^\#" | sed '/^$/d' )
		do
			_par_xtr=$( echo $_line | cut -d';' -f2 )
			_par_src=$( echo $_line | cut -d';' -f3 )
			_par_dst=$( echo $_line | cut -d';' -f4 )
			
			_extract_tmp_file=$_cyclops_temp_path/$_par_dst".slurm.extract.tmp"

			_last_file=$( ls -1 $_stat_slurm_data_dir/$_par_dst/*.txt 2>/dev/null | tail -n 1 )
			if [ -z "$_last_file" ] 
			then
				_par_date_start=$( date +%Y )"-01-01" 
			else
				_par_date_start=$( tail -n 1 $_last_file | cut -d';' -f1 ) 
				_par_date_start=$( date -d @$_par_date_start +%Y-%m-%dT%H:%M:%S ) 
			fi

			echo "$( date +%s ) : PROCESSING: $_par_xtr : $_par_src : $_par_dst : FROM: $_par_date_start END: $_par_date_end" >> $_mon_log_path/$_hostname.$_command_name.log
			
			main_action
			main_compact_data
	
		done

		echo "$( date +%s ) : FINISH : MANUAL MODE" >> $_mon_log_path/$_hostname.$_command_name.log
	;;
	extractor)
		[ -z "$_par_date_start" ] && _par_date_start=$( date +%Y-%m-%d ) || _par_date_start=$( date -d $_par_date_start +%Y-%m-%d 2>/dev/null ; [ "$?" != "0" ] && echo FAIL )
		[ -z "$_par_date_end" ] && _par_date_end=$( date +%Y-%m-%dT%H:%M:%S ) || _par_date_end=$( date -d $_par_date_end"T23:59:59" +%Y-%m-%dT%H:%M:%S 2>/dev/null ; [ "$?" != "0" ] && echo FAIL )

		[ -z "$_par_xtr" ] && _par_xtr="main"
		[ -z "$_par_src" ] && echo "ERR: Need Source for get data, use -e help to see options" && exit 1 
		[ -z "$_par_dst" ] && _par_dst=$( cat $_stat_slurm_cfg_file | awk -F\; -v _src="$_par_src" -v _xtr="$_par_xtr" '$2 == _xtr && $3 == _src { print $4 }' ) 

		_extract_tmp_file=$_cyclops_temp_path/$_par_dst".slurm.extract.tmp"
		_process_tmp_file=$_cyclops_temp_path/$_par_dst".slurm.process.tmp"

		main_action

		_script_end=$( date +%s )
			
		let "_script_et=(_script_end-_script_start)/60"

		echo "Elapsed Time: "$_script_et" mins"
		echo "FINISH"

	;;
	compact)

		[ -z "$_par_dst" ] && echo "Need Destination Data, use -e help, to see options" && exit 1

		echo "COMPACTING SLURM DATA"
		
		main_compact_data
	;;
esac

