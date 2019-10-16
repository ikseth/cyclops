#!/bin/bash
#### CONTROL SQUEUE REASON FIELD STATUS ####

case "$_reason" in
	None)
		_reason="UP "
	;;
	Resources|Priority|NonZeroExitCode|TimeLimit)
		_reason="MARK "$_reason
	;;
	PartitionDown|NodeDown|SystemFailure|JobLaunchFailure)
		_reason="DOWN "$_reason
		_general_partition_state="DOWN"
		_general_node_state="DOWN"

		_procedure_code="4"
		_ia_report=$_ia_report"\n"$_procedure_code";"$_node

		let "_exit_ia_code++"
	;;
	*)
		_reason="UNK "$_reason

		let "_exit_ia_code++"
	;;
esac

