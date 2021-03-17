------------------------------------------------------------------------
-- Using RMAN to Perform Recovery
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Perform complete recovery from a critical or noncritical
-- data file loss using RMAN
------------------------------------------------------------------------
	-- Realizando backup

	RMAN> backup as compressed backupset database plus archivelog delete input;

  ------------------------------------------------------------------------
	-- Simulando crash da tablespace users
	------------------------------------------------------------------------
	[oracle@bd01 ~]$ ./crashmanager.sh
		-- Loss of a non-system tablespace:                        [12]

	-- Verificar se o banco de dados está ativo
	[oracle@bd01 ~]$ sqlplus  / as sysdba

	-- Restaundo o DATAFILE;
		-- SE o banco estiver DOWN, precisa subir em modo mount:
		[oracle@bd01 ~]$ rman target /
		RMAN> startup mount;
		RMAN> restore tablespace users;
		RMAN> recover tablespace users;
		RMAN> alter database open;

		------------------------------------------------------------------------
		-- Configurando Schema HR
		------------------------------------------------------------------------
		[oracle@bd01 ~]$ sqlplus / as sysdba
		SQL> @?/demo/schema/human_resources/hr_main.sql
			specify password for HR as parameter 1:
			Enter value for 1: hr

			specify default tablespeace for HR as parameter 2:
			Enter value for 2: users

			specify temporary tablespace for HR as parameter 3:
			Enter value for 3: temp

			specify log path as parameter 4:
			Enter value for 4:
			SP2-0137: DEFINE requires a value following equal sign

			Enter value for log_path:
			SP2-0606: Cannot create SPOOL file "/hr_main.log"


		-- realizando backup da tablespace, users
		[oracle@bd01 ~]$ rman target /
		RMAN> backup tablespace users;
		RMAN> exit;

		-- Testando acesso aos dados
		[oracle@bd01 ~]$ sqlplus / as sysdba
		SQL> select count(1) from hr.employees;

		  COUNT(1)
		----------
		       107


		-- Corrompendo o datafiles
		SQL> ! > /u01/oracle/oradata/ORCL/users01.dbf
		SQL> ! ls -l /u01/oracle/oradata/ORCL/users01.dbf

		-rw-r----- 1 oracle oinstall 0 Oct 17 22:22 /u01/oracle/oradata/ORCL/users01.dbf

		-- Limpando a memoria, e Testando acesso aos dados
		SQL>  alter system flush buffer_cache;
		SQL> select count(1) from hr.employees;
		select count(1) from hr.employees
		*
		ERROR at line 1:
		ORA-01115: IO error reading block from file  (block # )
		ORA-01110: data file 4: '/u01/oracle/oradata/ORCL/users01.dbf'
		ORA-27072: File I/O error
		Additional information: 4
		Additional information: 211

		-- SE o banco de dados estiver online, vc pode restaurar a tablespace online
		RMAN> sql 'alter tablespace users offline immediate';
		RMAN> restore tablespace users;
		RMAN> recover tablespace users;
		RMAN> sql 'alter tablespace users online';

		-- Por segurança vamos fazer um novo backup
		RMAN> backup as compressed backupset database plus archivelog delete input;
		RMAN> delete noprompt obsolete;


------------------------------------------------------------------------
-- Perform incomplete recovery using RMAN
------------------------------------------------------------------------
	--------------------------------------------------------------------
	-- Ponto de Restauração
	--------------------------------------------------------------------
		SYS@orcl > select current_scn from v$database;

			CURRENT_SCN
			-----------
				2054718

		SYS@orcl > create restore point good_for_now;
		-- or
		SYS@orcl > create restore point good_for_now2 as of scn 2025087;
		-- or

		SYS@orcl> COL NAME FORMAT A30;
					    COL TIME FORMAT A30;
							select SCN, NAME, TIME  from V$RESTORE_POINT;

		SYS@orcl > DROP USER HR CASCADE;
		SYS@orcl > SELECT * FROM HR.EMPLOYEES;

		RMAN> run {
			shutdown immediate;
			startup mount;
			set until restore point good_for_now;
			restore database;
			recover database;
			alter database open resetlogs;
			}

			SYS@orcl > SELECT * FROM HR.EMPLOYEES;

		-- Por segurança vamos fazer um novo backup
		RMAN> backup as compressed backupset database plus archivelog delete input;
		RMAN> crosscheck archivelog all;
		RMAN> crosscheck backupset;
		RMAN> delete noprompt obsolete;

	--------------------------------------------------------------------
	-- Incomplete Restore
	--------------------------------------------------------------------
		SYS@orcl > create table t1 as select * from all_objects;
		SYS@orcl > insert into t1 select * from t1;
		SYS@orcl > insert into t1 select * from t1;
		SYS@orcl > commit;
		-- fornçando um switch logfile:
		SYS@orcl > alter system switch logfile;

		-- verificando o SCN
		SYS@orcl > select CURRENT_SCN from v$database;
			CURRENT_SCN
			-----------
				17360345

		-- Relizando um drop.
		SYS@orcl > delete from t1;
		SYS@orcl > commit;

		-- Relizando Incomplete Restore
		RMAN> shutdown immediate;
		RMAN> startup mount;
		RMAN> restore database until scn 17360345;
		RMAN> recover database until scn 17360345;
		RMAN> alter database open resetlogs;

		-- OR
		RMAN> run {
					shutdown immediate;
					startup mount;
					restore database until scn 2056116;
					recover database until scn 2056116;
					alter database open resetlogs;
					}

		-- Por segurança vamos fazer um novo backup
		RMAN> backup as compressed backupset database plus archivelog delete input;
		RMAN> delete noprompt obsolete;

		--------------------------------------------------------------------
		-- Restor UNTIL TIME
		--------------------------------------------------------------------
		SYS@orcl > select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') hora from dual;

			HORA
			--------------------
			18-OCT-2019 10:02:16

		-- Relizando drop da table
		SYS@orcl > drop table t1;
		SYS@orcl > exit

		-- Realizando restore / recover
		RMAN> run {
					shutdown immediate;
					startup mount;
					restore database until time "to_date('17-MAR-2021 20:11:00','DD-MON-YYYY HH24:MI:SS')";
					recover database until time "to_date('17-MAR-2021 20:11:00','DD-MON-YYYY HH24:MI:SS')";
					alter database open resetlogs;
					}

		-- OR
		RMAN> run {
					shutdown immediate;
					startup mount;
					set until time "to_date('17-MAR-2021 20:11:00','DD-MON-YYYY HH24:MI:SS')";
					restore database;
					recover database;
					alter database open resetlogs;
					}


		-- Por segurança vamos fazer um novo backup
		RMAN> backup as compressed backupset database plus archivelog delete input;
		RMAN> delete noprompt obsolete;


------------------------------------------------------------------------
-- Recover using incrementally updated backups
------------------------------------------------------------------------
	-- Removendo TODOS os Backups
	[oracle@bd01 ~]$ rman target /
	RMAN> delete noprompt backupset;

	-- Realizando backup level 0
	RMAN> BACKUP INCREMENTAL LEVEL 0 DATABASE FORMAT '/u02/fra/%d/backupset/BKP_FULL_%d_%I_%s_%T.bkp'
	TAG 'BKP_FULL'
	PLUS ARCHIVELOG DELETE INPUT FORMAT '/u02/fra/%d/backupset/BKP_ARC_%d_%I_%s_%T.bkp';

	-- Criando uma tabela t2
	RMAN> exit
	[oracle@bd01 ~]$ sqlplus / as sysdba
	SYS@orcl > create table t3 as select * from all_objects;
	SYS@orcl > select count(1) from t3;

		  COUNT(1)
		----------
			 71885

	SYS@orcl >  exit;

	-- BACKUP CUMULATIVE LEVEL 1
	[oracle@bd01 ~]$ rman target /
	RMAN> BACKUP INCREMENTAL LEVEL 1 DATABASE FORMAT '/u02/fra/%d/backupset/BKP_INCR_%d_%I_%s_%T.bkp'
	TAG 'BKP_INCR'PLUS ARCHIVELOG DELETE INPUT FORMAT '/u02/fra/%d/backupset/BKP_ARC_%d_%I_%s_%T.bkp';

	-- Relizando mais alterações na tabela t3
	RMAN> exit;
	[oracle@bd01 ~]$ sqlplus  / as sysdba
	SYS@orcl > truncate table t3;

	-- Fazendo restore.
	RMAN> run {
				shutdown immediate;
	 			startup mount;
	 			restore database;
 				recover database;
	 			alter database open;
		}

	-- Por segurança vamos fazer um novo backup
	RMAN> backup as compressed backupset database plus archivelog delete input;
	RMAN> delete noprompt obsolete;
------------------------------------------------------------------------
-- Switch to image copies for fast recovery
------------------------------------------------------------------------
	-- Realizando backup as copy
	$ mkdir -p /u02/fra/ORCL/datafile
	RMAN> backup as copy tablespace users format '/u02/fra/ORCL/datafile/USERS_01.dbf';

	--USANDO SIWTCH PARA RECUPERAR
	SQL> alter tablespace users offline immediate; 
	RMAN> switch tablespace USERS  to copy;
	RMAN> recover tablespace USERS;
	rman> alter tablespace users online;

	-- Verificar a localização da tablespace users
	RMAN> report schema;

		Report of database schema for database with db_unique_name ORCL

		List of Permanent Datafiles
		===========================
		File Size(MB) Tablespace           RB segs Datafile Name
		---- -------- -------------------- ------- ------------------------
		1    880      SYSTEM               YES     /u01/oracle/oradata/orcl/system01.dbf
		3    1790     SYSAUX               NO      /u01/oracle/oradata/orcl/sysaux01.dbf
		4    75       UNDOTBS1             YES     /u01/oracle/oradata/orcl/undotbs01.dbf
		7    5        USERS                NO      /u02/fra/ORCL/datafile/USERS_01.dbf


	-- Voltando a localização anterior.
	-- Realizando backup as copy
	$ rm -f /u01/oracle/oradata/ORCL/user01.dbf
	RMAN> backup as copy tablespace users format '/u01/oracle/oradata/ORCL/user01.dbf';

	--USANDO SIWTCH PARA RECUPERAR
	SQL> alter tablespace users offline immediate; 
	RMAN> switch tablespace USERS  to copy;
	RMAN> recover tablespace USERS;
	rman> alter tablespace users online;

	-- Por segurança vamos fazer um novo backup
	RMAN> backup as compressed backupset database plus archivelog delete input;
	RMAN> delete noprompt obsolete;

------------------------------------------------------------------------
-- USANDO O SET NEWNAME do RMAN
------------------------------------------------------------------------
	/*
	Uma das diversas opções do comando SET no RMAN é comando SET NEWNAME.
	Dentro de um bloco RUN, o SET NEWNAME facilita especificar um ou mais
	destinos de arquivos de dados como uma preparação para os comandos subsequentes
	RESTORE e SWITCH.

	Veja a seguir um bloco RUN do RMAN para especificar uma nova localização para o
	arquivo de dados restaurado do tablespace users.
	*/

	-- voltando localização original
	RMAN>  run {
		sql "alter tablespace users offline immediate";
		set newname for datafile '/u01/oracle/oradata/orcl/user01.dbf' to '/u02/fra/users01.dbf';
		restore tablespace users;
		switch datafile all;
		recover tablespace users;
		sql "alter tablespace users online";
	}

	-- Por segurança vamos fazer um novo backup
	RMAN> backup as compressed backupset database plus archivelog delete input;
	RMAN> delete noprompt obsolete;

	-- Voltando localização original
	RMAN>  run {
		sql "alter tablespace users offline immediate";
		set newname for datafile '/u02/fra/users01.dbf' to '/u01/oracle/oradata/orcl/user01.dbf';
		restore tablespace users;
		switch datafile all;
		recover tablespace users;
		sql "alter tablespace users online";
	}


	-- Exemplo de um caso reaal
	RMAN> alter database mount;
	RMAN> catalog start with '/bkp';
	RMAN> run {
			set newname for datafile 1 to '/u01/oracle/oradata/orcl/system01.dbf';
			set newname for datafile 2 to '/u01/oracle/oradata/orcl/undotbs1.dbf';
			set newname for datafile 3 to '/u01/oracle/oradata/orcl/sysaux01.dbf';
			set newname for datafile 4 to '/u01/oracle/oradata/orcl/user01.dbf';
			set newname for datafile 5 to '/u01/oracle/oradata/orcl/prod01_data01.dbf';
			set newname for datafile 6 to '/u01/oracle/oradata/orcl/prod01_indx01.dbf';
			set newname for datafile 7 to '/u01/oracle/oradata/orcl/tmp01.dbf';
			set newname for datafile 8 to '/u01/oracle/oradata/orcl/prod01_data02.dbf';
			set newname for datafile 9 to '/u01/oracle/oradata/orcl/prod01_data03.dbf';
			set newname for datafile 10 to '/u01/oracle/oradata/orcl/prod01_data04.dbf';
			set newname for datafile 11 to '/u01/oracle/oradata/orcl/prod01_data05.dbf';
			set newname for datafile 12 to '/u01/oracle/oradata/orcl/prod01_data06.dbf';
			set newname for datafile 13 to '/u01/oracle/oradata/orcl/undotbs2.dbf';
			set newname for datafile 14 to '/u01/oracle/oradata/orcl/sysaux02.dbf';
			set newname for datafile 15 to '/u01/oracle/oradata/orcl/sysaux03.dbf';
			SET NEWNAME FOR tempfile 1 to '/u01/oracle/oradata/orcl/prod01_tmp.dbf';
			SET NEWNAME FOR tempfile 2 to '/u01/oracle/oradata/orcl/prod02_tmp.dbf';
			SET NEWNAME FOR tempfile 3 to '/u01/oracle/oradata/orcl/prod03_tmp.dbf';
			SET NEWNAME FOR tempfile 4 to '/u01/oracle/oradata/orcl/prod04_tmp.dbf';
			restore database;
			switch datafile all;
			switch tempfile all;
			}


------------------------------------------------------------------------
-- Cliente liberado espaço em disco
------------------------------------------------------------------------

	[oracle@bd01 orcl]$ cd /u01/oracle/oradata/ORCL/
	[oracle@bd01 orcl]$ rm -f *


	-- Realizando Recover
	[oracle@bd01 orcl]$ rman target /
	RMAN> startup nomount;
	RMAN> restore controlfile from autobackup;
	RMAN> alter database mount;
	RMAN> restore database;
	RMAN> recover database noredo;
	RMAN> alter database open resetlogs;
