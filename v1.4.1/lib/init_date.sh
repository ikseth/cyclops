#!/bin/bash

### FIRTS CYCLOPS FUNCTION LIBRARY #### 2016-11-03
### INIT DATE - FORMAT DATE FROM PATTERNS AND CREATE TIMESTAMP 

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

init_date()
{

	_date_start=$1
	_date_end=$2

        _date_tsn=$( date +%s )

        case "$_date_start" in
	*[0-9]hour|hour)
		_hour_count=$( echo $_date_start | grep -o ^[0-9]* )
		_date_start="hour"

		[ -z "$_hour_count" ] && _hour_count=1

                let _ts_date=3600*_hour_count

                let _date_tsb=_date_tsn-_ts_date
                _date_tse=$_date_tsn

                _date_filter=$_date_start
                _date_start=$( date -d @$_date_tsb +%Y-%m-%d )
                _date_end=$( date +%Y-%m-%d )
	;;
        *[0-9]day|day)
		_day_count=$( echo $_date_start | grep -o ^[0-9]* )
		_date_start="day"

		[ -z "$_day_count" ] && _day_count=1

                let _ts_date=86400*_day_count

                let _date_tsb=_date_tsn-_ts_date
                _date_tse=$_date_tsn

                _date_filter=$_date_start
                _date_start=$( date -d @$_date_tsb +%Y-%m-%d )
                _date_end=$( date +%Y-%m-%d )
        ;;
        week|"")
                _ts_date=604800

                let _date_tsb=_date_tsn-_ts_date
                _date_tse=$_date_tsn

                _date_filter=$_date_start
                _date_start=$( date -d "last week" +%Y-%m-%d )
                _date_end=$( date +%Y-%m-%d )

        ;;
        *[0-9]month|month)
                #_ask_date=$( date -d "last month" +%Y-%m-%d )
		_month_count=$( echo $_date_start | grep -o ^[0-9]* )
		_date_start="month"

		[ -z "$_month_count" ] && _month_count=1

                let _ts_date=2592000*_month_count

                let _date_tsb=_date_tsn-_ts_date
                _date_tse=$_date_tsn

                _date_filter=$_date_start
                _date_start=$( date -d @$_date_tsb +%Y-%m-%d )
                _date_end=$( date +%Y-%m-%d )
        ;;
        *[0-9]year|year)
                #_ask_date=$( date -d "last year" +%Y-%m-%d )

		_year_count=$( echo $_date_start | grep -o ^[0-9]* )
		_date_start="year"

		[ -z "$_year_count" ] && _year_count=1

                let _ts_date=31536000*_year_count

                let _date_tsb=_date_tsn-_ts_date
                _date_tse=$_date_tsn

                _date_filter=$_date_start
                _date_start=$( date -d "last year" +%Y-%m-%d )
                _date_end=$( date +%Y-%m-%d )
        ;;
        "Jan-"*|"Feb-"*|"Mar-"*|"Apr-"*|"May-"*|"Jun-"*|"Jul-"*|"Aug-"*|"Sep-"*|"Oct-"*|"Nov-"*|"Dec-"*)
                _date_year=$( echo $_date_start | cut -d'-' -f2 )
                _date_month=$( echo $_date_start | cut -d'-' -f1 )

                _query_month=$( date -d '1 '$_date_month' '$_date_year +%m | sed 's/^0//' )
                _date_tsb=$( date -d '1 '$_date_month' '$_date_year +%s )

                let "_next_month=_query_month+1"
                [ "$_next_month" == "13" ] && let "_next_year=_date_year+1" && _next_month="1" || _next_year=$_date_year

                _date_tse=$( date -d $_next_year'-'$_next_month'-1' +%s)

                let "_date_tse=_date_tse-1"

                _date_filter="month"
                _date_start=$( date -d @$_date_tsb +%Y-%m-%d )
                _date_end=$( date -d @$_date_tse +%Y-%m-%d )
        ;;
        [0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]*)
		_date_start=$( echo "$_date_start" | sed 's/T/ /' )
                _date_tsb=$( date -d "$_date_start" +%s )
                if [ -z "$_date_end" ]
                then
                        _date_tse=$( date +%s )
                        _date_end=$( date +%Y-%m-%d )
                else
			_date_end=$( echo "$_date_end" | sed 's/T/ /' )
                        _date_tse=$( date -d "$_date_end" +%s )
                fi

		let _day_count=(_date_tse-_date_tsb )/86400 

		case "$_day_count" in
		0)
			_date_filter="hour"
		;;
		[1-2])
			_date_filter="day"
		;;
		[3-9])
			_date_filter="week"
		;;
		[1-4][0-9])
			_date_filter="month"
		;;
		*)
			_date_filter="year"
		;;
		esac
        ;;
        [0-9][0-9][0-9][0-9])
                _date_tsb=$( date -d '1 Jan '$_date_start +%s )
                _date_tse=$( date -d '31 Dec '$_date_start +%s )

                _date_filter="year"
                _date_start=$( date -d @$_date_tsb +%Y-%m-%d )
                _date_end=$( date -d @$_date_tse +%Y-%m-%d )
        ;;
	ever)
                _date_tsb=1
                _date_tse=$( date +%s )

                _date_filter="year"
                _date_start=1970-01-01
                _date_end=$( date -d @$_date_tse +%Y-%m-%d )
	;;
	*)
		### IF DATE START WRONG... GET DAY BY DEFAULT ####
                _ts_date=86400

                let _date_tsb=_date_tsn-_ts_date
                _date_tse=$_date_tsn

                _date_filter=$_date_start
                _date_start=$( date -d "last day" +%Y-%m-%d )
                _date_end=$( date +%Y-%m-%d )
	;;
        esac

        let "_hour_days=((_date_tse-_date_tsb)/86400)+1"
}
