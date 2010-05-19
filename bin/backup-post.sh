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

echo
echo "[`date`]: Werfe Backup-Sets weg."
echo

remove_all

echo
echo "[`date`]: Backup beendet."
echo

# vim: noai : ts=4 fenc=utf-8 filetype=sh : expandtab
