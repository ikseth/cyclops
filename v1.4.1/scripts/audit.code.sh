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

############# VARIABLES ###################
#


        IFS="
        "

        _sh_color_green='\033[32m'
        _sh_color_red='\033[31m'
        _sh_color_yellow='\033[33m'
        _sh_color_bolt='\033[1m'
        _sh_color_nformat='\033[0m'

        _command_opts=$( echo "$@" | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^m/ ) { gsub(/^[a-z] /,"&@",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' )
        _command_name=$( basename "$0" )
        _command_dir=$( dirname "${BASH_SOURCE[0]}" )
        _command="$_command_dir/$_command_name $_command_opts"

        [ -f "/etc/cyclops/global.cfg" ] && source /etc/cyclops/global.cfg || _exit_code="111"

        [ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
        [ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
        [ -f "$_libs_path/node_ungroup.sh" ] && source $_libs_path/node_ungroup.sh || _exit_code="114"
	[ -f "$_color_cfg_file" ] && source $_color_cfg_file || _exit_code="116"
	[ -f "$_libs_path/init_date.sh" ] && source $_libs_path/init_date.sh || _exit_code="118"

        case "$_exit_code" in
        111)
                echo "Main Config file doesn't exists, please revise your cyclops installation"
                exit 1
        ;;
        112)
                echo "HA Control Script doesn't exists, please revise your cyclops installation"
                exit 1
        ;;
        11[3-4])
                echo "Necesary libs files doesn't exits, please revise your cyclops installation"
                exit 1
        ;;
	116)
                echo "WARNING: Color file doesn't exits, you see data in black"
        ;;
        esac

#
        _cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

#### DEFAULT VALUES ####

        _par_typ="status"
        _par_act="all"

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":c:d:e:n:f:t:s:q:v:ih:" _optname
do
        case "$_optname" in
                "c")
                        _opt_code_pattern="yes"
                        _par_code_pattern=$OPTARG
                ;;
                "d")
                        _opt_date_start="yes"
                        _par_date_start=$OPTARG
		;;
		"e")
                        _opt_date_end="yes"
                        _par_date_end=$OPTARG
		;;
		"n")
                        _opt_node="yes"
                        _par_node=$OPTARG

                        _ctrl_grp=$( echo $_par_node | grep @ 2>&1 >/dev/null ; echo $? )

                        if [ "$_ctrl_grp" == "0" ]
                        then
                                _par_node_grp=$( echo "$_par_node" | tr ',' '\n' | grep ^@ | sed 's/@//g' | tr '\n' ',' )
                                _par_node=$( echo $_par_node | tr ',' '\n' | grep -v ^@ | tr '\n' ',' )
                                _par_node_grp=$( awk -F\; -v _grp="$_par_node_grp" '{ split (_grp,g,",") ; for ( i in g ) {  if ( $2 == g[i] || $3 == g[i] || $4 == g[i] ) { _n=_n""$2","  }}} END { print _n }' $_type )
                                _par_node_grp=$( node_group $_par_node_grp )
                                _par_node=$_par_node""$_par_node_grp
                                [ -z "$_par_node" ] && echo "ERR: Don't find nodes in [$_par_node_grp] definited group(s)/family(s)" && exit 1
                        fi
		;;
		"s")
			_opt_sta="yes"
			_par_sta=$OPTARG
			[ "$_par_sta" != "open" ] && [ "$_par_sta" != "close" ] && [ "$_par_sta" != "all" ] && echo -e "Filter error [$_par_sta]\nUse -h for help" && exit 1
		;;
		"t")
			_opt_tkt="yes"
			_par_tkt=$OPTARG
		;;
		"f")
			_opt_filter="yes"
			_par_filter=$OPTARG
		;;
		"i")
			_opt_stats="yes"
		;;
		"v")
			_opt_show="yes"
			_par_show=$OPTARG
		;;
		"q")
			_par_easternegg=$OPTARG
		;;
                "h")
                        _opt_help="yes"
                        _par_help=$OPTARG

                        case "$_par_help" in
                                        "des")
                                                echo "$( basename "$0" ) : Cyclops Issue Control Audit Tool"
                                                echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
                                                echo "	Global config path : $_config_path"
                                                echo "		Global config file: global.cfg"
						echo "		Issue Codes Config file: ./audit/issuecodes.cfg"
                                                echo

                                                exit 0
                        esac
		;;
		":")
                        case "$OPTARG" in
                        "h")
                                echo
                                echo "CYCLOPS ISSUE CONTROL AUDIT TOOL"
                                echo "  Help to know logbook issue and control state of them"
				echo
				echo "	-c [pattern name|help], select issue code pattern, use help for know avaibility"
				echo
                                echo "FILTER:"
				echo
				echo "	-s [open|close|all] show codes by state"
				echo "		open: show only open codes"
				echo "		close: show only close codes"
				echo "		all: ( by default ), show all codes"
				echo 
				echo "	-t [code], ask for specific code"
				echo 
				echo " 	-n [node|node range] node filter"
                                echo "		You can use @[group or family name] to define range node"
                                echo "		and you can use more than one group/family comma separated"
				echo
                                echo "	-d [date format], start date or range to filter by date:"
                                echo "		[YYYY]: ask for complete year"
                                echo "		[Mmm-YYYY]: ask for concrete month"
                                echo "		year: ask for last year"
                                echo "		[1-9*]month: ask for last month ( by default )"
                                echo "		week: ask for last week"
                                echo "		[1-9*]day: ask for last n days ( sort by day format )"
                                echo "		[1-9*]day: ask for last n hours ( sort by hour format )"
                                echo "		report: ask for year,month,week,day"
                                echo "		[YYYY-MM-DD]: Implies data from date to now if you dont use -e"
                                echo "	-e [YYYY-MM-DD], end date for concrete start date" 
                                echo "		mandatory use the same format with -d parameter"
				echo
				echo "OUTPUT:"
				echo
				echo "	-i show statistics data"
				echo "  -v [human|timeline] select diferent output formats"
				echo "		human: default mode"
				echo "		timeline: show code timeline evolution format"

				exit 0
			;;
			esac
		;;
	esac
