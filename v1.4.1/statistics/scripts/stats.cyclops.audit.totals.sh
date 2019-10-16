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

        _command_opts=$( echo "~$@~" | tr -d '~' | tr '@' '#' | sed 's/-\([0-9]*\)/~\1/g' | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^[a-z] / ) { gsub(/^[a-z] /,"&@",$i) ; gsub(/ $/,"",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' | tr '#' '@'  | tr '~' '-' )
        _command_name=$( basename "$0" )
        _command_dir=$( dirname "${BASH_SOURCE[0]}" )
        _command="$_command_dir/$_command_name $_command_opts"

        [ -f "/etc/cyclops/global.cfg" ] && source /etc/cyclops/global.cfg || _exit_code="111"

        [ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
        [ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
        [ -f "$_libs_path/node_ungroup.sh" ] && source $_libs_path/node_ungroup.sh || _exit_code="114"
        [ -f "$_libs_path/init_date.sh" ] && source $_libs_path/init_date.sh || _exit_code="115"
        [ -f "$_color_cfg_file" ] && source $_color_cfg_file || _exit_code="116"

        source $_color_cfg_file

        case "$_exit_code" in
        111)
                echo "Main Config file doesn't exists, please revise your cyclops installation"
                exit 1
        ;;
        112)
                echo "HA Control Script doesn't exists, please revise your cyclops installation"
                exit 1
        ;;
        11[3-5])
                echo "Necesary libs files doesn't exits, please revise your cyclops installation"
                exit 1
        ;;
        116)
                echo "WARNING: Color file doesn't exits, you see data in black"
        ;;
        esac

_stat_slurm_data=$( cat $_stat_main_cfg_file | awk -F\; '$2 == "slurm" { print $0 }' | head -n 1 )
_stat_slurm_cfg_file=$_config_path_sta"/"$( echo $_stat_slurm_data | cut -d';' -f3 )
_stat_slurm_data_dir=$_stat_data_path"/"$( echo $_stat_slurm_data | cut -d';' -f4 )

###########################################
#              PARAMETERs                 #
###########################################

_date_now=$( date +%s )
_par_grp="day"
_par_show="commas"

