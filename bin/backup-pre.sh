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

MD5SUMFILE=${BACKUP_DIR}/md5.txt
SHA1SUMFILE=${BACKUP_DIR}/sha1.txt

TMP_MD5SUMFILE=$( mktemp /tmp/backup.md5.XXXXXXXX.txt )
TMP_SHA1SUMFILE=$( mktemp /tmp/backup.sha1.XXXXXXXX.txt )

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

for vdir in "${VHOSTS_DIR}"/* ; do
    if [ -d "${vdir}" ] ; then
        d=`basename "${vdir}"`
        if [ "${d}" == "fotoalbum" ] ; then
            do_backup_fs "${vdir}" www."${d}" "${DATUM}"
        else
            do_backup_fs "${vdir}" www."${d}" "${DATUM}" 1
        fi
    fi
done

do_backup_fs "/etc"                     "etc"                "${DATUM}" 1
do_backup_fs "/opt/fbrehm"              "opt-fbrehm"         "${DATUM}" 1
do_backup_fs "/var/bind"                "var-bind"           "${DATUM}" 1
do_backup_fs "/var/lib/portage"         "var-lib-portage"    "${DATUM}" 1
do_backup_fs "/var/lib/git"             "var-lib-git"        "${DATUM}" 1
do_backup_fs "/var/lib/ip*tables"       "var-lib-iptables"   "${DATUM}" 1
do_backup_fs "/var/lib/openldap-*"      "var-lib-openldap"   "${DATUM}" 1
do_backup_fs "/var/lib/layman"          "var-lib-layman"     "${DATUM}" 1
#do_backup_fs "/var/lib/svn-repos"       "var-lib-subversion" "${DATUM}" 1
#do_backup_fs "/var/lib/svn-repos-priv"  "var-lib-svn-priv"   "${DATUM}" 1
do_backup_fs "/var/log"                 "var-log"            "${DATUM}" 1
do_backup_fs "/var/spool/cron/crontabs" "var-spool-crontabs" "${DATUM}" 1
do_backup_fs "/root"                    "root"               "${DATUM}" 1

BOOT_MOUNTED=
if [ -d /boot/grub ] ; then
    BOOT_MOUNTED=1
fi

if [ -z "${BOOT_MOUNTED}" ] ; then
    mount /boot
    if [ "$?" != "0" ] ; then
        echo "Konnte /boot nicht mounten." >&2
        exit 8
    fi
fi

do_backup_fs "/boot" "boot" "${DATUM}" 1

if [ -z "${BOOT_MOUNTED}" ] ; then
    umount /boot
fi

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
echo "[`date`]: Erstelle Prüfsummen ..."
echo

(
    cd "${BACKUP_DIR}"
    echo "[`date`]: MD5 ..."
    md5sum * >${TMP_MD5SUMFILE}
    echo "[`date`]: SHA1 ..."
    sha1sum * >${TMP_SHA1SUMFILE}
)

if [ -f ${TMP_MD5SUMFILE} ] ; then
    mv -v ${TMP_MD5SUMFILE} ${MD5SUMFILE}
else
    echo "Datei '${TMP_MD5SUMFILE}' irgendwie nicht erstellt."
fi

if [ -f ${TMP_SHA1SUMFILE} ] ; then
    mv -v ${TMP_SHA1SUMFILE} ${SHA1SUMFILE}
else
    echo "Datei '${TMP_SHA1SUMFILE}' irgendwie nicht erstellt."
fi

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

exit 0

# vim: noai : ts=4 fenc=utf-8 filetype=sh : expandtab
