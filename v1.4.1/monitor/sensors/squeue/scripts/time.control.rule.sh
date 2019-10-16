#!/bin/bash
#### CONTROL SQUEUE MULTIPLE NODES BEHAVIOUR ####

_time_ctrl=$( awk -F\; -v _job=$_job_id -v _time=$_time '$2 == _job && $7 == _time { print $0 }' $_last_check_file | wc -l )

if [ $_time_ctrl -ne 0 ]
then
	_time="DOWN "$_time
	_general_partition_state="DOWN" 
	_general_node_state="DOWN"

	_procedure_code="5"
	_ia_report=$_ia_report"\n"$_procedure_code";"$_node

	let "_exit_ia_code++"
else
	_time="UP "$_time
fi
