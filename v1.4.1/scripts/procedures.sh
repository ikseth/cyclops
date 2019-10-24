#!/bin/bash

###########################################
#     PROCEDURES MANAGEMENT  SCRIPT       #
###########################################

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

_pid=$( echo $$ )
_debug_code="PROCEDURES "
_debug_prefix_msg="Procedures: "
_exit_code=0

_opt_show="no"
_opt_changes="no"
_opt_action="no"
_opt_node="no"

## GLOBAL --

_config_path="/etc/cyclops"

if [ ! -f $_config_path/global.cfg ]
then
        echo "Global config file don't exits"
        exit 1
else
        source $_config_path/global.cfg
fi

source $_color_cfg_file

###########################################
#              PARAMETERs                 #
###########################################

_proc_action="start"
_par_show="human"

while getopts ":p:t:v:eh:" _optname
do

        case "$_optname" in
		"t")
			## Set type of procedure for filter script actions (node/dev/slurm/security)
			_opt_type="yes"
			_par_type=$OPTARG

			if [ !"$_par_show" == "node" ] || [ !"$_par_show" == "env" ] || [ !"$_par_show" == "rules" ]
                        then
                                echo "-t [type] select procedure type"
                                echo "          node: procedures designed for nodes/hosts"
                                echo "          env: procedures designed for environment devices like switch,power,etc."
				echo "		rules: show if sensor links procedure"
                                exit 1
                        fi
		;;
		"v")
			## Format script output 
                        _opt_show="yes"
                        _par_show=$OPTARG
                        if [ !"$_par_show" == "human" ] || [ !"$_par_show" == "wiki" ] || [ !"$_par_show" == "commas" ]
                        then
                                echo "-v [option] Show formated results"
                                echo "          human: human readable"
                                echo "          wiki:  wiki format readable"
                                echo "          commas: excell readable"
                                exit 1
                        fi
		;;
		"e")
			_opt_edi="yes"
		;;
		"p")
			## Show concrete procedure ##
			_opt_proc="yes"
			_par_proc=$OPTARG
			_par_type="procedure"
		;;
		"h")
			case "$OPTARG" in
                        "des")
                                echo "$( basename "$0" ) : Cyclops Prodedures Management Command"
				echo "	Default path: $( dirname "${BASH_SOURCE[0]}" )"
				echo "	Config path: $_config_path_mon"
				echo "		Config Codes file: $( echo $_sensors_ia_codes_file | awk -F\/ '{ print $NF }' )"
				echo "	Node IA path: $_sensors_ia_path"
				echo "	Env IA path: $_sensors_env_ia"
				echo "	Wiki path: $_pages_path/operation/procedures "
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
				echo "CYCLOPS PROCEDURE MANAGEMENT COMMAND"
				echo 
				echo "-t [type] select procedure type"
				echo "          node: procedures designed for nodes/hosts"
				echo "          env: procedures designed for environment devices like switch,power,etc."
				echo "		rules: show if sensor links procedure"
				echo "-p [procedure code|list] show content of specific procedure"
				echo "		list: show all available procedures"
				echo "-e EXPERIMENTAL: use vim to edit selected procedure"
				echo "-v [option] Show formated results"
				echo "          human: human readable"
				echo "          wiki:  wiki format readable"
				echo "          commas: excell readable"
				echo "-h [|des] help is help"
				echo "		des: Detailed Command Help"
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
#              FUNCTIONs                 #
###########################################


