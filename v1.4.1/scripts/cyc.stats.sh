#!/bin/bash

### FIRTS CYCLOPS FUNCTION LIBRARY #### 2016-11-03
### NODE GRUPING - GIVE LIST OF NODES COMMA SEPARATED

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
#                  VARs                   #
###########################################

################# GLOBAL ##################

IFS="
"

_config_path="/etc/cyclops"


if [ -f $_config_path/global.cfg ]
then
        source $_config_path/global.cfg
        source $_color_cfg_file
	source $_config_path_sys/wiki.cfg
else
        echo "Global config don't exits" 
        exit 1
fi


_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

################# LOCAL ###################

_command_opts=$( echo "$@" | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^m/ ) { gsub(/^[a-z] /,"&@",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' )
_command_name=$( basename "$0" )
_command_dir=$( dirname "${BASH_SOURCE[0]}" )
_command="$_command_dir/$_command_name $_command_opts"

################# LIBS ####################

[ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
[ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
[ -f "$_libs_path/node_ungroup.sh" ] && source $_libs_path/node_ungroup.sh || _exit_code="114"

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":t:n:v:b:f:xi:d:rkh:" _optname
do
        case "$_optname" in
                "t")
			# Type Option
                        _opt_typ="yes"
			_par_typ=$OPTARG
			
			export _sh_action=$_par_type	

                ;;
		"n")
                        # field node [ FACTORY NODE RANGE ] 
                        _opt_nod="yes"
                        _par_nod=$OPTARG
				
			if [ "$_par_nod" != "all" ]
			then
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

				_long=$( node_ungroup $_par_nod | tr ' ' '\n' )
				_total_nodes=$( echo "${_long}" | wc -l )
			fi

		;;
		"b")
			# Begin Date Option
			_opt_beg="yes"
			_par_beg=$OPTARG

		;;
		"f")
			# End Date Option
			_opt_end="yes"
			_par_end=$OPTARG
		;;
		"v")
			# Show Format Option
			_opt_shw="yes"
			_par_shw=$OPTARG
		;;
		"x")
			# Debug Option
			_opt_dbg="yes"
		;;
		"i")
			# Index Name Option
			_opt_idx="yes"
			_par_idx=$OPTARG
		;;
		"k")
			# Enable Link Option
			_opt_lnk="yes"
		;;
		"r")
			# Enable Recursive Option
			_opt_rcr="yes"
		;;
		"d")
			# Description Option
			_opt_des="yes"
			_par_des=$OPTARG
		;;
                "h")
			# Help Option
                        case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops System Global Generator Statistics" 
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
                                echo "CYCLOPS STATISTICS: CYC AUDIT MODULE"
                                echo
				echo "-t [global] Type of Cyclops Statistics"
				echo "	cyclops: global report statistics"
				echo "	slurm: report statistics from this source"
				echo "	users: [NOT YET IMPLEMENTED]"
				echo "	index: Regenerate report index web page"
				echo "	daemon: scheduled stats defined in cfg file:"
				echo "		$_stat_daemon_cfg_file"
				echo
                                echo "FILTER FIELDS:"
                                echo "-b [YYYY-MM-DD|[Jan~Dec-YYYY]|[YYYY]] start date search, if no use this option, script use today one"
                                echo "	[YYYY-MM-DD]: common start date"
                                echo "	[Jan~Dec-YYYY]: Get all days from indicated month, let unused -f parameter"  
                                echo "	[YYYY]: Get all days from indicated year, let unused -f parameter"
                                echo "-f [YYYY-MM-DD] end date search, if no use this option, script use today one"
                                echo "-n [nodename] optional: (only cyclops type)filter data with a node"
                                echo
				echo "INCLUDES:"
				echo "-k add links to each audit node report for your report"
				echo "-r Recurse report, creating sub-report from families and groups existing in your master report" 
				echo
                                echo "SHOW:"
				echo "-i [string]: name for stat report, don't use spaces or special characters"
				echo "-d '[string]': use quotes if you use spaces, include a descriptive field"
                                echo
                                echo "HELP:"
                                echo "-h [|des] help, this help"
                                echo "	des: Detailed Command Help"
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
#               FUNCTIONs                 #
###########################################

############# LOCAL FUNCT #################

