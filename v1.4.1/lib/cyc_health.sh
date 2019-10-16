#!/bin/bash
### FIRTS CYCLOPS FUNCTION LIBRARY #### 2018-07-12
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

### LIB HELP ###

# THIS LIB CHECK CYCLOPS MAIN WORK FILE #
# YOU CAN USE FROM OTHERS SCRIPTS #
# DEPENDENCY: GLOBAL CYCLOPS VARIABLES ( bydefault: /etc/cyclops/global.cfg ) #
# SETTINGS: YOU CAN ASK FOR VERBOSE, ADD: #
#	log: only for timestamp and log trace ( standard output, redirect to cyclops log or other log file ) #
#	simple: simple message human comprensible ( error output ) #
#	all: both, log and simple message #
# YOU CAN USE exitcode for knows cyclops file status #

### FUNCTION ####

sensor_sot_health()
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
                        _cycstatusmsg="GOOD"
			_exit_code=$_cyccodes_status
                ;;
                [1-9]*)
                        _cycstatusmsg="BAD"
                        _cycstatuslog="$( date +%s ) : LIB CYCLOPS HEALTH : MISS $_cyccodes_status CYCLOPS CODES: VERIFY $_sensors_sot FILE"
			_exit_code=$_cyccodes_status
                ;;
		ALL)
                        _cycstatus="CRITICAL"
                        _cycstatuslog="$( date +%s ) : LIB CYCLOPS HEALTH : MISS ALL CYCLOPS CODES: VERIFY $_sensors_sot FILE"
			_exit_code=99
		;;
                *)
                        _cycstatus="CRITICAL"
                        _cycstatuslog="$( date +%s ) : LIB CYCLOPS HEALTH : UNKNOWN ERROR, CHECK CYCLOPS INSTALL"
			_exit_code=100
                ;;
                esac
        else
                _cycstatusmsg="CRITICAL"
                _cycstatuslog="$( date +%s ) : LIB CYCLOPS HEALTH : MISS $_sensors_sot FILE, CHECK CYCLOPS INSTALL"
		_exit_code=101
        fi

	[ "$1" == "simple" ] && echo $_cycstatusmsg >&2
	[ "$1" == "log" ] && echo $_cycstatuslog 
	[ "$1" == "all" ] && echo $_cycstatusmsg >&2 && echo $_cycstatuslog
	return $_exit_code

}
