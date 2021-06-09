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

	_main_cfg_file=$_config_path_srv"/service.quota.cfg"

        [ -f "$_libs_path/ha_ctrl.sh" ] && source $_libs_path/ha_ctrl.sh || _exit_code="112"
        [ -f "$_color_cfg_file" ] && source $_color_cfg_file || _exit_code="117"
	[ ! -f "$_main_cfg_file" ] && _exit_code="115"

        case "$_exit_code" in
        111)
                echo "Main Config file doesn't exists, please revise your cyclops installation" >&2
                exit 1
        ;;
        112)
                echo "HA Control Script doesn't exists, please revise your cyclops installation" >&2 
                exit 1
        ;;
        11[3-5])
                echo "Necesary libs files doesn't exits, please revise your cyclops installation" >&2
                exit 1
        ;;
        117)
                echo "WARNING: Color file doesn't exits, you see data in black" >&2
        ;;
        esac

        _cyclops_ha=$( awk -F\; '$1 == "CYC" && $2 == "0006" { print $4}' $_sensors_sot )

###########################################
#              PARAMETERs                 #
###########################################

while getopts ":ids:t:n:u:o:q:v:h:" _optname
do
        case "$_optname" in
                "d")
                        _opt_dae="yes"
			_sh_action="daemon"
                ;;
                "i")
			_opt_ia="yes"
                ;;
                "v")
                        _opt_shw="yes"
                        _par_shw=$OPTARG
			[ "$_par_shw" == "config" ] && _sh_action="config"
                ;;
                "u")
                        _opt_usr="yes"
                        _par_usr=$OPTARG
                ;;
		"s")
			_opt_srt="yes"
			_par_srt=$OPTARG
		;;
                "n")
                        _opt_srv="yes"
                        _par_srv=$OPTARG
			_sh_action="manual"
                ;;
		"t")
			_opt_typ="yes"
			_par_typ=$OPTARG
		;;
		"o")
			_opt_fs="yes"
			_par_fs=$OPTARG
		;;
		"q")
			_opt_qt="yes"
			_par_qt=$OPTARG
		;;
                "h")
                        _opt_help="yes"
                        _par_help=$OPTARG

                        case "$_par_help" in
                                        "des")
						echo "$( basename "$0" ) : Cyclops Quota Monitoring Service"
                                                echo "  Default path: $( dirname "${BASH_SOURCE[0]}" )"
                                                echo "  Global config path : $_config_path"
                                                echo "          Global config file: global.cfg"
						echo "	Service config files:"
						echo "		$_main_cfg_file"
                                                echo "  Cyclops dependencies:"
                                                echo "          Cyclops libs: $_libs_path"
						echo "			ha_ctrl.sh"
						echo "	Cyclops Links:"
						echo "		Monitoring Module"
                                                echo

                                                exit 0
                        esac
                ;;
               ":")
                        case "$OPTARG" in
                        "h")
                                echo
                                echo "CYCLOPS QUOTA MONITORING SERVICE"
                                echo "  Check quota services from one or multiple file servers"
				echo
				echo "	-d Daemon option [NOT OPERATIVE YET]"
				echo "	-i Adaptative Intelligence enable [NOT OPERATIVE YET]"
				echo
				echo "STANDARD OPTIONS"
				echo "	-n [SERVER], specify different server from config file"
				echo " 		help: show available config server and settings"
				echo "	-t [lustre|kernel], specify file server type"
				echo "		kernel: linux standard quota fs system ( default )"
				echo "		lustre: Lustre FS quota system, need FS to check"
				echo " 		help: show available config server and settings"
				echo "	-o [filesystem], Lustre FS to check"
				echo " 		help: show available config server and settings"
				echo "	-q [user|group], Quota type"
				echo "		user: user quota control"
				echo "		group: user quota control"
				echo " 		help: show available config server and settings"
				echo 
				echo "FILTER AND SORT OPTIONS"
				echo "	-u [USER], filter date from one or many users ( comma separated ) [NOT OPERATIVE YET]"
				echo "	-s [user|inode|block], sort list from field"
				echo "		user: by default, user name sort"
				echo "		inode: file number use sort"
				echo "		block: size use sort"
				echo "		status: quota status sort"
				echo "	-v [commas,wiki,human], specify an output format"
				echo "		commas: comma separated output" 
				echo "		wiki: dokuwiki output format"
				echo "		human: human readable format"
				echo "		config: show config servers and settings"
                                echo
                                echo "-h [|des] help is help"
                                echo "  des: detailed help about this command"
                                echo

                                exit 0
                        ;;
                        esac
                ;;
        esac