calc_date_title_day()
{
                _date_title_str=$( echo "" | awk -v _df="$_date_count" -v _tsb="$_date_tsb" -v _tse="$_date_tse" '
                        BEGIN { 
                                _daycalc=_tsb ; 
                                } 
                        { 
                                for ( i=1 ; i<=_df ;i++ ) {
                                        _day=strftime("%d",_daycalc) ;
                                        _month=strftime("%m",_daycalc) ;
                                        _year=strftime("%Y",_daycalc)
                                        if ( _old_year < _year ) { 
                                                _year_s=_year"-" ;
                                                _old_year=_year ;
                                                } else {
                                                _year_s="" ;
                                                }
                                        if ( _old_month < _month ) {
                                                _month_s=_month"-" ;
                                                _old_month=_month ;
                                                } else {
                                                _month_s="" ;
                                                }
                                        _daycalc=_daycalc+86400 ;
                                        _string=_string";"_year_s""_month_s""_day ;
                          
                                        } 
                                }
                        END {
                                print _string
                        }' )
}

calc_date_title_month()
{

		_date_title_str=$( echo "" | awk -v _df="$_date_count" -v _tsb="$_date_tsb" -v _tse="$_date_tse" '
                        BEGIN { 
                                _monthts=_tsb ; 
                                _monthcalc=strftime("%m",_monthts)
                                } 
                        { 
                                for ( i=1 ; i<=_df ;i++ ) {
                                        _month=strftime("%m",_monthts) ;
                                        _year=strftime("%Y",_monthts)
                                        if ( _old_year < _year ) { 
                                                _year_s=_year"-" ;
                                                _old_year=_year ;
                                                } else {
                                                _year_s="" ;
                                                }
                                        _monthcalc=_monthcalc+1 ;
                                        _monthts=mktime( _old_year" "_monthcalc" 1 0 0 1")
                                        if ( _monthcalc == 13 ) { _monthcalc=1 }
                                        _string=_string";"_year_s""_month ;
                                        } 
                                }
                        END {
                                print _string
                        }' )

}

cyclops_global_calc()
{
	#### GRAPH STATS ####

	_cyc_eve_global_g=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v wiki -g $_date_filter -n $_par_nod -c )
	_cyc_mng_global_g=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v wiki -g $_date_filter -n $_par_nod -c -e mngt -w Tbar )
	_cyc_ale_global_g=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v wiki -g $_date_filter -n $_par_nod -c -e alerts )
	_cyc_iss_global_g=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v wiki -g $_date_filter -n $_par_nod -e issues )
	_cyc_rea_global_g=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v wiki -g $_date_filter -n $_par_nod -c -e reactive )

	_cyc_ava_global_g=$( $_stat_extr_path/stats.cyclops.logs.sh -n dashboard -r OPER_ENV -d $_date_start -e $_date_end -v wiki -t per -w hidden,Tbar,value 2>/dev/null )
	_cyc_usr_global_g=$( $_stat_extr_path/stats.cyclops.logs.sh -n dashboard -r USR_LGN -d $_date_start -e $_date_end -v wiki -t max -w hidden,Tline,value 2>/dev/null )
	_cyc_cpu_global_g=$( $_stat_extr_path/stats.cyclops.logs.sh -n dashboard -r NOD_LOAD -d $_date_start -e $_date_end -v wiki -t per -w hidden,Tline,value 2>/dev/null )

	#### TREND CALC ####

	_cyc_eve_global_trend=$( echo "${_cyc_eve_global_g}" | awk -F\= '$0 ~ "=" { 
			x++ ; 
			ex+=x ; 
			ey+=$2 ; 
			xy+=x*$2 ; 
			x2e+=x*x ; 
			y2e+=$2*$2 
		} 
		END { 
			a0=( ey * x2e - ex * xy )/( x * x2e - (ex * ex )) ; 
			a1=( x  * xy - ex * ey )/(x * x2e  - ( ex * ex )) ; 
			pro=a0+a1*(x+1) ; 
			print pro";"a0";"a1 
		}' )
	_cyc_mng_global_trend=$( echo "${_cyc_mng_global_g}" | awk -F\= '$0 ~ "=" { 
			x++ ; 
			ex+=x ; 
			ey+=$2 ; 
			xy+=x*$2 ; 
			x2e+=x*x ; 
			y2e+=$2*$2 
		} 
		END { 
			a0=( ey * x2e - ex * xy )/( x * x2e - (ex * ex )) ; 
			a1=( x  * xy - ex * ey )/(x * x2e  - ( ex * ex )) ; 
			pro=a0+a1*(x+1) ; 
			print pro";"a0";"a1 
		}' )
	_cyc_ale_global_trend=$( echo "${_cyc_ale_global_g}" | awk -F\= '$0 ~ "=" { 
			x++ ; 
			ex+=x ; 
			ey+=$2 ; 
			xy+=x*$2 ; 
			x2e+=x*x ; 
			y2e+=$2*$2 
		} 
		END { 
			a0=( ey * x2e - ex * xy )/( x * x2e - (ex * ex )) ; 
			a1=( x  * xy - ex * ey )/(x * x2e  - ( ex * ex )) ; 
			pro=a0+a1*(x+1) ; 
			print pro";"a0";"a1 
		}' )
	_cyc_iss_global_trend=$( echo "${_cyc_iss_global_g}" | awk -F\= '$0 ~ "=" { 
			x++ ; 
			ex+=x ; 
			ey+=$2 ; 
			xy+=x*$2 ; 
			x2e+=x*x ; 
			y2e+=$2*$2 
		} 
		END { 
			a0=( ey * x2e - ex * xy )/( x * x2e - (ex * ex )) ; 
			a1=( x  * xy - ex * ey )/(x * x2e  - ( ex * ex )) ; 
			pro=a0+a1*(x+1) ; 
			print pro";"a0";"a1 
		}' )
	_cyc_rea_global_trend=$( echo "${_cyc_rea_global_g}" | awk -F\= '$0 ~ "=" { 
			x++ ; 
			ex+=x ; 
			ey+=$2 ; 
			xy+=x*$2 ; 
			x2e+=x*x ; 
			y2e+=$2*$2 
		} 
		END { 
			a0=( ey * x2e - ex * xy )/( x * x2e - (ex * ex )) ; 
			a1=( x  * xy - ex * ey )/(x * x2e  - ( ex * ex )) ; 
			pro=a0+a1*(x+1) ; 
			print pro";"a0";"a1 
		}' )

	
	#### TABLE DATA STATS ####

	_cyc_eve_global_t=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_par_nod -c | 
		awk -F\; 'NR > 4 && $0 != "END OF FILE" { printf "%s;%.3f\n",$1, $2 }' | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$/\n/' ) 
	_cyc_mng_global_t=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_par_nod -c -e mngt | 
		awk -F\; 'NR > 4 && $0 != "END OF FILE" { printf "%s;%.3f\n",$1, $2 }' | sort -t\; -n | cut -d';' -f2 | tr '\n' ';' ) 
	_cyc_ale_global_t=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_par_nod -c -e alerts | 
		awk -F\; 'NR > 4 && $0 != "END OF FILE" { printf "%s;%.3f\n",$1, $2 }' | sort -t\; -n | cut -d';' -f2 | tr '\n' ';' ) 
	_cyc_iss_global_t=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_par_nod -e issues | 
		awk -F\; 'NR > 4 && $0 != "END OF FILE" { print $0 }' | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$/\n/' ) 
	_cyc_rea_global_t=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_par_nod -c -e reactive | 
		awk -F\; 'NR > 4 && $0 != "END OF FILE" { print $0 }' | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$/\n/' ) 

	_cyc_global_table="Management;"$_cyc_mng_global_t"\nAlert;"$_cyc_ale_global_t"\nRazor;"$_cyc_rea_global_t";"
	_cyc_global_mark=$( echo -e "${_cyc_global_table}" | sed -e 's/;$//' | cut -d';' -f2- | awk -F\; '
		BEGIN { 
			OFS=";" 
			} { 
			for ( i=1 ; i<=NF ; i++ ) { 
				if ( m[i] <= $i ) { 
					m[i]=$i ; 
					p[i]=NR 
					}
				}
			} 
		END { 
			print "" ; 
			for ( a in p ) { print a"."p[a] }
			}' | 
		sort -n | cut -d'.' -f2 | tr '\n' '.'  )

	#### RISK ANALISYS ####

	_cyc_wdy_global_r=$( $_script_path/audit.nod.sh -v commas -f activity -n $_par_nod | awk -F\;  -v _dts="$_date_tsb" -v _dte="$_date_tse" '
			{ 
			split($1,rd,"-") ; 
			split($2,rh,":") ; 
			_regts=mktime( rd[1]" "rd[2]" "rd[3]" "rh[1]" "rh[2]" "rh[3] ) 
			}
		_regts > _dts && _regts < _dte && $5 == "ALERT" { 
			split($1,d,"-") ; 
			_ts=mktime( d[1]" "d[2]" "d[3]" 0 0 1" ) ; 
			_nday=strftime("%u",_ts) ; 
			_dday=strftime("%a",_ts) ; 
			a[_nday";"_dday]++ ; 
			_t++ 
			} 
		END { 
			for( i in a ) { print i";"(a[i]*100)/_t }
			}' | 
		sort -n | cut -d';' -f2- )
	_cyc_mdy_global_r=$( $_script_path/audit.nod.sh -v commas -f activity -n $_par_nod | awk -F\;  -v _dts="$_date_tsb" -v _dte="$_date_tse" '
                        { 
                        split($1,rd,"-") ; 
                        split($2,rh,":") ; 
                        _regts=mktime( rd[1]" "rd[2]" "rd[3]" "rh[1]" "rh[2]" "rh[3] ) 
                        }
		_regts > _dts && _regts < _dte && $5 == "ALERT" { 
			split($1,h,"-") ; 
			a[h[3]]++ ; 
			_t++ 
			} 
		END { 
			for( i in a ) { print i";"(a[i]*100)/_t }
			}' | 
		sort -n )
	_cyc_hou_global_r=$( $_script_path/audit.nod.sh -v commas -f activity -n $_par_nod | awk -F\;  -v _dts="$_date_tsb" -v _dte="$_date_tse" '
                        { 
                        split($1,rd,"-") ; 
                        split($2,rh,":") ; 
                        _regts=mktime( rd[1]" "rd[2]" "rd[3]" "rh[1]" "rh[2]" "rh[3] ) 
                        }
		_regts > _dts && _regts < _dte && $5 == "ALERT" {
			 split($2,h,":") ; 
			a[h[1]]++ ; 
			_t++ 
			} 
		END { for( i in a ) { print i";"(a[i]*100)/_t }
			}' | 
		sort -n )
	_cyc_nod_global_r=$( $_script_path/audit.nod.sh -v commas -f activity -n $_par_nod | awk -F\;  -v _dts="$_date_tsb" -v _dte="$_date_tse" '
                        { 
                        split($1,rd,"-") ; 
                        split($2,rh,":") ; 
                        _regts=mktime( rd[1]" "rd[2]" "rd[3]" "rh[1]" "rh[2]" "rh[3] ) 
                        }
		_regts > _dts && _regts < _dte && $5 == "ALERT" { 
			a[$1";"$4]++ 
			} 
		END { for( i in a ) { print i";"a[i] }
			}' | 
		awk -F\; '{ 
			sum[$2]+=$3 ; 
			sumsq[$2]+=$3*$3 ; 
			lin[$2]++ 
			} 
		END { 
			for ( i in sum ) { 
				_mda+=sqrt(sumsq[i]/lin[i] - (sum[i]/lin[i])*(sum[i]/lin[i])) ; 
				_mdt++ 
				} ; 
			_md=_mda/_mdt; 
			for ( i in sum ) { 
				_des=sqrt(sumsq[i]/lin[i] - (sum[i]/lin[i])*(sum[i]/lin[i])) ; 
				if ( _des >  _md ) { print i";"_des } 
				}
			}' | 
		sort -t\; -k2,2nr )
	_cyc_sen_global_r=$( $_script_path/audit.nod.sh -v commas -f activity -n $_par_nod | awk -F\; -v _dts="$_date_tsb" -v _dte="$_date_tse" '
                        { 
                        split($1,rd,"-") ; 
                        split($2,rh,":") ; 
                        _regts=mktime( rd[1]" "rd[2]" "rd[3]" "rh[1]" "rh[2]" "rh[3] ) 
                        }
		_regts > _dts && _regts < _dte && $5 == "ALERT" { 
			a[$1";"$6]++ 
			} 
		END { 
			for( i in a ) { print i";"a[i] }
			}' | 
		awk -F\; '{ 
			sum[$2]+=$3 ; 
			sumsq[$2]+=$3*$3 ; 
			lin[$2]++ 
			} 
		END { 
			for ( i in sum ) { print i";"sqrt(sumsq[i]/lin[i] - (sum[i]/lin[i])*(sum[i]/lin[i])) }
			}' | 
		sort -t\; -k2,2nr )

	#### EVENTS PROCESSING ####

	_cyc_nodes_bitacora_global_e=$( $_script_path/audit.nod.sh -f bitacora -v eventlog -n $_par_nod )
	_cyc_main_bitacora_global_e=$(  $_script_path/audit.nod.sh -f main -v eventlog -n $_par_nod )

	_cyc_bitacora_global_e=$_cyc_nodes_bitacora_global_e"\n"$_cyc_main_bitacora_global_e
	_cyc_bitacora_global_e=$( echo -e "${_cyc_bitacora_global_e}" | sort -t\; -k1,1n | awk -F\; -v _dts="$_date_tsb" -v _dte="$_date_tse" '
		{ 
			if ( $4 ~ /ALERT|FAIL|INTERVENTION|TESTING|UPGRADE|REPAIR/ ) { $4="<fc orange>"$4"</fc>" } ;
			if ( $4 ~ /INFO|ENABLE|OK|STATUS/ ) { $4="<fc green>"$4"</fc>" } ;
			if ( $4 ~ /ISSUE|DISABLE|DRAIN|DOWN/ ) { $4="<fc red>"$4"</fc>" } ;
		}
		$1 > _dts && $1 < _dte { 
			_date=strftime("%Y-%m-%d",$1) ; 
			split(_date,d,"-") ; 
			_hour=strftime("%H:%M:%S",$1) ; 
			if ( d[1] == _yo ) { 
				if ( d[2] == _mo ) { 
					if ( d[3] == _do ) { 
						if ( $3 == "main" ) { print "    * ** "_hour" ** - "$4" - ** "$3" ** - "$5 } else { print "    * //"_hour" - "$4" - "$3" - "$5"//" } ;
						}
					else { 
						print "  * ** "strftime("%d - %A",$1)" ** " ;
						if ( $3 == "main" ) { print "    * ** "_hour" ** - "$4" - ** "$3" ** - "$5 } else { print "    * //"_hour" - "$4" - "$3" - "$5"//" } ;
						_do=d[3] ;
						}
					}
				else {
					print "=== "strftime("%B",$1 )" ===" ;
					print "  * ** "strftime("%d - %A",$1)" ** " ;
					if ( $3 == "main" ) { print "    * ** "_hour" ** - "$4" - ** "$3" ** - "$5 } else { print "    * //"_hour" - "$4" - "$3" - "$5"//" } ;
					_mo=d[2] ;
					_do=d[3] ;
					}
				}
			else {
				print "==== "strftime("%Y",$1 )" ====" ;
				print "=== "strftime("%B",$1 )" ===" ;
				print "  * ** "strftime("%d - %A",$1)" **" ;
				if ( $3 == "main" ) { print "    * ** "_hour" ** - "$4" - ** "$3" ** - "$5 } else { print "    * //"_hour" - "$4" - "$3" - "$5"//" } ;
				_yo=d[1] ;
				_mo=d[2] ;
				_do=d[3] ;
			}
		}'
		)
				

}

