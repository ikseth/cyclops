#!/bin/bash

###########################################
#         SLURM QUEUE IA MONITORING       #
###########################################

## VARIABLES ##

IFS="
"
_config_path="/etc/cyclops"

## GLOBAL --

if [ ! -f "$_config_path/global.cfg" ]
then
        echo "Global config file don't exits"
        exit 1
else
        source $_config_path/global.cfg
fi

## LOCAL --

_exit_ia_code=0

_pid=$( echo $$ )
_ppid=$1
_ia_temp_file=$2
_slurm_cluster_name=$3
_last_check_file="$_cyclops_temp_path/last.slurm.queue.ia.$_slurm_cluster_name.tmp"
_part_temp_file="$_cyclops_temp_path/squeue.part.status.$_slurm_cluster_name.tmp"

if [ ! -f "$_last_check_file" ]
then
	touch $_last_check_file
fi


## LOG --

_par_mon="all"
_par_show="default"

###########################################
#               MAIN EXEC                 #
###########################################

#------------- first check ---------------#

_general_partition_state="UP"
_ctrl_partition=""
_general_node_state="UP"
_ctrl_node=""

## ANALIZE SLURM QUEUE STATUS --

for _register in $( cat $_ia_temp_file )
do

	#---------- shredder register ------------#

	_partition=$( echo $_register | cut -d';' -f1 )
	_job_id=$( echo $_register | cut -d';' -f2 )
	_node=$( echo $_register | cut -d';' -f3 )
	_job_name=$( echo $_register | cut -d';' -f4 )
	_user=$( echo $_register | cut -d';' -f5 )
	_nnodes=$( echo $_register | cut -d';' -f6 )
	_time=$( echo $_register | cut -d';' -f7 )
	_state=$( echo $_register | cut -d';' -f8 )
	_reason=$( echo $_register | cut -d';' -f9 )

	#--------rules scripts processing---------#

	for _ia_script in $( ls -1 $_sensors_squeue_script_path/*.rule.sh )
	do
		source $_ia_script
	done

	_ia_output=$_ia_output$_general_partition_state" "$_partition";"$_job_id";"$_general_node_state" "$_node";"$_job_name";"$_user";"$_nnodes";"$_time";"$_state";"$_reason"\n"

done

## ANALIZE SLURM PROCEDURE NEEDs --

#_ia_report=$( echo -e $_ia_report | awk 	

if [ "$_exit_ia_code" != 0 ]
then
	_exit_code=2
	_ia_alerti_header=";DOWN SLURM QUEUE - ERROR(s) DETECTED;"$( echo "${_ia_alert_output}" | egrep "DOWN|FAIL" | awk -F\; '{ print $3 }' )";"
	_ia_hidden_state="initialState=\"visible\""
else
	_ia_alert=";OK SLURM QUEUE STATUS - OPERATIVE;"
	_ia_hidden_state=""
fi


	cat $_ia_temp_file > $_last_check_file
	echo $_ia_output

	exit $_exit_ia_code
