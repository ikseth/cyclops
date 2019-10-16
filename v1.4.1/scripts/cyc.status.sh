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

	_command_opts=$( echo "~$@~" | tr -d '~' | tr '@' '#' | awk -F\- 'BEGIN { OFS=" -" } { for (i=2;i<=NF;i++) { if ( $i ~ /^[a-z] / ) { gsub(/^[a-z] /,"&@",$i) ; gsub(/ $/,"",$i) ; gsub (/$/,"@",$i) }}; print $0 }' | tr '@' \' | tr '#' '@'  | tr '~' '-' ) 
	_command_name=$( basename "$0" )
	_command_dir=$( dirname "${BASH_SOURCE[0]}" )
	_command="$_command_dir/$_command_name $_command_opts"
	
	[ -f "/etc/cyclops/global.cfg" ] && source /etc/cyclops/global.cfg || _exit_code="111"
	[ ! -f "$_sensors_sot" ] && echo "ERR: Revise cyclops instalation" && exit 1 

	[ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
	[ -f "$_libs_path/node_group.sh" ] && source $_libs_path/node_group.sh || _exit_code="113"
	[ -f "$_libs_path/node_ungroup.sh" ] && source $_libs_path/node_ungroup.sh || _exit_code="114"
	[ -f "$_libs_path/init_date.sh" ] && source $_libs_path/init_date.sh || _exit_code="115"
	[ -f "$_color_cfg_file" ] && source $_color_cfg_file || _exit_code="116"
	

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

#
	_par_typ="status"
	_par_act="all"

	_cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":a:n:t:d:e:o:p:f:v:h:" _optname
do
        case "$_optname" in
		"a")
			_opt_act="yes"
			_par_act=$OPTARG
		;;
		"t")
			_opt_typ="yes"
			_par_typ=$OPTARG
		;;
		"o")
			_opt_opt="yes"
			_par_opt=$OPTARG
		;;
		"n")
			_opt_node="yes"
			_par_node=$OPTARG


		;;
		"d")
			_opt_date_start="yes"
			_par_date_start=$OPTARG
		;;
		"e")
			_opt_date_end="yes"
			_par_date_end=$OPTARG
		;;
		"v")
			_opt_shw="yes"
			_par_shw=$OPTARG
		;;
		"p")
			_opt_path="yes"
			_par_path=$OPTARG
		;;
		"f")
			_opt_filter="yes"
			_par_filter=$OPTARG
		;;
                "h")
                        _opt_help="yes"
                        _par_help=$OPTARG

                        case "$_par_help" in
                                        "des")
                                                echo "$( basename "$0" ) : Cyclops Global Status Tool"
                                                echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
                                                echo "  Global config path : $_config_path"
                                                echo "          Global config file: global.cfg"
						echo "	Cyclops dependencies:"
						echo "		Cyclops libs: $_libs_path"
						echo "		Cyclops Modules:"
						echo "			$_script_path/audit.nod.sh"
						echo "			$_stat_path/scripts/stats.slurm.total.jobs.sh"
						echo "		Tools:"
						echo "			$_tool_path/approved/test.productive.env.sh"
                                                echo

                                                exit 0
			esac
		;;
               ":")
                        case "$OPTARG" in
                        "h")
				echo
				echo "CYCLOPS GLOBAL STATUS COMMAND"
				echo "	Help to know any cyclops source status"
				echo "	Or a single way to know cyclops statistics"
				echo "	NOTE: if you want advanced stats use cyclops -h to use specific commads"
				echo "	NOTE: still not implemeted all options for all sources"
				echo
				echo "-a [option] Cyclops source to ask, can use more than one, comma separated"
				echo "	all: show all cyclops sources"
				echo "	node: Show node source"
				echo "	slurm: Show slurm service source"
				echo "	-t [status|stats|use|watt] Type of information"
				echo "		stats: show slurm statitics data"
				echo "		-o [option] filter available:"
				echo "			group=user: group by user"
				echo "			user=[user name]: filter by user"
				echo
				echo "	cyclops: Show cyclops source"
				echo "	audit: Show Audit source"
				echo "	-t [bitacora|codes], show several audit data types"
				echo "		bitacora: has filter options"
				echo "		-f [N][bitacora1,[bitacora2],[...]]: filter logbook that you want comma separated and put N capital for negate logbook"
				echo "		codeS: show audit code data"
				echo "		-o [open|close|stats|[code]], can add more than one comma separated"
				echo "			open|close, show open or close"
				echo "			stats, show statistics info"
				echo "			[code], select one exiting code"
				echo "	critical: Show critical environment source"
				echo "	system: Show data from system source"
				echo "	-t [status|use] Type of information"
				echo
				echo "-d [option] date start or date range"
				echo "	*[0-9]hour: last n hours before actual time"
				echo "	day: last 24 hours"
				echo "	week: last seven days"
				echo "	month: last thirty days"
				echo "	year: last 365 days"
				echo "	[Mmm]-[YYYY]: to select specific month"
				echo "	[YYYY]: to select specific year"
				echo "	[YYYY-MM-DD]: date start format"
				echo "-e [YYYY-MM-DD] end date, only works with date start format"
				echo 
				echo "-n [node|node range] node filter"
				echo "	You can use @[group or family name] to define range node"
				echo "	and you can use more than one group/family comma separated"
				echo 
				echo
				echo "-h [|des] help is help"
				echo "	des: detailed help about this command"
				echo
			
				exit 0
			;;
			esac
		;;
	esac
done

shift $((OPTIND-1))

#### FUNCTIONS ####