cyclops_concrete_calc()
{

	unset _cyc_eve_conc_t
	unset _cyc_mng_conc_t
	unset _cyc_ale_conc_t
	unset _cyc_iss_conc_t
	unset _cyc_rea_conc_t

	for _host_bubble_c in $( echo "${1}" ) 
	do
		_bubble_name=$( echo $_host_bubble_c | cut -d';' -f1 )
		_host_list_c=$( echo $_host_bubble_c | cut -d';' -f2 )
		_host_range_c=$( node_group $_host_list_c )

		_cyc_eve_conc_l=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_host_range_c -c | 
			awk -F\; 'NR > 4 && $0 != "END OF FILE" { printf "%s;%.3f\n",$1, $2 }' | sort -t\; -n | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$//' )
		_cyc_mng_conc_l=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_host_range_c -c -e mngt | 
			awk -F\; 'NR > 4 && $0 != "END OF FILE" { printf "%s;%.3f\n",$1, $2 }' | sort -t\; -n | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$//' )
		_cyc_ale_conc_l=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_host_range_c -c -e alerts | 
			awk -F\; 'NR > 4 && $0 != "END OF FILE" { printf "%s;%.3f\n",$1, $2 }' | sort -t\; -n | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$//' )
		_cyc_iss_conc_l=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_host_range_c -e issues | 
			awk -F\; 'NR > 4 && $0 != "END OF FILE" { print $0 }' | sort -t\; -n | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$//' )
		_cyc_rea_conc_l=$( $_stat_extr_path/stats.cyclops.audit.totals.sh -b $_date_start -f $_date_end -v commas -g $_date_filter -n $_host_range_c -c -e reactive | 
			awk -F\; 'NR > 4 && $0 != "END OF FILE" { print $0 }' | sort -t\; -n | cut -d';' -f2 | tr '\n' ';' | sed -e 's/;$//' )

		_cyc_eve_conc_t=$_cyc_eve_conc_t""$_bubble_name";"$_cyc_eve_conc_l"\n"
		_cyc_mng_conc_t=$_cyc_mng_conc_t""$_bubble_name";"$_cyc_mng_conc_l"\n"
		_cyc_ale_conc_t=$_cyc_ale_conc_t""$_bubble_name";"$_cyc_ale_conc_l"\n"
		_cyc_iss_conc_t=$_cyc_iss_conc_t""$_bubble_name";"$_cyc_iss_conc_l"\n"
		_cyc_rea_conc_t=$_cyc_rea_conc_t""$_bubble_name";"$_cyc_rea_conc_l"\n"
	done

	_cyc_eve_conc_t=$( echo -e "$_cyc_eve_conc_t" | sed '/^$/d' )
	_cyc_mng_conc_t=$( echo -e "$_cyc_mng_conc_t" | sed '/^$/d' )
	_cyc_ale_conc_t=$( echo -e "$_cyc_ale_conc_t" | sed '/^$/d' )
	_cyc_iss_conc_t=$( echo -e "$_cyc_iss_conc_t" | sed '/^$/d' )
	_cyc_rea_conc_t=$( echo -e "$_cyc_rea_conc_t" | sed '/^$/d' )

	_cyc_eve_mark=$( echo -e "${_cyc_eve_conc_t}" | sed -e 's/;$//' | cut -d';' -f2- | awk -F\; '
		BEGIN { 
			OFS=";" 
		} { 
			for ( i=1 ; i<=NF ; i++ ) { 
			if ( m[i] <= $i ) { 
				m[i]=$i ; 
				p[i]=NR 
				}
			}
		} 
		END { 
			print "" ; 
			for ( a in p ) { print a"."p[a] }
		}' | 
		sort -n | cut -d'.' -f2 | tr '\n' '.'  )

	_cyc_mng_mark=$( echo -e "${_cyc_mng_conc_t}" | sed -e 's/;$//' | cut -d';' -f2- | awk -F\; '
		BEGIN { 
			OFS=";" 
		} { 
			for ( i=1 ; i<=NF ; i++ ) { 
			if ( m[i] <= $i ) { 
				m[i]=$i ; 
				p[i]=NR 
				}
			}
		} 
		END { 
			print "" ; 
			for ( a in p ) { print a"."p[a] }
		}' | 
		sort -n | cut -d'.' -f2 | tr '\n' '.'  )

	_cyc_ale_mark=$( echo -e "${_cyc_ale_conc_t}" | sed -e 's/;$//' | cut -d';' -f2- | awk -F\; '
		BEGIN { 
			OFS=";" 
		} { 
			for ( i=1 ; i<=NF ; i++ ) { 
			if ( m[i] <= $i ) { 
				m[i]=$i ; 
				p[i]=NR 
				}
			}
		} 
		END { 
			print "" ; 
			for ( a in p ) { print a"."p[a] }
		}' | 
		sort -n | cut -d'.' -f2 | tr '\n' '.'  )

	_cyc_iss_mark=$( echo -e "${_cyc_iss_conc_t}" | sed -e 's/;$//' | cut -d';' -f2- | awk -F\; '
		BEGIN { 
			OFS=";" 
		} { 
			for ( i=1 ; i<=NF ; i++ ) { 
			if ( m[i] <= $i ) { 
				m[i]=$i ; 
				p[i]=NR 
				}
			}
		} 
		END { 
			print "" ; 
			for ( a in p ) { print a"."p[a] }
		}' | 
		sort -n | cut -d'.' -f2 | tr '\n' '.'  )

	_cyc_rea_mark=$( echo -e "${_cyc_rea_conc_t}" | sed -e 's/;$//' | cut -d';' -f2- | awk -F\; '
		BEGIN { 
			OFS=";" 
		} { 
			for ( i=1 ; i<=NF ; i++ ) { 
			if ( m[i] <= $i ) { 
				m[i]=$i ; 
				p[i]=NR 
				}
			}
		} 
		END { 
			print "" ; 
			for ( a in p ) { print a"."p[a] }
		}' | 
		sort -n | cut -d'.' -f2 | tr '\n' '.'  )

}

