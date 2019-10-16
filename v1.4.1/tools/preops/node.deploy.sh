#!/bin/bash

# -> TEST NODE UP
# -> TEST NODE IN DEPLOY STATUS
# -> PARAMETERS
# -> TEST CMD BY CMD EXECUTION
# -> DO STEP NODE BY NODE TO CONTROL CMDs INDEPENDENT FROM EACH NODE
# -> LAST TASK
## -> TEST NODE STATUS TO CHANGE CYCLOPS MONITOR STATUS
## -> ADD ITS OWN NFS HOME CHECK STATUS
## -> CLEAN BMC LOG TRACES

[ -z "$1" ] && echo "NEED NODE OR NODE RANGE" && exit 1

kconfca --force gen -w $1
kconfca deploy -w $1
kconf apply -w $1
shine update -m /etc/shine/models/scratch02.lmf -n $1 -y
shine update -m /etc/shine/models/scratch01.lmf -n $1 -y
pdsh -w $1 reboot