cyclops_status()
{

	if [ -f "$_sensors_sot" ]
	then
		_cyccodes=$( grep "^[0-9][0-9][0-9][0-9]" /etc/cyclops/system/cyc.codes.cfg | cut -d';' -f1 )
		_cyccodes_status=$( awk -F\; -v _cc="${_cyccodes}" '
			BEGIN { 
				_ct=split(_cc,c,"\n") ; 
				_ok=0 ; 
				_bad=0 
			} $1 == "CYC" { 
				_to=0 ; 
				_tb=0 ; 
				for ( i in c ) { 
					if ( c[i] == $2 ) { 
						_to=1 
					}
				} ; 
				if ( _to == 1 ) { 
					_ok++ 
				} else { 
					_bad++ 
				}
			} END { 
				if ( _ok == _ct ) { 
					print "0" 
				} else { 
					if ( _bad == _ct ) {
						print "ALL"
					} else {
						print _bad
					}
				} 
			}' $_sensors_sot )

		case "$_cyccodes_status" in
		0)
			_cycstatus=$_sh_color_green"GOOD"$_sh_color_nformat
		;;
		[0-9]*|ALL)
			_cycstatus=$_sh_color_red"BAD"$_sh_color_nformat
			_cycstatus_msg="MISS $_cyccodes_status CYCLOPS CODES: VERIFY $_sensors_sot FILE, USE INSTALL README"
		;;
		*)
			_cycstatus=$_sh_color_red"CRITICAL"$_sh_color_nformat
			_cycstatus_msg="UNKNOWN ERROR, CHECK CYCLOPS INSTALL"
		;;
		esac	
	else
		_cycstatus=$_sh_color_red"CRITICAL"$_sh_color_nformat
		_cycstatus_msg="MISS $_sensors_sot FILE, CHECK CYCLOPS INSTALL"
	fi

	echo
	echo -e $_sh_color_bolt"CYCLOPS: STATUS: $_cycstatus"$_sh_color_nformat
	echo -e $_sh_color_bolt"------------------------"$_sh_color_nformat
	[ ! -z "$_cycstatus_msg" ] && echo -e $_cycstatus_msg
	echo


	unset _tit 
	unset _status 

	[ ! -f "$_sensors_sot" ] && echo "ERR: revise cyclops configuration" && exit 1

	_sot_codes=$( awk -F\; '$1 ~ "[0-9]+" { print $0 }' $_sensors_sot_codes_file )
	
	awk -F\; -v _sc="${_sot_codes}" -v _cg="$_sh_color_green" -v _cy="$sh_color_gray" -v _nf="$_sh_color_nformat" '
		BEGIN {
			split(_sc,sc,"\n") 
			for ( s in sc ) {
				split(sc[s],ln,";") ;
				code[ln[1]]=ln[4] ;
				if ( ln[5] != "" ) { des[ln[1]]=ln[5] }
			} 
		} $1 == "CYC" && $2 != "0002" { 
			if ( code[$2] != "" ) {
				_field="" ; _f2c=""
				if ( $5 != "" ) { _field="[ "des[$2]" : "$5" ]" } ; 
				if ( $4 == "ENABLED" ) { _f2c=_cg }
				if ( $4 == "DISABLED" ) { _f2c=_cy }
				printf "%-35s %s%10s%s %s\n", code[$2], _f2c, $4, _nf, _field
			}
		}' $_sensors_sot  

	echo

}

audit_status()
{

	_cmd_audit_status="-v eventlog -f bitacora "$( [ ! -z "$_par_node" ] && echo "-n $_par_node" )
	_audit_status=$( eval exec $_script_path/audit.nod.sh $_cmd_audit_status 2>/dev/null | awk -F\; -v _tsb="$_date_tsb" -v _tse="$_date_tse" -v _fil="$_par_filter" '
		BEGIN { 
			_lf=split(_fil,filtro,",")
			if ( _lf != 0 ) {
				for ( z in filtro ) {
					if ( filtro[z] ~ "^N" ) {
						_cn++
					}
				}
				_cp=_lf-_cn
			} 
		} $1 >= _tsb && $1 <= _tse {
			if ( _lf == 0 ) {
				print strftime("%Y-%m-%d;%H:%M",$1)";"$3";"$4";"$6";"$5
			} else {
				_mn=0 ; _mp=0
				if ( _cp > 0 ) { _mp=0 } else { _mp=1 } ;
				for ( i in filtro ) {
					if ( filtro[i] ~ "^N" ) {
						_neg=filtro[i]
						gsub(/^N/,"",_neg) ;	
						if ( $3 == _neg ) { 
							_mn=1
						}
					} else {
						if ( $3 == filtro[i] )  {
							_mp=1
						}
					}
				}
				if ( _mn == 0 && _mp == 1 ) { print strftime("%Y-%m-%d;%H:%M",$1)";"$3";"$4";"$6";"$5 }
			}
		}' | sort -t\; -k1,1n -k1,2nr 
	)

	echo
	echo -e $_sh_color_bolt"AUDIT: STATUS"$_sh_color_nformat
	echo -e $_sh_color_bolt"-------------"$_sh_color_nformat
	echo
	[ ! -z "$_par_date_start" ] && echo -e "FILTER: Date Range: $_par_date_start\n" 
	echo "BITACORA DATA :"

	echo "${_audit_status}" | awk -F\; -v _ss="$( tput cols )" -v _nf="$_sh_color_nformat" -v _gc="$_sh_color_green" -v _rc="$_sh_color_red" -v _yc="$_sh_color_yellow" -v _ggc="$_sh_color_gray" -v _cc="$_sh_color_cyc" '
		BEGIN { 
			printf "%-10s %-10s %-14s %-12s %-6s %s\n", "Date", "Hour", "Source", "Type", "Status", "Message"
			printf "%-10s %-11s %-14s %-12s %-6s %s\n", "----------", "---------", "--------------", "------------", "------", "-------"
			_ajuste=0 ;
			_ls=10+1+5+1+4+1+14+1+12+1+6+1+_ajuste ;
			for (s=1;s<=_ls-_ajuste;s++) { _space=_space" " } ;
			_l=_ss-_ls ; 
		} NR > 1 { 
			if ( $0 == _lold ) {
				_c++ 
			} else {
				split(_lold,campo,";") ;
				_date=campo[1] ;
				_time=campo[2] ;
				if ( _date == _date_old ) { _date=" " } else { _date_old=_date }        
				_fs=length(campo[6]) ; 
				split(campo[6],chars,"") ; 
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
				if ( _c == 0 ) { _p="" } else { _p="["_c+1"]" }
				_f2c="" ; _f3c="" ; _f4c="" ; _f5c=""
				if ( campo[4] == "INFO" || campo[4] == "DISABLE" ) { _f4c=_ggc }
				if ( campo[5] == "INFO" || campo[5] == "CLOSE" ) { _f5c=_ggc }
				if ( campo[4] == "ENABLE" ) { _f4c=_gc ; _f3c=_gc ; _f2c=_gc }
				if ( campo[5] ~ /OK|UP/ ) { _f5c=_gc ; _f3c=_gc ; _f2c=_gc }
				if ( campo[4] ~ /INTERVENTION|ALERT|REPAIR|TESTING/ ) { _f4c=_yc ; _f3c=_yc ; _f2c=_yc }
				if ( campo[5] == "FAIL" ) { _f5c=_yc ; _f3c=_yc ; _f2c=_yc }
				if ( campo[4] == "ISSUE" ) { _f4c=_rc ; _f3c=_rc ; _f2c=_rc } 
				if ( campo[5] == "SOLVED" ) { _f5c=_gc ; _f3c=_gc ; _f2c=_gc }
				if ( campo[5] == "DOWN" ) { _f5c=_rc ; _f3c=_rc ; _f2c=_rc }
				if ( campo[3] == "cyclops" ) { _f3c=_cc }
				printf "%10s %s%5s%s %-4s %s%-14.14s%s %s%-12.12s%s %s%-6.6s%s %s%s\n", _date, _f2c, _time, _nf, _p, _f3c, campo[3], _nf, _f4c, campo[4], _nf, _f5c, campo[5], _nf, _f, _w;
				_c=0 ;
				_lold=$0
			}
		} NR == 1 { 
			_lold=$0 
		} END {
				split(_lold,campo,";") ;
				_date=campo[1] ;
				_time=campo[2] ;
				if ( _date == _date_old ) { _date=" " } else { _date_old=_date }        
				_fs=length(campo[6]) ; 
				split(campo[6],chars,"") ; 
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
				if (( _long + _ws ) > _l ) { _w="\n"_space""_w }
				if ( _c == 0 ) { _p="" } else { _p="["_c+1"]" }
				_f2c="" ; _f3c="" ; _f4c="" ; _f5c=""
				if ( campo[4] == "INFO" || campo[4] == "DISABLE" ) { _f4c=_ggc }
				if ( campo[5] == "INFO" || campo[5] == "CLOSE" ) { _f5c=_ggc }
				if ( campo[4] == "ENABLE" ) { _f4c=_gc ; _f3c=_gc ; _f2c=_gc }
				if ( campo[5] ~ /OK|UP/ ) { _f5c=_gc ; _f3c=_gc ; _f2c=_gc }
				if ( campo[4] ~ /INTERVENTION|ALERT|REPAIR|TESTING/ ) { _f4c=_yc ; _f3c=_yc ; _f2c=_yc }
				if ( campo[5] == "FAIL" ) { _f5c=_yc ; _f3c=_yc ; _f2c=_yc }
				if ( campo[4] == "ISSUE" ) { _f4c=_rc ; _f3c=_rc ; _f2c=_rc } 
				if ( campo[5] == "SOLVED" ) { _f5c=_gc ; _f3c=_gc ; _f2c=_gc }
				if ( campo[5] == "DOWN" ) { _f5c=_rc ; _f3c=_rc ; _f2c=_rc }
				if ( campo[3] == "cyclops" ) { _f3c=_cc }
				printf "%10s %s%5s%s %-4s %s%-14.14s%s %s%-12.12s%s %s%-6.6s%s %s%s\n", _date, _f2c, _time, _nf, _p, _f3c, campo[3], _nf, _f4c, campo[4], _nf, _f5c, campo[5], _nf, _f, _w;
		}' 

}

