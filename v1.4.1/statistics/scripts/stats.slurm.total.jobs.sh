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
else
        echo "Global config don't exits" 
        exit 1
fi

source $_color_cfg_file

_stat_slurm_data=$( cat $_stat_main_cfg_file | awk -F\; '$2 == "slurm" { print $0 }' | head -n 1 )
_stat_slurm_cfg_file=$_config_path_sta"/"$( echo $_stat_slurm_data | cut -d';' -f3 )
_stat_slurm_data_dir=$_stat_data_path"/"$( echo $_stat_slurm_data | cut -d';' -f4 )

###########################################
#              PARAMETERs                 #
###########################################

_date_now=$( date +%s )
_par_grp="day"
_par_show="human"

while getopts ":c:p:g:s:b:f:v:u:xyh:" _optname
do
        case "$_optname" in
		"g")
			_opt_grp="yes"

			case "$OPTARG" in
			year|month|day|user|partition|state|hour)
				_par_grp=$OPTARG
			;;
			*)
				echo "ERR: bad option year/month/day"
				exit 1
			;;
			esac
		;;
		"p")
			# field partition
			_opt_par="yes"
			_par_par=$OPTARG
		;;
		"c")
			# field job status
			_opt_sta="yes"
			_par_sta=$OPTARG
		;;
		"u")
			# field user 
			_opt_usr="yes"
			_par_usr=$OPTARG
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
		"v")
			# format output
			_opt_show="yes"
			_par_show=$OPTARG
		;;
		"s")
			# slurm statistic data source
			_opt_src="yes"
			_par_src=$OPTARG	
			
			[ ! -d "$_stat_slurm_data_dir/$_par_src" ] && echo "ERR: Source not exits: $_stat_slurm_data_dir/$_par_src/" && exit 1
		;;
		"x")
			_opt_hea="yes"
		;;
		"y")
			_opt_dbg="yes"
		;;
		"h")
			case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Slurm Statistics generator"
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
				echo "CYCLOPS STATISTICS: SLURM DATABASE:"
				echo 
				echo
				echo "CHOOSE SLURM SOURCE:"
				echo "	-s [cyclops slurm statistics description] mandatory: use main extractor script with -e to see options"
				echo
				echo "FILTER FIELDS:"
				echo "	-b [YYYY-MM-DD|[Jan~Dec]|[YYYY]] start date search, if no use this option, script use today one"
				echo "		[YYYY-MM-DD]: standar start date"
				echo "		[Jan~Dec]-[YYYY]: Get all days from indicated month, let unused -f parameter"	
				echo "		[YYYY]: Get all days from indicated year, let unused -f parameter"
				echo "		[year|month|week|day]: Get, last 365 days, last 30 days, last week, today"
				echo "	-f [YYYY-MM-DD] end date search, only when use specific start date, if no use this option, script use today one"
				echo "	-u [user name] optional: filter data with a user"
				echo "	-c [job state] optional: filter data with a job state"
				echo "	-p [partition name] optional: filter data for one partition"
				echo 
				echo "GROUP:"
				echo "	-g [year|month|day|hour|user|partition|state] optional: group data show"	
				echo 
				echo "SHOW:"
				echo "	-v [human|wiki|commas] optional, commas default."
				echo "		human, show command output human friendly"
				echo "		commas, show command output with ;"
				echo "		wiki, show command output with dokuwiki format (google graphs plugin)"
				echo "	-x Not show header"
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
	esac
done

shift $((OPTIND-1))

###########################################
#               FUNTIONs                  #
###########################################

#### AVAILABLE FIELDS: [1]Start,[2]JobID,[3]User,[4]Partition,[5]JobName,[6]ReqCPUS,[7]ReqMem,[8]NNodes,[9]NTasks,[10]ConsumedEnergy(KJulius),[11]ConsumedEnergy(KWh),[12]Elapsed(Time),[13]Elapsed(Seconds),[14]State