show_node_procedures()
{

        ## NODE IA PROCEDURES

        for _proc_file in $( ls -1 $_sensors_ia_path/* | awk '$1 ~ "rule$" { print $1 }' )
        do
                _code=$( echo $_proc_file | cut -d'.' -f2 )
                _priority=$( echo $_proc_file | awk -F\/ '{ print $NF }' | cut -d'.' -f1 )
                _host=$( cat $_proc_file | grep ^[0-9] | awk -F\; '{ if ( $3 == "" ) { $3="ALL" } { print $3 }}' | tr '\n' ',' | sed 's/,$//' )
                _sensors=$( cat $_proc_file | grep ^[0-9] | cut -d';' -f4- | sed -e 's/;/,/g' | tr '\n' ',' | sed 's/,$//'  )
                _file_des=$( grep "^$_code;" $_sensors_ia_codes_file | cut -d';' -f2 )
                [ -z "$_file_des" ] && _file_des="NONE"

                _wiki_file=$( ls -1 $_pages_path/operation/procedures/*.txt | cut -d'.' -f1 | tr '[:lower:]' '[:upper:]' | grep $_code | wc -l )
                _wiki_index=$( cat $_pages_path/operation/procedures/procedures.txt | grep $_code | wc -l )
                [ "$_wiki_index" -eq 0 ] && _wiki_index="NO" || _wiki_index="YES ("$_wiki_index")"
                if [ "$_wiki_file" -ne 0 ]
                then
                        _wiki_file=$( echo $_code | tr '[:upper:]' '[:lower:]' | sed -e 's/$/\.txt/' )
                        _wiki_version=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'  | awk -F\; '{ print $8 }' )
                        _wiki_verif=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $4 }' )
                        _wiki_opert=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $5 }' )
                else
                        _wiki_file="NO EXIST"
                        _wiki_version=""
                        _wiki_verif=""
                        _wiki_opert=""
                fi
                _proc_data=$_proc_data"\n"$_code";"$_file_des";"$_priority";"$_host";"$_sensors";"$_wiki_file";"$_wiki_index";"$_wiki_version";"$_wiki_opert";"$_wiki_verif
        done

        _output=$( echo $_header_procedure_output ; echo -e $_proc_data | sort )

}

show_env_procedures()
{

        ## ENV IA PROCEDURES 

        _proc_data=""

        for _proc_file in $( ls -1 $_sensors_env_ia/*.rule |  grep -v template  )
        do
                _code=$( echo $_proc_file | cut -d'.' -f2 )
                _priority=$( echo $_proc_file | awk -F\/ '{ print $NF }' | cut -d'.' -f1 )
                _env_dev=$( cat $_proc_file | grep ^[0-9] | awk -F\; '{ if ( $3 == "" ) { $3="ALL" } { print $3 }}' | tr '\n' ',' | sed 's/,$//' )
                _sensors=$( cat $_proc_file | grep ^[0-9] | cut -d';' -f4- | sed -e 's/;/,/g' | tr '\n' ',' | sed 's/,$//'  )
                _file_des=$( grep "^$_code;" $_sensors_ia_codes_file | cut -d';' -f2 )
                [ -z "$_file_des" ] && _file_des="NONE"

                _wiki_file=$( ls -1 $_pages_path/operation/procedures/*.txt | cut -d'.' -f1 | tr '[:lower:]' '[:upper:]' | grep $_code | wc -l )
                _wiki_index=$( cat $_pages_path/operation/procedures/procedures.txt | grep $_code | wc -l )
                [ "$_wiki_index" -eq 0 ] && _wiki_index="NO" || _wiki_index="YES ("$_wiki_index")"
                if [ "$_wiki_file" -ne 0 ]
                then
                        _wiki_file=$( echo $_code | tr '[:upper:]' '[:lower:]' | sed -e 's/$/\.txt/' )
                        _wiki_version=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'  | awk -F\; '{ print $8 }' )
                        _wiki_verif=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $4 }' )
                        _wiki_opert=$( cat $_pages_path/operation/procedures/$_wiki_file | awk -F\| -v _code=$_code '$2 ~ _code { print $0 }' | sed -e 's/ //g' -e 's/@#[A-F0-9]*\://g' -e 's/<[a-z /]*>//g' | tr '|' ';'    | awk -F\; '{ print $5 }' )
                else
                        _wiki_file="NO EXIST"
                        _wiki_version=""
                        _wiki_verif=""
                        _wiki_opert=""
                fi
                _proc_data=$_proc_data"\n"$_code";"$_file_des";"$_priority";"$_env_dev";"$_sensors";"$_wiki_file";"$_wiki_index";"$_wiki_version";"$_wiki_opert";"$_wiki_verif
        done

        _output=$( echo $_header_procedure_output ; echo -e $_proc_data | sort )
}

show_rules_link()
{
        echo "SENSOR;IA RULE LINK"
        for _sensor in $( ls -1R $_sensors_script_path/ | sed -e '/^$/d' | grep '.sh$' | grep -v "refactory" | sort -u  | cut -d'.' -f2 )
        do
                if grep -r $_sensor $_sensors_script_path/* >/dev/null
                then
                        echo "$_sensor;exist" 
                else
			[ "$_sensor" ==  "daemon_generic" ] && echo "$_sensor;Generic Sensor, Show Specific Config" || echo "$_sensor;Not exist"
                fi
        done | sort
}

show_procedure_link()
{
	#### NOT YET ACTIVE , COMMAND CHECK LINK BETWEN EXISTING PROCEDURE CODES WITH EXISTING IA RULES ####

	for _procedure in $( cat $_sensors_ia_codes_file | cut -d';' -f1 | awk '{ print $0 }' ) ; do _exist=$( ls -1 /opt/cyclops/monitor/sensors/status/ia/ | grep $_procedure | wc -l ) ; echo $_procedure":"$_exist  ; done
}

print_output()
{

        _header_procedure_output="CODE;DESCRIPTION;PRIORITY;HOST;SENSORS;WIKI FILE;WIKI INDEX;WIKI VER;OPERATIVE;VERIFICATED"


	case "$_par_show" in
	"human")
		echo -e "$_header_procedure_output\n${_output}" | column -s\; -t
	;;
	"wiki")
		echo
		echo "====== Procedure Status ($_par_type) ======"
		echo
		echo "|< 100% >|" 
		echo $_header_procedure_output | sed -e '/^$/d' -e "s/^/|  $_color_title/" -e 's/$/  |/' -e "s/;/  |  $_color_title /g"
		echo "${_output}" | sed -e '/^$/d' -e 's/^/|  /' -e 's/$/  |/' -e 's/;/  |  /g' -e "s/NO/$_color_down &/g" -e "s/YES/$_color_ok &/g" -e "s/SI/$_color_up &/g"

	;;
	"commas")
		echo -e "${_output}"
	;;
	"*")
		echo -e "${_output}"
	;;
	esac
	


}

print_generic()
{

	case "$_par_show" in
	"human")
		echo "${_output}" | column -s\; -t
	;;
	"wiki")
		echo "NO YET IMPLEMENTED IN THIS CASE, USE OTHER FORMAT [human|commas]"
	;;
	"commas")
		echo "${_output}"
	;;
	"*")
		echo "${_output}"
	;;
	esac
	
}

show_procedure()
{
	if [ -f "$_proc_file" ] 
	then
		awk -v _chm="$_color_mark" -v _chr="$_color_down" -v _chu="$_color_up" -v _ca="$_sh_color_gray" -v _ck="$_sh_color_blink" -v _cc="$_sh_color_cyc" -v _cr="$_sh_color_red" -v _co="$_sh_color_yellow" -v _cg="$_sh_color_green" -v _nf="$_sh_color_nformat" -v _cn="$_sh_color_bolt" -v _cm="$_sh_color_dim" '
			BEGIN { 
				print ""
			} {	 
				_tab=""
				if ( $1 ~ /=+.*=+/ ) { $0=toupper($0) } 
				$0=gensub(/[|]<.*>[|]/,"","g") ;  
				if ( $0 ~ /<\/hidden>/ ) {
					$0=_strghid"\n" ;
					_ctrlhid=0 ;
				}
				if ( _ctrlhid == 1 ) { _tabhid=" |\t" } else { _tabhid="" } 
				if ( $0 ~ /<hidden/ ) { 
					$0=gensub(/<hidden (.*)>/,"\\1","g",$0) ;
					$0=gensub(/^[ ]+/,"","g",$0 ) ; 
					_strghid=_cn" \\END: "toupper($0)""_nf ;
					$0="\n "_cn"/"toupper($0)""_nf ;
					_ctrlhid=1 ;
				}
				$0=gensub(/=(.*)=/,_cn"=\\1="_nf,"g") ; 
				if ( ( $1 ~ /^\*|^\-/ || $0 ~ /\*\*/ ) && $0 ~ /^[ \t]+.*/ ) {
					_tab=_tab""gensub(/^([ \t]+).*/,"\\1","g",$0) ;
				}
				$0=gensub(/(<code>)(.*)(<\/code>)/,_ca" [ \\2 ]"_nf,"g",$0 ) ;
				if ( _ctrlcode == 1 && _ctrlhid == 0 ) { _tabhc="\t" } else { _tabhc="" }
				if ( $0 ~ /<code>/  ) { 
					_ctrlcode=2  ; 
					_lncode="\t"gensub(/(.*)(<code>)(.*)/,"\\3","g",$0) ;
					if ( _lncode != "" ) {
						$0=gensub(/(.*)(<code>)(.*)/,"\\1","g",$0) ;
						gsub(/<\/code>/,"",_lncode) ;
					} else {
						gsub(/<code>/,"",$0) ; 
					}
				}
				if ( $0 ~ /<\/code>/ ) { _ctrlce=1 ; gsub(/<\/code>/,"",$0) }
				_ctrlbold=0 ;
				_ctrllk=0 ;
				if ( _ctrlcode == 1 ) {
					if ( _ctrlce == 1 ) { 
						if ( _lncode != "" ) { 
							print _tabhid""_tabhc" |\t"_tab""_ca""$0""_nf ; 
							print _tabhid""_tabhc" |\t"_ca""_lncode""_nf ; 
							_lncode="" ;
						} else {
							print _tabhid""_tabhc" |\t"_tab""_ca""$0""_nf ; 
						}
						print _tabhid""_tabhc""_cn" \\END CODE:"_nf"\n"_tabhid ; 
						_ctrlce=0 ; 
						_ctrlcode=0 ; 
					} else {
						print _tabhid""_tabhc" |\t"_tab""_ca""$0""_nf ; 
					}
				} else {
					for (f=1;f<=NF;f++) {
						if ( _ctrllk == 1 ) {
							_strglk=_strglk" "$f ;
							$f=""
						}
						if ( _ctrllk != 1 && $f ~ /\[\[|\{\{/ ) { 
							_ctrllk=1 ;
							_poslk=f+1 ;
							_strglk=gensub(/(\[\[|\{\{)(.*)/,"\\2","g",$f) ;
							$f=""
						}
						if ( _ctrllk == 1 && _strglk ~ /\]\]|\}\}/ ) {
							_strglk=gensub(/(\]\]|\}\})/,"","g",_strglk) ;
							split(_strglk,flink,"|") ;
							$_poslk=_cc"LINK: ["flink[2]"]"_nf ;
							_ctrllk=0 ; _strglk="" 
						}
						if ( $f ~ /<fc$/ && $(f+1) ~ /^[a-z]+>/ ) {
							$f=gensub(/<fc$/,"",1,$f) ; 
							$(f+1)=gensub(/^white>/,"",1,$(f+1)) ;
							$(f+1)=gensub(/^orange>/,_co,1,$(f+1)) ; 
							$(f+1)=gensub(/^red>/,_cr,1,$(f+1)) ; 
							$(f+1)=gensub(/^green>/,_cg,1,$(f+1)) ; 
						}
						if ( $f ~ /<\/fc>/ ) { $f=gensub(/<\/fc>/,_nf,"g",$f) }
						if ( $f ~ /\*\*/ ) {
							if ( _ctrlbold == 1 ) {
								gsub(/\*\*/,_nf,$f) ;
								_ctrlbold=0 ;
							} else {
								if ( $f ~ /\*\*.*\*\*/ ) { 
									$f=gensub(/\*\*(.*)\*\*/,_cn"\\1"_nf,"g",$f)
								} else {
									gsub(/\*\*/,_cn,$f) ;
									_ctrlbold=1 ;
								}
							}
						}
						if ( $f ~ /\/\// ) {
							if ( _ctrldim == 1 ) {
								gsub(/\/\//,_nf,$f) ;
								_ctrldim=0 ;
							} else {
								if ( $f ~ /\/\/.*\/\// ) { 
									$f=gensub(/\/\/(.*)\/\//,_cm"\\1"_nf,"g",$f)
								} else {
									gsub(/\/\//,_cm,$f) ;
									_ctrldim=1 ;
								}
							}
						}
					} 
					if ( $0 ~ /^\\\\$/ ) { $0="" }
					if ( $1 ~ /[|]/ || $1 ~ /\^/ ) { 
						if ( $1 ~ /\^/ ) { $0=gensub(/\^/,"|^","g",$0) } 
						_tl=split($0,tabla,"|") ; 
						_linea="|  "
						for(n=2;n<_tl;n++) { 
							if ( tabla[n] ~ /^\^/ ) { tabla[n]=gensub(/^\^/,"",1,tabla[n]) ; tabla[n]=_cn""toupper(tabla[n])""_nf }
							tabla[n]=gensub(/^[ \t]+(.*)/,"\\1","g",tabla[n]) ; 
							tabla[n]=gensub(/[ ]+$/,"","g",tabla[n]) ; 
							_tablac="" ;
							if ( tabla[n] ~ /@#[A-F0-9]+:/ ) { 
								if ( tabla[n] ~ _chr ) { _tablac=_cr } ; 
								if ( tabla[n] ~ _chu ) { _tablac=_cg } ; 
								if ( tabla[n] ~ _chm || tabla[n] ~ "@#FAAC58:" ) { _tablac=_co } ; 
								gsub(/@#[A-F0-9]+:/,"",tabla[n]) ;
							} ;
							if ( _ctrltab == 1 ) { _tablac=_cn } 
							_linea=_linea""sprintf("%s%-20s%s", _tablac, tabla[n], _nf )" | " ;
						} ; 
						if ( _ctrltab == 1 ) { _ctrltab=0 } 
						print _tabhid""_tab""_linea ; 
						_linea="" 
					} else { 
						if ( _ctrlhid == 1 ) { _tabbox="" } else { _tabbox="\t" ; _tabhc="\t" } 
						$0=gensub(/<box ([0-9]+\%|[a-z]+) ([a-z ]+)>(.*)<\/box>/,"\n"_tabhid" "_tab""_tabbox""_ck"\\3"_nf"\n"_tabhid""_tab,"g",$0) ;
						print _tabhid""_tab""$0 
						if ( _ctrlcode == 2 ) { 
							_ctrlcode=1 ; 
							print _tabhid"\n"_tabhid""_tabhc""_cn" /CODE:"_nf ; _tabcode="" 
						} 
					}
				}
		}' $_proc_file
	else 
		echo "ERR: file [$_proc_file] doesn't exists" && exit 1
	fi	
}


###########################################
#              MAIN EXEC                  #
###########################################

	case "$_par_type" in
	"env")
		show_env_procedures
		print_output
	;;
	"node")
		show_node_procedures
		print_output
	;;
	"rules")
		_output=$( show_rules_link )
		print_generic 
	;;
	"procedure")
		if [ "$_par_proc" == "list" ]
		then
			_proc_dir=$_pages_path"/operation/procedures/"
			echo "LIST PROCEDURES:"
			echo "NAME : DESCRIPTION"
			echo
			for _file in $( ls -1 $_proc_dir ) 
			do
				awk -v _nf="$_file" '
					BEGIN { 
						_ctrl=0 ;
						_ctrlfile=1 ; 
						split(_nf,name,".") ; 
						if ( name[1] ~ "[a-z][a-z][a-z][a-z]av[0-9]+" ) { _ty="av" }
						if ( name[1] ~ "[a-z][a-z][a-z][a-z]bs[0-9]+" ) { _ty="bs" }
						if ( name[1] ~ "[a-z][a-z][a-z][a-z]xx[0-9]+" ) { _ty="xx" }
						if ( _ty != "av" && _ty != "bs" && _ty != "xx" ) { 
							_ctrl=2 ; 
						} else { 
							_ctrlfile=0 ; 
							_des="ERR: cant get data" ; 
						} 
						_nametop=toupper(name[1]) ; 
					} { 
						if ( _ty == "av" && $2 ~ _nametop && _ctrl == 0 ) { _ctrl=1 }
						if ( _ty == "bs" && $1 ~ /[=]+/ && _ctrl == 0 ) { _ctrl=1 }
						if ( _ty == "xx" && $1 ~ /[=]+/ && _ctrl == 0 ) { _des=gensub(/=+/,"","g",$0) ; _ctrl=1 }
					} _ty == "bs" && _ctrl == 1 && $1 ~ /\*\*/ {
						_des=gensub(/\*\*/,"","g",$0) ; _ctrl=2 ; 
					} _ty == "av" && _ctrl == 1 {
						split($0,line,"|") ; _des=line[3] ; _ctrl=2 ; 
					} END {
						if ( _des == "" ) { _des="ERR: no header data in procedure document" } 
						if ( _ctrlfile == 0 ) { print _nametop" : "gensub(/^[ ]+/,"","g",_des) }
					}' $_proc_dir""$_file
			done
		else
			_par_proc=$( echo "$_par_proc" | tr [:upper:] [:lower:] )
			_proc_file=$_pages_path/operation/procedures/$_par_proc.txt

			if [ "$_opt_edi" == "yes" ]
			then
				[ -f "$_proc_file" ] && vim $_proc_file 
			else
				echo -e $_sh_color_blink"\n"$_sh_color_bolt"PROCESSING DOKUWIKI PROCEDURE DOC: ["$_par_proc"]"$_sh_color_nformat
				show_procedure
				echo -e "\n"$_sh_color_bolt"FILE: ["$_proc_file"]"$_sh_color_nformat
			fi
		fi
	;;
	esac


 