audit_codes()
{
	[ -z "$_codes" ] && _codes=$( awk -F\; '$1 !~ "#" && $1 ~ "[a-zA-Z0-9]+" { print $1 }' $_config_path_aud/issuecodes.cfg )
	[ -z "$_codes" ] && echo "ERR: No codes defined, please add it in $_config_path_aud/issuecodes.cfg file" && exit 1
	for _code in $( echo "${_codes}" ) 
	do
		eval $_script_path/audit.code.sh -c $_code -d $_par_date_start $_audit_special_opts 
	done
}

critical_env()
{
	echo
	echo -e $_sh_color_bolt"CRITICAL ENVIRONMENT: STATUS"$_sh_color_nformat
	echo -e $_sh_color_bolt"----------------------------"$_sh_color_nformat
	echo

	_critical_env=$( $_tool_path/approved/test.productive.env.sh -t pasive -v commas | awk '$1 !~ /date|analisys/ { print $0 }' )

	for _lin in $( echo "${_critical_env}" )
	do
		_group=$( echo "$_lin" | cut -d';' -f1 )
		_status=$( echo "$_lin" | cut -d';' -f2 )

		echo -e $_group";"$( [ "$_status" == "OPERATIVE" ] && echo $_sh_color_green || echo $_sh_color_red )$_status$_sh_color_nformat

	done | column -t -s\;
}

