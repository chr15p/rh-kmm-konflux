#!/bin/bash
PACKAGE=${1}
RELEASE=${2}
PULLSPEC_FILE=${3:-operator-bundle.yaml}
CATALOG_FILE=${4:-fbc/op/${OPERATOR}/catalog.json}

NEWIMAGE=$( cat ${PULLSPEC_FILE} )
OLDIMAGE=$( sed -n "/${PACKAGE}.v${RELEASE}/,+3{/image/p}" $CATALOG_FILE | awk -F'\"' '{print $4}' )

sed -i "s|$OLDIMAGE|$NEWIMAGE|" $CATALOG_FILE