done

shift $((OPTIND-1))

###########################################
#               FUNCTIONs                 #
###########################################

sel_cod_in_range()
{
	$_script_path/audit.nod.sh -v eventlog -f bitacora | 
		sed -e 's/ :/:/g' -e 's/: /:/g' -e 's/ *$//' | 
		awk -F\; -v tsb="$_date_tsb" -v tse="$_date_tse" -v cip="$_code_pattern" -v nd="$_par_node" -v _tkt="$_par_tkt" -v _ss="$( tput cols )" -v _ee="$_par_easternegg" '
			BEGIN { 
				split(_ee,cs,"") 
				if ( cs[1] == "" ) { cs[1]=":" }
				_ctkt=0 ; _regc=0 ; _pbl=0  
				for (l=1;l<=_ss;l++) { _blk=_blk" " }
				_bpt=_ss/2
			} {
				_idx="" ;
				ldes=split($5,des,":") ; 
				for(i=1;i<=ldes;i++) { 
					if ( des[i] ~ cip && des[i] ~ _tkt ) { 
						_idx=des[i]
						if ( cod[_idx] == "" || cod[_idx] > $1 ) {  
							if ( cod[_idx] == "" ) { _ctkt++ ; _pbl++ ; codclose[_idx]="0" } 
							cod[_idx]=$1 ;
						}
						codfld[_idx";"$1]=_idx";"$1";"$3";"$4";"$6";"$5
						codtim[$1]=_idx
						break ;
					}
				}
			} $3 ~ nd && _idx != "" { 
				if ( $1 >= tsb && $1 <= tse ) { 
					tkt[_idx]=$1
					_regc++ 
					if ( _pbl <= _ss/4 ) { _tktstrg=_tktstrg""cs[1] } else { _tktstrg="" ; _pbl=0  ; printf "%s\r", _blk >> "/dev/stderr" }
				} else {
					if ( cod[_idx] < tsb && $1 > tse ) {
						tkt[_idx]=$1
						_regc++
						if ( _pbl <= _ss/2 ) { _tktstrg=_tktstrg""cs[1] } else { _tktstrg="" ; _pbl=0  ; printf "%s\r", _blk >> "/dev/stderr" }
					} 
				}
				if ( codopen[_idx] > $1  ) { codopen[_idx]=$1 }
				if ( ($6 == "CLOSE" || $6 == "SOLVED")) { codclose[_idx]="1" }
			} {
				if ( _regc > 0 ) { 
					printf "PROCESSING [FND%/TOT%] [COD/REG/TOT]: [%'"'"'.2f%/%'"'"'.2f%] [%s/%s/%s] %s\r", (_ctkt*100)/_regc, (_ctkt*100)/NR, _ctkt, _regc, NR, _tktstrg >> "/dev/stderr" 
				} else {
					printf "SEARCHING REGISTERS FROM DATE RANGE : [%s]\r", NR >> "/dev/stderr"
				}
			} END {
				for ( c in cod ) {
					if ( tkt[c] != "" || codclose[c] == "0" ) {
						for ( t in codtim ) {
							if ( codtim[t] == c ) { 
								print codfld[c";"t]	
							}
						}
					}
				}
			}' | sort -t\; -n -k1 -k2
}