node_real_status()
{
	[ ! -f "$_type" ] && echo "ERR: Revise cyclops configuration" >&2 && exit 1 

	if [ "$_opt_path" == "yes" ] 
	then
		[ -f "$_mon_history_path/$_par_path" ] && _mon_nod_file=$_mon_history_path/$_par_path || _mon_nod_file=$_mon_path/monnod.txt
	else
		_mon_nod_file=$_mon_path/monnod.txt
	fi

	_critical_st_simp=$( $_tool_path/approved/test.productive.env.sh -t pasive -v simple 2>/dev/null )
	_critical_st_color=$( echo "$_critical_st_simp" | awk -F\; -v _g="$_sh_color_green" -v _f="$_sh_color_yellow" -v _r="$_sh_color_red" '
		{ 
			if ( $4 == "NOT OPERATIVE"  ) { _cs=_r } ;
			if ( $4 == "OPERATIVE WITH WARNINGS" ) { _cs=_f } ;
			if ( $4 == "OPERATIVE" ) { _cs=_g } ;
		} END {
			print _cs 
		}'  ) 

	if [ "$_opt_node" == "yes" ]
	then
		_node_list=$( node_ungroup $_par_node | tr ' ' ',' | sed 's/,$//' )
		_node_list=$( awk -F\; -v _nl="$_node_list" '
			BEGIN { 
				split (_nl,n,",") 
			} $1 !~ "#" { 
				for ( i in n ) { if ( $2 == n[i] ) { print $0 } }
			}' $_type 
			)
	else
		_node_list=$( cat $_type | grep -v "#" )
	fi

	_node_last_up=$( [ -f "$_mon_nod_file" ] && /usr/bin/stat -c %Y $_mon_nod_file || echo 0 )
	_node_last_st=$( echo "$_node_last_up" | awk -v _g="$_sh_color_green" -v _r="$_sh_color_red" 'BEGIN { _now=systime() } { if ( $1 < _now-300 )  { _s=_r } else { _s=_g }} END { print _s }' ) 

	_node_last_up=$( date -d @$_node_last_up +%Y-%m-%d\ %H:%M:%S )

	_node_real_status=$( 
		cat $_mon_nod_file 2>/dev/null | 
		tr '|' ';' | 
		grep ";" | 
		sed -e 's/\ *;\ */;/g' -e '/^$/d' -e '/:wiki:/d' -e "s/$_color_disable/DISABLE/g" -e "s/$_color_unk/UNK/g" -e "s/$_color_up/UP/g" -e "s/$_color_down/DOWN/g" -e "s/$_color_mark/MARK/g" -e "s/$_color_fail/FAIL/g" -e "s/$_color_check/CHECK/g" -e "s/$_color_ok/OK/g" -e "s/$_color_disable/DISABLE/" -e "s/$_color_title//g" -e "s/$_color_header//g" -e 's/^;//' -e 's/;$//' -e '/</d' -e 's/((.*))//' -e '/:::/d' | 
		awk -F\; ' 
			BEGIN { 
				OFS=";" ; 
				_print=0 
		} { 
			if ( $1 == "family" ) { _print=1 } ; 
			if ( $2 == "name" ) { _print=0 } ; 
			if ( _print == 1 ) { print $0 } 
		}' | 
		awk -F\; '
			$1 == "family" { 
				_sq=0 ;
				_nsi=0 ;
				for (i=1;i<=NF;i++) { 
					a[i]=$i ; 
					if ( $i == "slurm_status" ) { _sq=i }; 
					if ( $i == "uptime" ) { _nsi=i };
				} 
			} $1 != "family" { 
				for (i=1;i<=NF;i++) { 
					if ( $i ~ "FAIL" || $i ~ "DOWN" ) { _sens=_sens""a[i]"," } ;
				} ;
				if ( _sq != "0" ) { 
					split($_sq,ss," ") ;
					_sls=$_sq ;
					gsub(/^[A-Za-z]+ /,"",_sls) ;
					if ( ss[2] != "" ) { _wn=_sls } else { _wn="n/a" } ;
				} else { 
					_wn="n/a" ; 
				} ;
				if ( _nsi != "0" ) {
					_ns=$_nsi
				} ;
				split($2,n," ");
				if ( $2 ~ "UP" || $2 ~ "DOWN" || $2 ~ "FAIL" ) {
					_ns=n[1]
				} else {
					split(_ns,st," ") ; 
					_ns=st[2] ;
					if ( $2 ~ "DISABLE" && _ns ~ "MAINTENANCE" ) { _ns="POWER_OFF" } ;
				}
				print _ns";"n[2]";"_wn";"_sens ; 
				_sens="" ; 
			}'
		)

	for _node_data in $( echo "${_node_list}" )
	do
		_node_nam=$( echo $_node_data | cut -d';' -f2 )
		_node_grp=$( echo $_node_data | cut -d';' -f4 )
		_node_fam=$( echo $_node_data | cut -d';' -f3 )
		[ "$_opt_path" == "yes" ] && _node_mng="n/a" || _node_mng=$( echo $_node_data | cut -d';' -f7 )

		_node_std=$( echo "${_node_real_status}" | awk -F\; -v _n="$_node_nam" '$2 == _n { print $1";"$3";"$4 }') 

		if [ -z "$_node_std" ] 
		then
			_node_sta="NO DATA"
			_node_err="NO DATA"
			_node_slm="NO DATA"
		else
			_node_sta=$( echo $_node_std | cut -d';' -f1 )
			_node_slm=$( echo $_node_std | cut -d';' -f2 )
			_node_err=$( echo $_node_std | cut -d';' -f3 | sed 's/,$//' )
		fi

		_new_line=${_new_line}$_node_grp";"$_node_fam";"$_node_nam";"$_node_mng";"$_node_sta";"$_node_slm";"$_node_err"\n"
	done 

	_node_status=$( echo -e "${_new_line}" | sed '/^$/d' |  awk -F\; '{ _t[$1":"$2":"$4":"$5":"$6":"$7]=_t[$1":"$2":"$4":"$5":"$6":"$7]$3"," } END { for ( i in _t ) { print i":"_t[i] }}' | sed 's/,$//' | sort -t\: )

	_new_line="Group;Family;Qty;Mngt Cfg;Status;Slurm;Node Range;Errors\n------;-------;---;----------;--------;------;-------------;------\n"

	for _line in $( echo "${_node_status}" )
	do
		_node_adm=$( echo $_line | cut -d':' -f3 | tr [:lower:] [:upper:] )
		_node_grp=$( echo $_line | cut -d':' -f1 )
		_node_fam=$( echo $_line | cut -d':' -f2 )
		_node_sta=$( echo $_line | cut -d':' -f4 )
		_node_slm=$( echo $_line | cut -d':' -f5 ) 
		_node_err=$( echo $_line | cut -d':' -f6 ) 
		_node_lst=$( echo $_line | cut -d':' -f7 )
		
		_node_rng=$( node_group $_node_lst )
		_node_qty=$( echo "${_node_lst}" | tr ',' '\n'  | wc -l )

		if [ "$_node_grp" != "$_old_grp" ] 
		then
			_old_grp=$_node_grp 
			_print_grp=$_old_grp
			_extra_line="; \n"
		else
			_print_grp=" "
			_extra_line=""
		fi

		[ -z "$_node_err" ] && _node_err=" " 
		[ "$_node_sta" == "UP" ] && _node_sta="OK"

		_new_line=${_new_line}""$_extra_line""$_print_grp';'$_node_fam';'$_node_qty';'$_node_adm';'$_node_sta';'$_node_slm';'$_node_rng';'$_node_err'\n'

	done 

	_monnod_status=$( awk -F\; -v _sg="$_sh_color_green" -v _sr="$_sh_color_red" -v _sn="$_sh_color_nformat" '
		$1 == "CYC" && $2 == "0012" { 
			if ( $4 == "ENABLED" ) { 
				print _sg""$4""_sn 
			} else { 
				print _sr""$4""_sn 
			}
		}' $_sensors_sot )
	_cyc_status=$( awk -F\; -v _sg="$_sh_color_green" -v _sr="$_sh_color_red" -v _sn="$_sh_color_nformat" '
		$1 == "CYC" && $2 == "0001" { 
			if ( $4 == "ENABLED" ) { 
				print _sg""$4""_sn 
			} else { 
				print _sr""$4""_sn 
			}
		}' $_sensors_sot )

	echo
	echo -e $_sh_color_bolt"NODE: STATUS"$_sh_color_nformat
	echo -e $_sh_color_bolt"------------"$_sh_color_nformat
	echo
	echo -e "CYCLOPS STATUS :	$_cyc_status"
	echo -e "NODE MONITORING: 	$_monnod_status" 
	echo -e "LAST UPDATE: 		$_node_last_st$_node_last_up$_sh_color_nformat"
	echo -e "CRITICAL ENV STATUS: 	$_critical_st_color$( echo "${_critical_st_simp}" | cut -d';' -f4  )$_sh_color_nformat"
	echo
	[ "$_opt_node" == "yes" ] && echo -e "FILTER: "$_par_node"\n"
	echo -e "${_new_line}" | awk -F\; -v _nf="$_sh_color_nformat" -v _gc="$_sh_color_green" -v _rc="$_sh_color_red" -v _yc="$_sh_color_yellow" -v _ggc="$_sh_color_gray" '{
		_f2c="" ; _f4c="" ; _f5c="" ; _f6c="" ; _f7c="" ; _f8c=""
		if ( NR > 3 ) {
			if ( $6 == "n/a" ) { _f6c=_ggc }
			if ( $4 == "UP" ) { _f4c=_gc }
			if ( $4 == "DOWN" || $4 == "FAIL" ) { _f4c=_rc } 
			if ( $4 == "DIAGNOSE" || $4 == "REPAIR" || $4 == "LINK" || $4 == "UNLINK" ) {
				_f2c=_yc ;
				_f4c=_yc ;
				_f5c=_yc ;
				_f6c=_yc ;
				_f7c=_yc ;
			} else {
				_f2c=_gc ;
				_f7c=_gc ;
				if ( $6 == "working" || $6 == "go to drain" ) { _f6c=_yc ; _f7c=_yc }
			}
			if ( $4 == "UP" ) {
				if ( $5 == "MAINTENANCE" || $5 == "LINK" || $5 == "REPAIR" ) { _f5c=_yc ; _f6c=_yc ; _f7c=_yc } 
			}
			if ( $4 == "DRAIN" ) {
				_f2c=_ggc ; 
				_f4c=_ggc ;
				_f5c=_ggc ; 
				_f6c=_ggc ;
				_f7c=_ggc ;
				if ( $6 != "maintenance" && $6 != "n/a" ) { _f6c=_rc ; _f7c=_rc } ;
			} 
			if ( $5 == "OK" ) { _f5c=_gc }
			if ( $5 == "DOWN" || $5 == "FAIL" ) { _f5c=_rc ; _f2c=_rc ; _f4c=_rc  }
			if ( $6 == "idle" ) { _f6c=_gc }
			if ( $8 != " " ) { _f8c=_rc }
		}
		printf "%-15.15s %s%-12.12s%s %3s %s%10s%s %s%12s%s %s%12.12s%s\t%s%-30s%s %s%s%s\n", $1, _f2c, $2, _nf, $3, _f4c, $4, _nf, _f5c, $5, _nf, _f6c, $6, _nf, _f7c, $7, _nf, _f8c, $8, _nf ; 
	}'

	echo

}

slurm_activity()
{

	[ ! -f "$_pg_dashboard_log" ] && echo "ERR: Dashboard log plugin doesn't exits" >&2 && exit 1

	_slurm_activity=$( cat $_pg_dashboard_log | 
				sed -e 's/ //g'  -e 's/\%//' | 
				awk -F\: -v _dr="$_date_filter" -v _tsb="$_date_tsb" -v _tse="$_date_tse" '
					BEGIN { 
						_to="START" ; 
						t=0 ; 
						a=1 
					} $1 > _tsb && $1 < _tse { 
						if ( _dr == "year" ) { _time=strftime("%Y;%m_%b",$1) } ; 
						if ( _dr == "month" ) { _time=strftime("%Y-%m_%b;%d",$1) } ; 
						if ( _dr == "week" ) { _time=strftime("%Y-%m;%d_%a",$1) } ; 
						if ( _dr == "day" ) { _time=strftime("%Y-%m-%d;%Hh",$1) } ; 
						if ( _dr == "hour" ) { _time=strftime("%Y-%m-%d;%H:%M",$1) } ;
						split($6,d,"=") ;
						if ( _to != _time ) { 
							print _to"="t/a ; 
							_to=_time ; 
							t=d[2] ; 
							a=1  
						} else { 
							t=t+d[2] ; 
							a++ 
						}
					} END { 
						print _to"="t/a 
					}' | 
				grep -v START ) 

	case "$_par_shw" in
	commas)
		_slurm_output=$( echo "${_slurm_activity}" | tr '=' ';' | sed -e 's/;/\-/' -e 's/_[A-Z][a-z][a-z]//' -e 's/$/\%/' )
	;;
	*)
		_slurm_output=$( echo "${_slurm_activity}" | 
				awk -F\; -v _g="$_sh_color_green" -v _r="$_sh_color_red" -v _y="$_sh_color_yellow" -v _n="$_sh_color_nformat" '
					{ 
						split($2,a,"=") ; 
						split(a[2],b,".") ; 
						if ( b[1] > 30 ) {
							split(b[1]/1.5,y,".")
							split(b[1]/1.02,r,".")
						} else {
							y[1]=20
							r[1]=40
						}
						if ( b[1] <= 50 ) { _tp=_g""b[1]"%"_n ; hp=a[1] } ;
						if ( b[1] > 50 ) { _tp=_y""b[1]"%"_n ; hp=a[1] } ; 
						if ( b[1] > 75 ) { _tp=_r""b[1]"%"_n ; hp=_r""a[1]_n } ; 
						for (i=1;i<=b[1];i++) { 
							if ( i == 1 ) { _t=_g"|" } ;
							if ( i == y[1] ) { _t=_t""_n""_y } ;
							if ( i == r[1] ) { _t=_t""_n""_r } ;
							_t=_t"|" ; 
							if ( i == b[1] ) { _t=_t""_n } ;
							} ; 
						if ( _do != $1 ) { _do=$1 ; _pdo=_do } else { _pdo=" " } ; 
						printf "%-12s %-3s::%-s %-s\n",_pdo, hp, _t, _tp ; 
						_t="" 
					}' 
			)
	;;
	esac

	echo
	echo -e $_sh_color_bolt"SLURM CLUSTER: ACTIVE NODES"$_sh_color_nformat
	echo -e $_sh_color_bolt"---------------------------"$_sh_color_nformat
	echo
	echo -e "\tFILTER: DATE: $_par_date_start\n" 
	echo "${_slurm_output}"
	echo
}