calc_data()
{

        case "$_par_grp" in
	hour)
		cat $_files | awk -F\; -v _hd="$_hour_days" -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '
			$1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c { 
				_h=strftime("%H",$1) ; 
				if ( h[_h] == "" ) { 
					h[_h]="1;"$10+0";"$11+0";"$8";"$12 
				} else { 
					split(h[_h],ch,";") ; 
					h[_h]=ch[1]+1";"ch[2]+$10";"ch[3]+$11";"ch[4]+$8";"ch[5]+$12 
				}
			} END { 
				for ( i in h ) { 
					split(h[i],eo,";") ; 
					print i";"eo[1]/_hd";"eo[2]/_hd";"eo[3]/_hd";"eo[4]/_hd";"(eo[5]/3600)/_hd 
				}
			}' | sort -t\; -n
	;;
	day)
		cat $_files | sort -n -t\; | awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '
                BEGIN {
                        _doh=strftime("%Y-%m-%d",_ds)
                        split(_doh,r,"-")
                        _dou=mktime( r[1]" "r[2]" "r[3]" 0 0 1" )
                        a=0 ; _j=0 ; _w=0 ; _n=0 ;
                } 

                $1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c { 
                        _dnh=strftime("%Y-%m-%d",$1) ;
                        if ( _dnh == _doh ) {
                                a++ ;
				_n=_n+$8  ;
				_j=_j+$10 ;
				_w=_w+$11 ;
				_s=_s+$12 ;
                        }
                        else { 
				_s=_s/3600 ;
				print _doh";"a";"_j";"_w";"_n";"_s ;
				_dff=int ( ( $1 - _dou ) / 86400 ) ;
				if ( _dff > 1 ) { 
					for ( i=1;i<_dff;i++ ) { 
						_aux=(_dou + ( 86400 * i )) ; 
						print strftime("%Y-%m-%d",_aux)";0;0;0;0;0" 
					}
				} 
				a=1 ; _n=$8 ; _j=$10 ; _w=$11 ; _s=$12 ;
				_doh=_dnh ;
				split(_doh,r,"-") ;
				_dou=mktime( r[1]" "r[2]" "r[3]" 0 0 1" )
                        }
                }

                END { 
			_s=_s/3600 ;
                        print _doh";"a";"_j";"_w";"_n";"_s ;
                        _dff=int ( ( _de - _dou ) / 86400 ) ;
			if ( _dff >= 1 ) { for ( i=1;i<=_dff;i++ ) { _aux=(_dou + ( 86400 * i )) ; print strftime("%Y-%m-%d",_aux)";0;0;0;0;0" }}
                }'
	;;
	month)
		cat $_files | awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '
			$1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c { 
				_h=strftime("%Y-%m_%b",$1) ; 
				if ( h[_h] == "" ) { 
					h[_h]="1;"$10+0";"$11+0";"$8";"$12 
				} else { 
					split(h[_h],ch,";") ; 
					h[_h]=ch[1]+1";"ch[2]+$10";"ch[3]+$11";"ch[4]+$8";"ch[5]+$12 
				}
			} END { 
				for ( i in h ) { 
					split(h[i],eo,";") ; 
					print i";"eo[1]";"eo[2]";"eo[3]";"eo[4]";"eo[5]/3600 }
			}' | awk -F\; -v _ds="$_par_ds" -v _de="$_par_de" '
                        BEGIN { 
                                for ( i=_ds;i<_de;i+=86400 ) {
                                        _rd=strftime("%Y-%m_%b",i) ; 
                                        _dp=strftime("%Y %m",i) ;
                                        d[_rd]=mktime( _dp" 1 0 0 0" ) ; 
                                        }
                        } { 
                                _do[$1]=$2";"$3";"$4";"$5";"$6
                        } END {
                                for ( a in d ) {
                                        if ( _do[a] == "" ) { 
                                                print a";0;0;0;0;0" ;
                                        } else {
                                                print a";"_do[a] ;
                                        }
                                }
                        }' | sort -t\; -n 
	;;
        year)
		cat $_files | awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '
			$1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c { 
				_h=strftime("%Y",$1) ; 
				if ( h[_h] == "" ) { 
					h[_h]="1;"$10+0";"$11+0";"$8";"$12 
				} else { 
					split(h[_h],ch,";") ; 
					h[_h]=ch[1]+1";"ch[2]+$10";"ch[3]+$11";"ch[4]+$8";"ch[5]+$12 
				}
			} END { 
				for ( i in h ) { 
					split(h[i],eo,";") ; 
					print i";"eo[1]";"eo[2]";"eo[3]";"eo[4]";"eo[5]/3600 }
			}' | sort -t\; -n
        ;;
        user)
                cat $_files | sort -n -t\; |
		awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '{
		if ( $1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c ) {
			u[$3]++ ;
			n[$3]=n[$3]+$8 ; 
			j[$3]=j[$3]+$10 ; 
			w[$3]=w[$3]+$11 ; 
			s[$3]=s[$3]+$12 
			}
		} END { for ( i in u ) { 
			print i";"u[i]";"j[i]";"w[i]";"n[i]";"s[i]/3600 
			}
		}' | sort -n -t\; -k2,2rn
        ;;
        partition)
                cat $_files | sort -n -t\; |
		awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '{
		if ( $1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c ) {
			p[$4]++ ;
			n[$4]=n[$4]+$8 ; 
			j[$4]=j[$4]+$10 ; 
			w[$4]=w[$4]+$11 ; 
			s[$4]=s[$4]+$12 
			}
		} END { for ( i in p ) { 
			print i";"p[i]";"j[i]";"w[i]";"n[i]";"s[i]/3600 
			}
		}' | sort -n -t\; -k2,2rn
        ;;
	state)
                cat $_files | sort -n -t\; |
		awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '{
		if ( $1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c ) {
			t[$14]++ ;
			n[$14]=n[$14]+$8 ; 
			j[$14]=j[$14]+$10 ; 
			w[$14]=w[$14]+$11 ; 
			s[$14]=s[$14]+$12 
			}
		} END { for ( i in t ) { 
			print i";"t[i]";"j[i]";"w[i]";"n[i]";"s[i]/3600 
			}
		}' | sort -n -t\; -k2,2rn
	;;
        state_old)
                cat $_files | sort -n -t\; | awk -F\; -v _p="$_par_par" -v _u="$_par_usr" -v _c="$_par_sta" -v _ds="$_par_ds" -v _de="$_par_de" '{ if ( $1 >= _ds && $1 <= _de && $3 ~ _u && $4 ~ _p && $14 ~ _c ) { print $14 }}' | sed -e 's/ /_/g' | sort | uniq -c  | awk '{ print $2";"$1 }'
	;;
        esac
}

