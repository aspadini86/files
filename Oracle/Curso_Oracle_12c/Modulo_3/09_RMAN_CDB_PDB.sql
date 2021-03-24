---------------------------------------------------------------------------
-- Perform backup of CDB and PDB
---------------------------------------------------------------------------
	/*
	You can back up and recover an entire CDB and all
	PDBs, just the CDB root container, or one or more PDBs within the CDB.
	In addition, you can backup and recover individual tablespaces and
	datafiles in a PDB.
	*/

	-- Exportando variable
		[oracle@bd01 ~]$ . oraenv
		ORACLE_SID = [ORCL] ? ORCL2

		[oracle@bd01 ~]$ sqlplus  / as sysdba
		SYS@ORCL2> startup mount
		SYS@ORCL2> alter database archivelog;
		SYS@ORCL2> alter database open;
		SYS@ORCL2> exit;

	-- Report schema
		[oracle@bd01 ~]$ rman target /
		RMAN> report schema;

	-- Backup all database and PDBs
		RMAN> backup as compressed backupset database;

	-- Backup pluggable database
		RMAN> backup as compressed backupset pluggable database pdb01;

	-- Backup just root container
		RMAN> backup pluggable database 'CDB$ROOT';

	-- You can also perform user-managed hot backups of pluggable database;
		[oracle@bd01 ~]$ . oraenv
		ORACLE_SID = [ORCL] ? ORCL2
		[oracle@bd01 ~]$ sqlplus  / as sysdba
		SYS@ORCL2 > alter pluggable database pdb01 open;
		SYS@ORCL2 > alter session set container=PDB01;
		SYS@ORCL2 > alter pluggable database pdb01 begin backup;
		SYS@ORCL2 > exit

		-- Copiando datafiles
		[oracle@bd01 ~]$ cp -a /u01/oracle/oradata/ORCL2/pdb01 /u01/pdb01_bkp

		[oracle@bd01 ~]$ sqlplus  / as sysdba
		SYS@ORCL2 > alter session set container=pdb01;
		SYS@ORCL2 > alter pluggable database pdb01 end backup;
		SYS@ORCL2 > exit

	-- Performing a Partial backup of PDB
		[oracle@bd01 ~]$ rman target /
		RMAN> backup tablespace PDB01:SYSTEM;
		RMAN> backup tablespace PDB01:SYSTEM,PDB01:SYSAUX;

---------------------------------------------------------------------------
-- Perform recovery of CDB and PDB
---------------------------------------------------------------------------
	-- Create tablespace users
		[oracle@bd01 ~]$ . oraenv
		ORACLE_SID = [ORCL] ? ORCL2
		[oracle@bd01 ~]$ sqlplus  / as sysdba
		SYS@ORCL2 > alter pluggable database pdb01 open;
		SYS@ORCL2 > alter session set container=pdb01;
		SYS@ORCL2 > create tablespace users datafile '/u01/oracle/oradata/ORCL2/pdb01/users01.dbf' size 10m autoextend on;

	-- Performing Complete Recovery of a Whole CDB
		RMAN> backup as compressed backupset database;
		RMAN> shutdown immediate;
		RMAN> startup mount;
		RMAN> restore database;
		RMAN> recover database;
		RMAN> alter database open;

	-- Recovering the Root Container
		RMAN> backup as compressed backupset root;
		RMAN> shutdown immediate;
		RMAN> startup mount;
		RMAN> restore database root;
		RMAN> recover database root;
		RMAN> alter database open;

	-- Performing Complete Recovery of PDBs
		RMAN> backup as compressed backupset database pdb01;
		RMAN> alter pluggable database pdb01 close;
		RMAN> restore pluggable database pdb01;
		RMAN> recover pluggable database pdb01;
		rman> alter pluggable database pdb01 open;

	-- Loss of PDB a non-system Datafile
		[oracle@bd01 ~]$ sqlplus  / as sysdba
		SYS@ORCL2 > alter session set container=pdb01;
		SYSTEM@pdb01 > alter tablespace users offline immediate;
		SYSTEM@pdb01 > exit;

		[oracle@bd01 ~]$ rman target /
		rman> restore tablespace pdb01:users;
		rman> recover tablespace pdb01:users;
		rman> exit

		[oracle@bd01 ~]$ sqlplus  / as sysdba
		SYS@ORCL2 > alter session set container=pdb01;
		SYSTEM@pdb01 > alter tablespace users online;


	-- Performing a PITR for a PDB
		[oracle@bd01 ~]$ rman target /
		RMAN> backup as compressed backupset pluggable database pdb01;
		RMAN> exit;

		-- Verificar o SCN
		[oracle@bd01 ~]$ sqlplus  / as sysdba
		SYS@ORCL2  > select current_SCN FROM V$DATABASE;

			CURRENT_SCN
			-----------
				2479130

		$ cd /u01/oracle/oradata/ORCL2/pdb01/
		$ rm -f *.dbf

		[oracle@bd01 ~]$ rman target /
		RMAN> run {
				alter pluggable database pdb01 close immediate;
				set until scn=2479130;
				restore pluggable database pdb01;
				recover pluggable database pdb01;
				alter pluggable database pdb01 open resetlogs;
				}


	-- Multisection Backups of Image Copies 12c
		-- The capability to perform incremental multisection backups
		RMAN> backup section size 200m incremental level 0 database plus archivelog delete input;

		-- The capability to create multisection imagem copies with RMAN
		RMAN> backup as copy section size 200m database;

