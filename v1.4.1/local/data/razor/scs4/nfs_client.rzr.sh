#!/bin/bash
##### RAZOR RESOURCE CTRL CONFIG FILE ####

_rsc_rzr_nam="nfs_client"
_rsc_rzr_des="Cyclops Local NFS Client Mounts Ctrl Razor"
_rsc_rzr_cmd=""
_rsc_rzr_dae=""
_rsc_rzr_cfg="/etc/fstab"
_rsc_rzr_out_cod="119"
_rsc_rzr_hostname=$( hostname -s )

# [ ! -f "$_rsc_rzr_cmd" ] && exit $_rsc_rzr_out_cod

### SPECIFIC RAZOR VARS ###

_rsc_rzr_mount="/bin/mount"
_rsc_rzr_umount="/bin/umount"


case "$1" in
	check)
		_rsc_rzr_out_cod=$( awk 'BEGIN { _code="21" } $3 == "nfs" { _code="0" } END { print _code }' $_rsc_rzr_cfg 2>/dev/null )
		if [ "$_rsc_rzr_out_cod" == "0" ]
		then
			for _fs in $( awk '$3 == "nfs" { print $2 }' $_rsc_rzr_cfg 2>/dev/null )
			do
				_rsc_rzr_chk_mnt=$( $_rsc_rzr_mount | awk -v _m="$_fs" 'BEGIN { _ms="1" } $3 == _m && $5 == "nfs" { _ms="0" } END { print _ms }' 2>/dev/null )
				[ "$_rsc_rzr_chk_mnt" != "0" ] && _rsc_rzr_out_cod="11"
			done 
		fi
	;;
	start|link|up|boot)
		_rsc_rzr_out_cod=$( awk 'BEGIN { _code="21" } $3 == "nfs" { _code="0" } END { print _code }' $_rsc_rzr_cfg 2>/dev/null )
                if [ "$_rsc_rzr_out_cod" == "0" ]
                then
                        for _fs in $( awk '$3 == "nfs" { print $2 }' $_rsc_rzr_cfg 2>/dev/null )
                        do
                                _rsc_rzr_chk_mnt=$( $_rsc_rzr_mount | awk -v _m="$_fs" 'BEGIN { _ms="1" } $3 == _m && $5 == "nfs" { _ms="0" } END { print _ms }' 2>/dev/null )
                                [ "$_rsc_rzr_chk_mnt" != "0" ] && _rsc_rzr_chk_mnt=$( $_rsc_rzr_mount $_fs 2>&1 >/dev/null ; echo $? )
				[ "$_rsc_rzr_chk_mnt" != "0" ] && _rsc_rzr_out_cod="11"
                        done 
                fi
	;;
	stop|unlink|content)
		_rsc_rzr_out_cod=$( awk 'BEGIN { _code="21" } $3 == "nfs" { _code="0" } END { print _code }' $_rsc_rzr_cfg 2>/dev/null )
                if [ "$_rsc_rzr_out_cod" == "0" ]
                then
                        for _fs in $( $_rsc_rzr_mount | awk '$5 == "nfs" { print $3 }' 2>/dev/null )
                        do
                                _rsc_rzr_chk_mnt=$( $_rsc_rzr_umount -lf $_fs 2>&1 >/dev/null ; echo $? )
				[ "$_rsc_rzr_chk_mnt" != "0" ] && _rsc_rzr_out_cod="11"
                        done 
                fi
	;;
	diagnose|drain|repair)
		_rsc_rzr_out_cod="21"
	;;
	init)
		_rsc_rzr_out_cod="21"
	;;
	info)
		_rsc_rzr_out_code="0"
	;;
esac

exit $_rsc_rzr_out_cod
