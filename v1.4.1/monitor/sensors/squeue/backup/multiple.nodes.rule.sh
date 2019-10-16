#!/bin/bash
#### CONTROL SQUEUE MULTIPLE NODES BEHAVIOUR ####

_nnjobs=$(grep $_job_id  $_ia_temp_file | wc -l)

if [ $_nnjobs != "$_nnodes" ]
then
	_nnodes="DOWN "$_nnodes
	_general_partition_state="DOWN"
	_general_node_state="DOWN"
	
	_procedure_code="3"
	_ia_report=$_ia_report"\n"$_procedure_code";"$_node

	let "_exit_ia_code++"
else
	_nnodes="UP "$_nnodes
fi