done

shift $((OPTIND-1))

#### FUNCTIONS ####

extract_data()
{
	_quota_server=$1
	_fs_type=$2
	_quota_fs=$3
	_quota_type=$4
	
	unset _data_srv
	
	case "$_fs_type" in
	kernel)
		[ "$_quota_type" == "user" ] && _cmd_par="-pu"
		[ "$_quota_type" == "group" ] && _cmd_par="-pg" 
		_status_srv=$( ssh -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_quota_server  "$(typeset -f);check_server_kernel" $_quota_fs $_fs_type $_quota_type 2>/dev/null )
		[ -z "$_status_srv" ] && _status_srv="FAIL;na;server no respond" || _data_srv=$( ssh -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_quota_server repquota $_cmd_par $_quota_fs 2>/dev/null )
		[ -z "$_data_srv" ] && _data_srv="no data" 
	;;
	lustre)
		#_status_srv="user;$_quota_fs;$_quota_type;ENABLE"
		_status_srv=$( ssh -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_quota_server  "$(typeset -f);check_server_lustre" $_quota_fs $_fs_type $_quota_type 2>/dev/null )
		if [ -z "$_status_srv" ] 
		then
			_status_srv="FAIL;na;server no respond" 
		else
			_data_srv=$( ssh -o ConnectTimeout=12 -o StrictHostKeyChecking=no $_quota_server  "$(typeset -f);get_data_lustre" $_quota_fs $_quota_type 2>/dev/null )
		fi
		[ -z "$_data_srv" ] && _data_srv="no data recovery"
	;;
	esac
}

check_server_lustre()
{
	_fs_space=$( df $1 2>/dev/null | awk 'NF > 4 && $(NF-4) ~ "^[0-9]+$" { print $(NF-4) }' )
	[ -z "$_fs_space" ] && echo "$3;$1;na;$2;DISABLE" || echo "$3;$1;$_fs_space;$2;ENABLE" 
}

check_server_kernel()
{

	_ckquotabin=$( which quotaon 2>/dev/null ) 
	_fs_space=$( df $1 2>/dev/null | awk 'NF > 4 && $(NF-4) ~ "^[0-9]+$" { print $(NF-4) }' )
	[ ! -z "$_ckquotabin" ] && _data_status=$( $_ckquotabin -pa | awk -v _t="$3" -v _f="$1" -v _s="$_fs_space" '$1 == _t && $4 == _f { gsub("off","DISABLE",$NF) ; gsub("on","ENABLE",$NF) ; print $1";"$4";"_s";kernel;"$NF }' ) || echo "$3;$1;na;$2;DISABLE" 
	[ -z "$_data_status" ] && echo "$3;$1;na;$2;DISABLE" || echo "${_data_status}"

}

get_data_lustre()
{
		_lustre_fs=$1

		[ "$2" == "user" ] && _cmd_get="/usr/bin/getent passwd" && _idb="500" 
		[ "$2" == "group" ] && _cmd_get="/usr/bin/getent group" && _idb="500" 

		_items=$( eval exec $_cmd_get  | awk -F\: -v _id="$_idb" '$3 >= _id || $1 == "root" { print $1 }' | sort -u )

		for _item in $( echo "${_items}" ) 
		do 
			if [ "$2" == "user" ] 
			then
				/usr/bin/lfs quota -u $_item $_lustre_fs | awk -v _usr="$_item" -v _fs="$_lustre_fs" '$1 ~ _fs { print _usr" -- "$2" "$3" "$4" - "$6" "$7" "$8 }'  
			else
				/usr/bin/lfs quota -g $_item $_lustre_fs | awk -v _usr="$_item" -v _fs="$_lustre_fs" '$1 ~ _fs { print _usr" -- "$2" "$3" "$4" - "$6" "$7" "$8 }'  
			fi
		done
}