cyclops_global_print()
{

	echo

	echo "====== CYCLOPS GLOBAL STATS ($_date_title) ======"
	echo
	echo "===== MAIN DATA ====="
	echo "<tabbox Report Summary>"
	echo "  * ** Created: ** $( date +%Y-%m-%d\ %H:%M:%S )"
	echo "  * ** Date Threshold: ** $_date_title //( $_date_start to $_date_end )//"
	echo "  * ** System Threshold: ** $_node_title"
	echo "  * ** Group included: ** $( echo "${_group_list}" | cut -d';' -f1 | tr '\n' ',' | sed -e 's/,/, /g' -e 's/, $//' )"
	echo "  * ** Families included: ** $( echo "${_family_list}" | cut -d';' -f1 | tr '\n' ',' | sed -e 's/,/, /g' -e 's/, $//' )"
	echo 
	echo "  * ** Short Description: ** "$_par_des
	echo "<tabbox System Status>"
	echo "  * ** System Availability: ** Node/Host Availability Percent"
	echo "  * ** System CPU Average: ** Average with all cpu use in the system" 
	echo "  * ** User Activity: ** Max User Conected to the system" 
	echo 
	echo "|< 100% >|" 
	echo "|  $_color_header  Availibility  ||"
	echo "|  ${_cyc_ava_global_g}  ||"
	echo "|  $_color_header CPU Average  |  $_color_header  User Activity  |"
	echo "|  ${_cyc_cpu_global_g}  |  ${_cyc_usr_global_g}  |"
	if [ "$_opt_lnk" == "yes" ]
	then
		echo "<tabbox Node List>"
		echo
		echo "* ** Audit Node Detailed Info: **If node has had an alert event in last $_check_days days it is mark" 
        	echo 
        	echo "|< 100% 10% 10% 10% 10% 10% 10% 10% 10% 10% 10% >|"
        	echo -e "$_host_wiki_group"
	fi
	echo "</tabbox>"
	echo
	echo "===== GLOBAL AUDIT CHARTS ====="	
        echo "<tabbox Total Events >"
	echo "|< 100% >|"
	echo "|  $_color_header $_date_title |"
	echo "|  ${_cyc_eve_global_g}  |"
	echo "<tabbox Management Activity >"
	echo "|< 100% >|"
	echo "|  $_color_header $_date_title |"
	echo "|  ${_cyc_mng_global_g}  |"
	echo "<tabbox Alerts >"
	echo "|< 100% >|"
	echo "|  $_color_header $_date_title |"
	echo "|  ${_cyc_ale_global_g}  |"
	echo "<tabbox Incidents >"
	echo "|< 100% >|"
	echo "|  $_color_header $_date_title |"
	echo "|  ${_cyc_iss_global_g}  |"
	echo "<tabbox Razor Actions >"
	echo "|< 100% >|"
	echo "|  $_color_header $_date_title |"
	echo "|  ${_cyc_rea_global_g}  |"
	echo "</tabbox>"
	echo

	echo "===== RISK ANALISYS ====="
        echo "  * This information are little gauge and trend to knows resources or moments with more or less risk in the system could be in troubles"
        echo
        echo "<tabbox Trend>"
	echo
	echo "  * Trend are calculated to predict next month events, and mark if is trend is positive ( <fc red> red </fc> ) or negative ( <fc green> green </fc> )" 
	echo 
	echo "|< 40% >|"
	echo "|  $_color_title ** Future Events -> next month from finish date of report **  |||"
	echo "|  $_color_header ** Type **      |  $_color_header ** Events Num/per node **  |  $_color_header  ** Trend **  |" 
	echo "|  ** Total **          |  $( echo $_cyc_eve_global_trend | awk -F\; '{ if ( $3 > 0 ) { print "<fc red> "$1" </fc>  |  <fc red> ** INCREASE ** </fc>  |" } else { print "<fc green> "$1" </fc>  |  <fc green> ** DECREASE ** </fc>  |" }}' )" 
	echo "|  ** Management **     |  $( echo $_cyc_mng_global_trend | awk -F\; '{ if ( $3 > 0 ) { print "<fc red> "$1" </fc>  |  <fc red> ** INCREASE ** </fc>  |" } else { print "<fc green> "$1" </fc>  |  <fc green> ** DECREASE ** </fc>  |" }}' )" 
	echo "|  ** Alert Events **   |  $( echo $_cyc_ale_global_trend | awk -F\; '{ if ( $3 > 0 ) { print "<fc red> "$1" </fc>  |  <fc red> ** INCREASE ** </fc>  |" } else { print "<fc green> "$1" </fc>  |  <fc green> ** DECREASE ** </fc>  |" }}' )" 
	echo "|  ** Issue Events **   |  $( echo $_cyc_iss_global_trend | awk -F\; '{ if ( $3 > 0 ) { print "<fc red> "$1" </fc>  |  <fc red> ** INCREASE ** </fc>  |" } else { print "<fc green> "$1" </fc>  |  <fc green> ** DECREASE ** </fc>  |" }}' )" 
	echo "|  ** Razor Actions **  |  $( echo $_cyc_rea_global_trend | awk -F\; '{ if ( $3 > 0 ) { print "<fc red> "$1" </fc>  |  <fc red> ** INCREASE ** </fc>  |" } else { print "<fc green> "$1" </fc>  |  <fc green> ** DECREASE ** </fc>  |" }}' )" 
	echo "<tabbox Month Gauge>"
        echo "|< 100% >|"
        echo "|  $_color_header ** RISK ANALISYS CYC GAUGEs - $_date_title **  |"
        echo "|  <gchart 850x350 bar #0040FF #ffffff center>" ; echo "${_cyc_mdy_global_r}" | sed 's/;/=/' ; echo "</gchart>  |"
	echo "<tabbox Week Day Gauge>" 
	echo "|< 100% >|"
        echo "|  $_color_header WEEK DAY (%)  |" 
        echo "|  <gchart 700x350 bar #F7BE81 #ffffff center>" ; echo "${_cyc_wdy_global_r}"  | sed 's/;/=/' ; echo "</gchart>  |"
	echo "<tabbox Hour Gauge>" 
	echo "|< 100% >|"
	echo "|  $_color_header HOUR (%)  |"
	echo "|  <gchart 700x350 bar #FA5856 #ffffff center>" ; echo "${_cyc_hou_global_r}" | sed 's/;/=/' ; echo "</gchart>  |"
	echo "<tabbox Node Gauge>"
	echo "|< 100% >|"
        echo "|  $_color_header TOP RISK NODES (STANDARD DEVIATION (SD) - ONLY TOP 20 AVERAGE DEVIATION NODES)  |" 
        echo "|  <gchart 700x350 hbar #FA5858 #ffffff value center>" ; echo "${_cyc_nod_global_r}" | sed 's/;/=/' | head -n 30 ; echo "</gchart>  |"
	echo "<tabbox Sensors Gauge>"
	echo "|< 100% >|"
	echo "|  $_color_header TOP RISK SENSORS (STANDARD DEVIATION)  |"
	echo "|  <gchart 700x350 hbar #F7BE81 #ffffff value center>" ; echo "${_cyc_sen_global_r}" | sed 's/;/=/' ; echo "</gchart>  |"
        echo "</tabbox>"
	echo

	echo "===== DATA INFO ====="
        echo
	echo "  * Total of cyclops events, this data are node referenced for comparative purpuoses"
	echo
	echo "==== Global ===="
	echo
        echo "|< 100% 8%>|"
	echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|"
	echo $_date_title_str | sed -e "s/^/|  $_color_title/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"  
	echo "<fc white> Total Events </fc>;"$_cyc_eve_global_t | sed -e "s/^/|  $_color_graph/" -e 's/$/  |/' -e "s/;/  |  /g"
	echo
        echo "  * All event data are referenciated per node, for comparative reasons betwen different groups"
	echo "  * This data are grouped for differents types of registers and, could be shared register with other group like issues" 
        echo
        echo "|< 100% 8%>|"
	echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|"
	echo $_date_title_str | sed -e "s/^/|  $_color_title/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"  
        echo -e "${_cyc_global_table}" | awk -F\; -v _c="$_color_header" -v _ia="$_cyc_global_mark" -v _cm="$_color_red" '
		BEGIN { 
			OFS="  |  " ; 
			split(_ia,x,".") 
			} 
		{ 
			$1=_c" ** "$1" **" ; 
			for ( i=2 ; i<=NF ; i++ ) { 
				if ( x[i] == NR && $i != "0.000" ) { $i=_cm" ** "$i" ** " }
				} ; 
			print "|  "$0 
			}'
	echo
	echo "  * This events are not node referenced, because most of them are manual inserted when an //incident// is detected"
	echo
        echo "|< 100% 8%>|"
	echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|" 
	echo $_date_title_str | sed -e "s/^/|  $_color_title/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"  
	echo "<fc white> Issues </fc>;"$_cyc_iss_global_t | sed -e "s/^/|  $_color_down/" -e 's/$/  |/' -e "s/;/  |  /g"

	#### DATA DETAIL PRINT ####

	echo
	echo "==== Sort by Group ===="
	echo
	echo "${_output_group}"
	echo
	echo "==== Sort by Family ===="
	echo
	echo "${_output_family}"
	echo

	#### DATA DETAIL PRINT ####

	echo	

	echo "===== MAIN BITACORA REPORT ($_date_title) ====="
	echo
	echo "  * All registered events by human or by human triger"
	echo
	echo "${_cyc_bitacora_global_e}"
	echo
}

