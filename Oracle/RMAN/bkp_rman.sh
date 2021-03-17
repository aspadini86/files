#!/bin/bash														#
#                                                               #
# CCM TECNOLOGIA                                                #
# ANDRÉ DEL CAMPO SPADINI                                       #
# EMAIL: aspadini@ccmtecnologia.com.br                          #
# TEL: 16-3515-8300                                             #
#                                                               #
# FUNÇÃO                                                        #
# Efetua backup fisico full do banco de dados utilizando        #
# utilitario RMAN                                               #
#################################################################

#
# EXPORTANDO VARIAVEIS
source /home/oracle/.bash_profile
export DATA=$(date +%F)
export DIRBKP="/u02/fra/$(echo $ORACLE_SID | tr '[:lower:]' '[:upper:]')/backupset"

#
# VERIFICANDO SE DIRETORIO EXISTE
if [ ! -d $DIRBKP ]
then
        mkdir -p $DIRBKP
        chown oracle.oinstall $DIRBKP
fi

#
# INICIO BACKUP RMAN
$ORACLE_HOME/bin/rman log=$DIRBKP/bkprman_$DATA.log <<EOF
connect target
run {
        sql 'alter session set optimizer_mode=RULE';

        # Configuring RMAN
        CONFIGURE RETENTION POLICY TO REDUNDANCY 1;
        CONFIGURE BACKUP OPTIMIZATION ON;
        CONFIGURE CONTROLFILE AUTOBACKUP ON;
        CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/u02/fra/%d/backupset/CONTROLFILE_%F.bkp';
        CONFIGURE DEVICE TYPE DISK BACKUP TYPE TO COMPRESSED BACKUPSET PARALLELISM 1;
        CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 4G;

        # Perform crosscheck
        crosscheck ARCHIVELOG ALL ;
        crosscheck BACKUPSET ;
        crosscheck BACKUP ;

        # Clear EXPIRED backups
        delete noprompt EXPIRED archivelog all ;
        delete noprompt EXPIRED backupset ;
        delete noprompt EXPIRED backup ;

        # Perform archive log current
        sql 'alter system archive log current';
        sql 'alter system switch logfile';

        # Clear obsolete backups
        delete noprompt obsolete;

        # Bacup FULL database
        backup as compressed
        backupset database format '/u02/fra/%d/backupset/BKP_%d_%I_%s_%T_%p.bkp'
        tag BKP_FULL
        spfile format '/u02/fra/%d/backupset/SPFILE_%d_%I_%s_%T.bkp'  tag 'BKP_SPFILE'
        archivelog all format '/u02/fra/%d/backupset/ARC_%d_%I_%s_%T.bkp'  tag 'BKP_ARCHIVELOG' delete input;

        # Perform overview schemas
        report schema;
}
exit
EOF

#
# LIMPANDO LOGS MAIOES QUE 7 DIAS
find $DIRBKP -type f -name bkprman_* -ctime +6 -exec rm -f {} \;

# teste