while getopts ":g:s:b:f:n:e:w:v:r:cxzh:" _optname
do
        case "$_optname" in
		"g")
			_opt_grp="yes"

			case "$OPTARG" in
			year|month|day|user|partition|state|debug)
				_par_grp=$OPTARG
			;;
			*)
				echo "ERR: bad option year/month/day"
				exit 1
			;;
			esac
		;;
		"e")
			# field event 
			_opt_eve="yes"
			_par_eve=$OPTARG
			case "$_par_eve" in
			issues)
				_par_eve="FAIL|DOWN|ISSUE"
				_graph_color=$( echo "$_color_down" | sed 's/:$//' )
			;;
			mngt)
				_par_eve="STATUS|INFO|ISSUE"
				_graph_color=$( echo "$_color_ok" | sed 's/:$//' )
			;;
			alerts)
				_par_eve="ALERT|FAIL|DOWN"
				_graph_color=$( echo "$_color_fail" | sed 's/:$//' )
			;;
			reactive)
				_par_eve="REACTIVE"
				_graph_color=$( echo "$_color_rzr" | sed 's/:$//' )
			;;
			*)
				_par_eve=$( echo $_par_eve | tr '[:lower:]' '[:upper:]' )
			;;
			esac
		;;
		"r")
			_opt_sts="yes"
			_par_sts=$OPTARG
		;;
		"n")
			# field node [ FACTORY NODE RANGE ] 
			_opt_nod="yes"
			_par_nod=$OPTARG

			if [ "$_par_nod" == "all" ]
			then
				_long=$( cat $_type | sed -e '/^#/d' -e '/^$/d' | cut -d';' -f2 )
			else
				#_name=$(   echo $_par_nod | cut -d'[' -f1 | sed 's/[0-9]*$//' )
				#_range=$(  echo $_par_nod | sed -e "s/$_name\[/{/" -e 's/\([0-9]*\)\-\([0-9]*\)/\{\1\.\.\2\}/g' -e 's/\]$/\}/' -e "s/$_name\([0-9]*\)/\1/"  )
				#_values=$( eval echo $_range | tr -d '{' | tr -d '}' )
				#_long=$(   echo "${_values}" | tr ' ' '\n' | sed "s/^/$_name/" )
				_long=$( node_ungroup $_par_nod | tr ' ' '\n' )

				#[ -z $_range ] && echo "Need nodename or range of nodes" && exit 1
			fi

			_total_nodes=$( echo "${_long}" | wc -l )

		;;
		"c")
			_opt_avg="yes"
		;;
                "f")
			# date end
                        _opt_date_end="yes"
                        _par_date_end=$OPTARG
                ;;
                "b")
			# date start
                        _opt_date_start="yes"
                        _par_date_start=$OPTARG
		;;
		"w")
			_opt_vwiki="yes"
			_par_vwiki=$OPTARG
			
			_opt_hidden=$( echo $_par_vwiki | tr ',' '\n' | awk '$0 ~ "hidden" { print "yes" }' )
			_opt_with=$( echo $_par_vwiki | tr ',' '\n' | grep "^W" | sed 's/W//' ) 
			_opt_gtype=$( echo $_par_vwiki | tr ',' '\n' | awk '$0 ~ "^T" { gsub("T","",$1) ; print $1 }' )  
		;;
		"v")
			# format output
			_opt_show="yes"
			_par_show=$OPTARG
		;;
		"s")
			# audit data source
			_opt_src="yes"
			_par_src=$OPTARG	
		;;
		"z")
			# DEBUG option
			_opt_debug="yes"
		;;
                "x")
                        _opt_hea="yes"
		;;
		"h")
			case "$OPTARG" in
			"des")
				echo "$( basename "$0" ) : Cyclops Command for Audit Module Statistics" 
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
				echo "CYCLOPS STATISTICS: CYC AUDIT MODULE"
				echo
				echo "FILTER FIELDS:"
                                echo "	-b [YYYY-MM-DD|[Jan~Dec]|[YYYY]] start date search, if no use this option, script use today one"
                                echo "		[YYYY-MM-DD]: standar start date"
                                echo "		[Jan~Dec]: Get all days from indicated month, let unused -f parameter"  
                                echo "		[YYYY]: Get all days from indicated year, let unused -f parameter"
				echo "	-f [YYYY-MM-DD] end date search, if no use this option, script use today one"
				echo "	-n [nodename] optional: filter data with a node"
				echo "	-s [bitacora|activity] optional: filter data type of audit" 
				echo "	-e [issues|mngt|alerts|[others]] optional: filter data type of event"
				echo "		issues: group of FAIL, DOWN, ISSUE, register type, that show incident"
				echo "		mngt: group of STATUS,INFO,ISSUE, register type, that show administrator task"
				echo "		alerts: group of ALERT, FAIL, DOWN, register type, that show system problems"
				echo "		[others]: you can specify other register type"
				echo "	-r [status], filter data status type"
				echo
				echo "STATS:"
				echo "	By default: Number of Cyc Audit Events"
				echo "	-c : Node Events Average"
				echo
				echo "GROUP:"
				echo "	-g [year|month|day|node|event] optional: group data show"	
				echo
				echo "SHOW:"
				echo "	-v [human|wiki|commas] optional, commas default."
				echo "		human, show command output human friendly"
				echo "		commas, show command output with ;"
				echo "		wiki, show command output with dokuwiki format"
				echo "		-w [hidden,W[0-9],[Tbar|Tline|Tpie]] : only with wiki output, use hidden plugin with graph"
				echo "			hidden: Generates hidden section"	
				echo "			W[0-9]: Defines wide size (recomended threshold 200~800"
				echo "			Tbar:	Bar graph"
				echo "			Tline:	Line graph"
				echo "			Tpie:	Pie graph"
				echo "	-x disable info head"
				echo
				echo "HELP:"
				echo "	-h [|des] help, this help"
				echo "		des: Detailed Command Help"
				echo
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