cyclops_data_detail_print()
{
	echo "<tabbox All Events >"
        echo
        echo "  * All event data are referenciated per node, for comparative reasons betwen different groups"
        echo
        echo "|< 100% 15%>|"
	echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|"
	echo $_date_title_str | sed -e "s/^/|  $_color_graph <fc white> ALL EVENTs <\/fc>/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        echo -e "${_cyc_eve_conc_t}" | awk -F\; -v _r="$_opt_rcr" -v _s="$_par_idx" -v _c="$_color_header" -v _ia="$_cyc_eve_mark" -v _cm="$_color_graph" '
		BEGIN { 
			OFS="  |  " ; 
			split(_ia,x,".") 
			} 
		{ 
			if ( _r == "yes" ) {
				$1=_c" ** [[.:"_s"_"$1"|"$1"]] **" ;
			}
			else {
				$1=_c" ** "$1" ** " ;
			}
			for ( i=2 ; i<=NF ; i++ ) { 
				if ( x[i] == NR && $i != "0.000" ) { $i=_cm" <fc white>"$i"</fc>" }
				} ; 
			print "|  "$0"  |" 
			}' | sort 

        echo "<tabbox Management Activity >"
        echo
        echo "  * This events are register when human activity is detected"
        echo "  * This information is referenciated per node, for compartive reasons"
        echo
        echo "|< 100% 15% >|"
	echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|"
	echo $_date_title_str | sed -e "s/^/|  $_color_ok MNGT EVENTs /" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        echo -e "${_cyc_mng_conc_t}" | awk -F\; -v _r="$_opt_rcr" -v _s="$_par_idx" -v _c="$_color_header" -v _ia="$_cyc_mng_mark" -v _cm="$_color_ok" '
		BEGIN { 
			OFS="  |  " ; 
			split(_ia,x,".") 
			} 
		{ 
			if ( _r == "yes" ) {
				$1=_c" ** [[.:"_s"_"$1"|"$1"]] **" ;
			}
			else {
				$1=_c" ** "$1" ** " ;
			}
			for ( i=2 ; i<=NF ; i++ ) { 
				if ( x[i] == NR  && $i != "0.000" ) { $i=_cm" "$i }
				} ; 
			print "|  "$0"  |" 
			}' | sort 

        echo "<tabbox Alerts >"
        echo
        echo "  * This data are generated when cyclops detect alert in a sensor or administrator register a manual alert"
        echo "  * This information is referenciated per node, for compartive reason"
        echo
        echo "|< 100% 15% >|"
        echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|"
        echo $_date_title_str | sed -e "s/^/|  $_color_fail ALERT EVENTs /" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        echo -e "${_cyc_ale_conc_t}" | awk -F\; -v _r="$_opt_rcr" -v _s="$_par_idx" -v _c="$_color_header" -v _ia="$_cyc_ale_mark" -v _cm="$_color_fail" '
		BEGIN { 
			OFS="  |  " ; 
			split(_ia,x,".") 
			} 
		{ 
			if ( _r == "yes" ) {
				$1=_c" ** [[.:"_s"_"$1"|"$1"]] **" ;
			}
			else {
				$1=_c" ** "$1" ** " ;
			}
			for ( i=2 ; i<=NF ; i++ ) { 
				if ( x[i] == NR && $i != "0.000" ) { $i=_cm" "$i }
				} ; 
			print "|  "$0"  |" 
			}' | sort 

        echo "<tabbox Issues >"
        echo
        echo "  * This data are filter for issue cyclops register type (commonly manual register)"
        echo "  * Show the relevants incidents in the system" 
        echo "  * This information ** NOT ** referenciated per node"
        echo
        echo "|< 100% 15% >|"
        echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|"
        echo $_date_title_str | sed -e "s/^/|  $_color_down <fc white> ISSUE EVENTs <\/fc>/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        echo -e "${_cyc_iss_conc_t}" | awk -F\; -v _r="$_opt_rcr" -v _s="$_par_idx" -v _c="$_color_header" -v _ia="$_cyc_iss_mark" -v _cm="$_color_down" '
		BEGIN { 
			OFS="  |  " ; 
			split(_ia,x,".") 
			} 
		{ 
			if ( _r == "yes" ) {
				$1=_c" ** [[.:"_s"_"$1"|"$1"]] **" ;
			}
			else {
				$1=_c" ** "$1" ** " ;
			}
			for ( i=2 ; i<=NF ; i++ ) { 
				if ( x[i] == NR && $i != "0" ) { $i=_cm" <fc white>"$i"</fc>" }
				} ; 
			print "|  "$0"  |" 
			}' | sort 

        echo "<tabbox Razor Actions >"
        echo
        echo "  * This data are filter for Reactive and Razor cyclops module register type"
        echo "  * Show the automatic actions by cyclops modules" 
        echo
        echo "|< 100% 15% >|"
        echo "|  $_color_title ** $_date_title **  "$( echo $_date_title_str | grep -o ";" | tr -d '\n' | sed -e s'/;/|/g' )"|"
        echo $_date_title_str | sed -e "s/^/|  $_color_rzr <fc white> RAZOR ACTIONs <\/fc>/" -e 's/$/  |/' -e "s/;/  |  $_color_header/g"
        echo -e "${_cyc_rea_conc_t}" | awk -F\; -v _r="$_opt_rcr" -v _s="$_par_idx" -v _c="$_color_header" -v _ia="$_cyc_rea_mark" -v _cm="$_color_rzr" '
		BEGIN { 
			OFS="  |  " ; 
			split(_ia,x,".") 
			} 
		{ 
			if ( _r == "yes" ) {
				$1=_c" ** [[.:"_s"_"$1"|"$1"]] **" ;
			}
			else {
				$1=_c" ** "$1" ** " ;
			}
			for ( i=2 ; i<=NF ; i++ ) { 
				if ( x[i] == NR && $i != "0.000" ) { $i=_cm" "$i }
				} ; 
			print "|  "$0"  |" 
			}' | sort 
        echo "</tabbox>"
}

users_global_calc()
{
	echo "FACTORING"
}

users_concrete_calc()
{
	echo "FACTORING"
}

users_global_print()
{
	echo "FACTORING"
}

users_concrete_print()
{
	echo "FACTORING"
}

slurm_init()
{
	_slurm_cfg_env=$( cat $_stat_main_cfg_file | awk -F\; '$1 == "0001" && $2 == "slurm" { print $3 }' ) 
	_slurm_usr_cty="10"
	_slurm_part_cty="10"
	_slurm_date_creation=$( date +%Y-%m-%d\ %H:%M:%S )
	[ -z "$_par_des" ] && _par_des="user don't specific any description"

}

slurm_main()
{
	_slm_cyc_graph_g=$( $_stat_extr_path/stats.cyclops.logs.sh -n dashboard -r SLURM_LOAD -d $_date_start -e $_date_end -v wiki -t per -w W850 2>/dev/null ) 
	_slm_global_output=$( slurm_global_print )

	for _slurm_env_def in $( cat $_config_path_sta/$_slurm_cfg_env | awk -F\; '$1 ~ "[0-9]+" { print $0 }')
	do
		_slurm_src=$( echo $_slurm_env_def | cut -d';' -f4 )

		echo "REPORT: ($_par_typ) Launch $_slurm_src Environment Report "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" )
		echo "REPORT: ($_par_typ) Launch $_slurm_src Graphs Generation "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" )

		slurm_graphs_env

		echo "REPORT: ($_par_typ) Launch $_slurm_src Output Build "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" )

		_slm_global_output=$_slm_global_output"\n"$( slurm_print_env )
	done 
}

slurm_graphs_env()
{
	_slm_main_graph_g=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g $_date_filter -v wiki ) 
	_slm_user_graph_g=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g user -v wiki )
	_slm_part_graph_g=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g partition -v wiki )
	_slm_stat_graph_g=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g state -v wiki )

	_slm_part_list=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g partition -v commas -x | cut -d';' -f1 | head -n $_slurm_part_cty )
	unset _slm_part_output

	for _slm_part_c in $( echo "${_slm_part_list}" ) 
	do
		echo "REPORT: ($_par_typ) Launch $_slurm_src - $_slm_part_c Detailed Report "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" ) 

		_slm_part_graph_c=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g $_date_filter -p $_slm_part_c -v wiki ) 
		_slm_part_stat_graph_c=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g state -p $_slm_part_c -v wiki ) 
		_slm_part_usrs_graph_c=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g user -p $_slm_part_c -v wiki ) 
		_slm_part_format_output=$( slurm_print_part )
		_slm_part_output=$_slm_part_output"\n"$_slm_part_format_output
	done

	_slm_usr_list=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g user -v commas -x | cut -d';' -f1 | head -n $_slurm_usr_cty )
	unset _slm_usr_output

	for _slm_usr_c in $( echo "${_slm_usr_list}" ) 
	do
		echo "REPORT: ($_par_typ) Launch $_slurm_src - $_slm_usr_c Detailed Report "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" )

		_slm_usr_graph_c=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g $_date_filter -u $_slm_usr_c -v wiki ) 
		_slm_usr_stat_graph_c=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g state -u $_slm_usr_c -v wiki ) 
		_slm_usr_part_graph_c=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g partition -u $_slm_usr_c -v wiki ) 
		_slm_usr_format_output=$( slurm_print_usr )
		_slm_usr_output=$_slm_usr_output"\n"$_slm_usr_format_output
	done
}

slurm_global_print()
{
	echo "====== SLURM GLOBAL STATS ======"
	echo
	echo "<tabbox Report Summary>"
	echo 
	echo "  * ** Created: ** $_slurm_date_creation"  
	echo "  * ** Date Threshold: ** $_date_start to $_date_end"
	echo "  * ** Environment(s) Included: ** $( cat $_config_path_sta/$_slurm_cfg_env | awk -F\; '$1 ~ "[0-9]+" { print $4 }' | tr '\n' ',' | sed 's/,$//' )"
	echo 
	echo "  * ** Short Description: ** $_par_des"
	echo "<tabbox Slurm Activity>"
	echo "${_slm_cyc_graph_g}" 
	echo "</tabbox>"
}