format_output()
{
	case "$_par_show" in
	commas)
		if [ "$_opt_hea" != "yes" ]
		then
			echo "source;$_par_src"
			echo "date start;$_par_date_start"
			echo "date end;$_par_date_end"
			[ ! -z "$_par_grp" ] && echo "GROUP BY: $_par_grp" && _title=$_par_grp
			echo "$_title;numjobs;kjulius;kwatt/h;nodes;exptime/h"
		fi

		echo "${_output}"
	;;
	human)

		_filter="0"

		echo "SOURCE: $_par_src"
		echo "DATE RANGE FROM $_par_date_start TO $_par_date_end "$( [ "$_par_grp" == "hour" ] && echo "DAYS FOR HOUR AVERAGE: "$_hour_days )
		echo "TOTAL REGISTER PROCESSED: "$( cat $_files | wc -l )
		echo "ACTIVE FILTERS:"
		[ ! -z "$_par_par" ] && echo " PARTITION: $_par_par" && let "_filter++"
		[ ! -z "$_par_usr" ] && echo " USER: $_par_usr" && let "_filter++"
		[ ! -z "$_par_sta" ] && echo " JOB STATE: $_par_sta" && let "_filter++"
		[ "$_filter" == "0" ] && echo " NONE"
		[ ! -z "$_par_grp" ] && echo "GROUP BY: $_par_grp" && _title=$( echo $_par_grp | tr [:lower:] [:upper:] ) || _title="DAY" 
		echo
		echo -e "$_title;NUM JOBS;KJULIUS;KWATT/h;NODES;EXP TIME (h)\n--------;-------;--------;--------;--------;--------\n${_output}" | column -s\; -t
	;;
	wiki)
		_gcolor_job="#"$( echo Jobs | hexdump -e '16/1 "%x" "\n"' | sed 's/.*\(......\)$/\1/' )	
		_gcolor_nod="#"$( echo Nodes | hexdump -e '16/1 "%x" "\n"' | sed 's/.*\(......\)$/\1/' )	
		_gcolor_ete="#"$( echo Time | hexdump -e '16/1 "%x" "\n"' | sed 's/.*\(......\)$/\1/' )	

		echo "|< 100% >|"
		echo "|  $_color_title ** SLURM STATISTICS INFO **  ||||"
		echo "|  $_color_header SOURCE  |  $_color_header FROM  |  $_color_header TO  |  $_color_header GROUP BY  |" 
		echo "|  $_par_src  |  $_par_date_start  |  $_par_date_end  |  $_par_grp  |"
		echo

		case "$_par_grp" in 
		day|month|year)
			echo "${_output}" | awk -F\; -v _dr="$_par_grp" -v _ch="$_color_header" -v _ct="$_color_title" -v _gcj="$_gcolor_job" -v _gcn="$_gcolor_nod" -v _gce="$_gcolor_ete" '
				BEGIN {
					_tty="|  "_ct" ** Date **  |  "_ct" Year   "
					_ttm="|  :::   |  "_ct" Month  "
					_ttd="|  :::   |  "_ct" Day  |  "
					_tj="|  "_ct" ** Jobs **  ||  "
					_tn="|  "_ct" ** Nodes **  ||  "
					_te="|  "_ct" ** E.T.(h) **  ||  "
				} { 
					split($1,m,"_") ; 
					split(m[1],d,"-") ;
					if ( _dr == "month" ) { d[3]="1" } ;

					_ts=mktime( d[1]" "d[2]" "d[3]" 0 0 1" ) ;

					if ( _dr == "day" ) { m[2]=strftime("%b",_ts) ;  _ttd=_ttd""_ch" "d[3]"  |  " } ;
				
					if ( d[2] == _lm && _dr == "month" ) { _ttm=_ttm"|"  } else if ( d[2] != _lm && _dr == "month" ) { _lm=d[2] ; _ttm=_ttm"|  "_ch" "m[2]"  " }
					if ( d[1] == _ly && _dr == "month" ) { _tty=_tty"|" ; _fg=d[2] } else if ( d[1] != _ly && _dr == "month" ) { _ly=d[1] ; _tty=_tty"|  "_ch" "d[1]"  " ; _fg=d[1]"-"d[2] }
					if ( d[2] == _lm && _dr == "day" ) { _ttm=_ttm"|" ; _fg=d[3] } else if ( d[2] != _lm && _dr == "day" ) { _lm=d[2] ; _ttm=_ttm"|  "_ch" "m[2]"  " ; _fg=m[2]"_"d[3] }
					if ( d[1] == _ly && _dr == "day" ) { _tty=_tty"|" } else if ( d[1] != _ly && _dr == "day" ) { _ly=d[1] ; _tty=_tty"|  "_ch" "d[1]"  " ; _fg=d[1]" "m[2]"_"d[2] }

					_tj=_tj""$2"  |  " ;
					_tn=_tn""$5"  |  " ;
					_te=_te""$6"  |  " ;

					_jobs=_jobs""_fg"="$2"\n"
					_nodes=_nodes""_fg"="$5"\n"
					_et=_et""_fg"="$6"\n"
				} END { 
					print "|< 100% >|"
					print "|  "_ch" Total Jobs  ||"
					print "|  <gchart 850x350 line "_gcj" #ffffff center>" ; 
					print _jobs
					print "</gchart>  ||"
					print "|  "_ch" Nodes Reserved  |  "_ch" Expended Cluster Time (h)  |"
					print "|  <gchart 650x350 line "_gcn" #ffffff center>" ;
					print _nodes
					print "</gchart>  |  <gchart 650x350 line "_gce" #ffffff center>" ; 
					print _et
					print "</gchart>  |" ;
					print " " ;
					print "|< 100% 4% 4% >|" ;
					print _tty"|" ;
					print _ttm"|" ;
					if ( _dr == "day" ) { print _ttd } ;
					print _tj ;
					print _tn ;
					print _te ;
				}' | sed '/^$/d'
		;;
		user|partition|state)
			if [ "$_opt_dbg" == "yes" ]
			then
				echo 
				echo "-----------------------"
				echo "DEBUGING"
				echo "${_output}"
				echo "-----------------------"
				echo
			fi

			echo "${_output}" | awk -F\; -v _dr="$_par_grp" -v _ch="$_color_header" -v _ct="$_color_title" -v _gcj="$_gcolor_job" -v _gcn="$_gcolor_nod" -v _gce="$_gcolor_ete" '
				BEGIN {
					_gf="line" ;
					if ( _dr == "user" ) {  _tu="|  "_ct" ** Users **  |  " ; _gf="pie2d" } ; 
					if ( _dr == "partition" ) {  _tp="|  "_ct" ** Partitions **  |  " ; _gf="pie2d" } ; 
					if ( _dr == "state" ) { _ts="|  "_ct" ** States **  |  " ; _gf="value hbar" } ; 
					_tj="|  "_ct" ** Jobs **  |  " ; 
					_tn="|  "_ct" ** Nodes **  |  " ; 
					_te="|  "_ct" ** E.T.(h) **  |  " ;
				} {
					if ( FNR <= 10 ) { 	
						_jobs=_jobs""$1"="$2"\n"
						_nodes=_nodes""$1"="$5"\n"
						_et=_et""$1"="$6"\n"
					} else { 
						_jot=_jot+$2
						_not=_not+$5
						_net=_net+$6
					}

					if ( _dr == "user" ) { _tu=_tu" "_ch" ** "$1" **  |  " ; }
					if ( _dr == "partition" ) { _tp=_tp" "_ch" ** "$1" **  |  " ; }
					if ( _dr == "state" ) { _ts=_ts" "_ch" ** "$1" **  |  " ; }
					_tj=_tj""$2"  |  " ;
					_tn=_tn""$5"  |  " ;
					_te=_te""$6"  |  " ;
				} END {
					if ( NR > 10 ) { 
						_jobs=_jobs"others="_jot"\n" 
						_nodes=_nodes"others="_not"\n"
						_et=_et"others="_net"\n"
					}
					print "|< 100% >|"
					print "|  "_ch" Total Jobs  ||"
					print "|  <gchart 850x350 "_gf" "_gcj" #ffffff center>" ; 
					print _jobs
					print "</gchart>  ||"
					print "|  "_ch" Nodes Reserved  |  "_ch" Expended Cluster Time (h)  |"
					print "|  <gchart 650x350 "_gf" "_gcn" #ffffff center>" ;
					print _nodes
					print "</gchart>  |  <gchart 650x350 "_gf" "_gce" #ffffff center>" ; 
					print _et
					print "</gchart>  |" ;
					print " " ;
					print "|< 100% >|" ;
					if ( _dr == "user" ) { print _tu ; }
					if ( _dr == "partition" ) { print _tp ; }
					if ( _dr == "state" ) { print _ts ; }
					print _tj ;
					print _tn ;
					print _te ;
				}' | sed '/^$/d'
		;;
		esac
	;;
	esac
}

