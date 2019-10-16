#!/bin/bash

#### MAIN EXTRACTOR - CYCLOPS NODES ####

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

source /etc/cyclops/global.cfg

###########################################
#              PARAMETERs                 #
###########################################

while getopts "s:e:f:h" _optname
do

        case "$_optname" in
                "s")
                        _opt_start="yes"
                        _par_start=$OPTARG
                ;;
		"e")
			_opt_end="yes"
			_par_end=$OPTARG
		;;
		"f")
			_opt_file="yes"
			_par_file=$OPTARG
		;;
                "h")
                ;;
        esac
done

###########################################
#              FUNTIONs                   #
###########################################

main_extractor()
{
	cat $_src_file  | tr '|' ';' | grep ";" | sed -e 's/\ *;\ */;/g' -e '/^$/d' -e '/:wiki:/d' -e "s/$_color_unk/90/g" -e "s/$_color_up/01/g" -e "s/$_color_down/10/g" -e "s/$_color_mark/12/g" -e "s/$_color_fail/11/g" -e "s/$_color_check/20/g" -e "s/$_color_ok/00/g" -e "s/$_color_title//g" -e "s/$_color_header//g" -e 's/^;//' -e 's/;$//' -e '/</d' -e 's/((.*))//' -e '/:::/d' | awk -F\; 'BEGIN { OFS=";" ; _print=0 } { if ( $1 == "family" ) { _print=1 } ; if ( $2 == "name" ) { _print=0 } ; if ( _print == 1 ) { print $0 }}'
}


###########################################
#              MAIN EXEC                 #
##########################################


