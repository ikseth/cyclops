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

_config_path="/etc/cyclops"

if [ -f $_config_path/global.cfg ]
then
        source $_config_path/global.cfg
        [ -f "$_color_cfg_file" ] && source $_color_cfg_file

        [ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
        if [ -f "$_libs_path/node_ungroup.sh" ] 
	then
		source $_libs_path/node_ungroup.sh
		export -f node_ungroup
	else
		_exit_code="114"
	fi
        [ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="116"
	[ -f "$_color_cfg_file" ] && source $_color_cfg_file || _exit_code="1117"
        [ -f "$_libs_path/init_date.sh" ] && source $_libs_path/init_date.sh || _exit_code="118"
else
        echo "Global config don't exits" 
        exit 1
fi

        _command_opts=$( echo "~$@~" | tr -d '~' | tr '@' '#' | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^[a-z] / ) { gsub(/^[a-z] /,"&@",$i) ; gsub(/ $/,"",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' | tr '#' '@'  | tr '~' '-' )
        _command_name=$( basename "$0" )
        _command_dir=$( dirname "${BASH_SOURCE[0]}" )
        _command="$_command_dir/$_command_name $_command_opts"

        case "$_exit_code" in
        111)
                echo "Main Config file doesn't exists, please revise your cyclops installation"
                exit $_exit_code
        ;;
        112)
                echo "HA Control Script doesn't exists, please revise your cyclops installation"
                exit $_exit_code
        ;;
        11[3-4])
                echo "Necesary libs files doesn't exits, please revise your cyclops installation"
                exit $_exit_code
        ;;
	117)
		echo "WARNING: Color file doesn't exits, you see data in black&white" >&2
	;;
        esac

_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

_stat_slurm_data=$( cat $_stat_main_cfg_file | awk -F\; '$2 == "slurm" { print $0 }' | head -n 1 )
_stat_slurm_cfg_file=$_config_path_sta"/"$( echo $_stat_slurm_data | cut -d';' -f3 )
_stat_slurm_data_dir=$_stat_data_path"/"$( echo $_stat_slurm_data | cut -d';' -f4 )

#### DEFAULT OPTIONS ####

_par_date_start="day"
_par_date_shw="human"
_par_date_end=$( date +%Y-%m-%d ) 
_par_date_time=$( date +%H:%M:%S )

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":r:d:e:t:f:n:g:v:t:w:k:s:u:xlh:" _optname
do
        case "$_optname" in
                "n")
                        # field node [ FACTORY NODE RANGE ] 
                        _opt_nod="yes"
                        _par_nod=$OPTARG
                        _sh_opt=$_sh_opt" -"$_optname" "$OPTARG
		;;
		"d")
			_opt_date_start="yes"
			_par_date_start=$OPTARG
		;;
		"e")
			_opt_date_end="yes"
			_par_date_end=$OPTARG
		;;
		"j")
			_opt_job="yes"
			_par_job=$OPTARG
		;;
		"m")
			_opt_nam="yes"
			_par_nam=$OPTARG
		;;
		"f")
			_opt_fil="yes"
			_par_fil=$OPTARG
		;;
		"s")
			_opt_src="yes"
			_par_src=$OPTARG
		;;
		"g")
			_opt_grp="yes"
			_par_grp=$OPTARG
		;;
		"v")
			_opt_shw="yes"
			_par_shw=$OPTARG
		;;
		"t")
			_opt_top="yes"
			_par_top=$OPTARG
			_par_shw="timeline"
		;;
		"u")
			_opt_fusr="yes"
			_par_fusr=$OPTARG
		;;
		"h")
		        _opt_help="yes"
                        _par_help=$OPTARG

			case "$_par_help" in
			"des")
				echo "$( basename "$0" ) : Cyclops Slurm Job Activity Tool"
				echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "  Global config path : $_config_path"
				echo "  	Global config file: global.cfg"
				echo "  	Cyclops dependencies:"
				echo "  		Cyclops libs: $_libs_path"
				echo "				node_ungroup.sh"	
				echo "				node_group.sh"	
				echo "				init_date.sh"	
				echo "				ha_ctrl.sh"
				echo "				$_color_cfg_file"	
				echo "		Data source dir:"
				echo "			$_stat_slurm_data_dir"
				echo
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
				echo "CYCLOPS STATISTICS: CYC SLURM DATA ACCESS"
				echo
				echo "MAIN:"
				echo
				echo "	-s [slurm cluster source], name of data source"
				echo
				echo "FILTER:"
				echo "	-n [nodename|node range], by node or node range" 
				echo "	-j [slurm num job], by slurm number job"
				echo "	-m [slurm job name], by slurm job name" 
				echo "	-u [slurn user], by user name"
                                echo "	-d [date format], start date or range to filter by date:"
                                echo "          [YYYY]: ask for complete year"
                                echo "          [Mmm-YYYY]: ask for concrete month"
                                echo "          [1-9*]year: ask for last [n] year"
                                echo "          [1-9*]month: ask for last [n] month"
                                echo "          week: ask for last week"
                                echo "          [1-9*]day: ask for last [n] days ( sort by 24h format )"
                                echo "          [1-9*]hour: ask for last [n] hours ( sort by hour format )"
                                echo "          [YYYY-MM-DD]T[HH:MM:SS]: Implies data from date to now if you dont use -e, optional start time can be added"
                                echo "	-e [YYYY-MM-DD]T[HH:MM:SS], end date for concrete start date, optional end time can be added" 
                                echo "          mandatory use the same format with -d parameter"
				echo "SHOW:"
				echo
				echo "	-f [field1,field2,field3,...], output selected fields"
                                echo "	-v [graph|human|wiki|commas] optional, commas default."
                                echo "          graph, show console graph, only for percent processing sensors"
                                echo "          human, show command output human friendly"
                                echo "          commas, show command output with ;"	
                                echo "          timeline, show output like job timeline use -g for threshold time"	
				echo "			-g [seconds]: by defaul 5 seconds."
				echo "			-t [[name],[job],[user]] optional, implies -v timeline. comma separated for show two or more values"
				echo "				job, by default, show job id"
				echo "				name, show job name"
				echo "				user, show user name"
				echo
				exit 0
                        else
                                echo "ERR: Use -h for help"
                                exit 0
			fi
		;;
                "*")
                        echo "ERR: Use -h for help"
                        exit 0
                ;;
        esac
