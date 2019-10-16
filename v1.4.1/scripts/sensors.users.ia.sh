#!/bin/bash

###########################################
#         SLURM QUEUE MONITORING          #
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

_config_path="/etc/cyclops"

# --------------- GLOBAL -----------------#

if [ ! -f "$_config_path/global.cfg" ]
then
        echo "Global config file don't exits"
        exit 1
else
        source $_config_path/global.cfg
fi

# -------------- SCRIPT ------------------#


#----------------- log -------------------#

_par_mon="all"
_par_show="default"

###########################################
#               MAIN EXEC                 #
###########################################

### >>> BEGING TEMP >>>
cat $_sensors_ia_users_tmp_file | sed -e 's/^/UP\ /'
### >>> END TEMP <<<

#for _line in $(cat $_sensors_ia_users_tmp_file)
#do

#	for _rule_file in $( ls -1 $_sensors_users_rules_path/*.rule 2> /dev/null | grep -v template )
#	do

#	        _rule=$( cat $_rule_file | egrep -v "#|^$" | head -n 1 )
#       	_weight=$( echo $_rule | cut -d';' -f1 )
#        	_level_alert=$( echo $_rule | cut -d';' -f2 )
#        	_host=$( echo $_rule | cut -d';' -f3 )
#        	_source=$( echo $_rule | cut -d';' -f4 )
#        	_user=$( echo $_rule | cut -d';' -f5 )
#        	_command=$( echo $_rule | cut -d';' -f6 )
#
#        	[ -z $_source ] && _source="none"
#        	[ -z $_command ] && _command="none"

#		_status=$_status"\n"$(echo $_line | awk -F\; -v _w="$_weight" -v _l="$_level_alert" -v _h="$_host" -v _s="$_source" -v _u="$_user" -v _c="$_command" 'BEGIN { OFS=";"}{ if ( _h == $1 )  _a++  } { if ( _u == $2 )  { _a++ } } { if ( $3 == _s )  { _a++ } } { if ( $4 ~ _c )  { _a++ }} { if ( _a >= _w ) print _l" "$1";"_l" "$2";"_l" "$3";"_l" "$4";"_l" "$5 ; else print "UP "$0 } { _a=0 }' )
#	done

#done

#echo -e "${_status}"
