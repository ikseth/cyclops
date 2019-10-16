#!/bin/bash
IFS="
"

_colors_file="/opt/cyclops/local/etc/colors.cfg"

[ -f "$_colors_file" ] && source $_colors_file 

_par_show="human"

while getopts ":ltw:acu:f:v:h:" _optname
do
	case "$_optname" in
		"a")
			# PROCESS VARIABLES #
			_opt_var="yes"
		;;
                "c")
			# SOURCE CRON ACTIVE SCRIPTS #
                        _opt_crn="yes"
                ;;
		"f")
			# SOURCE FILE #
			_opt_fil="yes"
			_par_fil=$OPTARG	
		;;
		"l")
			# LOOP ANALISYS
			_opt_loo="yes"
		;;
		"t")
			# WAIT ANALISYS
			_opt_wai="yes"
		;;
		"w")
			# EXTRA WORDS ANALISYS
			_opt_wrd="yes"
			_par_wrd=$OPTARG
		;;
		"u")
			# USER FILTER
			_opt_usr="yes"
			_par_usr=$OPTARG
		;;
		"v")
			# OUTPUT FORMAT
			_opt_show="yes"
			_par_show=$OPTARG
		;;
		"h")
			echo "HELP HERE"
		;;
        esac
done

shift $((OPTIND-1))