###########################################
#               FUNTIONs                  #
###########################################

calc_data()
{

        case "$_par_grp" in
	month)
                cat $_files | sort -n -t\; | awk -F\; -v _e="$_par_eve" -v _ds="$_par_ds" -v _de="$_par_de" -v _ov="$_opt_avg" -v _nn="$_total_nodes" -v _sts="$_par_sts" '
                BEGIN {
                        _doh=strftime("%Y-%m",_ds) ;
                        split(_doh,r,"-") ;
                        _dou=mktime( r[1]" "r[2]" 1 0 0 1" ) ;
                        _dly=r[1] ;
                        _dlm=r[2] ;
                        a=0 ;
                } 

                $1 >= _ds && $1 <= _de && $4 ~ _e && $6 ~ _sts { 
                        _dnh=strftime("%Y-%m",$1) ;
                        if ( _dnh == _doh ) {
                                a++
                        }
                        else { 
                                split(_dnh,g,"-") ;
                                if ( _dly == g[1] ) {
                                        _dff=int ( g[2] - _dlm ) ;
                                        if ( _dff > 1 ) {
						if ( _ov == "yes" ) { print _doh";"a/_nn } else { print _doh";"a  }
                                                for ( i=_dlm+1;i<g[2];i++ ) { _aux=mktime( g[1]" "i" 1 0 0 1" ) ; print strftime("%Y-%m",_aux)";0" } 
                                                _dlm=g[2] ;
                                        }
                                        else {
                                                if ( _ov == "yes" ) { print _doh";"a/_nn } else { print _doh";"a  }
                                                _dlm=g[2] ;
                                        }
                                        _dly=g[1] ;
                                }
                                else {
                                        if ( a > 0 ) { 
                                                if ( _ov == "yes" ) { print _doh";"a/_nn } else { print _doh";"a } 
                                                _dly=g[1] ;
                                                _dlm=g[2] ; }
                                        else {
                                                if ( _ov == "yes" ) { print _doh";"a/_nn } else { print _doh";"a } 
                                                for ( i=_dlm+1;i<=12;i++ ) { _aux=mktime( _dly" "i" 1 0 0 1" ) ; print strftime("%Y-%m",_aux)";0" }
                                                _dly=_dly+1 ;
                                                _dlm=1 ;
                                        }
                                }
                                a=1 ;
                                _doh=_dnh ;
                                split(_doh,r,"-") ;
                                _dou=mktime( r[1]" "r[2]" 1 0 0 1" )    
                        }
                }

                END {   
                        if ( _ov == "yes" ) { print _doh";"a/_nn } else { print _doh";"a }
                        split(_doh,l,"-") ;
                        _doe=strftime("%Y-%m",_de) ;
                        split(_doe,g,"-") ;
                        if ( l[1] == g[1] ) {
                                _dff=int ( g[2] - l[2] ) ;
                                if ( _dff >= 1 ) {
                                        for ( i=l[2]+1;i<=g[2];i++ ) { _aux=mktime( g[1]" "i" 1 0 0 1" ) ; print strftime("%Y-%m",_aux)";0" }
                                }
                        }       
                }'
	;;
        year)
                cat $_files | sort -n -t\; | awk -F\; -v _e="$_par_eve" -v _ds="$_par_ds" -v _de="$_par_de" '{ if ( $1 >= _ds && $1 <= _de && $4 ~ _e ) { _date=strftime("%Y",$1) ; print _date }}' | uniq -c  | awk '{ print $2";"$1 }'
        ;;
	day)
		#### INSERT EMPTY DAYS BETWEEN DAYS WITH DATA AND EMPTY THRESHOLD EXTREMS ####
	        cat $_files | sort -n -t\; | awk -F\; -v _e="$_par_eve" -v _ds="$_par_ds" -v _de="$_par_de" -v _ov="$_opt_avg" -v _nn="$_total_nodes" '
                BEGIN {
                        _doh=strftime("%Y-%m-%d",_ds)
                        split(_doh,r,"-")
                        _dou=mktime( r[1]" "r[2]" "r[3]" 0 0 1" )
                        a=0
                } 

                $1 >= _ds && $1 <= _de && $4 ~ _e { 
                        _dnh=strftime("%Y-%m-%d",$1) ;
                        if ( _dnh == _doh ) {
                                a++
                        }
                        else { 
                        if ( _ov == "yes" ) { print _doh";"a/_nn } else { print _doh";"a }
                        _dff=int ( ( $1 - _dou ) / 86400 ) ;
                        if ( _dff > 1 ) { for ( i=1;i<_dff;i++ ) { _aux=(_dou + ( 86400 * i )) ; print strftime("%Y-%m-%d",_aux)";0" }} 
                        a=1 ;
                        _doh=_dnh ;
                        split(_doh,r,"-") ;
                        _dou=mktime( r[1]" "r[2]" "r[3]" 0 0 1" )
                        }
                }

                END { 
			if ( _ov == "yes" ) { print _doh";"a/_nn } else { print _doh";"a }
			_dff=int ( ( _de - _dou ) / 86400 ) ;
			if ( _dff >= 1 ) { for ( i=1;i<=_dff;i++ ) { _aux=(_dou + ( 86400 * i )) ; print strftime("%Y-%m-%d",_aux)";0" }}
		}'
	;;
        event)
		echo "FACTORY: event group"
                #cat $_files | sort -n -t\; | awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '{ if ( $1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $NF ~ _c ) { print $3 }}' | sort | uniq -c  | awk '{ print $2";"$1 }'
        ;;
        node)
		echo "FACTORY: node group"
                #cat $_files | sort -n -t\; | awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '{ if ( $1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $NF ~ _c ) { print $4 }}' | sort | uniq -c  | awk '{ print $2";"$1 }'
        ;;
        esac
}