system_avail()
{
	[ ! -f "$_pg_dashboard_log" ] && echo "ERR: Dashboard log plugin doesn't exits" >&2 && exit 1

	_system_avail=$( cat $_pg_dashboard_log | 
				sed -e 's/ //g'  -e 's/\%//' | 
				awk -F\: -v _dr="$_date_filter" -v _tsb="$_date_tsb" -v _tse="$_date_tse" '
					BEGIN { 
						_to="START" ; 
						t=0 ; 
						a=1 ; 
					} $1 > _tsb && $1 < _tse { 
						if ( _dr == "year" ) { _time=strftime("%Y;%m_%b",$1) } ; 
						if ( _dr == "month" ) { _time=strftime("%Y-%m_%b;%d",$1) } ; 
						if ( _dr == "week" ) { _time=strftime("%Y-%m;%d_%a",$1) } ; 
						if ( _dr == "day" ) { _time=strftime("%Y-%m-%d;%Hh",$1) } ; 
						if ( _dr == "hour" ) { _time=strftime("%Y-%m-%d;%H:%M",$1) } ;
						split($4,d,"=") ;
						if ( _to != _time ) { 
							print _to"="t/a ; 
							_to=_time ; 
							t=d[2] ; 
							a=1  
						} else { 
							t=t+d[2] ; 
							a++ 
						}
					} END { 
						print _to"="t/a 
					}' | 
				grep -v START ) 

	case "$_par_shw" in
	commas)
		_system_output=$( echo "${_system_avail}" | tr '=' ';' | sed -e 's/;/\-/' -e 's/_[A-Z][a-z][a-z]//' -e 's/$/\%/' )
	;;
	*)
		_system_output=$( echo "${_system_avail}" | 
				awk -F\; -v _g="$_sh_color_green" -v _r="$_sh_color_red" -v _y="$_sh_color_yellow" -v _n="$_sh_color_nformat" '
					{ 
						split($2,a,"=") ; 
						split(a[2],b,".") ; 
						if ( b[1] < 90 && b[1] >= 65 ) { _tp=_y""b[1]"%"_n ; hp=a[1] ; _ln=_y } ; 
						if ( b[1] < 65 ) { _tp=_r""b[1]"%"_n ; hp=a[1] ; _ln=_r } ;
						if ( b[1] >= 90 ) { _tp=_g""b[1]"%"_n ; hp=a[1] ; _ln=_g } ; 
						for (i=1;i<=b[1];i++) { 
							if ( i == 1 ) { _t=_ln"|" } ;
							_t=_t"|" ; 
							if ( i == b[1] ) { _t=_t""_n } ;
							} ; 
						if ( _do != $1 ) { _do=$1 ; _pdo=_do } else { _pdo=" " } ; 
						printf "%-12s %-3s::%-s %-s\n",_pdo, hp, _t, _tp ; 
						_t="" 
					}' 
			)
	;;
	esac

	echo
	echo -e $_sh_color_bolt"SYSTEM: HOST/NODE AVAILABILITY AVERAGE"$_sh_color_nformat
	echo -e $_sh_color_bolt"--------------------------------------"$_sh_color_nformat
	echo
	echo -e "\tFILTER: DATE: $_par_date_start\n" 
	echo "${_system_output}"
	echo
}