done

shift $((OPTIND-1))

###########################################
#               FUNTIONs                  #
###########################################

search_jobs()
{

	echo "${_main_data}" | sort -n | awk -F\; -v _tsdatei="$_date_tse" -v _tsdatef="$_date_tsb" -v _onod="$_opt_nod" -v _pnod="$_par_unode" -v _pusr="$_par_fusr" '
		BEGIN { 
			split(_pnod,nodos," ")
		} { 
			_ts=strftime("%F;%T",$1) ; 
			gsub(/:/," ",$13) ; 
			_tsplus=mktime( "1970 01 01 "$13 ) ; 
			_tsrange=$1+_tsplus  
		} (( $1 < _tsdatei && _tsrange > _tsdatef ) || ( $1 < _tsdatef && _tsrange > _tsdatef ) || ( $1 > _tsdatei && _tsrange < _tsdatef )) && $3 ~ _pusr  { 
			if ( _onod == "yes" ) { 
				split($16,nidos," ")
				for ( i in nodos ) { for ( a in nidos ) { if ( nodos[i] == nidos[a] ) { job[$2]=_ts";"$2";"$14";"$3";"$5";"$13";"$15 } } }  
			} else {
				job[$2]=_ts";"$2";"$14";"$3";"$5";"$13";"$15 
			}
		} END {
			for ( i in job ) { print job[i] }
		}' 
}