init_date()
{
        
        _date_tsn=$( date +%s )
        
        case "$_par_date_start" in
        day)    
                #_ask_date=$( date -d "last day" +%Y-%m-%d )
                _ts_date=86400
                
                let _par_ds=_date_tsn-_ts_date
                _par_de=$_date_tsn
                
                _date_filter="hour"
                _par_date_start=$( date -d "last day" +%Y-%m-%d )
                _par_date_end=$( date +%Y-%m-%d )
        ;;
        week|"")   
                #_ask_date=$( date -d "last week" +%Y-%m-%d )
                _ts_date=604800
                
                let _par_ds=_date_tsn-_ts_date
                _par_de=$_date_tsn
                
                _date_filter="day"
                _par_date_start=$( date -d "last week" +%Y-%m-%d )
                _par_date_end=$( date +%Y-%m-%d )
        
        ;;
        month)  
                #_ask_date=$( date -d "last month" +%Y-%m-%d )
                _ts_date=2592000
                
                let _par_ds=_date_tsn-_ts_date
                _par_de=$_date_tsn
                
                _date_filter="day"
                _par_date_start=$( date -d "last month" +%Y-%m-%d )
                _par_date_end=$( date +%Y-%m-%d )
        ;;
        year)   
                #_ask_date=$( date -d "last year" +%Y-%m-%d )
                _ts_date=31536000
                
                let _par_ds=_date_tsn-_ts_date
                _par_de=$_date_tsn
                
                _date_filter="month"
                _par_date_start=$( date -d "last year" +%Y-%m-%d )
                _par_date_end=$( date +%Y-%m-%d )
        ;;
        "Jan-"*|"Feb-"*|"Mar-"*|"Apr-"*|"May-"*|"Jun-"*|"Jul-"*|"Aug-"*|"Sep-"*|"Oct-"*|"Nov-"*|"Dec-"*)
		_date_year=$( echo $_par_date_start | cut -d'-' -f2 )
		_date_month=$( echo $_par_date_start | cut -d'-' -f1 )
                
                _query_month=$( date -d '1 '$_date_month' '$_date_year +%m | sed 's/^0//' )
                _par_ds=$( date -d '1 '$_date_month' '$_date_year +%s )
                
                let "_next_month=_query_month+1"
                [ "$_next_month" == "13" ] && let "_next_year=_date_year+1" && _next_month="1" || _next_year=$_date_year
                
                _par_de=$( date -d $_next_year'-'$_next_month'-1' +%s)
                
                let "_par_de=_par_de-10"
                
                _date_filter="month"
                _par_date_start=$( date -d @$_par_ds +%Y-%m-%d )
                _par_date_end=$( date -d @$_par_de +%Y-%m-%d )
        ;;
	2[0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9])
		
		_date_filter="day"

		_par_ds=$( date -d $_par_date_start +%s )
		if [ -z "$_par_date_end" ] 
		then
			_par_de=$( date +%s ) 
			_par_date_end=$( date +%Y-%m-%d )
		else
			_par_de=$( date -d $_par_date_end +%s ) 
		fi
	;;
        2[0-9][0-9][0-9])
                _par_ds=$( date -d '1 Jan '$_par_date_start +%s )
                _par_de=$( date -d '31 Dec '$_par_date_start +%s )
                
                _date_filter="month"
                _par_date_start=$( date -d @$_par_ds +%Y-%m-%d )
                _par_date_end=$( date -d @$_par_de +%Y-%m-%d )
        ;;
        esac

	let "_hour_days=((_par_de-_par_ds)/86400)+1"
}

