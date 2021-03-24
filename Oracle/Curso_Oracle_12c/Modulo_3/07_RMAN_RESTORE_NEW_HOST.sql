-------------------------------------------------------------------------------------
-- Restore a database onto a new host
-------------------------------------------------------------------------------------
-- Host Origem
-------------------------------------------------------------------------------------
	-- select dbid from v$database;
	[oracle@bd01 ~]$ sqlplus  / as sysdba
	SYS@orcl > select dbid from v$database;


		DBID
	----------
	1578698545


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
	-- Puxando para o servidor de backup
	[oracle@bd01 ~]$ rsync -ravzp --progress -e "ssh -p 22" [ip_servidor_origem]:/u01/fra/ORCL2 /u01/fra

	-- Enviar o backup para o Novo servidor.
	[oracle@bd01 ~]$ rsync -ravzp --progress -e "ssh -p 22" /u01/fra 152.67.62.102:/u01

	-- Configure as variaveis de ambiente
	$ export ORACLE_SID=ORCL

	-- Restaurando SPFILE 
	$  scp /u01/oracle/product/19.0.0/dbhome_1/dbs/spfileORCL.ora 152.67.62.102:/u01/oracle/product/19.0.0/dbhome_1/dbs/spfileORCL.ora

	-- Conecte-se ao novo banco de dados de destino com NOCATALOG
	$ rman target /

	-- Defina o DBID
    RMAN> set dbid 1578698545

	-- Inicialize a instancia em modo NOMOUNT
   
	-- Gerou o erro acima, pq não temos os diretorios criados
	-- Verificando e criando os diretorios
	$ strings /u01/oracle/product/19.0.0/dbhome_1/dbs/spfileORCL.oramkdir 
	$ mkdir -p /u01/oracle/admin/ORCL/adump
	$ mkdir -p /u01/oracle/oradata/ORCL/
	$ mkdir -p /u01/fra/ORCL/
	$ mkdir -p /u02/fra
	$ mkdir -p /u02/ORCL/arc

	-- Tentar subir novamente
	[oracle@bd01 ~]$ rman target /
	RMAN> set dbid 1578698545
	RMAN> startup nomount;

	-- Resturar o CONTROLFILE
	RMAN> RESTORE CONTROLFILE FROM '/u01/fra/ORCL/backupset/CONTROLFILE_ORCL_1578698545_91_20210324_1.bkp';

	-- Alterando a instancia para o modo mount;
	RMAN> alter database mount;

	-- Catalogando backup
	RMAN> catalog start with '/u01/fra/ORCL/backupset';

	-- Realizando o restor database;
	RMAN> restore database;

	-- Realizando o recover database;
	RMAN> recover database;
	-- RMAN-03002: failure of recover command at 09/29/2017 15:54:00
	-- RMAN-06054: media recovery requesting unknown archived log for thread 1 with sequence 3 and starting SCN of 187685
	-- RMAN> recover database noredo;

	-- Sincronizandos os backups diferenciais
	$ rsync -ravzp --progress -e "ssh -p 22" /u02/ORCL/arc 152.67.62.102:/u02/ORCL

	-- Catalogando backup
	RMAN> catalog start with '/u02/ORCL/arc';
	RMAN> recover database;

	-- Open database resetlogs;
	RMAN> alter database open resetlogs;

	-- Validando base de dados 
	RMAN> validate database; 

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

	-- Backup servidor de origem
	RMAN> alter tablespace teste read only;

	RMAN> backup to platform 'Linux x86 64-bit' format '/u01/fra/TRANSPORT_%u.rman' datapump format '/u01/fra/TRANSPORT_%u.dmp' tablespace 'TESTE';

---------------------------------------------------------------------------
-- Host de destino
---------------------------------------------------------------------------
	-------------------------------------------------------------------------
	-- Acertando characterset, pq na ORCL2 está diferente.
	-------------------------------------------------------------------------
	-- envia arquivos 
	$ scp /u01/fra/TRANSPORT_* 152.67.62.102:/u01/fra/

		[oracle@bd01 ]$ cd /u01/fra ; ls -l
	total 11568
	drwxr-xr-x 3 oracle oinstall       24 Oct 17 20:43 ORCL
	drwxr-x--- 5 oracle oinstall       59 Oct 24 14:07 ORCL2
	-rw-r----- 1 oracle oinstall 11632640 Oct 24 14:26 TRANSPORT_24uf4ggi.rman
	-rw-r----- 1 oracle oinstall   212992 Oct 24 14:26 TRANSPORT_25uf4ggj.dmp

	[oracle@bd01 ]$ export ORACLE_SID=ORCL2
  [oracle@bd01 ]$ rman target /
	RMAN> restore foreign tablespace 'TESTE'
	format '/u01/oracle/oradata/ORCL/teste.dbf'
	from backupset '/u01/fra/TRANSPORT_2vvqic7m.rman'
	dump file from backupset '/u01/fra/TRANSPORT_30vqic7o.dmp';
