#!/bin/bash
RELEASE=$(awk -F= '/RELEASE/{print $2}' build_settings.conf)
PULLSPEC_FILE=${1:-operator-bundle.yaml}
CATALOG_FILE=${2} # fbc/op/kernel-module-management/catalog.json

NEWIMAGE=$( cat ${PULLSPEC_FILE} )
OLDIMAGE=$( sed -n "/kernel-module-management.v$RELEASE/,+3{/image/p}" $CATALOG_FILE | awk -F'\"' '{print $4}' )

sed -i "s|$OLDIMAGE|$NEWIMAGE|" $CATALOG_FILE
