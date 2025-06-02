#!/usr/bin/bash

. scripts/functions.sh

APPLICATION=${1:-kmm-2-4}

SNAPSHOT=$(snapshots)

if [ -n "$(check_snapshot $SNAPSHOT)" ]; then
    echo "ERROR: snapshot $SNAPSHOT is not up to date, or pullspecs are wrong"
    exit 1
fi

RELEASEPLAN=$(releaseplan $APPLICATION)

RELEASE=$(next_release kmm)
#| kubectl apply -f - -o yaml

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
