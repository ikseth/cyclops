#!/bin/bash

source /etc/cyclops/global.cfg
source $_color_cfg_file

_clusters=$( awk -F\; '$0 !~ "^#" { print $1 }' $_config_path_srv/slurm.environment.cfg )

_nodes=$( cat $_type  | cut -d\; -f2,4,7 )

load_slurm_status()
{
	unset _jobs

	for _cluster in $( echo "${_clusters}" ) 
	do
		_jobs=$_jobs""$( $_script_path/service.slurm.sh -f $_config_path_srv/$_cluster -v commas | egrep -v "partition|No waiting jobs" )"\n" 
	done

	_jobs=$( echo -e "${_jobs}" ) 
}

load_cyclops_mon()
{
	_node_real_status=$( 
			cat $_mon_path/monnod.txt | 
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
					}
					print _ns";"n[2]";"_wn";"_sens ; 
					_sens="" ; 
				}'
			)
}

merge_node_status()
{
	_merge_status=$( echo -e "${_nodes}" | sed -e '/No waiting jobs/d' -e '/partition/d' | awk -F\; -v _j="$_jobs" -v _nrs="$_node_real_status" '
	    BEGIN {
		split(_j,l,"\n") ;                                                                  
		split(_nrs,nrs,"\n") ;
		for ( a in nrs ) {
			split(nrs[a],nrsf,";") ;
			ns[nrsf[2]]=nrsf[1]";"nrsf[3]";"nrsf[4]	
		}
		delete nrs ;
		delete nrsf ;
	    } { 
		for ( i in l ) { 
		    split(l[i],f,";") ; 
		    if ( $1 == f[3] ) { 
			u[$1]=u[$1]""f[4]"," ; 
			j[$1]++ 
		    }
		} ; 
		s[$1]=$3 ;
		nf[$1]=$2 ;
	    } END { 
		for ( i in s ) { 
		    sub(/,$/,"",u[i]) ; 
		    _g="" ;
		    _pos=gensub(/[a-z]+([0-9])([0-9])([0-9][0-9])/,"\\1;\\2;\\3", "g", i)
		    if ( _pos !~ "^[0-9;]+" ) { _pos="0;0;"gensub(/[a-z]+([0-9]+)/,"\\1", "g" , i ) }
		    print _pos";"i";"nf[i]";"toupper(s[i])";"u[i]";"j[i]";"ns[i]
		}
	    }' )
}

cluster_status_summary()
{
	_cs_summary=$( echo "${_merge_status}" | sort -n -t\; | awk -F\; '
		{ 
			if ( $10 !~ "n/a" ) { 
				if ( $8 != "" ) { $8="CPW" } else { $8="CPI" } 
			} else { 
				$8="SRV" 
			} ; 
			nod[$1":"$2]=nod[$1":"$2]""$9" "$8";" 
		} END { 
			for ( i in nod ) { print i";"nod[i] }
		}' | sort -n )

}

format_wiki()
{
	_output_css=$( echo "$_cs_summary" | awk -F\; '
		BEGIN {
			OFS=";"
			_nf=0
			_pol="NA"
			_nsu="{{ :wiki:srv.png?20&nolink }}"
			_nsw="{{ :wiki:pg_sr0.gif?nolink }}"
			_nsd="{{ :wiki:srv_drain.png?20&nolink }}"
		}
		{
			if ( _nf <= NF ) { _nf=NF } 
			split ($1,p,":") ;
			gsub("SRV",_nsu,$0)
			gsub("CPW",_nsw,$0)
			gsub("UP CPI","UP",$0)
			gsub("CPI",_nsd,$0)
			if ( p[1] != _pol ) { 
				_pol=p[1] ;
				_ppr=p[1]
			} else {
				_ppr=":::"
			}
			if ( p[2] ~ "0+" ) { p[2]="" }
			$1=_ppr";"p[2]
			_out=_out";"$0"\n"
		} END {
			_title=";@ Rack;@ Chassis"
			for (i=3;i<=_nf;i++) { _title=_title";@ node "(i-2)  }
			print "|< 100% >|"
			print _title";" ;
			print _out
		}' )
		
			 
	_output_css=$( echo -e "${_output_css}" | sed -e 's/^;/|  /' -e 's/;$/  |/' -e 's/;/  |  /g' -e "s/@/$_color_title/g" -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/FAIL/$_color_fail/g" -e "s/UNKNOWN/$_color_unknown/g" -e "s/UNKN/$_color_unk/g" -e "s/UNLINK/$_color_mark/" -e "s/REPAIR/$_color_mark/" -e "s/DIAGNOSE/$_color_mark/g" -e "s/LINK/$_color_mark/g" -e "s/MARK/$_color_mark/g" -e "s/CHECKING/$_color_check/g" -e "s/DISABLE/$_color_disable/g" -e "s/LOADED/$_color_loaded/g" -e "s/MAINTENANCE/$_color_disable/g" -e "s/DRAIN/$_color_disable/" -e "s/POWEROFF/$_color_poweroff/" -e "s/DEAD/$_color_dead/g" -e 's/·//g' -e "s/QUITE/$_color_up/" -e "s/WORK/$_color_ok/" -e '/^$/d' )

	_status=$( echo "${_merge_status}" | sort -t\; -k1,1n -k2,2n -k3,3n | awk -F\; '
	    BEGIN {
		_jiw="{{ :wiki:pg_sr0.gif?nolink |}}"
		_jis="{{ :wiki:hb-zzz-gen.gif?nolink }}"
		_jiss="{{ :wiki:hb-gray-medium.gif }}"
		_jio="{{ :wiki:hb-green-medium.gif?nolink }}"
		_jir="{{ :wiki:hb-yellow-green.gif?nolink }}"
		_jirw="{{ wiki:hb-zzz-yellow.gif }}" 
		_nsu="{{ :wiki:srv.png?20&nolink }}"
		_nsw="{{ :wiki:srv_wrk.png?20&nolink }}"
		_nsd="{{ :wiki:srv_drain.png?20&nolink }}"
		_nso="{{ :wiki:srv_pwroff.png?20&nolink }}"
		_nse="{{ :wiki:srv_err.png?20&nolink }}"
		_nsg="{{ :wiki:srv_diag.png?20&nolink }}"
		_nsl="{{ :wiki:srv_link.png?20&nolink }}"
		_x="INIT" ; 
		_t=systime() ; 
	    } { 
		if ( $9 == "UP" ) { 
			_ns=$9" "_nsu 
			if ( $10 == "n/a" ) { 
				_jgs=_jio ; 
				_an="UP Server Operation" ; 
				_ns=$9" "_nsu 
			} else { 
				if ( $7 == "" ) { 
					_jgs=""_jis ; 
					_an="UP" 
				} else {
					_an="OK Slurm: <fc white> ** "$7" ** </fc>"  ; 
					_jgs=_jiw
					if ( $9 == "UP" ) { _ns=$9" "_nsw }
				} 
			}
		}
		if ( $9 == "MAINTENANCE" ) { 
			_ns=$9" "_nso ; 
			_an=""
			_jgs=""
			if ( $7 == "" && $10 != "n/a" ) {
				_ns=$9" "_nsd ;
				_an="DISABLE" ;
				_jgs=_jis     ;
			}
			if ( $7 != "" && $10 != "n/a" ) {
				_ns=$9" "_nsw ;
				_an="DISABLE Slurm: ** "$7" ** " ;
				_jgs=_jiss    ;
			}
		}
		if ( $9 == "REPAIR" ) { 
			_ns=$9" "_nsr 
			if ( $7 == "" ) { 
				_jgs=_jirw
				_an="DISABLE"
			} else {
				_jgs=_jir ;
				_an="REPAIR Slurm: "$7 ;
			}
		}
		if ( $9 == "FAIL" || $9 == "DOWN" ) {
			_ns=$9" "_nse
			if ( $7 == "" ) { 
				_jgs=_jirw    ;
				_an="DISABLE" ;	
			} else {
				_jgs=jir ;
				_an="MARK Slurm: "$7 ;
			}
		}
		if ( $9 == "DIAGNOSE" ) {
			_ns=$9" "_nsg
			if ( $7 == "" ) {
				_jgs=_jirw ;
				_an="CHECKING" ;
			} else { 
				_jgs=_jir ;
				_an="CHECKING Slurm: "$7 ;
			}	
		}
		if ( $9 == "LINK" ) {
			_ns=$9" "_nsl
			_an="MARK"
		}
		if ( _x != $1 ) { 
		    _x=$1 ; 
		    _y=$2 ;
		    _po=$5 ;
		    print "<tabbox RACK "$1">" ; 
		    print "|< 100% 4% 4% 16% 66% 10% >|" ; 
		    print "|  @ ** Chassis "_x""_y" **  |||||" ; 
		    print "|  ID  |  Status  |  Group  |  Activity Name  |  Activity  |" 
		    print "|  "$6" "$3"  |  "_ns" |  "$5"  |  "_an"  |  "_jgs"  |" 
		} else if ( _y != $2 ) { 
			_y=$2 ;
			_po=$5 ;
			print "|  @ ** Chassis "_x""_y" **  |||||"  ; 
		    	print "|  ID  |  Status  |  Group  |  Activity Name  |  Activity  |" 
			print "|  "$6" "$3"  |  "_ns"  |  "$5"  |  "_an"  |  "_jgs"  |" 
		} else {
		    if ( _po != $5 ) { 
			_po=$5 ; _ppo=$5  
		    } else { 
			_ppo=":::" 
		    }
		    print "|  "$6" "$3"  |  "_ns"  |  "_ppo"  |  "_an"  |  "_jgs"  |" }
	    	}' )

	_output_dtl=$( echo -e "${_status}" | sed -e 's/^;/|  /' -e 's/;$/  |/' -e 's/;/  |  /g' -e "s/@/$_color_title/g" -e "s/UP/$_color_up/g" -e "s/DOWN/$_color_down/g" -e "s/OK/$_color_ok/g" -e "s/FAIL/$_color_fail/g" -e "s/UNKNOWN/$_color_unknown/g" -e "s/UNKN/$_color_unk/g" -e "s/UNLINK/$_color_mark/" -e "s/REPAIR/$_color_mark/" -e "s/DIAGNOSE/$_color_mark/g" -e "s/LINK/$_color_mark/g" -e "s/MARK/$_color_mark/g" -e "s/CHECKING/$_color_check/g" -e "s/DISABLE/$_color_disable/g" -e "s/LOADED/$_color_loaded/g" -e "s/MAINTENANCE/$_color_disable/g" -e "s/DRAIN/$_color_disable/" -e "s/POWEROFF/$_color_poweroff/" -e "s/DEAD/$_color_dead/g" -e 's/·//g' -e "s/QUITE/$_color_up/" -e "s/WORK/$_color_ok/" -e '/^$/d' )


	_page_refresh=$( 
		echo "
<html>
   <meta http-equiv="refresh" content="120" >
   <META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE">
   <META HTTP-EQUIV="EXPIRES" CONTENT="0">
   <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
</html>
~~NOCACHE~~
"
	)

	echo "==== CLUSTER STATUS - SLURM ====" ; 
	echo 
	echo "  *  Last Update: "$( date +%F\ %T ) 
	echo "  *  <fc red> ** Still Experimental ** </fc>"
	echo 
	echo "${_page_refresh}"
	echo 
	echo "<tabbox Summary>"
	echo "${_output_css}"
	echo "${_output_dtl}" 
	echo "</tabbox>"
}

############# MAIN EXEC ##############

	load_slurm_status
	load_cyclops_mon
	merge_node_status
	cluster_status_summary
	format_wiki

