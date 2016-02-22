#!/bin/bash

RCPT="frank@brehm-online.com"
LOG="/var/log/ftp-backup/backup.log"
export TZ="Europe/Berlin"

export LANG=de_DE.UTF-8
export LC_CTYPE=de_DE.utf8
export LC_NUMERIC=de_DE.utf8
export LC_TIME=de_DE.utf8
export LC_COLLATE=de_DE.utf8
export LC_MONETARY=de_DE.utf8
export LC_MESSAGES=de_DE.utf8
export LC_PAPER=de_DE.utf8
export LC_NAME=de_DE.utf8
export LC_ADDRESS=de_DE.utf8
export LC_TELEPHONE=de_DE.utf8
export LC_MEASUREMENT=de_DE.utf8
export LC_IDENTIFICATION=de_DE.utf8
export LC_ALL=

MY_HOSTNAME=$( hostname | perl -p -E '$_ =~ s/^(.)/uc($1)/e;' )

LOG_NEW=${LOG}.new

MY_UID=$( id -u )
if [ "${MY_UID}" != "0" ] ; then
    echo "Nur root darf dieses Script ausfrühren." >&2
    exit 20
fi

BASEDIR=$(dirname $0)

BACKUP_PRE_SCRIPT="${BASEDIR}/backup-pre.sh"
BACKUP_SVN_SCRIPT="${BASEDIR}/backup-svn-full.sh"
#BACKUP_SCRIPT="${BASEDIR}/backup-per-ftp.pl"
BACKUP_SCRIPT="/root/work/ftp-backup/bin/backup-per-ftp"
BACKUP_POST_SCRIPT="${BASEDIR}/backup-post.sh"
FUNC_LIB="${BASEDIR}/backup-functions.rc"

ALL_SCRIPTS_FOUND=1
for S in ${BACKUP_PRE_SCRIPT} ${BACKUP_SVN_SCRIPT} ${BACKUP_SCRIPT} ${BACKUP_POST_SCRIPT} ; do
    if [ ! -x ${S} ] ; then
        echo "Script '${S}' fehlt." >&2
        ALL_SCRIPTS_FOUND=0
    fi
done
if [ ! -f ${FUNC_LIB} ] ; then
    echo "Script '${FUNC_LIB}' fehlt." >&2
    ALL_SCRIPTS_FOUND=0
fi

if [ "${ALL_SCRIPTS_FOUND}" == "0" ] ; then
    exit 10
fi

cp /dev/null ${LOG_NEW}
echo "Backupergebnisse:" >>${LOG_NEW}
echo "=================" >>${LOG_NEW}
echo                     >>${LOG_NEW}
for S in ${BACKUP_PRE_SCRIPT} ${BACKUP_SVN_SCRIPT} ${BACKUP_SCRIPT} ${BACKUP_POST_SCRIPT} ; do
    echo "${S} 2>&1 </dev/null | tee -a ${LOG_NEW}"
    ${S} 2>&1 </dev/null | tee -a ${LOG_NEW}
    RES=$?
    echo -e "Rückgabewert von '${S}': ${RES}\n" | tee -a ${LOG_NEW} 
    if [ "${RES}" != "0" ] ; then
        break
    fi
done

cat ${LOG_NEW} >> ${LOG}
echo "" | mailx -s "Backup ${MY_HOSTNAME} [`date +'%Y-%m-%d'`]" -q "${LOG_NEW}" $RCPT

# vim: noai : ts=4 fenc=utf-8 filetype=sh : expandtab
