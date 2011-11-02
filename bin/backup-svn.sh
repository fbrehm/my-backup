#!/bin/bash

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

BACKUP_DIR=/var/backup/svn
test -d ${BACKUP_DIR} || mkdir -p ${BACKUP_DIR} || exit 5
cd ${BACKUP_DIR}

for repo_base in /var/lib/svn-repos /var/lib/svn-repos-priv ; do
#for repo_base in /var/lib/svn-repos ; do

	test -d ${repo_base} || continue

	prefix=$( basename ${repo_base} | sed 's/svn-repos//' )
	printf "\nSvn-Basedir: %s\n" ${repo_base}

	for repo in ${repo_base}/* ; do

		test -d ${repo} || continue

		repo_name=$( basename ${repo} )

		cur_revision=$( svnlook youngest ${repo} )
		if [ "$?" != "0" ] ; then
			printf "Verzeichnis %s ist kein Subversion Repository.\n" ${repo} >&2
			continue
		fi

		changed=$( svnlook date -r ${cur_revision} ${repo} )
		date_str=$( echo ${changed} | awk '{ print $1 "_" $2 }' )
		dumpfile=${BACKUP_DIR}/svn${prefix}.${repo_name}.full.${cur_revision}.${date_str}.dump

        rev_file=${BACKUP_DIR}/svn${prefix}.${repo_name}.revision
		last_revision=
		dump_revisions="-r 0:${cur_revision}"
        if [ -f ${rev_file} ] ; then
			last_revision=$( cat ${rev_file} | sed 's/[^0-9]//g' )
            if [ "${last_revision}" != "" ] ; then
				last_revision=$(( last_revision + 1 ))
				if [ "${last_revision}" -gt "${cur_revision}" ] ; then
					printf "\n[$( date +'%Y-%m-%d %H:%M:%S' )]\n"
					printf "Dump Repository %s ist auf dem neuestem Stand.\n" ${repo}
					continue
				fi
				dumpfile=${BACKUP_DIR}/svn${prefix}.${repo_name}.inc.${cur_revision}.${date_str}.dump
				dump_revisions="--incremental -r ${last_revision}:${cur_revision}"
			else
				rm ${rev_file}
			fi
		fi

		printf "\n[$( date +'%Y-%m-%d %H:%M:%S' )]\n"
		printf "Dumping Repository %s nach %s\n" ${repo} "${dumpfile}.gz"
		printf "    (Revision %d, Letzte Änderung: %s)\n" ${cur_revision} "${changed}"
		md5_file=${dumpfile}.gz.md5
		#set -x
		svnadmin dump --quiet ${dump_revisions} ${repo} | gzip -9 >"${dumpfile}.gz"
		md5sum "${dumpfile}.gz" >${md5_file}
		echo ${cur_revision} >${rev_file}
		#set +x

	done

done

# vim: noai : ts=4 fenc=utf-8 filetype=sh