format_output_data()
{
	case "$_par_shw" in
	human)
		echo -e "Date;Time;Job ID;Status;user;Job Name;Elapsed Time;Node(s)\n----;----;------;------;----;--------;------------;-------\n${1}" | column -t -s\;
	;;
	commas)
		echo -e "Date;Time;Job ID;Status;user;Job Name;Elapsed Time;Node(s)\n${1}"
	;;
	timeline)
		[ -z "$_par_grp" ] && _par_grp=5
		echo
		echo "${1}" | awk -F\; -v _dti="$_date_tsb" -v _dte="$_date_tse" -v _onam="$_par_top" -v _gtl="$_par_grp" -v _cy="$_sh_color_yellow" -v _cg="$_sh_color_green" -v _cr="$_sh_color_red" -v _cn="$_sh_color_nformat" '
			$1 ~ "[0-9]+" { 
				_d=$1 ; 
				_t=$2 ; 
				gsub(/-/," ",_d) ; 
				gsub(/:/," ",_t) ; 
				_tsi=mktime( _d" "_t ) ; 
				_tsd=mktime( "1970 01 01 "$7 ) ; 
				_tse=_tsi+_tsd ; 
				job[$3]=_tsi","_tse ;
				jobdet[$3]=$4";"$5";"$6";"$7 ;
				name[$3]=$6 ; 
				split(_onam,fil,",") ;
			} END { 
				for (i=_dti;i<=_dte;i+=_gtl) { 
					_y++ ; _xt=0 ; _idxv=0 ;
					nomy[_y]=i ;
					for ( a in job ) {                 
						split(job[a],ts,",") ; 
						if (( i < ts[1] && i+_gtl > ts[2] ) || ( i < ts[2] && i+_gtl > ts[2] ) || ( i > ts[1] && i+_gtl < ts[2] )) { 
							_xt++ ;
							if ( posx[a] == "" ) { 
								if ( vacio[_xt] == "" ) {
									posx[a]=_xt ; 
									pos[_y,_xt]=a ;
									vacio[_xt]=a ;
									_idxv++ ; 
								} else {
									for (v=1;v<=_idxv;v++) { 
										if ( vacio[v] == "" ) {
											posx[a]=v ;
											pos[_t,v]=a ;
											vacio[v]=a ;
											_idxv++ ;
											break ;
										}
									}
								}
							} else {
								pos[_y,posx[a]]=a ;
								vacio[posx[a]]=a ;
								_idxv++ ;
							}
						} else {
							vacio[posx[a]]="" ;
							posx[a]="" ;
							_idxv=_idxv-1 ;                    
						}
					} ;
					if ( _x <= _xt ) { _x=_xt } ;
				} ;
				for (_dy=1;_dy<=_y;_dy++) {
					_line="" ;
					for (_dx=1;_dx<=_x;_dx++) {
						if ( pos[_dy,_dx] == "" ) { 
							_fprt=" " 
							_cfs=_cg ; _nfs=_cn
						} else {
							split(jobdet[pos[_dy,_dx]],jfields,";") ; 
							_cfs="" ; _nfs=""
							if ( jfields[1] == "COMPLETED" ) { _cfs=_cg ; _nfs=_cn } 
							if ( jfields[1] == "FAILED" ) { _cfs=_cr ; _nfs=_cn }
							if ( jfields[1] == "CANCELLED" ) { _cfs=_cy ; _nfs=_cn }
							_fprt="" ; _fl=0
							if ( _onam == "" ) {
								_fprt="["pos[_dy,_dx]"]" ;
								_fl=10 ;
							} else { 
								_fprt="["
								for ( _ifil in fil ) { 
									if ( fil[_ifil] == "user" ) { _fprt=_fprt""sprintf("%8.8s", jfields[2])"|"   ; _fl=_fl+9  }
									if ( fil[_ifil] == "name" ) { _fprt=_fprt""sprintf("%10.10s", jfields[3])"|" ; _fl=_fl+9 }
									if ( fil[_ifil] == "job" ) {  _fprt=_fprt""sprintf("%8.8s", pos[_dy,_dx])"|";_fl=_fl+9 }
								}	
								gsub(/\|$/,"",_fprt) ;
								_fprt=_fprt"]" ; _fl=_fl+3 ;
							}
							if ( _onam == "user" ) { _fprt=jfields[2] } 
							if ( _onam == "name" ) { _fprt=jfields[3] }
						};
						_line=_line" "sprintf("%s%"_fl"-s%s", _cfs, _fprt, _nfs) ;
					}
					print ""strftime("%F %T",nomy[_dy])" "_line ;
				}
			}'
		echo
	;;
	*)
		echo -e "Date;Time;Job ID;Status;user;Job Name;Elapsed Time;Node(s)\n${1}" | column -t -s\;
	;;
	esac
}

node_filter_active()
{
	awk -F\; -v _tsdatei="$_date_tse" -v _tsdatef="$_date_tsb" '
		BEGIN { 
			OFS=";" 
		} {
			_ts=strftime("%FT%T",$1) ; 
                        gsub(/:/," ",$13) ; 
                        _tsplus=mktime( "1970 01 01 "$13 ) ; 
                        _tsrange=$1+_tsplus
		} ( $1 < _tsdatei && _tsrange > _tsdatef ) || ( $1 < _tsdatef && _tsrange > _tsdatef ) || ( $1 > _tsdatei && _tsrange < _tsdatef ) { 
			printf $0";" ; system("node_ungroup "$NF)  ; print "" 
		}' $1
}

debug()
{
        echo
        echo "DEBUG:"
        set | grep "^_"
        echo "-----"
}

###########################################
#               MAIN EXEC                 #
###########################################


	## DATE INIT

	init_date $_par_date_start $_par_date_end

	## DATA FILES SELECTION

	_files=$( ls -1 $_stat_slurm_data_dir/$_par_src/*.txt | awk -F\/ -v _ds="$_date_tsb" -v _de="$_date_tse" '
	{
		split ($NF,a,".") ;
		if ( a[2] != "12" ) {
			_next_m=a[2]+1 ;
			_next_date=mktime(" "a[1]" "_next_m" 1 0 0 0" ) ;
			_last_day=_next_date-3600 ;
			_last_day=strftime("%d",_last_day) ;
		} else {
			_last_day="31" ;
		}
		_date_e=mktime(" "a[1]" "a[2]" "_last_day" 23 59 59") ;
		_date_s=mktime(" "a[1]" "a[2]" 1 0 0 0") ;
		if ( ( _ds <= _date_s && _de >= _date_s ) || ( _ds <= _date_e && _de >= _date_e ) || ( _ds >= _date_s && _de <= _date_e )) { file[$NF]=$0 }  
	} END {
		for ( i in file ) { print file[i] } 
	}' ) 

	[ -z "$_files" ] && echo "NO FILES FINDED [$_par_src][$( date -d @$_date_tsb)][$( date -d @$_date_tse)]" && exit 1

	## PROCESSING

	[ "$_opt_nod" == "yes" ] && _par_unode=$( node_ungroup $_par_nod )

	for _file in $( echo "${_files}" )
	do
		if [ "$_opt_nod" == "yes" ] 
		then
			_main_data=$_main_data""$( node_filter_active $_file )
		else 
			_main_data=$_main_data""$( cat $_file )
		fi
	done

	_data_output=$( search_jobs )

	## FORMATING

	format_output_data "${_data_output}"

exit 0
