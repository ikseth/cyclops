CYCLOPS 1.4.1v INSTALL
==============================================================================================================

    0. COMPATIBILITY
    ----------------------------------------------------------------------------------------------------------

	THIS HOWTO HAS BEEN TESTED WITH:
		- Red Hat Enterprise Linux 6 and 7
		- Debian 9

	SHOULD WORK FINE WITH:
		- CentOS 6 and 7
		- openSUSE Leap

	WE THINK IT WILL WORK WITH:
		- Debian 7 and 8
		- openSUSE Tumbleweed
		- SLES 11, 12 and 13
		- Fedora
		- ArchLinux
		- Ubuntu

    1. PREPARE NECESSARY ENVIRONMENT
    ----------------------------------------------------------------------------------------------------------

    - install git
	- yum install git 			## Red Hat Enterprise Linux and CentOS
	- apt-get install git			## Debian
	- zypper install git			## openSUSE

    - install apache + php + php gd + ssl module
        - yum install httpd php php-gd mod_ssl 	## Red Hat Enterprise Linux and CentOS
	- apt-get install apache2 php php-gd	## Debian

    - install gawk 				## IMPORTANT: for Debian users!!!
	- apt-get install gawk
    
    - Other Linux recomended packages:
	- vim
	- pdsh
	- sysstat
	- rsync
	- redhat-lsb-core
	- mailx 				## Command Line mail client or MUA

    - Apache customization
	1. You can use cyclops' default SSL certificates for Apache if you want HTTPS
	2. [Red Hat USERS] you can use Cyclops' template found here /opt/cyclops/docs/apache.cyclops.conf
		- [OTHER DISTROS] you can adapt the paths in the above mentioned template
		- Use, create or change paths for SSL certs if you use your own certs or copy /opt/cyclops/docs certs to the correct paths
	3. IMPORTANT: disable SElinux for a correct Apache behaviour

    - Red Hat users can find a template in /opt/cyclops/docs to configure Apache. Users of other distros might also find this template useful

    - Create node hostname like [NAME(string)][ID(numeric)] example: minion01, minion02, minion03, etc... 
	We recommended to use something like [NAME][ROL(character)][ID] example: grubs01,grubs02,grubs03, etc...
	Is better to use a different prefix for server name and a letter like grubS01 (s) for server role
	It's better inf compute node names follow this format: minionc01
	Use letter (c) minionC01 for node rol for example Compute.

	We recommend NOT to use special characters like (-,.%) or other characters differnet from [a-z] or/and [0-9] for the hostname
	You can use DNS alias or /etc/hosts alias


    2. INSTALL CYCLOPS
    ----------------------------------------------------------------------------------------------------------

	1. FROM TAR:

	- copy cyclops.[version].tgz and untar in /opt
	- untar /opt/cyclops/monitor/packs/*.tar

	2. FROM GITHUB: 

	- create dir /opt/git:
		mkdir /opt/git
	- cd /opt/git/
	- git clone --depth=1 https://github.com/ikseth/cyclops.git
	- create link in /opt/ 
		- EXPERIMENTAL: ln -s /opt/git/cyclops/[version] cyclops ## EXPERIMENTAL, BETTER USE THE NEXT OPTION
		- STABLE OPTION: copy /opt/git/cyclops/[version] to /opt/cyclops:
			- rsync -acvu /opt/git/cyclops/[version]/ /opt/cyclops
	- after that add two more git repositories
		- Cyclops WEBGUI:
			- refers to sensors, razor, IA rules, audits
			- in /opt/git type:
				git clone --depth=1 https://github.com/ikseth/cyclops_web_gui

		- Cyclops Adds:
			- in /opt/git type:
				git clone --depth=1 https://github.com/ikseth/cyclops_complements
			- Copy to /opt/cyclops/www the version that you want
	
	3. CREATE the necessary directories
		cd /opt/cyclops
		mkdir -p logs lock temp audit/data backups
		cd /opt/cyclops/local
		mkdir -p logs
		cd /opt/cyclops/www/data
		mkdir -p attic cache index locks media_attic media_meta meta tmp
		mkdir -p pages/operation/monitoring pages/operation/monitoring/history/noindex 
		cd /opt/cyclops/monitor/sensors 
		mkdir -p temp status/data/ environment/conf environment/data

	4. CREATE SYMLINKS

	- Configuration path
		cd /etc
		ln -s /opt/cyclops/etc/cyclops

	- Web Data
                cd /var/www/html/ 		## REDHAT WEB PATH (Use the right path if you are running another distro or other www configuration)
		ln -s /opt/cyclops/www cyclops 
		cp -p /etc/cyclops/system/wiki.cfg.template /etc/cyclops/system/wiki.cfg
		
		- Edit the wiki.cfg file and change the default user and group if necessary:
			[REDHAT/CENTOS]	-> 	_apache_usr="apache"
			[DEBIAN] 	->	_apache_usr="www-data"
			[OPENSUSE]	->	_apache_usr="wwwrun"
			[ALL DISTROS]	->	_apache_grp="cyclops"	## RECOMMENDED
		
    5. INIT CYCLOPS CONFIGURATION BASE

	- Copy /etc/cyclops/global.cfg.template to /etc/cyclops/global.cfg
	- Copy /etc/cyclops/monitor/alert.email.cfg.template to /etc/cyclops/monitor/alert.email.cfg
	- Copy /etc/cyclops/statistics/main.ext.cfg.template to /etc/cyclops/statistics/main.ext.cfg
	- Copy /opt/cyclops/monitor/sensors/data/status/stateofthings.cyc.template to /opt/cyclops/monitor/sensors/data/status/stateofthings.cyc
	- Copy /etc/cyclops/audit/bitacoras.cfg.template to /etc/cyclops/audit/bitacoras.cfg
	- Copy /etc/cyclops/audit/issuecodes.cfg.template to /etc/cyclops/audit/issuecodes.cfg
	- Copy /etc/cyclops/statistics/sensors.report.cfg.template to /etc/cyclops/statistics/sensors.report.cfg
		
	6. INITIALIZE BITACORAS (LOGBOOKS):
		for _file in $( awk -F\; '$1 !~ "#" { print $1 }' /etc/cyclops/audit/bitacoras.cfg ) ; do touch /opt/cyclops/audit/data/"${_file}".bitacora.txt ; done

	7. INSTALL SENSORS, IA RULES AND NODE RAZOR
	- Decompress /opt/cyclops/monitor/packs to obtain the necessary sensors, rules and razors files
		from the root directory (cd /)
		tar xvf /opt/cyclops/monitor/packs/*.tar
		OR
		for _file in $( ls -1 /opt/cyclops/monitor/packs/* ) ; do tar xvf "${_file}" ; done ## IF *.tar does not work
	
	8. PREPARE LAST FILES:
		- initializate files:
			touch /opt/cyclops/logs/dashboard.plugin.log
			touch /opt/cyclops/www/data/pages/operation/monitoring/dashboard.txt
    
    3. CREATE AND CONFIGURE PERMISSIONS AND OWNERS
    ----------------------------------------------------------------------------------------------------------

	1. Create Cyclops Group and User

        groupadd -g 900 cyclops					## CHANGE GID IF YOUR DISTRO OR SYSTEM HAS 900 IN USE
        useradd -g 900 -u 900 cyclops     			## CHANGE UID IF YOUR DISTRO OR SYSMTE HAS 900 IN USE
	useradd -g 900 -u 900 -s /bin/bash cyclops		## [DEBIAN ONLY| MAYBE UBUNTU]
	passwd cyclops						## CREATE cyclops password

	NOTE: if you use LDAP or other user authentication software use the right commands to create the user and group and assign IDs and GIDs

	2. Assign Permissions

        chown -R cyclops:cyclops /opt/cyclops
        chown -R apache /opt/cyclops/www 			## REDHAT DEFAULT APACHE USER , CHANGE IT IF YOU HAVE A DIFFERENT DISTRO OR USER
        chown -R www-data /opt/cyclops/www			## DEBIAN DEFAULT APACHE USER 
        chown -R wwwrun /opt/cyclops/wwwrun	         	## SUSE DEFAULT APACHE USER
        
        chmod -R g+w,o-rwx /opt/cyclops/www/

        chmod -R 750 /opt/cyclops/scripts/
        chmod -R 750 /opt/cyclops/tools/
        chmod -R 750 /opt/cyclops/statistics/scripts/
      
    4. PROFILING USER'S ENVIRONMENT
    ----------------------------------------------------------------------------------------------------------

	- For Cyclops' RC module, link cyclopsrc in /etc/profile.d  ## [ REDHAT/CENTOS ] adapt to your distro if it's not RHEL based
	
		copy /etc/cyclops/monitor/plugin.users.ctrl.cfg.template to /etc/cyclops/monitor/plugin.users.ctrl.cfg
		cd /etc/profile.d 
		copy /etc/cyclops/system/cyclopsrc.template to same path cyclopsrc [ without .template ] and customize the file contents.
		ln -s /etc/cyclops/system/cyclopsrc cyclopsrc.sh
            
		RECOMENDED: change permissions from /etc/cyclops/system/cyclopsrc to 750 

	- edit /etc/cyclops/monitor/plugin.users.ctrl.cfg file with your favourite editor and change:
		_pg_usr_ctrl_admin="[USER1],[USER2],..."                ### existing users for admin role
		_pg_usr_ctrl_l1_support="[USER1],[USER2],..."           ### OPTIONAL: for Level 1 support users
		_pg_usr_ctrl_l2_support="[USER1],[USER2],..."           ### OPTIONAL: for Level 2 support users
		_pg_usr_ctrl_l3_support="[USER1],[USER2],..."           ### OPTIONAL: for Level 3 support users
		_pg_usr_ctrl_other="[USER1],[USER2],..."                ### OPTIONAL: for deploy users, or whatever users you want to be able to manage

                NOTE: if you don't change this file, user cyclops would be Cyclops' default admin user

    5. INSTALL WEB INTERFACE (DOKUWIKI BASED)
    ----------------------------------------------------------------------------------------------------------

 	- [OPTIONAL INSTALL] If you want, you can install dokuwiki base from the original source and update it before with Cyclops' customization
		- [REDHAT/CENTOS] - https://www.dokuwiki.org/install:centos
		- Install necessary dokuwiki plugins
		- REMEMBER: to overwrite dokuwiki install files with Cyclops' files (at least /opt/cyclops/www/data/pages and /opt/cyclops/www/data/media) 
		- use rsync and customize it to update whatever you want

	- [RECOMMENDED INSTALL] use cyclops dokuwiki customization
		1. Configure symbolic link or right path for Apache to access Cyclops' web interface ( default /opt/cyclops/www )
		- [REDHAT/CENTOS] can use this commands: 
			cd /var/www/html
			ln -s /opt/cyclops/www cyclops
		- [DEBIAN] do not use cyclops pre-configure site.

	- If you use Cyclops Apache templates you can access:
		[REDHAT/CENTOS]  https://[IP/DOMAIN NAME]/doku.php
		[DEBIAN]         http://[IP/DOMAIN NAME]/cyclops/doku.php

	* Web access credentials:
		User: admin
		Pass: cyclops

	NOTE: Verify apache is up (usually service apache2 status or service httpd status or systemctl status httpd)

    6. CONFIGURE CYCLOPS
    ----------------------------------------------------------------------------------------------------------

	IMPORTANT: you need to be able to resolve all hostnames of all nodes/hosts, via dns or /etc/hosts

	1. check /etc/cyclops/nodes/node.type.cfg.template and remove the ".template" suffix at the end of the file

	2. check /etc/cyclops/nodes/critical.res.cfg.template and remove the ".template" suffix at the end of the file name

	3. You can use a Cyclops prototype option if you want to configure several of its items:
		cyclops -y config  ## USE IT SPECIALLY FOR NODE, FAMILY, GROUP, AND MONITORING ITEMS

		- Use option 11 to define family, group and node settings, include the complete range of nodes to manage.

		BUG: Please exit (end option) every time you finish configuring one option, variables don't reinit properly

		- iOnce finished, you need to configure option 19

	4. You have the next files to configure Cyclops (rename them by removing the ".template" suffix at the end of the file name so Cyclops can read them)

        /etc/cyclops/
                global.cfg.template *               ## MAIN CFG (RECOMMENDED NOT TO CHANGE IT IF NOT NECESSARY) - RENAME IT TO global.cfg 
            ./system
                wiki.cfg.template *                 ## APACHE USR & GRP
                cyclopsrc.template                  ## CYCLOPS profile customize option (optional)
            ./nodes
                bios.mng.cfg.template               ## IPMITOOL CREDENTIALS
                critical.res.cfg.template           ## CYCLOPS Critical resources monitor option (optional) [[BUG - IF NO DATA SHOW NO DATA]]
                name.mon.cfg.template               ## Define monitor sensors groups
                    [CHANGE name with group name], you need to create one file per group
                node.type.cfg.template *            ## Define node list and settings [[BUG - IF NO NODES SHOW TOTAL=0]]
            ./environment
                env.devices.cfg.template            ## List of IPMITOOL hardware devices to monitor
                name.env.cfg.template               ## Define monitoring sensors groups
                    [CHANGE name with group name], you need to create one file per group
            ./monitor
                alert.email.cfg.template            ## Configure non-auth email server and mails for alerts
                monitor.cfg.template *              ## DEFINE MODULES AND GROUPS TO MONITOR
                plugin.users.ctrl.cfg.template      ## Define support and admin users for monitoring with this plugin
                procedure.ia.codes.cfg.template     ## DO NOT TOUCH IF NOT NECESSARY - PROCEDURES CODES AND NAMES
	    ./audit
		bitacoras.cfg			    ## Create your generic logbooks
		issuecodes.cfg.template		    ## Define your provider issue code, local or whatever code you need to follow your issues.
            ./security
                login.node.list.cfg.template        ## Define nodes to monitor users in them
            ./services
                name.slurm.cfg.template             ## Define slurm service settings
                    [CHANGE name with slurm environment name], you need to create one file per environment
            ./statistics
                main.ext.cfg.template               ## Define slurm stats config file ( )
                main.slurm.ext.cfg.template         ## The name of this file is defined in previous cfg file - Here define slurm env dabase(s)
            ./tools
                tool.b7xx.upgrade.fw.cfg.template   ## ONLY FOR B7xx HARDWARE - Firmware definitions profiles files

	5. Other Important directories and files:
		- Nodes items:
			/opt/cyclops/monitor/sensors/status
				./scripts		## [SENSORS COMPILANCE]/SENSORS FILES ## NECESSARY IF YOU WANT TO CREATE NEW ONES OR MODIFY THEM, see .template file for help
				./ia			## IA RULES FILES, see .template file for help
		- Environment items:
			/opt/cyclops/monitor/sensors/environment
				./scripts		## [SENSORS COMPILANCE]/SENSORS FILES ## NECESSARY IF YOU WANT TO CREATE NEW ONES OR MODIFY THEM, see .template file for help
				./ia			## IA RULES FILES, see .template file for help
		- Slurm items:
			/opt/cyclops/monitor/sensors/squeue
				./ia			## EXPERIMENTAL, RULE LIST
				./scripts		## RULES FILES, see template for help
		- Audit items:
			/opt/cyclops/audit
				./scripts/[OS|STOCK COMPILANCE]	## AUDIT EXTRACTION FILES, edit one of them for help
		- Cyclops items:
			/opt/cyclops
				./logs			## CYCLOPS LOGS STORAGE
				./www			## DOKUWIKI WEB INTERAFACE, MOVE OR LINK APACHE SITE DEFINITION TO USE THE WEB INTERFACE
		- Tools items:
			/opt/cyclops/tools
				./approved		## OFFICIAL CYCLOPS TOOLS
				./preops		## PRE-OFFICIAL CYCLOPS TOOLS
				./testing		## TESTING CYCLOPS TOOLS AND YOUR OWN CYCLOPS TOOLS

       	- WARNING: Rename .template for each one it changes, best practice is to copy the file without the ".template" suffix and change the new file.
	- WARNING: Files with * are mandatory to be configurated previously to run cyclops 

    7. HA CYCLOPS ENVIRONMENT NOTES [OPTIONAL]
    ----------------------------------------------------------------------------------------------------------

        - Repeat steps 1 and 2.
        - Configure ssh keys for passwordless ssh connections
        - Sync /opt/cyclops with the HA mirror node
	- Copy file /etc/cyclops/system/ha.cfg.template with same name in same place without the ".template" suffix and edit as necessary
        - Define settings in the HA config file
        - Cyclops needs HA software like heartbeat or pacemaker to control the HA resources
        - Cyclops needs a floating IP to refer to the master node

    8. ACTIVATE CYCLOPS SERVICES
    ----------------------------------------------------------------------------------------------------------
    
	- Add cron entries like this REDHAT/CENTOS example:

		NOTE: Use cron root user

		13 4 * * * /opt/cyclops/scripts/backup.cyc.sh -t all &>>/opt/cyclops/logs/$HOSTNAME.bkp.log                                               #### OPTIONAL FOR BACKUP PROUPOSES
		*/3 * * * * /opt/cyclops/scripts/monitoring.sh -d 2>>/opt/cyclops/logs/$HOSTNAME.mon.err.log                                              #### MANDATORY - MAIN CYCLOPS MONITOR ENTRY
		36 * * * * /opt/cyclops/scripts/audit.nod.sh -d  2>&1 >>/opt/cyclops/logs/audit.err.log                                                   #### OPTIONAL - IF YOU WANT TO USE AUDIT MODULE
		59 * * * * /opt/cyclops/scripts/historic.mon.sh  -d 2>>/opt/cyclops/logs/historic.err.log                                                 #### RECOMENDED - TO SHOW HISTORICAL MONITORING DATA
		20 * * * * /opt/cyclops/scripts/procedures.sh -t node -v wiki >/opt/cyclops/www/data/pages/documentation/procedures/node_status.txt       #### OPTIONAL - UPDATE PROCEDURE STATUS
		21 * * * * /opt/cyclops/scripts/procedures.sh -t env -v wiki >/opt/cyclops/www/data/pages/documentation/procedures/env_status.txt         #### OPTIONAL - UPDATE PROCEDURE STATUS
		42 * * * * /opt/cyclops/scripts/cyc.stats.sh -t daemon >/dev/null 2>/opt/cyclops/logs/cyc.stats.err.log					  #### OPTIONAL - MANDATORY IF YOU ENABLE AUDIT MODULE
		17 * * * * /opt/cyclops/statistics/scripts/extract.main.slurm.sh -d 2>&1 >/opt/cyclops/logs/$HOSTNAME.slurm.extract.log                   #### OPTIONAL - SLURM STATISTICS

	- We recomend you enable one by one, trying each, step by step.

	NOTE: we really try to get time to make a daemon service, please be patient and use this "old and ugly" method, we apologize 
	NOTE: we have an EXPERIMENTAL DAEMON, you can use it with systemd or SysV init, in this case don't configure cron entries
		- systemd:
			- copy /opt/cyclops/docs/cyclops.service to multi-user.target.wants inside of your systemd lib directory distroto
			- enable the service to run at boot time -> systemctl enable cyclops.service
			- in order to start the service/daemon use systemctl start cyclops.service
		- sysV:
			- create a symlink from /opt/cyclops/scripts/cyc.daemon.sh to /etc/rc3.d the symlink name should follow this convention S[0-9][0-9]cyclops. For example:
				ln -s /opt/cyclops/scripts/cyc.daemon.sh /etc/rc3.d/S65cyclops/S65cyclops
			- use chkconfig to enable it at boot time
		- Both:
			- you can use cyc.daemon.sh command to configure or enable different cyclops modules
			
		

    9. NODES CONFIG
    ----------------------------------------------------------------------------------------------------------

        - Configure ssh keys for passwordless SSH connections
		- ssh-keygen
		- ssh-copy-id [IP OR HOSTNAME]

	- Use pdsh to test it 
		- pdsh -w [HOSTNAME-RANGE] hostname -s

		[DEBIAN] ## CREATE OR USE : export PDSH_RCMD_TYPE=ssh : if you have problems with pdsh (debian rules ;))
		[DEBIAN] ## we recommend to create this export inside of /etc/system/cyclopsrc if you want.

	- Create Cyclops working directories
		1. Copy from Cyclpos server /opt/cyclops/local to all Cyclops monitored hosts
			NOTE: you can use pdcp to make it easier
			pdsh -w [NODERANGE] mkdir /opt/cyclops
			pdcp -w [NODERANGE] /opt/cyclops/local /opt/cyclops

		2. Default path: /opt/cyclops/local/data/sensors
		- if you want to change it [ NOT RECOMMENDED ] :
			1. Edit /opt/cyclops/monitor/sensors/status/conf/sensor.var.cfg file and change: _sensor_remote_path variable
			2. Edit /etc/cyclops/global.cfg file and change: _sensor_remote_path variable

	- If you want to enable management (RAZOR) integration with Cyclops client hosts and enable host control razor on clients

		1. Create this entry in the client host cron
			*/2 * * * * /opt/cyclops/local/scripts/cyc.host.ctrl.sh -a daemon 2>>/opt/cyclops/local/log/hctrl.err.log
			NOTE: Use cron root user

		2. Create this entry in the /etc/rc.local
			/opt/cyclops/local/scripts/cyc.host.ctrl.sh -a boot 2>>/opt/cyclops/local/log/hctrl.err.log

		3. You need to create a razor list in Cyclops server
		- Available razors can be found in /opt/cyclops/local/data/razor/[STOCK/OS]/

		4. Create a family file with selected razors in /etc/cyclops/nodes/[FAMILY NAME].rzr.lst
		- Use template in /etc/cyclops/nodes, family.rzr.lst.template, the name has the following format:
		- The order of razors is hierarchical, from top (first to do action) to cwbottomdown (last to do action)
		- [ RECOMMENDED ] first insert the razor with host passive checksi. After that, add with host dramatical actions like shutdown/reboot
		- if you have problems try: touch /opt/cyclops/local/etc/hctrl/[HOSTNAME].rol.cfg

    10. TEST AND ENABLE CYCLOPS
    ----------------------------------------------------------------------------------------------------------
    
	1. See available options with:
		cyclops.sh -h

	2. Check Status with:
		cyc.status.sh -a cyclops ## FOR CYCLOPS OPTIONS STATUS
		cyc.status.sh -a node  ## FOR NODE STATUS
		
	3. Generate monitoring entries 
		- With cyclops.sh -y config (option 19) or editing /etc/cyclops/monitor/monitor.cfg.template and rename it to monitor.cfg
		- Change /etc/cyclops/monitor/monitor.cfg manually for security, services and environment monitoring if you need activate this module.
		- For security module you need to edit and change /etc/cyclops/security/login.node.list.cfg ( you can use the .template as a template for your file) 
		- Services only has slurm service for now, soon we wll add the configuration instructions
		- Environment only compatible with ipmitool compatible devices for now. We have only developed a few devices sensors for now.
	
	4. Enable Cyclops in testing mode with:
		cyclops.sh -y testing -m '[MESSAGE]' -c

	5. Enable Cyclops in operative mode with:
		cyclops.sh -y enable -c

    11. UPDATE CYCLOPS
    ----------------------------------------------------------------------------------------------------------

	- BEFORE YOU UPDATE/UPGRADE BEWARE WITH THIS:
		- BACKUP the root Cyclops directoty 
		- WITH rsync USE --exclude="[FILE|DIR|STRING]" with any customization that you change in www cyclops web directory

	- UPDATE IS EXPERIMENTAL FOR NOW

	- MORE SAFETY, WITH THE STABLE GITHUB :
		- from /opt/git/cyclops
			git pull
		- after git update, use:
			rsync -vrltDuc /opt/git/cyclops/[version]/ /opt/cyclops/
		* We recommend first to run rsync with --dry-run option to see what changes will occur

	- LESS SAFETY BUT MORE CONFORTABLE  
		- use GITHUB EXPERIMENTAL OPTION INSTALL FOR CYCLOPS
		- from /opt/git/cyclops
			git pull

	- WITHOUT GITHUB
		- download zip from github
		- decompress file in a temporary directory
		- rsync with -vrltDuc options from the temporary directory to the Cyclops directory (BEWARE use --dry-run rsync option to verify everything is correct)

	NOTE: careful with the update process, sometimes ownership or permissions might change, use chown or/and chmod commands to recover the correct file and directory permissions and ownership, next step detail actions.

	
    12. OTHER CONFIGS
    ----------------------------------------------------------------------------------------------------------
	
    a. Example for logrotate configure if you need it
	
	- add a new logrotate file in /etc/logrotate.d named cyclops.mon.log
		
	- Configuration example, change settings based on your own requierements
	
	/opt/cyclops/logs/*.log
	{
    		su cyclops cyclops
		compress
		dateext
		maxage 365
		rotate 99
		missingok
		notifempty
		size +4096k
		create 640 cyclops cyclops 
		sharedscripts
		postrotate
		/usr/bin/systemctl reload syslog.service > /dev/null
		endscript
	}

	* This example ha sbeen tested on openSUSE
