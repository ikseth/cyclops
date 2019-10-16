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

### FUNCTION ####


node_group()
{

	unset _node_range

	_prefix=$( echo "${1}" | sed -e 's/ /,/g' -e 's/^,*//' -e 's/,*$//' | tr ',' '\n' | sed 's/^\([a-zA-Z_-]*\)[0-9]*$/\1/' | sort -u )

	for _node_prefix in $( echo "${_prefix}" )
	do
	       _node_range=$_node_range""$( echo "${1}" | sed -e 's/ /,/g' -e 's/^ *//' -e 's/ *$//' | tr ',' '\n' | sed 's/[0-9]*$/;&/' | awk -F\; -v _p="$_node_prefix" '$1 ~ "^"_p"[0-9]+$" || $1 == _p { print $0 }' | sort -t\; -k2,2n -u | awk -F\; '
		{ if ( NR == "1" ) { _sta=$2 ; _end=$2  ; _string=$1"[" }
		else {
		    if ( $2 == _end + 1 ) {
			_sep="-" ;
			_end=$2 }
			else
			{
			    if ( _sep == "-" ) { 
				_string=_string""_sta"-"_end"," }
				else {
				    _string=_string""_sta"," }
			    _sep="," ;
			    _sta=$2 ;
			    _end=$2 ;
			}
		    }
		}

		END { if ( $2 == _end + 1 ) {
			_sep="-" ;
			_end=$2 }
			else
			{
			    if ( _sep == "-" ) { 
				_string=_string""_sta"-"_end }
				else {
				    _string=_string""_sta }
			    _sep="," ;
			    _sta=$2 ;
			    _end=$2 ;
			}
			print _string"]" }' )","
	done

	echo "$_node_range" | sed -e 's/\,$//' -e 's/\[\]//g' -e 's/[][]\([0-9]*\)[][]/\1/g'

}

