#!/bin/bash

#export VERBOSE=1

MY_UID=$( id -u )
if [ "${MY_UID}" != "0" ] ; then
    echo "Nur root darf dieses Script ausfrühren." >&2
    exit 20
fi

LIBDIR=$(dirname $0)

FUNC_LIB="${LIBDIR}/backup-functions.rc"
if [ ! -f "${FUNC_LIB}" ] ; then
    echo "Datei '${FUNC_LIB}' nicht gefunden." >&2
    exit 8
fi
. "${FUNC_LIB}"

DATUM=$( date +'%Y-%m-%d' )

echo
echo "[`date`]: Beginne Backup."
echo
echo "Backup-Datum: ${DATUM}"
echo

cd /

echo "Sichere Virtuelle Webhosts ..."
if [ ! -d "${VHOSTS_DIR}" ] ; then
    echo "Verzeichnis '${VHOSTS_DIR}' existiert nicht." >&2
    exit 7
fi

#for vdir in "${VHOSTS_DIR}"/* ; do
#    if [ -d "${vdir}" ] ; then
#        d=`basename "${vdir}"`
#        if [ "${d}" == "fotoalbum" ] ; then
#            do_backup_fs "${vdir}" www."${d}" "${DATUM}"
#        else
#            do_backup_fs "${vdir}" www."${d}" "${DATUM}" 1
#        fi
#    fi
#done

do_backup_fs "/etc"                "etc"         "${DATUM}" 1
do_backup_fs "/var/bind"           "bind"        "${DATUM}" 1
do_backup_fs "/var/lib/portage"    "lib-portage" "${DATUM}" 1
do_backup_fs "/var/lib/ip*tables"  "iptables"    "${DATUM}" 1
do_backup_fs "/var/lib/openldap-*" "openldap"    "${DATUM}" 1
do_backup_fs "/var/lib/svn-repos"  "subversion"  "${DATUM}" 1
do_backup_fs "/var/log"            "var-log"     "${DATUM}" 1
do_backup_fs "/root"               "root"        "${DATUM}" 1

for dir in /home/* ; do

    base=`basename "${dir}"`
    if echo ${base} | grep "^aquota\." >/dev/null ; then
        continue
    fi
    if [ "${base}" = "lost+found" ] ; then
        continue
    fi

    do_backup_fs "${dir}" home."${base}" "${TYPE}" 1

done

do_backup_mysql "${TYPE}"
do_backup_ldap  "${TYPE}"

echo
echo "Backup-Verzeichnis '${BACKUP_DIR}':"
echo
ls -lA "${BACKUP_DIR}"

echo
echo "Plattenauslastung Backup-Verzeichnis '${BACKUP_DIR}':"
echo
df -k "${BACKUP_DIR}"

echo
echo "[`date`]: Vorbereitung Backup beendet."
echo

# vim: noai : ts=4 fenc=utf-8 filetype=sh : expandtab
