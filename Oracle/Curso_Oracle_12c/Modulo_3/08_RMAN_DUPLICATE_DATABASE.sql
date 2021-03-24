---------------------------------------------------------------------------
-- RMAN DUPLICATE (usando backup)
---------------------------------------------------------------------------
--1. Configuração da Instancia de Origem
	ORACLE_SID: ORCL
	DATAFILES: /u01/oracle/oradata/ORCL
	ARCHIVELOG: Habilitado

-- 2. Backup instância de origem ORCL
	[oracle@bd01 ~]$ export ORACLE_SID=ORCL
	[oracle@bd01 ~]$ rman target /
	RMAN> startup
	RMAN> backup as compressed backupset database;

-- 3. Configurando o arquivo de senhas do instância TESTE
-- A senha de system / sys das duas instâncias precisam ser a mesma
	[oracle@bd01 ~]$ rm -f $ORACLE_HOME/dbs/orapwORCL
	[oracle@bd01 ~]$ orapwd file=$ORACLE_HOME/dbs/orapwORCL password=password format=12 entries=10 force=y
	[oracle@bd01 ~]$ orapwd file=$ORACLE_HOME/dbs/orapwTESTE password=password format=12 entries=10 force=y


	-- Reiniciar o serviço de listener
	[oracle@bd01 ~]$  lsnrctl start

-- 6. Configurando o init.ora da instância TESTE
	[oracle@bd01 ~]$ vim $ORACLE_HOME/dbs/initTESTE.ora
	DB_NAME=TESTE
	DB_BLOCK_SIZE=8192
	CONTROL_FILES=(/u01/oracle/oradata/TESTE/control01.ctl,/u01/oracle/oradata/TESTE/control02.ctl)
	DB_FILE_NAME_CONVERT=(/u01/oracle/oradata/ORCL/,/u01/oracle/oradata/TESTE/)
	LOG_FILE_NAME_CONVERT=(/u01/oracle/oradata/ORCL/,/u01/oracle/oradata/TESTE/)
	COMPATIBLE=19.0.0.0.0


-- 7. Criar a estrutura de diretórios inseridas para a instância TESTE
	[oracle@bd01 ~]$ mkdir -p /u01/oracle/oradata/TESTE
	[oracle@bd01 ~]$ mkdir -p /u01/oracle/admin/TESTE/adump

-- 8. Iniciar a instância TESTE em modo nomount e criar o arquivo de spfile.
	[oracle@bd01 ~]$ export ORACLE_SID=TESTE
	[oracle@bd01 ~]$ sqlplus / as sysdba
	SYS@teste > startup nomount pfile='$ORACLE_HOME/dbs/initTESTE.ora';
	SYS@teste > exit;

-- 9. Duplicante a instância ORCL na instância TESTE
	[oracle@bd01 ~]$ export ORACLE_SID=TESTE
	[oracle@bd01 admin]$ rman target sys/password@ORCL auxiliary /

-- 10. Duplicate database
	RMAN> duplicate target database to TESTE;
	RMAN> exit;


-- 12. Verificando o status
	[oracle@bd01 ~]$ export ORACLE_SID=TESTE
	[oracle@bd01 ~]$ sqlplus / as sysdba
	SYS@teste > select open_mode,name,created from v$database;

	OPEN_MODE            NAME      CREATED
	-------------------- --------- ---------
	READ WRITE           TESTE     24-OCT-19


	SYS@teste > select file_name from dba_data_files;

		FILE_NAME
		--------------------------------------------------------------------------------
		/u01/oracle/oradata/TESTE/system01.dbf
		/u01/oracle/oradata/TESTE/sysaux01.dbf
		/u01/oracle/oradata/TESTE/undotbs01.dbf
		/u01/oracle/oradata/TESTE/user01.dbf
		/u01/oracle/oradata/TESTE/rman01.dbf
		/u01/oracle/oradata/TESTE/teste01.dbf


	SYS@teste > select file_name from dba_temp_files;


		FILE_NAME
		--------------------------------------------------------------------------------
		/u01/oracle/oradata/TESTE/temp01.dbf
