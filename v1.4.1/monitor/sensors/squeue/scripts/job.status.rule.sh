#!/bin/bash
#### CONTROL SQUEUE JOB STATUS ####

case "$_state" in
	CD|CF|R|PR)
		_state="UP "$_state
	;;
	CG)
		_cg_state=$( awk -F\; -v _job=$_job_id '$2 == _job && $8 == "CG" { print $0 }' $_last_check_file | wc -l )
		if [ $_cg_state -eq 0 ]
		then
			_state="OK "$_state
		else
			_state="DOWN "$_state
			_general_partition_state="DOWN" 
			_general_node_state="DOWN"
			let "_exit_ia_code++"
			_procedure_code="1"
			_ia_report=$_ia_report"\n"$_procedure_code";"$_node
		fi
	;;
	PD|S)
		_state="MARK "$_state
	;;
	CA|F|NF|TO)
		_state="DOWN "$_state
		_general_partition_state="DOWN" 
		_general_node_state="DOWN"
		let "_exit_ia_code++"
		_procedure_code="2"
		_ia_report=$_ia_report"\n"$_procedure_code";"$_node
	;;
	*)
		_state="UNK "$_state
		_procedure_code="0"

		let "_exit_ia_code++"
	;;
esac