format_data()
{
	_data_head=$( echo "${_status_srv}" )
	_data_srv=$( echo "${_data_srv}" | 
		awk '
			$1 ~ "[a-z]" && $3 ~ "[0-9]" { 
				_usrg="UP" ; 
				_ig="UP" ; 
				_bg="UP" ;
				_usr=0 ;
				$3=int($3) ;
				$7=int($7) ;
				if ( $4 != 0 ) {  
					if ( $3 >= $4 ) { 
						_usrg="MARK" ; 
						_bg="MARK" ; 
						_bs="MARK" 
					} else { 
						_bs="OK" 
					}
					_usr=_usr+2
				} else { 
					_bs="UP" 
					_usr++
				} ; 
				if ( $5 != 0 ) { 
					if ( $3 >= $5 ) { 
						_usrg="DOWN" ; 
						_bg="DOWN" ; 
						_bh="DOWN" ; 
					} else { 
						_bh="OK" 
					}
					_usr=_usr+2
				} else { 
					_bh="UP" 
					_usr++
				} ; 
				if ( $8 != 0 ) {
					if ( $7 >= $8 ) {
						_usrg="MARK" ;
						_ig="MARK" ;
						_is="MARK" ;
					} else {
						_is="OK"
					}
					_usr=_usr+2
				} else { 
					_is="UP"
					_usr++
				} ;
				if ( $8 != 0 ) {
					if ( $7 >= $9 ) {
						_usrg="DOWN" ;
						_ig="DOWN" ;
						_ih="DOWN" ;
					} else {
						_ih="OK"
					}
					_usr=_usr+2
				} else {
					_ih="UP"
					_usr++
				} ;
				if ( _usr > 4 && _usrg == "UP" ) { _usrg="OK" } 
				if ( _usr == 4 ) { _usrg="OFF" }
				print _usrg":"$1";"_bg":"$3";"_bs":"$4";"_bh":"$5";"_ig":"$7";"_is":"$8";"_ih":"$9  
			}' ) 

	case "$_par_srt" in
	inode)
		_data_srv=$( echo "${_data_srv}" | sort -t\: -k6n )
	;;
	block)
		_data_srv=$( echo "${_data_srv}" | sort -t\: -k3n )
	;;
	status)
		_data_srv=$( echo "${_data_srv}" | sort -t\: -k1 )
	;;
	*)
		_data_srv=$( echo "${_data_srv}" | sort -t\: -k2 )
	;;
	esac

	case "$_par_shw" in
	human)
		_data_head=$( echo "${_data_head}" | awk -F\; '
			{
				if ( $3 <= 1024 ) { $3=$3 ; _m="K" }
				if ( $3 > 1024 && $3 < 1024^2 ) { $3=$3/1024; _m="M" }
				if ( $3 >= 1024^2 && $3 < 1024^3 ) { $3=$3/(1024^2); _m="G" }
				if ( $3 >= 1024^3 ) { $3=$3/(1024^3); _m="T" }
				printf "%s;%s;%'"'"'6.1f%s;%s;%s", $1, $2, $3, _m, $4, $5 
			}' |sed -e "s/ENABLE/\\$_sh_color_green&\\$_sh_color_nformat/" )
		_data_out=$( echo "${_data_srv}" | awk -F\; -v _cw="$_sh_color_yellow" -v _cu="$_sh_color_green" -v _cd="$_sh_color_red" -v _cn="$_sh_color_nformat" '
			BEGIN { 
				printf "%8s %-12s %13s %13s %13s %13s %12s %12s %12s\n", " status ", "    user    ", "  ratio b/i  ", "  block used  ", "  block soft  ", "  block hard  ", "inode used", "inode soft", "inode hard"
				printf "%8s %-12s %13s %13s %13s %13s %12s %12s %12s\n", "--------", "------------", "-------------", "--------------", "--------------", "--------------", "-------------", "-------------", "------------" 
			} { 
				split($1,fa,":")
				if ( fa[1] == "UP" || fa[1] == "OK" ) { _st=_cu" "fa[1]" "_cn }
				if ( fa[1] == "DOWN" ) { _st=_cd""fa[1]""_cn }
				if ( fa[1] == "OFF" ) { _st=_cw""fa[1]" "_cn }
				if ( fa[1] == "MARK" ) { _st=_cw"WRNG"_cn }
				for (i=2;i<=NF;i++) {
					cs[i]="" ; ce[i]="" ;
					split($i,fd,":")
					fd[2]=int(fd[2])
					if ( i == 2 ) { _bt=_bt+fd[2] ; _rb=fd[2] }
					if ( i == 5 ) { _it=_it+fd[2] ; _ri=fd[2] }
					if ( i > 1 && i < 5 ) {
						if ( fd[2] <= 1024 ) { $i=fd[2] ; ms[i]="K" }
						if ( fd[2] > 1024 && fd[2] < 1024^2 ) { $i=fd[2]/1024; ms[i]="M" }
						if ( fd[2] >= 1024^2 && fd[2] < 1024^3 ) { $i=fd[2]/1024^2; ms[i]="G" }
						if ( fd[2] >= 1024^3 ) { $i=fd[2]/1024^3; ms[i]="T" }
					} else {
						if ( fd[2] < 1000^2 ) { $i=fd[2] ; msi[i]=" " }
						if ( fd[2] >= 1000^2 ) { $i=fd[2]/(1000) ; msi[i]="k" }
					}
					if ( fd[1] == "DOWN" ) { cs[i]=_cd ; ce[i]=_cn }
					if ( fd[1] == "MARK" ) { cs[i]=_cw ; ce[i]=_cn }
				}
				if ( _ri != 0 ) { 
					_rbi=int(_rb/_ri) 
					if ( _rbi < 1024 ) { _rbio=_rbi ; _mrbio="K" }
					if ( _rbi >= 1024 && _rbi < 1024^2 ) { _rbio=_rbi/1024 ; _mrbio="M" }
					if ( _rbi >= 1024^2 ) { _rbio=_rbi/1024^2 ; _mrbio="G" }
					_rbt=_rbt+_rbi ; _rbtc++
				} else { 
					if ( _rb != 0 ) { 
						_st=_cd"ERR "_cn 
						cs[2]=_cd ; ce[2]=_cn 
						cs[5]=_cd ; ce[5]=_cn
					} 
					_rbio=0 ; _mrbio=" " 
				}
				printf "[ %4s ]  %-12s %'"'"'10.1f%s %s%'"'"'13.1f%s%s %s%'"'"'13.1f%s%s %s%'"'"'13.1f%s%s %s%'"'"'12d%s%s %s%'"'"'13d%s%s %s%'"'"'10d%s%s\n", _st, fa[2], _rbio, _mrbio, cs[2], $2, ms[2], ce[2], cs[3], $3, ms[3], ce[3], cs[4], $4, ms[4], ce[4], cs[5], $5, msi[5], ce[5], cs[6], $6, msi[6], ce[6], cs[7], $7, msi[7], ce[7]
			} END { 
				_rbt=int(_rbt/_rbtc) ; _mrbt="K" 
				if ( _rbt > 1024 && _rbt < 1024^2 ) { _rbt=_rbt/1024 ; _mrbt="M" }
				if ( _rbt >= 1024^2 ) { _rbt=_rbt/1024^2 ; _mrbt="G" }
				_it=_it/1000 ; _is="-" ; _ih="-" ; 
				if ( _bt > 1024 && _bt < 1024^2 ) { _bt=_bt/1024 ; _mbt="M" }
				if ( _bt >= 1024^2 && _bt < 1024^3 ) { _bt=_bt/1024^2 ; _mbt="G" }
				if ( _bt >= 1024^3 ) { _bt=_bt/1024^3 ; _mbt="T" }
				_bs="-" ; _bh="-"
				printf "%8s %-12s %13s %13s %13s %13s %12s %12s %12s\n", "        ", "------------", "-------------", "--------------", "--------------", "--------------", "-------------", "-------------", "------------" 
				printf "\n%8s %10s %'"'"'14.1f%s/i %'"'"'10.1f%s %14s %14s %'"'"'12dk %12s %12s\n", "        ", "total", _rbt, _mrbt, _bt, _mbt, _bs, _bh, _it, _is, _ih 
			}' )
		echo
		echo "quota server: "$_srv
		echo "---------------------------"
		echo
		echo -e "quota type;filesystem;fs size;fs type;status
----------;----------;-------;-------;------
${_data_head}" | column -t -s\;
		echo
		echo -e "${_data_out}" #| column -t -s\; 
		echo
	;;
	commas)
		echo
		echo "quota server: "$_srv
		echo
		echo "quota type;filesystem;fs size;fs type;status"
		echo "${_data_head}"
		echo
		echo
		echo "user;inode used;inode soft;inode hard;block used;block soft;block hard"
		echo "${_data_srv}"
		echo
	;;
	wiki)

		[ ! -d "$_srv_quota_logs" ] && mkdir -p "$_srv_quota_logs"

		echo
		echo "~~NOTOC~~"
		echo "~~NOCACHE~~"
		echo
		echo
		echo '\\'
		echo
		echo "${_data_head}" | awk -F\; -v _s="$_srv" -v _cm="$_color_mark" -v _co="$_color_ok" -v _cd="$_color_down" -v _cu="$_color_up" -v _ce="$_color_disable" -v _cf="$_color_fail" '
			BEGIN { 
				_ts=systime() 
				_mt=strftime("%H:%M:%S",_ts)
				_head="|  "_cu" Mon Time  |  "_cu" Quota Type  ||  "_cu" File System  |  "_cu" File System Size  ||  "_cu" File System Type  |  "_cu" Status  |"
				print "|< 100% >|"
			}
			NR == 1 { 
				print "|< 100% 16% 8% 8% 8% 8% 8% %12 %12 >|"
				print "|  "_co"  ** <fc white>QUOTA SERVER:  "toupper(_s)"</fc> **  "_head  
			} {
				if ( $5 == "ENABLE" ) { $5=_co" ** <fc white>ENABLED</fc> ** " }
				if ( $5 == "DISABLE" ) { $5=_ce" ** DISABLED ** " }
				if ( $3 <= 1024 ) { _m="K" }
				if ( $3 > 1024 && $3 < 1024^2 ) { $3=$3/1024; _m="M" }
				if ( $3 >= 1024^2 && $3 < 1024^3 ) { $3=$3/1024^2 ; _m="G" }
				if ( $3 >= 1024^3 ) { $3=$3/1024^3 ; _m="T" }
				if ( $1 == "FAIL" ) { $1=" ** <fc white> "_cd" </fc> ** "$1 ; $4=$1 ; $5=$1 }
				printf "|  :::  |  %s  |  %s  ||  %s  |  %'"'"'8.1f%s  ||  %s  |  %s  |\n", _mt, $1, $2, $3, _m, $4, $5 
			}'
		echo "${_data_srv}" | awk -F\; -v _s="$_srv" -v _cm="$_color_mark" -v _co="$_color_ok" -v _cd="$_color_down" -v _cu="$_color_up" -v _ce="$_color_disable" -v _cf="$_color_fail" -v _lp="$_srv_quota_logs" -v _dh="${_data_head}" '
			BEGIN { 
				_tud=0 ; _tum=0 ; _tuo=0 ; _tuf=0 ; _tue=0 ; 
				logtit[1]="" ; logtit[2]="b_used" ; logtit[3]="b_soft" ; logtit[4]="b_hard" ; 
				logtit[5]="i_used" ; logtit[6]="i_soft" ; logtit[7]="i_hard" ;  
				split(_dh,dh,";") ;
				_mt=systime() ;
			} {
				split($1,fa,":")
				_err=0
				_log_dst=fa[2]
				_log_line=_mt" : "fa[2]" : "fa[1]" : mon_time="strftime("%H.%M.%S",_mt)" : server="_s" : quota_type="dh[1]" : fs_path="dh[2]" : fs_size="dh[3]" : fs_type="dh[4]" : fs_status="dh[5]
				for (i=2;i<=NF;i++) {
					_idx=fa[2]":"i
					_bc=0
					split($i,f,":")
					if ( i != 2 && i != 5 ) { if ( f[2] != 0 ) { _bc++ } }
					if ( i == 2 ) {
						if ( f[2] != 0 ) { _err=1 }
						_rb=f[2]
					}
					if ( i == 4 ) { _pb=f[2] }
					if ( i == 5 ) {
						if ( _err == 1 && f[2] == 0 ) { _err=2 }
						_ri=f[2]
					}
					if ( i < 5 ) {
						if ( f[2] <= 1024 ) { fld[_idx]=f[2] ; mb[_idx]="K" }
						if ( f[2] > 1024 && f[2] < 1024^2 ) { fld[_idx]=f[2]/1024; mb[_idx]="M" }
						if ( f[2] >= 1024^2 && f[2] < 1024^3 ) { fld[_idx]=f[2]/1024^2; mb[_idx]="G" }
						if ( f[2] >= 1024^3 ) { fld[_idx]=f[2]/1024^3; mb[_idx]="T" }
					} else {
						fld[_idx]=f[2]
					}
					if ( i == 7 ) { _pi=f[2] }
					if ( f[1] == "UP" ) {   cf[_idx]=_cu } 
					if ( f[1] == "OK" ) {   cf[_idx]=_co }
					if ( f[1] == "DOWN" ) { cf[_idx]=_cf } 
					if ( f[1] == "MARK" ) { cf[_idx]=_cm } 
					_log_line=_log_line" : "logtit[i]"="f[2]
				}
				if ( _ri != 0 ) { 
					_ratio_bi=_rb/_ri 
					if ( _ratio_bi <= 1024 ) { rat[fa[2]]=_ratio_bi ; ratm[fa[2]]="K" }
					if ( _ratio_bi > 1024 && _ratio_bi < 1024^2 ) { rat[fa[2]]=_ratio_bi/1024 ; ratm[fa[2]]="M" }
					if ( _ratio_bi >= 1024^2 && _ratio_bi < 1024^3 ) { rat[fa[2]]=_ratio_bi/1024^2; ratm[fa[2]]="G" }
				} else { 
					_ratio_bi=0
					rat[fa[2]]=0 
				}
				if ( fa[1] == "DOWN" ) { _id=1 ; _tud++ }
				if ( fa[1] == "MARK" ) { _id=2 ; _tum++ }
				if ( fa[1] == "OK" ) {   _id=3 ; _tuo++ }
				if ( _bc == 0 ) {        _id=4 ; _tuf++ }
				if ( _err == 2 ) {       _id=5 ; cf[fa[2]":"2]=_cf ; cf[fa[2]":"5]=_cf ; _tue++ }
				if ( _id < 4 && int(_pb) != 0 ) { pblock[fa[2]]=int((_rb * 100)/_pb) ; pinode[fa[2]]=int((_ri * 100)/_pi) } else { pblock[fa[2]]=0 ; pinode[fa[2]]=0 }
				ord[_id]=ord[_id]""fa[2]","
				ordb[_id]=ordb[_id]+_rb ; ordi[_id]=ordi[_id]+_ri
				_tbc=_tbc+_rb
				_tic=_tic+_ri
				_log_line=_log_line" : bi_ratio="_ratio_bi" : per_block="pblock[fa[2]]"% : per_inode="pinode[fa[2]]"%"
				print _log_line >> _lp"/"_log_dst".qt.mon.log"
			} END {
				_head="^  user  ^  ratio B/i  ^  Blocks Used %  ^  Inodes Used %  ^  Block Used  ^  Block Soft  ^  Block Hard  ^  Inode Used  ^  Inode Soft  ^  Inode Hard  ^"
				_tab="|< 100% 12% 8% 6% 6% 11% 11% 11% 11% 11% 11%>|"

				_tbcl=_tbc

				if ( _tbc <= 1024 ) { _tbcm="K" }
				if ( _tbc > 1024 && _tbc < 1024^2 ) { _tbc=_tbc/1024 ; _tbcm="M" }
				if ( _tbc >= 1024^2 && _tbc < 1024^3 ) { _tbc=_tbc/1024^2; _tbcm="G" }
				if ( _tbc >= 1024^3 ) { _tbc=_tbc/1024^3; _tbcm="T" }
				
				split(_dh,dlog,";") 
				_tu=_tud+_tum+_tuo+_tuf+_tue

				if ( _tu == _tuo ) { _tuc=_co } else { _tuc=_cu }
				if ( _tuo > 0 )  { _tuoc=_co } else { _tuoc=_ce } 
				if ( _tud == 0 ) { _tudc=_co } else { _tudc=_cd }
				if ( _tum == 0 ) { _tumc=_co } else { _tumc=_cm }
				if ( _tuf == 0 ) { _tufc=_co } else { _tufc=_ce }
				if ( _tue == 0 ) { _tuec=_co } else { _tuec=_cf }

				print  "|  :::  |  "_cu" Users                                    ||||||  "_cu" Total Blocks used  |  "_cu" Total inodes used  |"
				print  "|  :::  |  "_tuc" Total  |  "_tuoc" On  |   "_tudc" Down  |  "_tumc" Warning  |  "_tufc" Off  |  "_tuec" Err  |  :::          |  :::                      |"
				printf "|  :::  |   %s         |  %s        |   %s    |  %s       |  %s   |  %s   |  %'"'"'8.1f%s   |  %'"'"'d                  |\n\n", _tu, _tuo, _tud, _tum, _tuf, _tue, _tbc, _tbcm, _tic

				print _mt" : "strftime("%H.%M.%S",_mt)" : quota_type="dlog[1]" : filesystem="dlog[2]" : size="dlog[3]" : fstype="dlog[4]" : status="dlog[5]" : usr_tot="_tu" : usr_on="_tuo" : usr_down="_tud" : usr_warning="_tum" : usr_off="_tuf" : usr_err="_tue" : size_used="_tbcl" : size_per="int((_tbcl*100)/dlog[3])"% : inode_used="_tic >> _lp"/"_s".qt.mon.log" 
	
				for (a=1;a<=5;a++) {
					if ( a == 1 ) { 
						_cg=_cd" ** <fc white>DOWN</fc> ** "
						_secc="<hidden Quota Down Details>"
					}
					if ( a == 2 ) { 
						_cg=_cm" ** WARNING **"
						_secc="<hidden Quota Warning Details>"
					}
					if ( a == 3 ) { 
						_cg=_co" ** <fc white>ON</fc> **" 
						_secc="<hidden Quota Enable Details >"
					}
					if ( a == 4 ) { 
						_cg=_ce" ** OFF **"
						_secc="<hidden Quota Disable Details >"
					}
					if ( a == 5 ) { 
						_cg=_cf" ** <fc white>ERROR</fc> **"
						_secc="<hidden Quota Err Details>"
					}
					ul=split(ord[a],u,",")
					ul=ul-1
					if ( ul > 0 ) {
						if ( ordb[a] <= 1024 ) { ordbm="K" }
						if ( ordb[a] > 1024 && ordb[a] < 1024^2 ) { ordb[a]=int(ordb[a]/1024) ; ordbm="M" }
						if ( ordb[a] >= 1024^2 && ordb[a] < 1024^3 ) { ordb[a]=int(ordb[a]/(1024^2)); ordbm="G" }
						if ( ordb[a] >= 1024^3 ) { ordb[a]=int(ordb[a]/(1024^3)); ordbm="T" }

						print _secc
						print _tab
						print "|  "_cg"  ||  "_cu" Users  ||  "_cu" Blocks Used  |||  "_cu" inodes Used  |||" 
						printf "|  :::    ||  %s       ||  %'"'"'8.1f%s  |||  %'"'"'d   |||\n", ul, ordb[a], ordbm, ordi[a] 
						print _head
						ul=asorti(u, user)	
						for (idx=1;idx<=ul;idx++) {
							if ( u[idx] != "" ) {
								_ix=u[idx]":"
								if ( pblock[u[idx]] <= 50 ) { _pbc=_cu } else if ( pblock[u[idx]] <= 70 ) { _pbc=_co } else if ( pblock[u[idx]] < 99 ) { _pbc=_cm } else { _pbc=cf[_ix""4] }
								if ( pinode[u[idx]] <= 50 ) { _pic=_cu } else if ( pinode[u[idx]] <= 70 ) { _pic=_co } else if ( pinode[u[idx]] < 99 ) { _pic=_cm } else { _pic=cf[_ix""4] }
								printf  "| %s  |  %'"'"'8.1f%s |  %s %'"'"'d%%  |  %s %'"'"'d%%  |  %s %'"'"'8.1f%s |  %s %'"'"'8.1f%s |  %s %'"'"'8.1f%s |  %s %'"'"'d |  %s %'"'"'d |  %s %'"'"'d |\n", u[idx], rat[u[idx]], ratm[u[idx]], _pbc, pblock[u[idx]], _pic, pinode[u[idx]], cf[_ix""2], fld[_ix""2], mb[_ix""2], cf[_ix""3], fld[_ix""3], mb[_ix""3], cf[_ix""4], fld[_ix""4], mb[_ix""4], cf[_ix""5], fld[_ix""5], cf[_ix""6], fld[_ix""6], cf[_ix""7], fld[_ix""7]
							}
						}
						print "</hidden>"
					}
				}
			}' 
			
	;;
	debug)
		echo "${_data_srv}"	
	;;
	esac
}

