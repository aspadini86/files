-------------------------------------------------------------------------------------
-- Restore a database onto a new host
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Host Origem
-------------------------------------------------------------------------------------
	-- select dbid from v$database;
	[oracle@bd01 ~]$ sqlplus  / as sysdba
	SYS@orcl > select dbid from v$database;


		DBID
	----------
	1003278535


	-- Gerar um novo backup
	[oracle@bd01 ~]$ rman target /
	RMAN> delete noprompt backupset;

	RMAN> delete noprompt obsolete;

	RMAN> backup as compressed
		backupset database format '/u01/fra/%d/backupset/BKP_%d_%I_%s_%T_%p.bkp'
        tag BKP_FULL
		current controlfile format  '/u01/fra/%d/backupset/CONTROLFILE_%d_%I_%s_%T_%p.bkp'
		spfile format '/u01/fra/%d/backupset/SPFILE_%d_%I_%s_%T.bkp'  tag 'BKP_SPFILE'
        archivelog all format '/u01/fra/%d/backupset/ARC_%d_%I_%s_%T.bkp'  tag 'BKP_ARCHIVELOG' delete input;

-------------------------------------------------------------------------------------
-- Host Destino
-------------------------------------------------------------------------------------
	-- Enviar o backup para o Novo servidor.
	[oracle@bd01 ~]$ rsync -ravzp --progress -e "ssh -p 2200" [ip_servidor_origem]:/u01/fra/ORCL2 /u01/fra


	-- Configure as variaveis de ambiente
	$ export ORACLE_SID=ORCL2

	-- Conecte-se ao novo banco de dados de destino com NOCATALOG
	$ rman target /

	-- Defina o DBID
    RMAN> set dbid 1003278535

	-- Inicialize a instancia em modo NOMOUNT
    RMAN> startup nomount

	-- Restaura o SPFILE
	RMAN> restore spfile from '/u01/fra/ORCL2/backupset/SPFILE_ORCL2_1003278535_7_20191024.bkp';
	RMAN> shutdown immediate;
	RMAN> startup nomount;

		connected to target database (not started)
		RMAN-00571: ===========================================================
		RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
		RMAN-00571: ===========================================================
		RMAN-03002: failure of startup command at 10/19/2018 11:40:31
		RMAN-04014: startup failed: ORA-16032: parameter LOG_ARCHIVE_DEST_2 destination string cannot be translated
		ORA-07286: sksagdi: cannot obtain device information.
		Linux-x86_64 Error: 2: No such file or directory

	-- Gerou o erro acima, pq não temos os diretorios criados
	-- Verificando e criando os diretorios
	[oracle@bd01 ~]$ cat /u02/fra/ORCL/backupset/SPFILE_ORCL2_1003278535_7_20191024.bkp
	[oracle@bd01 ~]$ mkdir -p /u01/oracle/admin/ORCL2/adump  /u01/oracle/oradata/ORCL2/
	[oracle@bd01 ~]$ chown oracle:oinstall /u01/oracle/admin/ORCL2/adump  /u01/oracle/oradata/ORCL2/
	[oracle@bd01 ~]$ exit

	-- Tentar subir novamente
	[oracle@bd01 ~]$ rman target /
	RMAN> set dbid 1003278535
	RMAN> startup nomount;

	-- Resturar o CONTROLFILE
	RMAN> RESTORE CONTROLFILE FROM '/u01/fra/ORCL2/backupset/CONTROLFILE_ORCL2_1003278535_6_20191024_1.bkp';

	-- Alterando a instancia para o modo mount;
	RMAN> alter database mount;

	-- Catalogando backup
	RMAN> catalog start with '/u01/fra/ORCL2/backupset';

	-- Realizando o restor database;
	RMAN> restore database;

	-- Realizando o recover database;
	RMAN> recover database;
	-- RMAN-03002: failure of recover command at 09/29/2017 15:54:00
	-- RMAN-06054: media recovery requesting unknown archived log for thread 1 with sequence 3 and starting SCN of 187685
	-- RMAN> recover database noredo;

	-- Open database resetlogs;
	RMAN> alter database open resetlogs;

	-- Restore realizado com sucesso!!!!
	RMAN> shutdown immediate;

---------------------------------------------------------------------------
--Transporting Tablespaces to a Different Platform Using RMAN Backupsets
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Database Origem: ORCL
---------------------------------------------------------------------------

	[oracle@bd01 ~]$ export ORACLE_SID=ORCL
	[oracle@bd01 ~]$ sqlplus / as sysdba
	SYS@ORCL > startup
	SYS@orcl > create tablespace teste datafile '/u01/oracle/oradata/ORCL/teste01.dbf' size 100m;


	-- Inserindo dados nessa tablespace
	SYS@orcl > CREATE TABLE t1_tbs TABLESPACE teste AS SELECT * FROM all_objects;

	-- Atualizando statistics do Oracle
	SYS@orcl > ALTER SYSTEM SET RESOURCE_MANAGER_PLAN = default_plan;
	SYS@orcl > exit;

	-- Backup servidor de origem
	RMAN> alter tablespace teste read only;

	RMAN> backup to platform 'Linux x86 64-bit'
		format '/u01/fra/TRANSPORT_%u.rman' datapump
		format '/u01/fra/TRANSPORT_%u.dmp'
		tablespace 'TESTE';

	RMAN> shutdown immediate;
	RMAN> exit;

---------------------------------------------------------------------------
-- Host de destino
---------------------------------------------------------------------------
	-------------------------------------------------------------------------
	-- Acertando characterset, pq na ORCL2 está diferente.
	-------------------------------------------------------------------------
	[oracle@bd01 ]$ export ORACLE_SID=ORCL2
	[oracle@bd01 ]$ sqlplus / as sysdba
	SYS@ORCL2 > select * from v$nls_parameters where parameter in ('NLS_CHARACTERSET');

	PARAMETER                                                        VALUE                                                                CON_ID
	---------------------------------------------------------------- ---------------------------------------------------------------- ----------
	NLS_CHARACTERSET                                                 AL32UTF8                                                                  1

	SYS@ORCL2 >	shutdown immediate;
	SYS@ORCL2 > startup restrict;
	SYS@ORCL2 > alter database character set INTERNAL_USE WE8ISO8859P1;
	SYS@ORCL2 >	shutdown immediate;
	SYS@ORCL2 > startup;
	SYS@ORCL2 > exit;

	[oracle@bd01 ]$ cd /u01/fra ; ls -l
	total 11568
	drwxr-xr-x 3 oracle oinstall       24 Oct 17 20:43 ORCL
	drwxr-x--- 5 oracle oinstall       59 Oct 24 14:07 ORCL2
	-rw-r----- 1 oracle oinstall 11632640 Oct 24 14:26 TRANSPORT_24uf4ggi.rman
	-rw-r----- 1 oracle oinstall   212992 Oct 24 14:26 TRANSPORT_25uf4ggj.dmp

	[oracle@bd01 ]$ export ORACLE_SID=ORCL2
  [oracle@bd01 ]$ rman target /
	RMAN> restore foreign tablespace 'TESTE'
	format '/u01/oracle/oradata/ORCL2/teste.dbf'
	from backupset '/u01/fra/TRANSPORT_24uf4ggi.rman'
	dump file from backupset '/u01/fra/TRANSPORT_25uf4ggj.dmp';
