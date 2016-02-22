#!/bin/bash

exit 0

export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib64/subversion/bin
export LANG="de_DE.UTF-8"
export LC_CTYPE="de_DE.utf8"
export LC_NUMERIC="de_DE.utf8"
export LC_TIME="de_DE.utf8"
export LC_COLLATE="de_DE.utf8"
export LC_MONETARY="de_DE.utf8"
export LC_MESSAGES="de_DE.utf8"
export LC_PAPER="de_DE.utf8"
export LC_NAME="de_DE.utf8"
export LC_ADDRESS="de_DE.utf8"
export LC_TELEPHONE="de_DE.utf8"
export LC_MEASUREMENT="de_DE.utf8"
export LC_IDENTIFICATION="de_DE.utf8"
export LC_ALL=

BACKUP_SCRIPT=$( realpath $( dirname $0 )/backup-svn.sh )

if [ ! -x ${BACKUP_SCRIPT} ] ; then
	printf "Script %s exitiert nicht oder ist nicht ausführbar.\n" ${BACKUP_SCRIPT} >&2
	exit 5
fi

BACKUP_DIR=/var/backup/svn
test -d ${BACKUP_DIR} || mkdir -p ${BACKUP_DIR} || exit 5
cd ${BACKUP_DIR}

echo
echo "[$( date +'%Y-%m-%d %H:%M:%S' )]: Starte Full Backup der Subversion Repositories"
echo

printf "Lösche vorhergehende Backups ... "
rm svn*
printf "OK\n"

${BACKUP_SCRIPT}

echo "Linke Dumps nach /var/backup ..."
for dump in svn*.dump.gz ; do
	if [ -f "${dump}" ] ; then
		target="/var/backup/${dump}"
		if [ ! -f "${target}" ] ; then
			ln "${dump}" "${target}"
		fi
	fi
done

svn_md5_file=/var/backup/svn.md5
echo "Erstelle MD5-Checksummendatei ${svn_md5_file} ..."
cp /dev/null ${svn_md5_file}
for file in svn*.dump.gz.md5 ; do
	if [ -f "${file}" ] ; then
		cat "${file}"  | sed 's|/var/backup/svn/||' >> ${svn_md5_file}
	fi
done

echo
echo "[$( date +'%Y-%m-%d %H:%M:%S' )]: Full Backup der Subversion Repositories beendet"

# vim: noai : ts=4 fenc=utf-8 filetype=sh