format_output()
{

	echo
	echo "${_codedata}"  | awk -F\; -v _oi="$_opt_stats" -v _ps="$_par_sta" -v _ss="$( tput cols )" -v _bc="$_sh_color_blink" -v _nf="$_sh_color_nformat" -v _gc="$_sh_color_green" -v _rc="$_sh_color_red" -v _yc="$_sh_color_yellow" -v _ggc="$_sh_color_gray" -v _cc="$_sh_color_cyc" -v _btc="$_sh_color_bolt" -v tsb="$_date_tsb" -v tse="$_date_tse" '
		BEGIN {
                        _ajuste=4 ;
                        _ls=12+1+5+1+4+1+14+1+12+1+6+1+_ajuste ;
			_space="|"
                        for (s=1;s<_ls-_ajuste;s++) { _space=_space" " } ;
                        _l=_ss-_ls ; 
		} {
			_lf6=split($6,af6,":")
			_tf6=af6[_lf6]
			if ( _lf6 > 1 ) { _tf6=af6[1]" : "_tf6 } 
			_fs=length(_tf6) ; 
			split(_tf6,chars,"") ; 
			_long=0 ; 
			_f="" ; _pw="" ; _w="" ;  
			_fdbg="" ;
			for (i=1;i<=_fs;i++) { 
				if ( chars[i] == " " ) { 
					_ws=length(_w) ; 
					_pw=_w ; 
					_long=_long+_ws+1
					_w="" ; 
					if ( _long > _l ) { 
						_long=_ws+1 ;
						_f=_f"\n"_space""_pw" " ; 
					} else { 
						_f=_f""_pw" " ; 
					}
				} else { 
					_w=_w""chars[i] ; 
				} ; 
			}
			_ws=length(_w) ;
			if (( _long + _ws ) > _l ) { _w="\n"_space""_w }
			_f3c="" ; _f4c="" ; _f5c="" ;
			if ( $4 == "INFO" || $4 == "DISABLE" ) { _f4c=_ggc }
			if ( $4 == "ISSUE" ) { _f4c=_rc } 
			if ( $4 == "cyclops" ) { _f4c=_cc }
			if ( $5 == "INFO" ) { _f5c=_ggc }
			if ( $5 == "CLOSE" ) { _f5c=_btc }
			if ( $5 ~ /OK|UP/ ) { _f3c=_gc ; _f5c=_gc }
			if ( $5 == "FAIL" ) { _f3c=_yc ; _f5c=_yc }
			if ( $5 == "SOLVED" ) { _f4c=_gc ; _f3c=_gc ; _f5c=_gc }
			if ( $5 == "DOWN" ) { _f3c=_rc ; _f5c=_rc }
			_line=sprintf("|\t%10s %5s%s  %s%-14.14s%s %s%-8s%s %s%-8s%s %s%s", strftime("%F",$2), strftime("%H:%M",$2), _nf, _f3c, $3, _nf, _f4c, $4, _nf, _f5c, $5, _nf, _f, _w)
			complex[$1]=complex[$1]+_fs
			_chart=_chart+_fs
			if ( code[$1] == "" ) {
				code[$1]=_line
			} else { 
				code[$1]=code[$1]"\n"_line
			}
			if ( tkto[$1] > int($2) || tkto[$1] == "" ) { 
				tkto[$1]=int($2) 
			}  
			if ( ( tktc[$1] < int($2) || tktc[$1] == "" ) && ( $5 == "SOLVED" || $5 == "CLOSE" ) ) { 
				tktc[$1]=int($2) 
			}
		} END {
			_tc=length(code)
			_clg=asorti(code, codix)
			_ot=0 ; _ct=0 ; _ciah=0 ; _ciam=0 ; _cial=0 ; _closec=0 ; _newc=0 ; _oldc=0  
			for (i=1;i<=_clg;i++) {
				t=codix[i]
				_tm="h" ;
				if ( tktc[t] == "" ) { 
					_ftc=_rc ; _foc=_rc ; _fcc=_ggc ;
					_st=1 ; _ot++ 
					_t=int((systime()-tkto[t])/(3600)) ; 
					_endline=sprintf("|\n\\______________ CODE IN PROGRESS: %s%s>>>%s", _bc, _rc, _nf)
				} else { 
					_ftc=_gc ; _foc=_ggc ; _fcc=_gc ; 
					_st=0 ; _ct++
					_t=(tktc[t]-tkto[t])/(3600) ; 
					_endline=sprintf("|\n\\______________ %sCLOSE%s [%19.19s] : ", _fcc, _nf, strftime("%F %T",tktc[t]) ) 
					if ( tktc[t] <= tse ) { _closec++ }
				} ; 
				if ( tkto[t] >= tsb ) { _newc++ } else { _oldc++ } 
				_cplxavg=_chart/_tc
				if ( complex[t] > _cplxavg+_cplxavg/2 ) { _cc="HIGH" ; _fcc=_rc ; _ciah++ ; _crth=_crth+_t } 
				if ( complex[t] >= _cplxavg && complex[t] <= _cplxavg+_cplxavg/2 ) { _cc="MEDIUM" ; _fcc=_yc ; _ciam++ ; _crtm=_crtm+_t } 
				if ( complex[t] < _cplxavg ) { _cc="LOW" ; _fcc=_gc ; _cial++ ; _crtl=_crtl+_t }
				_tavg=_tavg+_t ; 
				if ( _t > 24 ) { _t=_t/24 ; _tm="d" ; _flc=_rc } else { _flc=_gc } 
				if ( ((_ps == "open" && _st == 1 ) || ( _ps == "close" && _st == 0 ) || _ps == "all" || _ps == "" ) && _oi != "yes" ) { 
					print " ______________"
					printf "%s%-14s%s : %sOPEN%s  [%19.19s] : COMPLEX [%s%s%s]\n|\n", _ftc, t, _nf, _foc, _nf, strftime("%F %T",tkto[t]), _fcc, _cc, _nf
					print code[t] ;
					printf "%s %sLIFE%s [%'"'"'.2f]%s\n\n", _endline, _flc, _nf, _t , _tm
				}
			}
			if ( _oi == "yes" ) {
				print ""
				print "TOTAL:" ;
				printf "\tCODES: %8s\n", _tc ;
				printf "\t  OPEN : %6s : %'"'"'6.2f%\n", _ot, (_ot*100)/_tc ;
				printf "\t  CLOSE: %6s : %'"'"'6.2f%\n", _ct, (_ct*100)/_tc ;
				printf "\t  NEW  : %6s : %'"'"'6.2f%\n", _newc, (_newc*100)/_tc ;
				printf "\t  OLD  : %6s : %'"'"'6.2f%\n", _oldc, (_oldc*100)/_tc ;
				printf "\t  END  : %6s : %'"'"'6.2f%\n", _closec, (_closec*100)/_tc ;
				printf "\t  ALIVE: %6s : %'"'"'6.2f%\n", _tc-_closec, ((_tc-_closec)*100)/_tc ;
				print "\n\tCOMPLEX:" 
				if ( _ciah > 0 ) { printf "\t  HIGH : %6s : %'"'"'6.2f%\n", _ciah, (_ciah*100)/_tc } 
				if ( _ciam > 0 ) { printf "\t  MED  : %6s : %'"'"'6.2f%\n", _ciam, (_ciam*100)/_tc }
				if ( _cial > 0 ) { printf "\t  LOW  : %6s : %'"'"'6.2f%\n", _cial, (_cial*100)/_tc }
				printf "\n\tREGISTERS: %4s\n", NR ;
				print "\nCODE AVG:" ;
				printf "\tREG/CODE: %'"'"'.2f\n", NR/_tc ;
				printf "\n\tRESOLUTION TIME: %'"'"'.2fh ( %'"'"'.2fd )\n", (_tavg/_tc), (_tavg/_tc)/24 ; 
				print "\t  COMPLEX:"
				if ( _ciah > 0 ) { printf "\t    HIGH : %'"'"'10.2fh ( %'"'"'6.2fd )\n", _crth/_ciah, _crth/_ciah/24 } 
				if ( _ciam > 0 ) { printf "\t    MED  : %'"'"'10.2fh ( %'"'"'6.2fd )\n", _crtm/_ciam, _crth/_ciam/24 } 
				if ( _cial > 0 ) { printf "\t    LOW  : %'"'"'10.2fh ( %'"'"'6.2fd )\n", _crtl/_cial, _crth/_cial/24 }
				print "\n"
			}
		
		}'

}

format_timeline()
{
	echo "${_codedata}"  | sort -n -k1 -k2 | awk -F\; -v tsb="$_date_tsb" -v tse="$_date_tse" ' 
		BEGIN { 
			_syst=systime()
		} { 
			if ( $2 > _max) { _max=$2 } ; 
			if ( $2 < _min ) { _min=$2 } ; 
			if ( dates[$1] == "" ) { dates[$1]=$2 } else { dates[$1]=dates[$1]","$2 } ; 
			state[$1, $2]=$5 
		} END { 
			_dbrk=strftime("%Y%m%d",_syst)
			_ymax=strftime("%Y",tse)
			_dmax=strftime("%Y%m%d",tse)
			_mmax=int(strftime("%m",tse))
			_ymin=strftime("%Y",tsb)
			_dmin=strftime("%Y%m%d",tsb)
			_mmin=int(strftime("%m",tsb))
			printf "MAX [%s] MIN [%s] YMAX [%s] MMAX[%s] YMIN [%s] MMIN[%s] \n", _max, _min, _ymax, _mmax, _ymin, _mmin
			_head=sprintf("%-15s : |", "CODE")
			_lcod=asorti(dates, datesidx)
			for (ci=1;ci<=_lcod;ci++) {
				_cctrl=0 ; _dctrl=0 ; _tls=""
				c=datesidx[ci] ;
				split(dates[c],ts,",")      
				for ( kk in ts ) { if ( ts[kk] < tsb ) { _cctrl=1 }}
				for (y=_ymin;y<=_ymax;y++) {
					if ( y == _ymin ) { _mi=_mmin } else { _mi=1 }	
					if ( y == _ymax ) { _ma=_mmax } else { _ma=12 }	
					for (m=_mi;m<=_ma;m++) {
						_dayini=mktime(y" "m" 1 0 0 0" )
						if ( m == 12 ) { _dayend=mktime(y+1" 1 1 0 0 0")-1 } else { _dayend=mktime(y" "m+1" 1 0 0 0")-1 }
						_day=0
						for (d=_dayini;d<=_dayend;d=d+86400) {
							_day++
							_ectrl=0 ;
							if ( d < tsb  ) { 
								if ( d + 86400 > tsb ) {
									_tls=_tls">" 
								} else { 
									_tls=_tls" " 
								}
							} else {
								_lev=asorti(ts, tsidx)
								for (ev=1;ev<=_lev;ev++) {
									i=tsidx[ev] ;
									_dte=strftime("%Y%m%d",ts[i])
									if ( _dte == ((y*100+m)*100)+_day ) {
										_ectrl=1 ;
										if ( _cctrl == 0 ) { _cctrl=1 }
										if ( state[c, ts[i]] ~ "SOLVED" || state[c, ts[i]] ~ "CLOSE" ) {
											 _dctrl=1
										}
									} 
								}
								if ( _ectrl == 1 && _cctrl == 1 ) { _tls=_tls"X" }
								if ( _ectrl == 0 && _cctrl == 1 ) { _tls=_tls"-" }
								if ( _ectrl == 1 && _cctrl == 0 ) { _cctrl=1     }
								if ( _ectrl == 0 && _cctrl == 0 ) { _tls=_tls" " }
								if ( _dctrl == 1 ) { _cctrl=0 }
								if ( _dbrk == ((y*100+m)*100)+_day ) { _cctrl=0 ;  break }
							}
						}
						head[_dayini]=_day
						_tls=_tls"|" 
					}
				}
				_body=_body""sprintf("[%13.13s] : |%s\n", c, _tls)
			}
			_lh=asorti(head, headidx)
			for (h=1;h<=_lh;h++) { 
				_hidx=headidx[h]
				_title=strftime("%B-%Y",_hidx)
				_long=length(_title)
				_head=_head""sprintf("%-"head[_hidx]"s|",_title" ["head[_hidx]"]" )
				_hsub=_hsub""sprintf("%"head[_hidx]"."head[_hidx]"s ", "--------------------------------------" ) 
			}
			printf "\n%s\n", _head
			printf "%s %s\n", "------------------", _hsub
			printf "%s", _body
			printf "%s %s\n", "------------------", _hsub
			print " "
		}'
}

###########################################
#               MAIN EXEC                 #
###########################################

############### REQUIREMENTS CHECK ##################

	[ "$_cyclops_ha" == "ENABLED" ] && ha_check $_command

	[ ! -f "$_config_path/audit/issuecodes.cfg" ] && echo "ERR: issue codes file doesn't exists, please create it" && exit 1

########### OPTIONS PROCESSING ############

	[ "$_opt_date_start" != "yes" ] && [ "$_opt_tkt" == "yes" ] && _par_date_start="ever" 
	[ "$_opt_date_start" != "yes" ] && [ "$_opt_tkt" != "yes" ] && _par_date_start="month"

	init_date $_par_date_start $_par_date_end
	
	if [ "$_par_code_pattern" == "help" ]
	then
		echo
		echo "Cyclops Audit Module"
		echo "Available codenames for show issues reports"
		echo ""
		awk -F\; 'BEGIN { print "CODENAME;| PATTERN\n-----------;|----------------" } $1 ~ "^[0-9a-z_-]+$" && NF == 2 { print $1";| "$2 }' $_config_path/audit/issuecodes.cfg | column -t -s\; 
		echo ""
		exit 0
	else
		[ ! -z "$_par_code_pattern" ] && _code_pattern=$( awk -F\; -v cp="$_par_code_pattern" 'NF == 2 && $1 !~ "^[ #]" && $1 == cp { _sd=$2 } END { print _sd }' $_config_path/audit/issuecodes.cfg )
		[ -z "$_code_pattern" ] && echo "Not have a valid issue code pattern" && exit 1
	fi


	[ ! -z "$_par_node" ] && _par_node=$( node_ungroup $_par_node | sed -e 's/ /$|^/g' -e 's,^,/,' -e 's,$,/,' )
	

################ LAUNCHING ###################

	echo ===============
	echo "PATTERN SEARCH: [$_par_code_pattern : $_code_pattern ]" 
	echo "DATE FILTER: [$_par_date_start] [$( date -d @$_date_tsb +%F\ %T)] TO [$( date -d @$_date_tse +%F\ %T)]"
	[ ! -z "$_par_easternegg" ] && echo "EASTERN EGG: ["$_par_easternegg"]"
	echo ===============
	
	case "$_par_show" in
	debug)
		sel_cod_in_range
	;;
	timeline)
		_codedata=$( sel_cod_in_range )

		if [ -z "$_codedata" ] 
		then
			echo -e "NO TICKETS FOUND\n"
		else
			echo
			format_timeline
		fi
	;;
	*)
		_codedata=$( sel_cod_in_range )

		if [ -z "$_codedata" ] 
		then
			echo -e "NO TICKETS FOUND\n"
		else
			format_output
		fi
	;;
	esac
