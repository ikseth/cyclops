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

### LIB HELP ###

# THIS LIB CONVERT XML FILES TO CYCLOPS LOG FORMAT #
# YOU CAN USE FROM OTHERS SCRIPTS #
# DEPENDENCY: NONE
# SETTINGS: #
#	YOU MUST INCLUDE: FIRST ARGUMENT: PATH/FILENAME
# OPTIONAL : SECOND ARGUMENT: [yes] ( if you want to include filename as first field of the new generated log )

### FUNCTION ####

func_xml2log()
{
        awk -v _fno="$2" 'BEGIN {
                _idx=0
                if ( _fno == "yes" ) { _filen=ARGV[1]" : " } else { _filen="" }
        } NR > 1 {
                _up=0 ; _down=0
                $0=gensub(/<(.*)/,"\\1","g",$0) ;
                $0=gensub(/(.*)>/,"\\1","g",$0) ;
                if ( NF == 1 && $1 !~ "^/" && $1 !~ "=" ) { _up=2 }
                if ( NF == 1 && $1 ~ "^/"  ) { _down=2 }
                if ( NF > 1 && $1 !~ "=" ) { _up=1 }
                if ( NF > 1 && $NF ~ "/$" ) { _down=1 }

                gsub("/$","",$NF)

                if ( _up > 0 && _fields != "" ) {
                        for (x=1;x<=_idx;x++) {
                                if ( x > 1 ) { _pre=_pre" : att"x"="idx[x] } else { _pre="att"x"="idx[x] }
                        }
                        print _filen""_pre""_fields
                        _fields=""
                        _pre=""
                }

                if ( _up == 1 ) { i=2 } else { i=1 }
                if ( _up > 0 ) { _idx++ ; idx[_idx]=$1 }

                if ( _up != 2 && _down != 2 ) {
                        _cf=0 ;
                        for (f=i;f<=NF;f++) {
                                if ( $f ~ /"/ ) {
                                        if ( $f ~ "\"$" && $f !~ /="/ ) { _fields=_fields""_fstrg" "$f ; _cf=0 ; _fstrg="" }
                                        if ( $f ~ /="/ && $f !~ "\"$" ) { _cf=1 ; _fstrg=" : "$f }
                                        if ( $f ~ /="/ && $f ~ "\"$" ) { _fields=_fields" : "$f }
                                } else {
                                        if ( _cf == 1 ) {
                                                _fstrg=_fstrg" "$f
                                        } else {
                                                _fields=_fields" : "$f
                                        }
                                }
                        }
                }

                if ( _down == 1 ) {
                        for (x=1;x<=_idx;x++) {
                                if ( x > 1 ) { _pre=_pre" : att"x"="idx[x] } else { _pre="att"x"="idx[x] }
                        }
                        print _filen""_pre""_fields
                        _pre=""
                        _fields=""
                }

                if ( _down > 0 ) { unset idx[_idx] ; _idx-- }
        }' $1

}