launch()
{
	for _line in $( echo "${_srvlist}" )
	do
		_srv=$( echo "$_line" | cut -d';' -f1 )
		_typ=$( echo "$_line" | cut -d';' -f2 )
		_fs=$(  echo "$_line" | cut -d';' -f3 ) 
		_qt=$(  echo "$_line" | cut -d';' -f4 )
		extract_data $_srv $_typ $_fs $_qt
		format_data
	done
}

log_data()
{
	echo "WORKING ON IT"
}

#### MAIN EXEC ####


	if [ "$_par_srv" == "help" ] || [ "$_par_typ" == "help" ] || [ "$_par_fs" == "help" ] || [ "$_par_qt" == "help" ] 
	then
		awk -F";" 'BEGIN {
			print "\nConfigurated quota services\n"
			printf "%-14s %-10s %-18s %-10s\n", "Server", "Type", "File System", "Quota Type"
			printf "%-14s %-10s %-18s %-10s\n", "------", "----", "-----------", "----------"
		} $1 !~ "#" { 
			printf "%-14s %-10s %-18s %-10s\n", $2, $3, $4, $5 
		} END { print "" }' $_main_cfg_file 
		exit 0
	fi

	case "$_sh_action" in
	daemon)
		_srvlist=$( awk -F\; '$1 ~ "^[0-9]+$" { print $2";"$3";"$4";"$5 }' $_main_cfg_file )
		launch
	;;
	manual)
		[ -z "$_par_shw" ] && _par_shw="human"

		if [ -z "$_par_srv" ] 
		then
			_srvlist=$( awk -F\; '$1 ~ "^[0-9]+$" { print $2";"$3";"$4";"$5 }' $_main_cfg_file ) 
		else
			[ -z "$_par_typ" ] && _par_typ=$( awk -F\; -v _srv="$_par_srv" 'BEGIN { _s=1 } $1 ~ "^[0-9]+$" && $2 == _srv { print $3 ; _s=0 } END { if ( _s == 1 ) { print "kernel" }}' $_main_cfg_file )
			[ -z "$_par_fs" ] && _par_fs=$( awk -F\; -v _srv="$_par_srv" '$1 ~ "^[0-9]+$" && $2 == _srv { print $4 }' $_main_cfg_file )
			[ -z "$_par_qt" ] && _par_qt=$( awk -F\; -v _srv="$_par_srv" '$1 ~ "^[0-9]+$" && $2 == _srv { print $5 }' $_main_cfg_file )
			_srvlist=$_par_srv";"$_par_typ";"$_par_fs";"$_par_qt
		fi

		launch
	;;
	config)
		awk -F\; 'BEGIN { print "index;server;quota type;fs name" ; print "-----;------;----------;-------" } $1 ~ "^[0-9]+" { print $0 }' $_main_cfg_file | column -t -s\; 
	;;
	*)
		echo "ERR: Use -h for Help"
		exit 1
	;;
	esac
