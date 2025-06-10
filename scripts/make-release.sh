#!/usr/bin/bash

REPODIR=$(git rev-parse --show-toplevel)
. ${REPODIR}/scripts/functions.sh

APPLICATION=${1:-kmm-2-4}
COMMIT=$2
SNAPSHOT=$3

if [ -z "$APPLICATION" -o -z "$COMMIT" ]; then
    echo "usage: $0 APPLICATION COMMIT"
    exit 1
fi

update_pullspecs

if [ -z "$SNAPSHOT" ]; then
    SNAPSHOT=$(snapshots $APPLICATION $COMMIT)
fi

if [ -n "$(check_snapshot $SNAPSHOT)" ]; then
    echo "ERROR: snapshot $SNAPSHOT is not up to date, or pullspecs are wrong"
    exit 1
fi

RELEASEPLAN=$(releaseplan $APPLICATION)

RELEASE=$(next_release kmm-2-4 $APPLICATION)


cat << EOF | kubectl apply -f - -o yaml 
apiVersion: appstudio.redhat.com/v1alpha1
kind: Release
metadata:
  name: ${RELEASE}
  namespace: rh-kmm-tenant
  labels:
    appstudio.openshift.io/application: ${APPLICATION}
spec:
  releasePlan: ${RELEASEPLAN}
  snapshot: ${SNAPSHOT}
EOF