system_use()
{
	[ ! -f "$_pg_dashboard_log" ] && echo "ERR: Dashboard log plugin doesn't exits" >&2 && exit 1

	_system_use=$( cat $_pg_dashboard_log | 
				sed -e 's/ //g'  -e 's/\%//' | 
				awk -F\: -v _dr="$_date_filter" -v _tsb="$_date_tsb" -v _tse="$_date_tse" '
					BEGIN { 
						_to="START" ; 
						t=0 ; 
						a=1 
					} $1 > _tsb && $1 < _tse { 
						if ( _dr == "year" ) { _time=strftime("%Y;%m_%b",$1) } ; 
						if ( _dr == "month" ) { _time=strftime("%Y-%m_%b;%d",$1) } ; 
						if ( _dr == "week" ) { _time=strftime("%Y-%m;%d_%a",$1) } ; 
						if ( _dr == "day" ) { _time=strftime("%Y-%m-%d;%Hh",$1) } ; 
						if ( _dr == "hour" ) { _time=strftime("%Y-%m-%d;%H:%M",$1) } ;
						split($7,d,"=") ;
						if ( _to != _time ) { 
							print _to"="t/a ; 
							_to=_time ; 
							t=d[2] ; 
							a=1  
						} else { 
							t=t+d[2] ; 
							a++ 
						}
					} END { 
						print _to"="t/a 
					}' | 
				grep -v START ) 

	case "$_par_shw" in
	commas)
		_system_output=$( echo "${_system_use}" | tr '=' ';' | sed -e 's/;/\-/' -e 's/_[A-Z][a-z][a-z]//' -e 's/$/\%/' )
	;;
	*)
		_system_output=$( echo "${_system_use}" | 
				awk -F\; -v _g="$_sh_color_green" -v _r="$_sh_color_red" -v _y="$_sh_color_yellow" -v _n="$_sh_color_nformat" '
					{ 
						split($2,a,"=") ; 
						split(a[2],b,".") ; 
						if ( b[1] > 30 ) {
							split(b[1]/1.5,y,".")
							split(b[1]/1.02,r,".")
						} else {
							y[1]=20
							r[1]=40
						}
						if ( b[1] < 50 ) { _tp=_g""b[1]"%"_n ; hp=a[1] } ;
						if ( b[1] >= 50 ) { _tp=_y""b[1]"%"_n ; hp=a[1] } ; 
						if ( b[1] >= 75 ) { _tp=_r""b[1]"%"_n ; hp=_r""a[1]_n } ; 
						for (i=1;i<=b[1];i++) { 
							if ( i == 1 ) { _t=_g"|" } ;
							if ( i == y[1] ) { _t=_t""_n""_y } ;
							if ( i == r[1] ) { _t=_t""_n""_r } ;
							_t=_t"|" ; 
							if ( i == b[1] ) { _t=_t""_n } ;
							} ; 
						if ( _do != $1 ) { _do=$1 ; _pdo=_do } else { _pdo=" " } ; 
						printf "%-12s %-3s::%-s %-s\n",_pdo, hp, _t, _tp ; 
						_t="" 
					}' 
			)
	;;
	esac

	echo
	echo -e $_sh_color_bolt"SYSTEM: CPU ACTIVITY AVERAGE"$_sh_color_nformat
	echo -e $_sh_color_bolt"----------------------------"$_sh_color_nformat
	echo
	echo -e "\tFILTER: DATE: $_par_date_start\n" 
	echo "${_system_output}"
	echo
}

slurm_consumption()
{
	[ -z "$_slurm_group" ] && _slurm_group=$_date_filter 
	[ ! -f "$_stat_main_cfg_file" ] && echo "ERR: Slurm main config doesn't exits" && exit 1

	_slurm_cfg=$( cat $_stat_main_cfg_file | awk -F\; '$2 == "slurm" { print $3 }' )
	_slurm_sources=$( cat $_config_path_sta/$_slurm_cfg | awk -F\; '$1 ~ "[0-9]" { print $4 }')
	
	for _slurm_src in $( echo "${_slurm_sources}" )
	do
	
		_slurm_exec_opts=" -s "$_slurm_src" -b "$_date_start" -f "$_date_end" -g day -v commas -x "$( [ ! -z "$_slurm_filter_usr" ] && echo "-u "$_slurm_filter_usr )
		_slurm_cons_data=$_slurm_cons_data"\n"$( eval exec $_stat_path/scripts/stats.slurm.total.jobs.sh $_slurm_exec_opts )

	done

	_slurm_cons_data=$( echo -e "${_slurm_cons_data}" | cut -d';' -f1,3 | sort -n -t\; | 
				sed -e '/^$/d' |
				awk -F\; -v _dr="$_slurm_group" '
					BEGIN { 
						t=0 ; 
						a=1 ;
					} {
						if ( _dr == "year" ) {
							split($1,dti,"-")
							_time=dti[1]"-"dti[2] ;
						} else {
							_time=$1 ; 
						}
						if ( _to != _time ) { 
							print _to"="t/a ; 
							_to=_time ; 
							t=$2 ; 
							a=1 ;
						} else { 
							t=+$2 ; 
							a++ ;
						}
					} END { 
						print _to"="t/a 
					}' | 
				grep -v "^=0" )

	case "$_par_shw" in
	commas)
		_slurm_output=$( echo "${_slurm_cons_data}" | tr '=' ';' | sed 's/$/\%/' )
	;;
	graph)
		_slurm_output=$( echo "${_slurm_cons_data}" | 
						awk -v _g="$_sh_color_green" -v _r="$_sh_color_red" -v _y="$_sh_color_yellow" -v _n="$_sh_color_nformat" '
						{ 
							split($1,a,"=") ; 
							split(a[2],b,".") ; 
							if ( b[1] > 30 ) {
								split(b[1]/1.5,y,".")
								split(b[1]/1.02,r,".")
							} else {
								y[1]=20
								r[1]=40
							}
							if ( b[1] <= 50 ) { _tp=_g""b[1]"%"_n ; hp=a[2]" h" } ;
							if ( b[1] > 50 ) { _tp=_y""b[1]"%"_n ; hp=a[2]" h" } ; 
							if ( b[1] > 75 ) { _tp=_r""b[1]"%"_n ; hp=_r""a[2]" h"_n } ; 
							for (i=1;i<=b[1];i++) { 
								if ( i == 1 ) { _t=_g"|" } else { _t=_t"|" } ;
								if ( i == y[1] ) { _t=_t""_n""_y } ;
								if ( i == r[1] ) { _t=_t""_n""_r } ;
								if ( i == b[1] ) { _t=_t""_n } ;
								} ; 
							if ( _do != $1 ) { _do=a[1] ; _pdo=_do } else { _pdo=" " } ; 
							printf "%-12s::%-s %-s\n",_pdo,_t , _tp ; 
							_t="" 
						}' 
				)
	;;
	*)
		_slurm_output=$( echo -e "date=kjulius\n----=-------\n${_slurm_cons_data}" | column -t -s\= )
	;;
	esac

	echo
	echo -e $_sh_color_red"EXPERIMENTAL - STILL NOT OPERATIVE\n"$_sh_color_nformat
	echo -e $_sh_color_bolt"SLURM CLUSTER: SLURM ENERGY CONSUMPTION"$_sh_color_nformat
	echo -e $_sh_color_bolt"---------------------------------------"$_sh_color_nformat
	echo
	echo -e "\tSOURCES: [$( echo "${_slurm_sources}" | tr '\n' ',' | sed 's/,$//' )]"
	echo -e "\tFILTER: DATE: $_par_date_start" 
	[ ! -z "$_slurm_filter_usr" ] && echo -e "\tFILTER USER: "$_slurm_filter_usr
	echo 
	echo "${_slurm_output}"
	echo

}

