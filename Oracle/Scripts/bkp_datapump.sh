#!/bin/bash
#                                                               #
# CCM TECNOLOGIA                                                #
# ANDRÉ DEL CAMPO SPADINI                                       #
# EMAIL: aspadini@ccmtecnologia.com.br                          #
# TEL: 16-3515-8300                                             #
#                                                               #
# FUNÇÃO                                                        #
# Efetua backup logico full do banco de dados utilizando        #
# utilitario DATAPUMP                                           #
#################################################################
source /home/oracle/.bash_profile
export DIRBKP=/u02/bkp_logico
export DATA=$(date +%F)

#
# Acessando diretorio
cd $DIRBKP

#
# EXPORT 
expdp \'/ as sysdba\' full=Y directory=BKPDIR dumpfile=BKP_"$ORACLE_SID"_"$DATA".dmp logfile=BKP_"$ORACLE_SID"_"$DATA".log reuse_dumpfiles=y
# EXCLUDE=SCHEMA:\"IN \(\'OE\'\)\"

#
# Compactando
tar -cpzvf $DIRBKP/BKP_"$ORACLE_SID"_"$DATA".tgz $DIRBKP/BKP_"$ORACLE_SID"_"$DATA".dmp $DIRBKP/BKP_"$ORACLE_SID"_"$DATA".log
rm -f $DIRBKP/BKP_"$ORACLE_SID"_"$DATA".dmp
 
#
# Removendo BKPs com + de 2 dias
find $DIRBKP -type f -ctime +2 -exec rm -f {} \;

