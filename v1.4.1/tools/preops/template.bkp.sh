#!/bin/bash

#### VARIABLES

_home_main_path="[BKP SOURCE DIR(FILE SYSTEM DIR)]"
_bkp_path="[BKP DIR DESTINITY (FINAL DIR)"
_fs_bkp="[BKP DESTINITY DIR(FILE SYSTEM DIR)]"
_ha_ip="[IP FOR HA CONTROL]"

_date_log=$( date +%s )
_file_log="/root/$( echo $_home_main_path | sed -e 's/\//./g' -e 's/^\.//' ).bkp.log"

echo "$_date_log : INIT BKP $_home_main_path" >> $_file_log

_test_ha_ip=$( ip addr | grep -o $_ha_ip 2>&1 >/dev/null ; echo $? ) 
[ "$_test_ha_ip" != "0" ] && echo "$_date_log : NO IP -> exit 3" >> $_file_log && exit 3

_test_bkp_path=$( mount | grep -o $_fs_bkp 2>&1 >/dev/null ; echo $? )
[ "$_test_bkp_path" != "0" ] && echo "$_date_log : NO SOURCE -> exit 1" >> $_file_log && exit 1

_test_home=$( mount | grep -o $_home_main_path 2>&1 >/dev/null ; echo $? )
[ "$_test_home" != "0" ] && echo "$_date_log : NO DEST -> exit 2" >> $_file_log && exit 2

#### FUNCTIONS

bkp_f()
{
        [ -z "$_bkp_path" ] && echo "$_date_log : $_dir DEST EMPTY -> exit 4" >> $_file_log && exit 4
        [ ! -d "$_bkp_path" ] && echo "$_date_log : $_bkp_path/$_dir NOT EXIST -> exit 5" >> $_file_log && exit 5
	echo "$_date_log : START BKP -> $_dir" >> $_file_log
        rsync -auz --delete $_home_main_path/$_dir $_bkp_path/$_home_main_path 2>&1 >> $_file_log
}

#### MAIN EXEC

echo "$_date_log : START BKP $_home_main_path" >> $_file_log

for _dir in $( ls -1 $_home_main_path ) 
do
	bkp_f &
done
wait

echo "$_date_log : END BKP $_home_main_path" >> $_file_log
