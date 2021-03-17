-----------------------------------------------------------------------------
-- Oracle Cloud Infrastructure
-----------------------------------------------------------------------------
	# sudo su -
---------------------------------------------------------------------------------
-- Verificar conectividade
---------------------------------------------------------------------------------
	# ping www.terra.com.br
	# ping 8.8.8.8
	

---------------------------------------------------------------------------------
-- Desabilitar selinux
---------------------------------------------------------------------------------
	$ sudo su - 
	# sed -i  "s/enforcing/permissive/g" /etc/selinux/config
	
---------------------------------------------------------------------------------
-- Desabilitar firewall
---------------------------------------------------------------------------------
	# iptables -L -nv
	# systemctl disable firewalld
	# systemctl stop firewalld
	# systemctl status firewalld	
	
---------------------------------------------------------------------------------
-- Acertar o hosts 
---------------------------------------------------------------------------------
	# cat /etc/hosts 
	
---------------------------------------------------------------------------------
-- Configuração repositorio epel CentOS 7
---------------------------------------------------------------------------------
	# yum install oracle-epel-release-el7.x86_64 
	# yum install screen rlwrap 
	# yum install oracle-database-preinstall-19c.x86_64
	# yum update -y 
	
	-- https://oracle-base.com/articles/19c/oracle-db-19c-installation-on-oracle-linux-7
	
	-- sysctl.conf possui parametros de kernel 
	# cat /etc/sysctl.conf
	
	-- oracle-database-preinstall-19c.conf
	# cat /etc/security/limits.d/oracle-database-preinstall-19c.conf

---------------------------------------------------------------------------------
-- Configuração bash_profile 
---------------------------------------------------------------------------------
	-- SETUP AUTOMATICO
	# mkdir -p /u01 /u02 
	# chown oracle. /u01 /u02 -R

	# sudo su - oracle
	$ vim .bash_profile

	# Oracle Variaveis
	export ORACLE_BASE=/u01/oracle
	export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
	export ORACLE_SID=ORCL

	export PATH=/usr/sbin:$PATH
	export PATH=$ORACLE_HOME/bin:$PATH

	export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
	export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib


	alias sqlplus='rlwrap sqlplus'
	alias rman='rlwrap rman'
	
	$ exit 
	# reboot 
	
---------------------------------------------------------------------------------
-- Instalação Oracle 19c 
---------------------------------------------------------------------------------
	-- Baixar instalador 
	[opc@bancora ~]$ screen 
	[opc@bancora ~]$ sudo su - oracle
	[oracle@bancora ~]$ echo $ORACLE_HOME 
	[oracle@bancora ~]$ mkdir -p $ORACLE_HOME
	[oracle@bancora ~]$ cd $ORACLE_HOME 
	[oracle@bancora dbhome_1]$ wget https://objectstorage.sa-saopaulo-1.oraclecloud.com/p/fxbl1QJYDRPrURKZCeUbZkuGLmHsQWkUAeJLCYmAJZgaSJf0UXtYWkqeg7v2yCbd/n/grvbgjbjzjjg/b/BUCKET-ASPADINI/o/LINUX.X64_193000_db_home.zip
	[oracle@bancora dbhome_1]$ unzip LINUX.X64_193000_db_home.zip
	
	-- Installation 
	[oracle@bancora dbhome_1]$ ./runInstaller -ignorePrereq -waitforcompletion -silent \
    -responseFile ${ORACLE_HOME}/install/response/db_install.rsp               \
    oracle.install.option=INSTALL_DB_SWONLY                                    \
    ORACLE_HOSTNAME=${ORACLE_HOSTNAME}                                         \
    UNIX_GROUP_NAME=oinstall                                                   \
    INVENTORY_LOCATION=${ORACLE_BASE}/oraInventory                             \
    SELECTED_LANGUAGES=en,en_GB                                                \
    ORACLE_HOME=${ORACLE_HOME}                                                 \
    ORACLE_BASE=${ORACLE_BASE}                                                 \
    oracle.install.db.InstallEdition=EE                                        \
    oracle.install.db.OSDBA_GROUP=dba                                          \
    oracle.install.db.OSBACKUPDBA_GROUP=dba                                    \
    oracle.install.db.OSDGDBA_GROUP=dba                                        \
    oracle.install.db.OSKMDBA_GROUP=dba                                        \
    oracle.install.db.OSRACDBA_GROUP=dba                                       \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false                                 \
    DECLINE_SECURITY_UPDATES=true
	
	-- Run the root scripts 
	-- As a root user, execute the following script(s):
	[oracle@bancora dbhome_1]$ exit
	logout
	[opc@bancora ~]$ sudo su -
	[root@bancora ~]# /u01/oracle/oraInventory/orainstRoot.sh
    [root@bancora ~]# /u01/oracle/product/19.0.0/dbhome_1/root.sh
		
	-- Database Creation 
	-- Start the listener.
	[root@bancora ~]# sudo su - oracle 
	[oracle@bancora ~]$ lsnrctl start

	--  Interactive mode.
	[oracle@bancora ~]$ dbca 

	-- Silent mode.
	[oracle@bancora ~]$ dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname ${ORACLE_SID} -sid  ${ORACLE_SID} -responseFile NO_VALUE -characterSet WE8MSWIN1252  -sysPassword password   -systemPassword password -createAsContainerDatabase true -numberOfPDBs 1 -pdbName PDB01 -pdbAdminPassword password -databaseType MULTIPURPOSE -memoryMgmtType auto_sga -totalMemory 800 -redoLogFileSize 100 -emConfiguration NONE -ignorePreReqs
		 
	-- Post Installation 
	[oracle@bancora ~]$ sudo su - 
	[root@bancora ~]# vim /etc/oratab 
	[root@bancora ~]# ORCL:/u01/app/oracle/product/19.0.0/db_1:Y
	
	
	