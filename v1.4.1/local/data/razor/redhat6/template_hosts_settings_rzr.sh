#!/bin/bash                                                                                                                         
##### RAZOR RESOURCE CTRL CONFIG FILE ####                                                                                          
##### WARNING : WE RECOMMENDED THIS RAZOR AT THE END OF RAZOR LIST OF FAMILY NODES ####
##### WARNING : CHANGE DRAIN COMMAND IF YOU DON'T WANT HALT THE NODE ( BY DEFAULT ) ####
                                                                                                                                    
_rsc_rzr_nam="water64"
_rsc_rzr_des="Cyclops Razor AEMET Compute 64 GB specific Host General Settings Ctrl"  ## Use this script like family template for different types of hosts                                                                                  
_rsc_rzr_cmd=""                                                                          
_rsc_rzr_dae=""                                                                                                                     
_rsc_rzr_cfg=""                                                                             
_rsc_rzr_out_cod="119"                                                                                                              
_rsc_rzr_hostname=$( hostname -s )                                                                                                  

###### NON-STANDARD RAZOR VARIABLES ####

_rsc_rzr_ht_cmd="/usr/sbin/ht"
_rsc_rzr_ht_sts="0"			### DESIRE HYPERTHREADING STATUS ###
_rsc_rzr_ht_mem="60"			### GB ### B700 MEMORY LIKE 128...
_rsc_rzr_sf_slm="14.11.9"		### SOFTWARE CTRL - SLURM ###
_rsc_rzr_sl_cmd="/usr/bin/squeue"	### SLURM CMD FOR JOB CTRL ###
_rsc_rzr_pkg_lua="lua"			### CHECK STRING PACKAGES PACKAGE INSTALL
                                                                                                                                    
# [ ! -f "$_rsc_rzr_cmd" ] && exit $_rsc_rzr_out_cod                                                                                
                                                                                                                                    
case "$1" in                                                                                                                        
        check)                                                                                                                      
		_rsc_rzr_pkg_list=$( rpm -qa )

                _rsc_rzr_out_cod=$( /usr/sbin/ht 2>&1 >/dev/null ; echo $? )                                               
		[ "$_rsc_rzr_out_cod" == "$_rsc_rzr_ht_sts" ] && _rsc_rzr_out_cod=$( awk -v _m="$_rsc_rzr_ht_mem" 'BEGIN { _m=_m*1024*1024 } $1 == "MemTotal:" { _mem=$2 } END { if ( _mem >= _m ) { print "0" } else { print "12"}} ' /proc/meminfo 2>/dev/null )
		[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod=$( echo "${_rsc_rzr_pkg_list}" | awk -F\- -v _v="$_rsc_rzr_sf_slm" 'BEGIN { _s="13" } $1 == "slurm" && $2 == _v { _s="0" } END  { print _s }' )
		[ "$_rsc_rzr_out_cod" == "0" ] && _rsc_rzr_out_cod=$( echo "${_rsc_rzr_pkg_list}" | awk -v _st="$_rsc_rzr_pkg_lua=" 'BEGIN { _s="14" } $0 ~ _st { _t++ } END { if ( _t = 8 ) { print "0" } else { print _s }}' ) 
		[ -z "$_rsc_rzr_out_cod" ] && _rsc_rzr_out_cod="19"
        ;;                                                                                                                          
        start|link|unlink|diagnose|boot|init|up|stop|content|drain|repair|reset|reboot)
                _rsc_rzr_out_cod="21"                                                                                               
        ;;                                                                                                                          
        info)
                _rsc_rzr_out_cod="21"
        ;;
esac

exit $_rsc_rzr_out_cod