format_output()
{
	case "$_par_show" in
	commas)
		if [ "$_opt_hea" != "yes" ]
		then
			echo "source;$( [ -z "$_par_src" ] && echo -n bitacora,activity || echo -n $_par_src )"
			echo "date start;$_par_date_start"
			echo "date end;$_par_date_end"
			echo "average: $( [ "$_opt_avg" == "yes" ] && echo "$_total_nodes processed nodes" || echo "na" )"
		fi
		echo "${_output}"
	;;
	human)

		_filter="0"

		if [ "$_opt_hea" != "yes" ]
		then
			echo "SOURCE: $( [ -z "$_par_src" ] && echo -n bitacora,activity || echo -n $_par_src )"
			echo "DATE RANGE FROM $_par_date_start TO $_par_date_end"
			echo "TOTAL REGISTER PROCESSED: "$( cat $_files | wc -l )
			echo "ACTIVE FILTERS:"
			[ ! -z "$_par_eve" ] && echo " EVENTS: $_par_eve" && let "_filter++"
			[ "$_filter" == "0" ] && echo " NONE"
			[ ! -z "$_par_grp" ] && echo "GROUP BY: $_par_grp" && _title=$( echo $_par_grp | tr [:lower:] [:upper:] ) || _title="DAY" 
			echo
		fi
		echo -e "$_title;NUM REG\n--------;---------\n${_output}" | column -s\; -t ### DOT FOR MILES >> | sed -e ':a;s/\B[0-9]\{3\}\>/.&/;ta'
	;;
	wiki)
		_par_ys=$( echo $_par_date_start | cut -d'-' -f1 )
		_par_ms=$( echo $_par_date_start | cut -d'-' -f2 )
		_par_ds=$( echo $_par_date_start | cut -d'-' -f3 )
		
		_par_ye=$( echo $_par_date_end | cut -d'-' -f1 )
		_par_me=$( echo $_par_date_end | cut -d'-' -f2 )
		_par_de=$( echo $_par_date_end | cut -d'-' -f3 )

		[ "$_par_ys" == "$_par_ye" ] && [ "$_par_ms" == "$_par_me" ] && _title_date=$_par_ys" - "$( date -d $_par_ys-$_par_ms-01 +%B )
		[ "$_par_ys" == "$_par_ye" ] && [ "$_par_ms" != "$_par_me" ] && _title_date=$_par_ys" - "$( date -d $_par_ys-$_par_ms-01 +%B )" to "$( date -d $_par_ye-$_par_me-01 +%B )
		[ "$_par_ys" != "$_par_ye" ] && _title_date=$_par_date_start" to "$_par_date_end 

		### FACTORING: MAKE GRAPH GROUPING DATA ....

		
		[ -z "$_graph_color" ] && _graph_color=$( echo $_color_graph | sed -e 's/^@//' -e 's/\:$//' )
		[ -z "$_opt_with" ] && _opt_with="850"
		[ -z "$_opt_gtype" ] && [ "$_opt_gtype" != "bar" ] && [ "$_opt_gtype" != "line" ] && [ "$_opt_gtype" != "pie" ] && _opt_gtype="line"

		case "$_par_grp" in
		day)
			[ "$_opt_hidden" == "yes" ] && echo "<hidden $( [ -z "$_par_src" ] && echo -n bitacora,activity || echo -n $_par_src ) - $_title_date $( [ "$_opt_avg" == "yes" ] && echo -n "- Node Avg Events" ) >"
			echo "<gchart "$_opt_with"x350 $_opt_gtype $_graph_color #ffffff center>"
			echo "${_output}" | awk -F\; '{ split($1,a,"-") ; if ( a[2] != _old ) { print "M"a[2]"-"a[3]"="$2 ; _old=a[2] } else { print "D"a[3]"="$2 }}'
			echo "</gchart>"
			[ "$_opt_hidden" == "yes" ] && echo "</hidden>"
		;;
		month)
			[ "$_opt_hidden" == "yes" ] && echo "<hidden $( [ -z "$_par_src" ] && echo -n bitacora,activity || echo -n $_par_src ) - $_title_date $( [ "$_opt_avg" == "yes" ] && echo -n "- Node Avg Events" )>"
			echo "<gchart "$_opt_with"x350 $_opt_gtype $_graph_color #ffffff center>"
			echo "${_output}" | awk -F\; 'BEGIN { OFS="=" } { 
				split($1,a,"-") ; 
				_date=mktime( a[1]" "a[2]" 1 0 0 0" ) ; 
				if ( a[1] == _yo ) { 
					_month=strftime("%B",_date) 
					}
				else { 
					_month=strftime("%Y-%B",_date) ;
					_yo=a[1] ;
					} 
				print _month"="$2 }' 
			echo "</gchart>"
			[ "$_opt_hidden" == "yes" ] && echo "</hidden>"
		;;
		year)
			echo "<gchart "$_opt_with"x350 $_opt_gtype $_graph_color #ffffff center \"$( [ -z "$_par_src" ] && echo -n bitacora,activity || echo -n $_par_src )  - $_title_date\">"
			echo "${_output}" | sed -e 's/;/=/'
			echo "</gchart>"
		;; 
		#user|partition|state)
		#	echo "</hidden>"
		#	echo "<hidden $_par_src - $_title_date - $_par_grp - Top 10 >"
		#	echo "<gchart 700x350 bar #$_graph_color #ffffff center>"
		#	echo "${_output}" | sort -t\; -k2,1nr | head -n 10 | sed -e 's/;/=/' -e ':a;s/\B[0-9]\{3\}\>/.&/;ta'
		#	echo "</gchart>"
		#;;
		esac
	;;
	esac
}