slurm_print_env()
{
	_slm_data_resume=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g $_date_filter -v commas | awk -F\; '
		{ 
			_jobs+=$2 ; 
			_nodes+=$5 ; 
			_et+=$6 
		} END { 
			print "Jobs Submited;"_jobs"\nNodes Reserved;"_nodes"\nConsumed Time;"_et 
		}' )

	echo "===== $( echo $_slurm_src | tr [:lower:] [:upper:] ) SOURCE ====="
	echo
	echo "==== SUMMARY ===="
	echo
	echo "|< 30% 15% 15% >|"
	echo "|  $_color_title ** Environment Data Resume **  ||"
	echo "${_slm_data_resume}" | sed -e "s/^/|  $_color_header /" -e 's/;/  |  /' -e 's/$/  |/' 
	echo
	echo "<tabbox General Data>"
	echo "${_slm_main_graph_g}"
	echo "<tabbox Partition Data>"
	echo "${_slm_part_graph_g}"
	echo "<tabbox Users Data>"
	echo "${_slm_user_graph_g}"
	echo "<tabbox Job State Data>"
	echo "${_slm_stat_graph_g}"
	echo "<tabbox Top $_slurm_part_cty Partitions detail charts>"
	echo -e "${_slm_part_output}" 
	echo "<tabbox Top $_slurm_usr_cty Users detail charts>"
	echo -e "${_slm_usr_output}"
	echo "</tabbox>"
	
}

slurm_print_part()
{
	_slm_part_data_resume=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g $_date_filter -p $_slm_part_c -v commas | awk -F\; '
		{ 
			_jobs+=$2 ; 
			_nodes+=$5 ; 
			_et+=$6 
		} END { 
			print "Jobs Submited;"_jobs"\nNodes Reserved;"_nodes"\nConsumed Time;"_et 
		}' )
	echo
	echo "<hidden $_slm_part_c>"
	echo
	echo "|< 30% 15% 15% >|"
	echo "|  $_color_title User Resume Data  ||"
	echo "${_slm_part_data_resume}" | sed -e "s/^/|  $_color_header /" -e 's/;/  |  /' -e 's/$/  |/' 
	echo
	echo "<hidden -- Jobs General Info>"
	echo "${_slm_part_graph_c}"
	echo "</hidden>"
	echo
	echo "<hidden -- User Info>"
	echo "${_slm_part_usrs_graph_c}"
	echo "</hidden>"
	echo 
	echo "<hidden -- State Graph Info>" 
	echo "${_slm_part_stat_graph_c}"
	echo "</hidden>"
	echo
	echo "</hidden>"
}

slurm_print_usr()
{
	_slm_usr_data_resume=$( $_stat_extr_path/stats.slurm.total.jobs.sh -s $_slurm_src -b $_date_start -f $_date_end -g $_date_filter -u $_slm_usr_c -v commas | awk -F\; '
		{ 
			_jobs+=$2 ; 
			_nodes+=$5 ; 
			_et+=$6 
		} END { 
			print "Jobs Submited;"_jobs"\nNodes Reserved;"_nodes"\nConsumed Time;"_et 
		}' )

	echo
	echo "<hidden $_slm_usr_c>"
	echo "|< 30% 15% 15% >|"
	echo "|  $_color_title User Resume Data  ||"
	echo "${_slm_usr_data_resume}" | sed -e "s/^/|  $_color_header /" -e 's/;/  |  /' -e 's/$/  |/' 
	echo
	echo "<hidden -- Jobs General Info>"
	echo "${_slm_usr_graph_c}"
	echo "</hidden>"
	echo
	echo "<hidden -- Partition Use>"
	echo "${_slm_usr_part_graph_c}"
	echo "</hidden>"
	echo
	echo "<hidden -- Job State Info>" 
	echo "${_slm_usr_stat_graph_c}"
	echo "</hidden>"
	echo 
	echo "</hidden>"
}

index_generation()
{

	for _idx_dir_typ in $( ls -d1 $_stat_wiki_path/*/ 2>/dev/null | awk -F\/ '{ print $( NF - 1 ) }' )
	do
		unset _idx_data

		for _idx_dir in $( ls -d1 $_stat_wiki_path/$_idx_dir_typ/*/ 2>/dev/null | awk -F\/ '$(NF - 1) ~ /[0-9][0-9][0-9][0-9]/ { print $0 }' )
		do

			_idx_name_dir=$( echo $_idx_dir | awk -F\/ '{ print $(NF - 1) }' )

			for _idx_file_global in $( ls -1 $_idx_dir""*.txt )
			do
				_idx_file=$( echo $_idx_file_global | awk -F\/ '{ print $NF }' )
				_idx_file_wiki=$( echo $_idx_file | sed -e 's/\.txt$//' )
				_idx_file_date_b=$( echo $_idx_file | awk -F\. '{ print strftime("%Y-%m-%d %H:%M",$1) }' )
				_idx_file_date_e=$( echo $_idx_file | awk -F\. '{ print strftime("%Y-%m-%d %H:%M",$2) }' )
				_idx_file_name=$( echo $_idx_file | sed -e "s/^$_idx_dir_typ\.//" -e 's/\.txt$//' )
				_idx_file_link=$( echo "[[.:$_idx_name_dir:$_idx_file_wiki|$_idx_file_name]]" )

				_idx_des=$( cat $_idx_file_global | tr -d '*' | grep "Short Description:" | cut -d':' -f2 | sed -e 's/^ *//'  2>/dev/null )
				[ -z "$_idx_des" ] && _idx_des="NO DESCRIPTION" || _ctrl_subrep=$( echo $_idx_des | grep -o "SUB-REPORT" ) 

				[ "$_ctrl_subrep" != "SUB-REPORT" ] && _idx_data=$_idx_data""$_idx_name_dir";"$_idx_file_link";"$_idx_des";"$_idx_file_date_b";"$_idx_file_date_e"\n"
			done
					
		done 

		index_print > $_stat_wiki_path/$_idx_dir_typ/start.txt
		chmod u+rw,g+rw,o-rwx $_stat_wiki_path/$_idx_dir_typ/start.txt 
		/bin/chown $_apache_usr:$_apache_grp $_stat_wiki_path/$_idx_dir_typ/start.txt
	done

}

index_print()
{
	echo
	echo "====== CYCLOPS STATISTICS INDEX ( $_idx_dir_typ ) ======"
	echo
	echo "|< 100% 8% 12% %64 8% 8% >|"
	echo "|  $_color_title YEAR  |  $_color_title Report  |  $_color_title  Description  |  $_color_title Start Date  |  $_color_title  End Date  |"
	echo -e "${_idx_data}" | sed -e '/^$/d' -e 's/^/|  /' -e 's/$/  |/' -e 's/;/  |  /g'
	echo

}

audit_link_nodes()
{

	_host_wiki_count=0
	_host_wiki_group="|  "
	_ctrl_new_line=0

	for _host_wiki in $( echo "${_long}" )
	do
		if [ -f $_audit_wiki_path/$_host_wiki.audit.txt ]
		then
			[ "$_ctrl_new_line" -eq 9 ] && _new_line="  |\n|  " || _new_line="  |  " 
			[ "$_ctrl_new_line" -eq 9 ] && _ctrl_new_line=0 || let "_ctrl_new_line++"

			_check_days=10

			[ -f $_audit_data_path/$_host_wiki".activity.txt" ] && _check_file=$( cat $_audit_data_path/$_host_wiki".activity.txt" | 
				awk -F\; -v _dt="$_check_days" -v _dn="$_date_tsn" -v _cf="$_color_check" -v _cu="$_color_up" '
					BEGIN { 
						_dt=_dt*24*60*60 ; 
						_db=_dn-_dt ; 
						_status=_cu 
					} $1 > _db && $4 ~ "ALERT" { 
						_status=_cf 
					} END { print _status }' ) || _check_file=$_color_disable

			_host_wiki_group=$_host_wiki_group" "$_check_file" <fc white> [[ $_wiki_audit_path:$_host_wiki.audit|$_host_wiki ]] </fc> "$_new_line
			let "_host_wiki_count++"
		fi
	done

}

output_file()
{

	case "$_par_typ" in
	cyclops)
		echo -e "REPORT: ($_par_typ) $_par_idx : Generating Output"

		if [ "$_opt_idx" == "yes" ] 
		then
			case "$_par_idx" in 
			audit)
				_output_path=$_audit_wiki_path
				_output_file="start.txt"
				echo "${_output}" > $_output_path/$_output_file

				chmod u+rw,g+rw,o-rwx $_output_path/$_output_file
				/bin/chown $_apache_usr:$_apache_grp $_output_path/$_output_file
			;;
			audit*)
				_output_path=$_audit_wiki_path
				_output_file=$( echo $_par_idx".txt" | tr [:upper:] [:lower:] )
				echo "${_output}" > $_output_path/$_output_file

				chmod u+rw,g+rw,o-rwx $_output_path/$_output_file
				/bin/chown $_apache_usr:$_apache_grp $_output_path/$_output_file
			;;
			*)
				_date_year_start=$( date -d@$_date_tsb +%Y )
				_output_file=$( echo "cyclops."$_par_idx".txt" | tr [:upper:] [:lower:] )

				_output_path=$_stat_wiki_path/$_path_type/$_date_year_start

				if [ ! -d "$_output_path" ] 
				then
					mkdir -p $_output_path
					chmod u+rw,g+rw,o-rwx $_output_path
					/bin/chown $_apache_usr:$_apache_grp $_output_path
				fi

				echo "${_output}" > $_output_path/$_output_file

				chmod u+rw,g+rw,o-rwx $_output_path/$_output_file
				/bin/chown $_apache_usr:$_apache_grp $_output_path/$_output_file

				index_generation
			;;
			esac
		else
			echo "${_output}"
		fi

		if [ "$_opt_rcr" == "yes" ]
		then
			echo "REPORT: ($_par_typ) $_par_idx : Waiting For Subreports"
			wait
			echo "REPORT: ($_par_typ) $_par_idx : Finish"
		else
			echo -e "REPORT: ($_par_typ) $_par_idx : Finish"
		fi
	;;
	slurm)
		echo "REPORT: ($_par_typ) Creating Wiki Files"

		if [ "$_opt_idx" == "yes" ]
		then
			_date_year_start=$( date -d@$_date_tsb +%Y )
			_output_path=$_stat_wiki_path/$_path_type/$_date_year_start

			if [ ! -d "$_output_path" ] 
			then
				mkdir -p $_output_path
				chmod 770 $_output_path
				/bin/chown $_apache_usr:$_apache_grp $_output_path
			fi

			_output_file=$( echo "slurm."$_par_idx".txt" | tr [:upper:] [:lower:] )
			echo -e "${_slm_global_output}" > $_output_path/$_output_file

			chmod 660 $_output_path/$_output_file
			/bin/chown $_apache_usr:$_apache_grp $_output_path/$_output_file

			index_generation
		else
			echo -e "${_slm_global_output}"
		fi

		echo "REPORT: ($_par_typ) Finish Slurm Report"
	;;
	esac

}