slurm_use()
{
	[ -z "$_slurm_group" ] && _slurm_group=$_date_filter 
	[ ! -f "$_stat_main_cfg_file" ] && echo "ERR: Slurm main config doesn't exits" && exit 1

	_slurm_cfg=$( cat $_stat_main_cfg_file | awk -F\; '$2 == "slurm" { print $3 }' )
	_slurm_sources=$( cat $_config_path_sta/$_slurm_cfg | awk -F\; '$1 ~ "[0-9]" { print $4 }')
	_slurm_src_num=$( echo "${_slurm_sources}" | wc -l )
	
	for _slurm_src in $( echo "${_slurm_sources}" )
	do
	
		_slurm_exec_opts=" -s "$_slurm_src" -b "$_date_start" -f "$_date_end" -g day -v commas -x "$( [ ! -z "$_slurm_filter_usr" ] && echo "-u "$_slurm_filter_usr )

		_slurm_nod_ctl=$( cat $_config_path_sta/$_slurm_cfg | awk -F\; -v _src="$_slurm_src" '$1 ~ "[0-9]" && $4 == _src { print $3 }')
		_slurm_nod_env=$( ssh $_slurm_nod_ctl sinfo -o %F -h 2>/dev/null | cut -d'/' -f4 )

		[ -z "$_slurm_nod_env" ] && _slurm_nod_env=0
		let _slurm_nod_tot=_slurm_nod_tot+_slurm_nod_env

		[ -z "$_slurm_nod_tot" ] && echo "ZERO ERR: EXIT" && exit

		_slurm_con_data=$_slurm_con_data"\n"$( eval exec $_stat_path/scripts/stats.slurm.total.jobs.sh $_slurm_exec_opts )

	done

	_slurm_use_data=$( echo -e "${_slurm_con_data}" | cut -d';' -f1,6 | sort -n -t\; | 
				sed -e '/^$/d' |
				awk -F\; -v _dr="$_slurm_group" -v _sns="$_slurm_src_num" -v _snt="$_slurm_nod_tot" '
					BEGIN { 
						_count=1
						t=0 ; 
					} {
						split($1,dti,"-")
						_tsd=mktime( dti[1]" "dti[2]" "dti[3]" 0 0 1" )
						if ( _dr == "year" ) { _m=strftime("%b",_tsd) ; _time=dti[1]";"dti[2]"_"_m ; } 
						if ( _dr == "month" ) { _m=strftime("%b",_tsd) ; _time=dti[1]"-"dti[2]"_"_m";"dti[3] } 
						if ( _dr == "week" ) { _m=strftime("%a",_tsd) ; _time=dti[1]"-"dti[2]";"dti[3]"_"_m } 
						if ( _dr == "day" ) { _m=strftime("%b",_tsd) ; _time=dti[1]"-"dti[2]"_"_m";"dti[3] } 
						if ( _dr == "user" ) { _time=$1 } 
						if ( _to != _time ) { 
							print _to"="(t*100)/(_snt*24)/(_count/_sns) ; 
							_to=_time ; 
							_count=1 ;
							t=$2 ; 
						} else { 
							t+=$2 ; 
							_count++ ;
						}
					} END { 
						print _to"="((t*100)/(_snt*24))/(_count/_sns) ;
					}' | 
				grep -v "^=0" )


	case "$_par_shw" in
	commas)
		_slurm_output=$( echo "${_slurm_use_data}" | tr '=' ';' )
	;;
	*)
		_slurm_output=$( echo "${_slurm_use_data}" | 
						awk -F\; -v _g="$_sh_color_green" -v _r="$_sh_color_red" -v _y="$_sh_color_yellow" -v _n="$_sh_color_nformat" '
						{ 
							split($2,a,"=") ; 
							split(a[2],b,".") ; 
							if ( b[1] > 30 ) {
								split(b[1]/1.5,y,".")
								split(b[1]/1.02,r,".")
							} else {
								y[1]=20
								r[1]=40
							}
							if ( b[1] <= 50 ) { _tp=_g""b[1]"%"_n ; hp=a[2]" h" } ;
							if ( b[1] > 50 ) { _tp=_y""b[1]"%"_n ; hp=a[2]" h" } ; 
							if ( b[1] > 75 ) { _tp=_r""b[1]"%"_n ; hp=_r""a[2]" h"_n } ; 
							for (i=1;i<=b[1];i++) { 
								if ( i == 1 ) { _t=_g"|" } else { _t=_t"|" } ;
								if ( i == y[1] ) { _t=_t""_n""_y } ;
								if ( i == r[1] ) { _t=_t""_n""_r } ;
								if ( i == b[1] ) { _t=_t""_n } ;
								} ; 
							if ( _do != $1 ) { _do=$1 ; _pdo=_do } else { _pdo=" " } ; 
							printf "%-12s %s::%-s %-s\n",_pdo, a[1],_t , _tp ; 
							_t="" 
						}' 
				)
	;;
	esac

	echo
	echo -e $_sh_color_red"EXPERIMENTAL - ONLY ASK FOR YEAR RANGE\n"$_sh_color_nformat
	echo -e $_sh_color_bolt"SLURM CLUSTER: TIME OCCUPATION"$_sh_color_nformat
	echo -e $_sh_color_bolt"------------------------------"$_sh_color_nformat
	echo
	echo -e "\tSOURCES: [$( echo "${_slurm_sources}" | tr '\n' ',' | sed 's/,$//' )]"
	echo -e "\tTOTAL NODES: $_slurm_nod_tot"
	echo -e "\tFILTER: DATE: $_par_date_start" 
	[ ! -z "$_slurm_filter_usr" ] && echo -e "\tFILTER USER: "$_slurm_filter_usr
	echo 
	echo "${_slurm_output}"
	echo

}