process_data()
{
	unset _content 
	if [ -f "$_file" ] 
	then
		_content=$( cat $_file 2>/dev/null )
	else
		echo "ERR: FILE DOESN'T EXISTS: $_file" 
		exit 1
	fi
	[ ! -z "$_content" ] && _process=$( echo "${_content}" | awk -v _wlist="$_par_wrd" -v _ov="$_opt_var" -v _f="$_file" -v _cb="$_sh_color_bolt" -v _nf="$_sh_color_nformat" -v _cr="$_sh_color_down" '
		BEGIN { 
			_c=0 ; 
			_ctrlb=0 ;
			_varstrg=0 ; 
			_disable=0 ;
			_lword=split(_wlist,wrds,",") ;
			_matchwc=0
		} {
			for (a=1;a<=NF;a++) {
				if ( $a == "awk" ) { 
					_awkctrl=1 ; 
					_awkpos=NR";"NF ; 
					_awkNRi=NR ; 
					awk[_awkpos]=$a 
				}
				if ( _awkctrl == 1 ) { 
					if ( NR != _awkNRi ) { 
						awk[_awkpos]=awk[_awkpos]" ;"$a 
					} else { 
						awk[_awkpos]=awk[_awkpos]" "$a 
					}
				}
				if ( _awkctrl == 1 && $a ~ /[}]['\'']/ ) { _awkctrl=0 }
				if ( _lword != 0 && $1 !~ /^#/ ) {
					_lwordd++ ;
					for ( w in wrds ) {
						if ( $a ~ wrds[w] && $a !~ "[a-zA-z_-]+"wrds[w]"[a-zA-z0-9_-]+" ) {
							matchw[wrds[w]]++ ;
							_matchwc++	  ;
							_matchctrl=1	  ;
						}
					} 
				}
			}
			if ( _lword != 0 && _matchctrl == 1 ) { matchl[NR]=$0 ; _matchctrl=0 }
		} $1 !~ /^#|echo/ && _awkctrl == 0 { 
			gsub("^[ \t]+","",$0) ;
			if ( _ov == "yes" ) { 
				for (i=1;i<=NF;i++) {
					if ( _varstrg == 1 ) {
						if ( $i ~ /[;")}`'\'']/ ) { 
							_varstrg=0 ; 
							split($i,vartemp,";") ; 
							variables[varspl[1]]=variables[varspl[1]]" "vartemp[1] ; 
						} else {  
							variables[varspl[1]]=variables[varspl[1]]" "$i 
						}
					}
					if (  _varstrg == 0 && $i ~ "^[A-Za-z0-9_-]+=" && $i !~ /^[$-]/ && $i !~ "==" ) {
							split($i,varspl,"=") ;
							if ( varspl[1] != "" && varspl[2] != "" ) { 
								_varlock++ ; 
								if ( varspl[2] ~ ";" && varspl[2] !~ /["]/ ) {
									split(varspl[2],vartmp,";") ;
									variables[varspl[1]]=vartmp[1]; 
								} else {
									variables[varspl[1]]=varspl[2] ; 
								}
							}
							if ( varspl[2] ~ /["({`'\'']/ && varspl[2] !~ /[;")}`'\'']$/ ) { _varstrg=1 }
							varpos[varspl[1]]=NR":"NF ;
					}
					if ( $i ~ /[$]/ && _varstrg == 0 && _disable==0 ) {
						_varmatch++ ;
					}
				}
				for ( v in variables ) {
					gsub("[$]"v"[);/$]",""variables[v]"") 
					gsub("[$]{"v"}",""variables[v]"") 
					gsub("[$]"v"$",""variables[v]"") 
				}
				_varstrg=0 ; 
			}
			if ( $0 ~ /while |for / && $1 !~ "#" ) { 
				_bucle++ ;  
				buclestr[_bucle]=NR"·"$0  
			} ;  
			if ( _sp == 1 && $0 ~ "wait" ) { 
				_line=_line"\n"_f"·WAIT·"NR"·"$0 ; _sp=0 
			} ; 
			if ( $0 ~ / &$|scp|mpirun|sbatch|srun|ssh|rsync|nimbus|sum|find|sacct|\.sh|[0-2]+\.[0-9]+\.[0-9]+\.[0-9]+|[a-z0-9]+\.[a-z0-9]\./ ) { 
				if ( $NF == "&" ) { _sp=1 } ; 
				if ( _bucle > 0 ) {  
					_match=1 ; 
					_ctrlb=1 ; 
					for(i=1;i<=_bucle;i++) {  
						if ( buclestr[i] != "" ) { 
							_line=_line"\n"_f"·LOOP·"buclestr[i] ; 
							buclestr[i]="" 
						}
					}  
				} ; 
				_c++ ;  
				_line=_line"\n"_f"·LINE·"NR"·"$0
			} 
			if ( $0 ~ "done" && _bucle > 0 && _match == "1" ) { 
				delete buclestr[_bucle] ; 
				_bucle-- ; 
				if ( _bucle <= 1 ) { _match=0 } ; 
				_line=_line"\n"_f"·LOOP·"NR"·"$0 
			} else {  
				if  ( $0 ~ "done" && _match != "1" ) { 
					delete buclestr[_bucle] ; 
					_bucle-- 
				}
			} 
		} END { 
			if ( _c > 0 ) { 
				print _line ; 
				if ( _sp == "1" ) { 
					print _f"·WAIT_RESULT·NO WAIT" 
				} else if ( _sp == "0" ) { 
					print _f"·WAIT_RESULT·OK"
				} 
				if ( _ctrlb == 1 ) { 
					print _f"·LOOP_ANALYSIS·"_bucle"·"_match
				} ; 
				if ( _ov == "yes" ) {
					for ( v in variables ) {
						printf "%s·VAR·%s·%s·%s\n", _f, varpos[v], v, variables[v]
					}
					print _f"·VARIABLES_ANALYSIS·"_varlock"·"_varmatch
				}
				print _f"·WORD_ANALYSIS·"_matchwc"/"_lword
			} else { 
				print _f"·FILE CLEAN" 
			} 
			if ( _lword > 0 ) {
				for ( m in matchw ) {
					printf "%s·WORD_COUNT·%s = %s\n", _f, m, matchw[m]
				}
				for ( k in matchl ) {
					printf "%s·WORD·%s·%s\n", _f, k, matchl[k]
				} 
			}
		}' ) || _process=$( echo -e "\tFILE ERR: NO CONTENT: $_file" ) 
	echo -e "${_process}"
}

cron_filter()
{
	if [ "$_opt_usr" == "yes" ]
	then
		_usrctrl=$( getent passwd | awk -F\: -v _u="$_par_usr" 'BEGIN { _ctrl=0 } $1 == _u { _ctrl=1 } END { print _ctrl }' )
		if [ "$_usrctrl" == "0" ] 
		then
			echo "\tERR: NO USER FINDING: $_par_usr"
			exit 1
		else
			_userlist=$_par_usr
		fi
	else
		_userlist=$( getent passwd | cut -d':' -f1 | sort -u )
	fi

	for _user in $( echo "${_userlist}"  ) 
	do 
		_cron=$( crontab -l -u $_user 2>&1 | egrep -v "#|^$|no crontab"  ) 
		if [ ! -z "$_cron" ] 
		then 
			_home=$( getent passwd | cut -d":" -f 1,6 | sort -u | awk -F\: -v _u="$_user" '$1 == _u { print $2 }' ) 

			_cronfiles=$( echo "${_cron}" | awk '
				$1 ~ "[0-9]+" && $1 !~ "^#" && $0 !~ "no crontab" { 
					gsub(">"," > ",$0) ;
					_line="" ; 
					_ctlr=0 ; 
					for(i=6;i<=NF;i++) { 
						_line=_line""$i" " 
					} 
					if ( _line != "" ) { 
						print _line 
					}
				}' | tr ';' '\n' | sed 's/^ *//' | awk -v _h="$_home" '
					{ 
						if ( $1 ~ /source|sbatch|srun|bash|^sh|python|java/ ) { 
							_file=$1":"$2 
						} else { 
							_file="SHELL:"$1 
						} 
						gsub(".HOME",_h,_file) ; 
						print _file 
					}' | sort -u )
	
			for _line in $( echo "${_cronfiles}" ) 
			do 
				_ftype=$( echo "$_line" | cut -d':' -f1 )
				_file=$(  echo "$_line" | cut -d':' -f2 )
				process_data | sed -e "/^$/d" -e "s/^/$_user·$_ftype·/"
			done 
		fi 
	done
}

format_output()
{

	case "$_par_show" in
	human)
		echo "${_data}" | awk -F\· '
			{ 
				_line="" ;
				if ( $4 == "LOOP_ANALYSIS" ) {
					if ( $5 == 0 && $6 == 0 ) {
						$5="OK" ;
					} else {
						$5="INCONSISTENCE" ;
					}
					$6="" ;
				} 
				if ( NF >= 5 && $5 ~ "^[0-9]+" && $4 != "VAR" ) {
					_linectrl=1 ;
					for (a=6;a<=NF;a++) {
						_line=_line""$a"·" ;
					}
					gsub(/·$/,"",_line) ;
				} else {
					_linectrl=0 ;
				}
			} $1 != _usrold {
				_usrold=$1  ;
				_fileold=$3 ;
				print "\nUSER: "$1 ;
				print "\tFILE: "$3 ;
				print "\tTYPE: "$2 ; 
			} $1 == _usrold && $3 != _fileold {
				_fileold=$3 ;
				print "\n\tFILE: "$3
				print "\tTYPE: "$2 ; 
			} $1 == _usrold && $3 == _fileold {
				if ( _linectrl == 1 ) {
					print "\t\t"$4"\t"$5"\t"_line 
				} else {
					if ( $4 == "VAR" ) {
						print "\t\t\t"$4"\t"$5"\t"$6" = "$7
					} else {
						print "\t\t"$4"\t"$5
					}
				}
			}' 
	;;
	commas|debug)
		echo "${_data}"
	;;
	esac
		
}

	#### MAIN EXEC ####

		if [ "$_opt_crn" == "yes" ] 
	then
		_data=$( cron_filter )
		format_output
	else
		if [ -f "$_par_fil" ]
		then
			_file=$_par_fil
			_data=$( process_data | sed -e "/^$/d" -e "s/^/$USER·SHELL·/" )
			format_output
		else
			echo "ERR: NO FILE EXIT OR CRON OPTION ENABLED"
			exit 1 
		fi
	fi