daemon_launch()
{
	_dae_launch_state="OK"

	_dae_idx=$( echo $_daemon_line | cut -d';' -f1 )
	_dae_typ=$( echo $_daemon_line | cut -d';' -f2 )
	_dae_sdt=$( echo $_daemon_line | cut -d';' -f3 )
	_dae_nod=$( echo $_daemon_line | cut -d';' -f4 )
	_dae_lnk=$( echo $_daemon_line | cut -d';' -f5 )			
	_dae_rcr=$( echo $_daemon_line | cut -d';' -f6 )
	_dae_nam=$( echo $_daemon_line | cut -d';' -f7 )
	_dae_des=$( echo $_daemon_line | cut -d';' -f8 )

	[ -z "$_dae_idx" ] && _dae_launch_state="FAIL"
	[ -z "$_dae_typ" ] && _dae_launch_state="FAIL" || _dae_launch_string=$_dae_launch_string" -t "$_dae_typ
	[ ! -z "$_dae_nod" ] && _dae_launch_string=$_dae_launch_string" -n "$_dae_nod
	[ "$_dae_lnk" == "yes" ] && _dae_launch_string=$_dae_launch_string" -k "
	[ "$_dae_rcr" == "yes" ] && _dae_launch_string=$_dae_launch_string" -r "
	[ -z "$_dae_nam" ] && _dae_launch_state="FAIL" || _dae_launch_string=$_dae_launch_string" -i "$_dae_nam
	[ -z "$_dae_des" ] && _dae_launch_state="FAIL" || _dae_launch_string=$_dae_launch_string" -d '"$_dae_des"' "
	
	case "$_dae_sdt" in 
	*Y)
		_dae_sdt=$( echo $_dae_sdt | awk -F"Y" '{ _d=systime() - ( $1 * 365 * 24 * 3600) ; print strftime("%Y-%m-%d",_d) }' )
	;;
	*M)
		_dae_sdt=$( echo $_dae_sdt | awk -F"Y" '{ _d=systime() - ( $1 * 30 * 24 * 3600) ; print strftime("%Y-%m-%d",_d) }' )
	;;
	*D)
		_dae_sdt=$( echo $_dae_sdt | awk -F"Y" '{ _d=systime() - ( $1 * 24 * 3600) ; print strftime("%Y-%m-%d",_d) }' )
	;;
	*)
		_dae_launch_state="FAIL"
	;;
	esac

	echo "$( date +%s ): CYC STATS : ALL SETTINGS FOR LAUNCH ($_dae_nam) $_dae_launch_state : $_dae_idx.$_dae_nam" >> $_cyclops_log 

	if [ "$_dae_launch_state" == "OK" ] 
	then
		echo "$( date +%s ): CYC STATS : TRY LAUNCH REPORT ($_dae_nam) [$_dae_launch_string] : $_dae_idx.$_dae_nam" >> $_cyclops_log 
		_dae_launch_string=$_dae_launch_string" -b "$_dae_sdt
		eval exec $_script_path/cyc.stats.sh $_dae_launch_string
		echo "$( date +%s ): CYC STATS : FINISH REPORT ($_dae_nam) : $_dae_idx.$_dae_nam" >> $_cyclops_log 

		if [ "$?" == "0" ] 
		then
			echo "$( date +%s ): CYC STATS : DAEMON LAUNCH ($_dae_nam) OK: $_dae_idx.$_dae_nam" >> $_cyclops_log 
		else
			echo "$( date +%s ): CYC STATS : DAEMON LAUNCH ($_dae_nam) ERR: $_dae_idx.$_dae_nam" >> $_cyclops_log
		fi
	else
		echo "$( date +%s ): CYC STATS : DAEMON ERR: [$_dae_launch_string] Command generation fail, revise config file" >> $_cyclops_log
	fi

	echo "$( date +%s ): CYC STATS : FINSH DAEMON REPORT LAUNCH ($_dae_nam) : $_dae_idx.$_dae_nam" >> $_cyclops_log 
}

###########################################
#               MAIN EXEC                 #
###########################################

	[ "$_cyclops_ha" == "ENABLED" ] && ha_check $_command

############ DATE PROCESSING ##############

	_date_tsn=$( date +%s )
	_now_year=$( date -d @$_date_tsn +%Y )

	[ -z "$_par_beg" ] && _par_beg=$_now_year

	case "$_par_beg" in
	"Jan-"*|"Feb-"*|"Mar-"*|"Apr-"*|"May-"*|"Jun-"*|"Jul-"*|"Aug-"*|"Sep-"*|"Oct-"*|"Nov-"*|"Dec-"*)

		_date_year=$( echo $_par_beg | cut -d'-' -f2 )
		_date_month=$( echo $_par_beg | cut -d'-' -f1 )

		_query_month=$( date -d '1 '$_date_month' '$_date_year +%m | sed 's/^0//' )

		_date_tsb=$( date -d '1 '$_date_month' '$_date_year +%s )

		let "_next_month=_query_month+1"

		[ "$_next_month" == "13" ] && let "_next_year=_date_year+1" && _next_month="1" || _next_year=$_date_year

		_date_tse=$( date -d $_next_year'-'$_next_month'-1' +%s)

		let "_date_tse=_date_tse-10"

		_date_filter="day"
		_date_start=$( date -d @$_date_tsb +%Y-%m-%d )
		_date_end=$( date -d @$_date_tse +%Y-%m-%d )
		_date_title=$_par_beg
		
		let "_date_count=((_date_tse-_date_tsb)/86400)+1"
		
		calc_date_title_day

	;;
	2[0-9][0-9][0-9])
		## COOKIE: Stephen Hawkings told us that humanity dissapear in One thousand years if we will not go out of earth... cyclops only control de next one thousand years.

		[ "$_par_beg" -gt "$_now_year" ] && echo "Your are funny, maybe you want that we use tarot to get statatistics of the future?" && exit 1

		_date_tsb=$( date -d '1 Jan '$_par_beg +%s )
		_date_tse=$( date -d '31 Dec '$_par_beg +%s )

		_date_filter="month"
		_date_start=$( date -d @$_date_tsb +%Y-%m-%d )
		_date_end=$( date -d @$_date_tse +%Y-%m-%d ) 
		_date_title=$_par_beg
		_date_count="12"

		calc_date_title_month

	;;
	2[0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9])

		[ -z "$_par_end" ] && _date_tse=$_date_tsn || _date_tse=$( date -d $_par_end +%s )

		_date_tsb=$( date -d $_par_beg +%s )

		let "_days_count=((_date_tse-_date_tsb)/86400)+1"

		_date_start=$( date -d $_par_beg +%Y-%m-%d )
		_date_end=$( date -d @$_date_tse +%Y-%m-%d )
		_date_title=$_date_start" to "$_date_end

		case "$_days_count" in
		0)
			echo "ERR: Stat less than 1 day? not please, use big threshold"
			exit 1
		;;
		[1-9]|[0-3][0-9])
			_date_count=$_days_count
			_date_filter="day"
			calc_date_title_day
		;;
		[4-9][0-9]|[1-3][0-9][0-9])
			_date_filter="month"
			_date_count=$( awk -v _de="$_date_end" -v _ds="$_date_start" '
				BEGIN { 
					split(_de, A,"-") ;
					split(_ds, B,"-") ;
					year_diff=A[1]-B[1] ;
					if (year_diff) {
						months_diff=A[2] + 12 * year_diff - B[2] + 1;
						} 
					else {
						months_diff=A[2]>B[2]?A[2]-B[2]+1:B[2]-A[2]+1
						};
					print months_diff
				}' )
			calc_date_title_month
		;;
		"*")
			_date_filter="year"
		;;
		esac

	;;
	"*")
		echo "ERR: Wrong Date Format, use -h for help"
		exit 1
	;;
	esac