slurm_stats()
{
	[ ! -f "$_stat_main_cfg_file" ] && echo "ERR: Slurm main config doesn't exits" && exit 1

	if [ -z "$_slurm_group" ]
	then
		case "$_date_filter" in
		day|week|month)
			_slurm_group="day"
		;;
		year)
			_slurm_group="month"
		;;
		esac
	fi

	_slurm_cfg=$( cat $_stat_main_cfg_file | awk -F\; '$2 == "slurm" { print $3 }' )
	_slurm_src=$( cat $_config_path_sta/$_slurm_cfg | awk -F\; '$1 ~ "[0-9]" { print $4 }')

	echo
	echo -e $_sh_color_bolt"SLURM: STATS"$_sh_color_nformat
	echo -e $_sh_color_bolt"------------"$_sh_color_nformat 
	echo
	echo -e "\tSOURCES: [$( echo "${_slurm_src}" | tr '\n' ',' | sed 's/,$//' )]"
	echo -e "\tFILTER: $_date_filter" 
	echo

	for _ssrc in $( echo "${_slurm_src}" )
	do

		_slurm_exec_opts=" -s "$_ssrc" -b "$_date_start" -f "$_date_end" -g "$_slurm_group" -v commas "$( [ ! -z "$_slurm_filter_usr" ] && echo "-u "$_slurm_filter_usr )

		echo "	Slurm cluster: $_ssrc"
		echo "	---------------------"
		echo

		eval exec $_stat_path/scripts/stats.slurm.total.jobs.sh $_slurm_exec_opts |
		awk -F\; '
		BEGIN { 
			_sw=0  
		} $1 == "user" || $1 == "day" || $1 == "month" { 
			_sw=1 
		} _sw == 1 { 
			print $0 ; 
			if ( $1 == "user" || $1 == "day" || $1 == "month" ) {
				print "-----;-------;-------;-------;-----;---------" 
				} 
		}' | column -t -s\; | sed 's/^/\t/' 

		echo 
	done
}
	
init_defaults()
{

	if [ -z "$_par_date_start" ]
	then
		case "$_opt" in
		system)
			case "$_par_typ" in
			status)
				_par_date_start="week"
			;;
			use)
				_par_date_start="week"
			;;
			esac
		;;
		slurm)
			case "$_par_typ" in
			status)
				_par_date_start="day"
			;;
			stats)
				_par_date_start="month"
			;;
			use)
				_par_date_start="year"
			;;
			watt)
				_par_date_start="week"
			;;	
			""|activity)
				_par_date_start="week"
			;;
			esac
		;;
		cyclops)
			_par_date_start="week"
		;;
		audit)
			_par_date_start="week"
		;;
		*)
			_par_date_start="day"
		;;
		esac
	fi
}

init_special_opts()
{

	if [ "$_opt_opt" == "yes" ]
	then
		[ "$_opt" == "audit" ] && [ "$_par_typ" == "codes" ] && _codes=$( awk -F\; '$1 !~ "#" && $1 ~ "[a-zA-Z0-9]+" { print $1 }' $_config_path_aud/issuecodes.cfg ) 
		for _spe_opt in $( echo "$_par_opt" | tr ',' '\n' )
		do
			_spe_par_nam=$( echo $_spe_opt | cut -d'=' -f1 )
			_spe_par_val=$( echo $_spe_opt | cut -d'=' -f2 )

			case $_opt in
			slurm)
				case $_spe_par_nam in
				group)
					_slurm_group=$_spe_par_val
				;;
				user)
					_slurm_filter_usr=$_spe_par_val
				;;
				esac
			;;
			audit)
				if [ "$_par_typ" == "codes" ]
				then
					case $_spe_par_nam in
					open|close)
						_audit_special_opts=$_audit_special_opts" -s "$_spe_par_nam
					;;
					stats)
						_audit_special_opts=$_audit_special_opts" -i"
					;;
					*)
						_codes=""$( echo $_spe_par_nam | awk -v _c="$_codes" 'BEGIN { split(_c,cod,"\n") } { for ( i in cod ) { if ( $1 == cod[i] ) { _strg=cod[i] }}} END { print _strg }' )
						
					;;
					esac
				fi
			;;
			esac
		done
	fi
}

###########################################
#               MAIN EXEC                 #
###########################################

############### HA CHECK ##################

[ "$_cyclops_ha" == "ENABLED" ] && ha_check $_command

########### OPTIONS PROCESSING ############

####====== DEFAULT GENERAL OPTS =======#### 

[ "$_par_act" == "all" ] && _par_act="slurm,cyclops,audit,critical,node"
[ -z "$_par_typ" ] && _par_type="status"


####====== FILTER PROCESSING =======#####


if [ "$_opt_node" == "yes" ]
then
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
fi

################ LAUNCHING ###################

for _opt in $( echo $_par_act | tr ',' '\n' )
do
	init_defaults
	init_date $_par_date_start $_par_date_end
	init_special_opts

	case "$_opt" in
	system)
		case "$_par_typ" in
		status)
			system_avail
		;;
		use)
			system_use
		;;
		esac
	;;
	slurm)
		case "$_par_typ" in
		status)
			slurm_activity
		;;
		stats)
			if [ "$_par_date_start" == "hour" ]
			then
				echo "Slurm stats can't ask by hour range, try other range for get info"
				exit 1
			else
				slurm_stats
			fi
		;;
		use)
			slurm_use
		;;
		watt)
			slurm_consumption
		;;
		esac
	;;
	cyclops)
		cyclops_status
	;;
	audit)
		case "$_par_typ" in
		bitacora)
			audit_status
		;;
		codes)
			audit_codes
		;;
		*)
			audit_status
		;;
		esac
	;;
	critical)
		critical_env
	;;
	node)
		node_real_status
	;;
	*)
		echo "Unknow option"
	;;
	esac
done