debug()
{
	echo 
	echo "DEBUG:"
	echo "----------------"
	echo "Thrershold betwen:"
	echo "Start Data: $_par_date_start 00:00:00 ($_par_ds)"
	echo "End Data: $_par_date_end 23:59:59 ($_par_de)"
	echo "Base Dir: $_stat_slurm_data_dir/$_par_src"
	echo "Audit Type: $( [ -z "$_par_src" ] && echo -n all || echo -n $_par_src )"
	echo "Group: $_par_grp"
	echo "Filter events:$_par_eve"
	echo "Filter node:$_par_nod"
	echo "$_long"
	echo "Files:"
	echo "${_files}"
	echo "----------------"
	echo
}

###########################################
#               MAIN EXEC                 #
###########################################

	#### AVERAGE PRE-PROCESING ####

	[ "$_opt_avg" == "yes" ] && [ -z "$_total_nodes" ] && _total_nodes=$( cat $_type | sed -e '/^$/d' -e '/^#/d' | wc -l )

	#### DATE PROCESSING ####

	 _now_year=$( date +%Y )

	case "$_par_date_start" in
		Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
			_query_month=$( date -d '1 '$_par_date_start' '$_now_year +%m | sed 's/^0//' )
			let "_next_month=_query_month+1"
			[ "$_next_month" == "13" ] && let "_next_year=_now_year+1" && _next_month="1" || _next_year=$_now_year
			_last_day=$( date -d $_next_year'-'$_next_month'-1' +%s)
			let "_last_day=_last_day-10"
			_par_date_start=$( date -d '1 '$_par_date_start' '$_now_year +%Y-%m-%d )
			_par_date_end=$( date -d @$_last_day +%Y-%m-%d )
		;;
		2[0-9][0-9][0-9])
			## COOKIE: Stephen Hawkings told us that humanity dissapear in One thousand years if we will not go out of earth... cyclops only control de next one thousand years.
			[ "$_now_year" == "$_par_date_start" ] && _par_date_end=$( date +%Y-%m-%d ) || _par_date_end=$_par_date_start"-12-31"
			[ "$_par_date_start" -gt "$_now_year" ] && echo "Your are funny, maybe you want that we use tarot to get statatistics of the future?" && exit 1
			_par_date_start=$_par_date_start"-01-01"
		;;
		"")
			_par_date_start=$( date +%Y-%m-%d )
		;;
	esac

	[ -z "$_par_date_end" ] && _par_date_end=$( date +%Y-%m-%d )

	[ "$_par_date_start" == "FAIL" ] || [ "$_par_date_end" == "FAIL" ] && echo "ERR: wrong data format" && exit 1 

	_par_ds=$( date -d $_par_date_start +%Y-%-m )	
	_par_ds=$( date -d $_par_ds"-01 00:00:00" +%s )
	_par_de=$( date -d $_par_date_end" 23:59:59" +%s  )
	
	let "_hour_days=((_par_de-_par_ds)/86400)+1"

	#### FILE PROCESSING ####

	if [ -z "$_par_nod" ]
	then
		_files=$( cat $_type | sed '/^$/d' | grep -v \# | awk -F\; -v _s="$_par_src" -v _p="$_audit_data_path" '{ _a=_p"/"$2".activity.txt" ; _b=_p"/"$2".bitacora.txt" }  _s != "bitacora" && system("[ -f " _a " ]") == "0" { print _a } _s != "activity" && system("[ -f " _b " ]") == "0" { print _b }' ) 
	else
		_files=$( echo "${_long}" | awk -F\; -v _s="$_par_src" -v _p="$_audit_data_path" '{ _a=_p"/"$1".activity.txt" ; _b=_p"/"$1".bitacora.txt" }  _s != "bitacora" && system("[ -f " _a " ]") == "0" { print _a } _s != "activity" && system("[ -f " _b " ]") == "0" { print _b }' ) 
		[ -z "$_files" ] && echo "ERR: Not files matches with selected nodes" && exit 1
	fi

	[ "$_opt_debug" == "yes" ] && debug

	_par_ds=$( date -d "$_par_date_start 00:00:00" +%s )
	_output=$( calc_data )

	format_output