############ NODE-PROCESSING ###############

	[ -z "$_par_nod" ] && _par_nod="all"

	if [ "$_par_nod" == "all" ] 
	then
		_node_title="All nodes" 
		_long=$( cat $_type | sed -e '/^$/d' -e '/^#/d' | cut -d';' -f2 )
		_par_node=$( echo "${_long}" | tr '\n' ',' | sed 's/,$//' )
		_par_node=$( node_group $_par_node ) 
	else
		_node_title=$_par_nod" nodes"
	fi

	_family_list=$( cat $_type | sed -e '/^$/d' -e '/^#/d' | awk -F\; -v _nl="$_long" '
		BEGIN { 
			split(_nl,n,"\n")
			}	 
		{ 
			for ( i in n ) { 
				if ( n[i] == $2 ) { f[$3]=f[$3]""n[i]"," 
					}
				}
			} 
		END { 
			for ( a in f ) { 
				print a";"f[a] 
				}
			}' | sed -e 's/,$//' )
	_group_list=$( cat $_type | sed -e '/^$/d' -e '/^#/d' | awk -F\; -v _nl="$_long" '
		BEGIN { 
			split(_nl,n,"\n")
			} 
		{ 
			for ( i in n ) { 
				if ( n[i] == $2 ) { f[$4]=f[$4]""n[i]"," }
				}
			} 
		END { 
			for ( a in f ) { 
				print a";"f[a] 
				}
			}' | sed -e 's/,$//' )

######### OTHER PRE-PROCESSING ############

#### STUDY DESCRIPTION AND FILE PREFIX SETTINGS - REFACTORY ####

	[ -z "$_par_idx" ] && _par_idx=$_par_typ

############# ACTION EXEC #################

	case "$_par_typ" in 
	cyclops)
		#### FACTORY - INDEX WIKI FUNCTION.

		echo -e "REPORT: ($_par_typ) $_par_idx : Processing Global Data"

		cyclops_global_calc

		echo -e "REPORT: ($_par_typ) $_par_idx : Processing Global Group Data"

		cyclops_concrete_calc "${_group_list}"
		_output_group=$( cyclops_data_detail_print )

		echo -e "REPORT: ($_par_typ) $_par_idx : Processing Global Family Data"

		cyclops_concrete_calc "${_family_list}"
		_output_family=$( cyclops_data_detail_print )

		[ "$_opt_lnk" == "yes" ] && audit_link_nodes

		_output=$( cyclops_global_print )

		_path_type="cyclops"

		if [ "$_opt_rcr" == "yes" ]
		then
			for _group_item in $( echo "${_group_list}" )
			do
				_group_name=$( echo $_group_item | cut -d';' -f1 )
				_node_sublist=$( echo $_group_item | cut -d';' -f2- )
				_node_subrange=$( node_group $_node_sublist )
				$_script_path/cyc.stats.sh -t cyclops -b $_par_beg -n $_node_subrange -i $_par_idx"_"$_group_name -d "$_par_idx SUB-REPORT: $_group_name : $_par_des" -k &

				echo -e "REPORT: ($_par_typ) $_par_idx : Processing Subreport $_group_name" 
			done
			wait

			for _family_item in $( echo "${_family_list}" | cut -d';' -f1 )
			do
				_family_name=$( echo $_family_item | cut -d';' -f1 )
				_node_sublist=$( cat $_type | awk -F\; -v _f="$_family_item" '$3 == _f { _nl=_nl$2"," } END { print _nl }' | sed 's/,$//' )
				_node_subrange=$( node_group $_node_sublist )
				$_script_path/cyc.stats.sh -t cyclops -b $_par_beg -n $_node_subrange -i $_par_idx"_"$_family_name -d "$_par_idx SUB-REPORT $_family_name : $_par_des" &

				echo -e "REPORT: ($_par_typ) $_par_idx : Processing Subreport $_family_name"
			done
			wait
		fi
	
		output_file	
	;;
	slurm)
		_path_type="slurm"

		echo "REPORT: ($_par_typ) Init Slurm Report "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" )

		slurm_init

		echo "REPORT: ($_par_typ) Launch Slurm Report "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" )

		slurm_main

		output_file
		
		echo "REPORT: ($_par_typ) End and Close Slurm Report "$( [ "$_opt_idx" == "yes" ] && echo "[$_par_idx]" )
	;;
	user)
		echo "FACTORING"
	;;
	daemon)
		#echo "DEBUG: ON DEPLOY TESTING MODE"

		if [ ! -f "$_stat_daemon_cfg_file" ] 
		then
			echo "$( date +%s ): CYC STATS : DAEMON ERR: Config File don't exists: ($_stat_daemon_cfg_file)" >> $_cyclops_log 
			exit 1
		fi

		echo "$( date +%s ): CYC STATS : LAUNCH STATS DAEMON ($(cat $_stat_daemon_cfg_file | awk -F\; '$1 ~ "^[0-9]+$" && NF == 8 { _c++ } END { print _c }')) REPORTS" >> $_cyclops_log 

		for _daemon_line in $( cat $_stat_daemon_cfg_file | awk -F\; '$1 ~ "^[0-9]+$" && NF == 8 { print $0}' )
		do
			daemon_launch &
		done 
		wait

		echo "$( date +%s ): CYC STATS : FINSH LAUNCH DAEMON" >> $_cyclops_log 
	;;
	index)
		echo "REPORT: ($_par_typ) : Sumited Index Generation"

		index_generation
	;;
	esac

#### DEBUG EXEC --- REFACTORY OR DELETE ####


	if [ "$_opt_dbg" == "yes" ]
	then
		echo "REPORT: ($_par_typ) $_par_idx : Debug Report" 

		echo
		
		echo "<hidden DEBUG:>"
		echo "<code>DEBUG:"
		echo "DATE_NOW : $( date -d @$_date_tsn +%Y-%m-%d ) : $_date_tsn : $_now_year"
		echo -e "DATE_START:$_date_start:$_date_tsb:$( date -d@$_date_tsb +%Y-%m-%d )\n"DATE_END:$_date_end:$_date_tse:$( date -d@$_date_tse +%Y-%m-%d )"" | column -s\: -t
		echo "DATE TITLE: "$_date_title
		echo "DATE TITLE STRING: "$_date_title_str
		echo "DATE FILTER: "$_date_filter
		echo "DATE COUNT: "$_date_count

			_date_elapsed_s=$( date +%s )
		cyclops_global_calc
			_date_elapsed_e=$( date +%s )
			let "_date_elapsed=_date_elapsed_e-_date_elapsed_s"
			echo "GLOBAL_CALC ET: $_date_elapsed"

			_date_elapsed_s=$( date +%s )
		cyclops_concrete_calc "${_group_list}"
		_output_group=$( cyclops_data_detail_print )
			_date_elapsed_e=$( date +%s )
			let "_date_elapsed=_date_elapsed_e-_date_elapsed_s"
			echo "CONCRETE_CALC - GROUP - ET: $_date_elapsed"

			_date_elapsed_s=$( date +%s )
		cyclops_concrete_calc "${_family_list}"
		_output_family=$( cyclops_data_detail_print )
			_date_elapsed_e=$( date +%s )
			let "_date_elapsed=_date_elapsed_e-_date_elapsed_s"
			echo "CONCRETE_CALC - FAMILY - ET: $_date_elapsed"

			_date_elapsed_s=$( date +%s )
		_output=$( cyclops_global_print )
			_date_elapsed_e=$( date +%s )
			let "_date_elapsed=_date_elapsed_e-_date_elapsed_s"
		echo "GLOBAL_PRINT ET: $_date_elapsed"
		echo "PATH STATS: "$_stat_extr_path

		echo "OUTPUT:"
		echo "</code>"
		echo "</hidden>"

		echo 
		echo "${_output}"

		
		echo "<hidden DEBUG>"
		echo "<code>DEBUG:"
		echo $_cyc_eve_global_t
		echo $_cyc_mng_global_t
		echo $_cyc_ale_global_t
		echo $_cyc_iss_global_t
		echo $_cyc_rea_global_t
		echo "</code>"
		echo "</hidden>"
		
	fi
