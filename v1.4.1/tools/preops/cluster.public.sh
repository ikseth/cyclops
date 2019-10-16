#!/bin/bash

source /etc/cyclops/global.cfg
source $_libs_path/ha_ctrl.sh 
source $_config_path_sys/wiki.cfg
source $_config_path_sys/wiki.cfg
source $_color_cfg_file

_wiki_dst=$_pages_path"/public/cluster/start.txt"
_public_main_page=$_pages_path"/public/start.txt"
_sh_action="daemon"

#####

teleprompt()
{
	_today_date=$( date +%F )
	_events=$( 
			$_script_path/audit.nod.sh -n main -v commas | awk -F\; -v _td="$_today_date" '$1 == _td { print "-- "$2" : "$5" : "$6 }' | sort -u | tr '\n' ' '
			$_script_path/audit.nod.sh -n users -v commas | awk -F\; -v _td="$_today_date" '$1 == _td { print "-- "$2" : "$5" : "$6 }' | sort -u | tr '\n' ' '
		)
	[ -z "$_events" ] && _events="No new messages"


	echo "${_load_page}" | awk -v _ev="$_events" '$0 ~ "marquee behavior" { print "<marquee behavior=\"scroll\" direction=\"left\">"_ev"</marquee>" } $0 !~ "marquee" { print $0 }'

}

cluster_status()
{
	echo "<html>"
	echo "<meta http-equiv="refresh" content="120">"
	echo "</html>"
	echo
	echo "~~NOTOC~~"
	echo "~~NOCACHE~~"

	echo
	#echo "{{ :public:maincyclopstitle.png?450&nolink }}"
	echo "===== CLUSTER STATUS ====="
	echo 
	echo "<tabbox Node Activity View>" 
	echo "<html> <img src="http:/172.24.29.88/cycusu/pinta_estado_nimbus.php"> </html>"
	echo "<tabbox Cluster Activity Chart>"
	$_stat_extr_path/stats.cyclops.logs.sh -r SLURM_LOAD -n dashboard -d day -v wiki
	echo "----" 
	$_stat_extr_path/stats.cyclops.logs.sh -r SLURM_LOAD -n dashboard -d month -v wiki
	echo "<tabbox Cluster Availability Chart>"
	$_stat_extr_path/stats.cyclops.logs.sh -r OPER_ENV -n dashboard -d day -v wiki
	echo "----"
	$_stat_extr_path/stats.cyclops.logs.sh -r OPER_ENV -n dashboard -d month -v wiki
	echo "<tabbox Users Bitacora>"
	$_script_path/audit.nod.sh -n users -v wiki | sed '/hidden/d'
	echo "<tabbox Desarrollo Slurm Queue>"
	$_script_path/service.slurm.sh -f $_config_path_srv/dev.srv.slurm.cfg -v wiki | sed '/hidden/d'
	echo "<tabbox Explotación Slurm Queue>"
	$_script_path/service.slurm.sh -f $_config_path_srv/expl.srv.slurm.cfg -v wiki | sed -e '/hidden/d' -e '/^\\$/d'
	echo "</tabbox>"
	echo
	echo "{{ :public:aemetatoslogo.png?450&nolink}}"
	echo
}

####

ha_check

#### ADHOC USER CLUSTER STATUS ####

#_output=$( cluster_status )

#echo -e "${_output}" >  $_wiki_dst
#chown $_apache_usr:$_apache_grp $_wiki_dst 

#### TELEPROMPT USERS PAGE ####

_load_page=$( cat $_public_main_page )

teleprompt > $_public_main_page
chown $_apache_usr:$_apache_grp $_public_main_page

#### SLURM CLUSTER STATUS 

$_tool_path/preops/cluster.status.sh >$_cyclops_temp_path/slurmstatus.txt
cp $_cyclops_temp_path/slurmstatus.txt $_wiki_dst #$_pages_path/imasd/hmtl/slurmstatus.txt
chown $_apache_usr:$_apache_grp $_wiki_dst 