------------------------------------------------------------------------------------------------
-- How to migrate non-cdb to pdb
------------------------------------------------------------------------------------------------
-- 1. Desligar a instancia CDB
	[oracle@bd01 ~]$ . oraenv
	ORACLE_SID = [ORCL] ? ORCL2
	[oracle@bd01 ~]$ sqlplus  / as sysdba
	SYS@ORCL2  > shutdown immediate;
	SYS@ORCL2  > exit;

-- 2. Ligar a instancia TESTE
	$ export ORACLE_SID=TESTE
	$ sqlplus  / as sysdba

	SYS@TESTE > shutdown immediate;
	SYS@TESTE > STARTUP OPEN READ ONLY;

-- 3. Describe the non-DBC using the DBMS_PDB.DESCRIBE procedure.]

	SYS@TESTE > BEGIN
	DBMS_PDB.DESCRIBE(
		pdb_descr_file => '/tmp/TESTE.xml');
	END;
	/

-- 4. SHUTDOWN AGAIN
	SYS@TESTE > SHUTDOWN IMMEDIATE;


-- 5. Logando na instancia ORCL2
	$ export ORACLE_SID=ORCL2
	$ sqlplus / as sysdba
	SYS@ORCL2 > startup
	SYS@ORCL2 > alter system set compatible='19.0.0.0.0' scope=spfile;
	SYS@ORCL2 > CREATE PLUGGABLE DATABASE PDB6 USING '/tmp/TESTE.xml'
	COPY
	FILE_NAME_CONVERT = ('/u01/oracle/oradata/TESTE/', '/u01/oracle/oradata/ORCL2/TESTE/');

-- 6. Alterar de database
	SYS@ORCL2 > ALTER SESSION SET CONTAINER=pdb6;
	SYS@ORCL2  > @$ORACLE_HOME/rdbms/admin/noncdb_to_pdb.sql

-- 7. Startup the PDB
	SYS@ORCL2 > ALTER SESSION SET CONTAINER=pdb6;
	SYS@ORCL2 > ALTER PLUGGABLE DATABASE OPEN;

	SYS@ORCL2 > select * from v$tablespace;

		   TS# NAME                           INC BIG FLA ENC     CON_ID
	---------- ------------------------------ --- --- --- --- ----------
			 0 SYSTEM                         YES NO  YES              4
			 1 SYSAUX                         YES NO  YES              4
			 2 UNDOTBS1                       YES NO  YES              4
			 3 TEMP                           NO  NO  YES              4
			 4 USERS                          YES NO  YES              4
			 6 RMAN                           YES NO  YES              4
			 7 TESTE                          YES NO  YES              4

	SYS@CDB > select name from v$datafile;

	NAME
	------------------------------------------------------------------------------------------------------------------------------------
	/u01/oracle/oradata/ORCL2/TESTE/system01.dbf
	/u01/oracle/oradata/ORCL2/TESTE/sysaux01.dbf
	/u01/oracle/oradata/ORCL2/TESTE/undotbs01.dbf
	/u01/oracle/oradata/ORCL2/TESTE/users01.dbf
