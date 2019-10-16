arp -d 172.29.100.107
sleep 2s

for _mount in $( cat /etc/fstab  | grep -v \# | grep nfs | awk '{ print $2 }' )
do 

	umount -lf $_mount
	sleep 2s
	mount $_mount
done