###########################################
#               MAIN EXEC                 #
###########################################

	[ -z "$_par_src" ] && echo -e "\nNeed Slurm Data Source\nUse -h for help\n" && exit 1

	
	#### DATE PROCESSING ####

	init_date

	#### FILE PROCESSING ####

	#_files=$( ls -1 $_stat_slurm_data_dir/$_par_src/*.txt | awk -F\/ -v _ds="$_par_ds" -v _de="$_par_de" '{ split ($NF,a,".") ; _date=mktime(" "a[1]" "a[2]" 1 0 0 0") ; if ( _date >= _ds || _date <= _de ) { print $0 }}' )
	_files=$( ls -1 $_stat_slurm_data_dir/$_par_src/*.txt | awk -F\/ -v _ds="$_par_ds" -v _de="$_par_de" '
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
			_date_s=mktime(" "a[1]" "a[2]" "_last_day" 0 0 0") ; 
			_date_e=mktime(" "a[1]" "a[2]" 1 0 0 0") ; 
			if ( _date_s >= _ds && _date_e <= _de ) { print $0 }
		}' )

	[ -z "$_files" ] && echo -e "Thrershold betwen:\nStart Data: $_par_date_start 00:00:00 ($_par_ds)\nEnd Data: $_par_date_end 23:59:59 ($_par_de)\nBase Dir: $_stat_slurm_data_dir/$_par_src\nERR: No data files finding" && exit 1

	[ "$_opt_dbg" == "yes" ] && echo -e "\n\nDEBUG:\n Thrershold betwen:\nStart Data: $_par_date_start 00:00:00 ($_par_ds)\nEnd Data: $_par_date_end 23:59:59 ($_par_de)\nParameters:$@\nBase Dir: $_stat_slurm_data_dir/$_par_src\nFiles:\n${_files}\n\n"

	[ -z "$_par_ds" ] && _par_ds=$( date -d "$_par_date_start 00:00:00" +%s )
	_output=$( calc_data )

	format_output
