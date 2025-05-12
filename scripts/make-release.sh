#!/usr/bin/bash

MAJOR=2
MINOR=4
PATCH=0

KMMVER=${MAJOR}${MINOR}${PATCH}

APPLICATION=kmm-${MAJOR}-${MINOR}
RELEASEPLAN=kmm-releaseplan-${MAJOR}-${MINOR}
RELVER="kmm-${KMMVER}-r"

if [ -z "$1" ]; then
    echo "USAGE: $0 [PIPELINE]"
    exit 0
    #    SNAPSHOT=$(kubectl get snapshot  --sort-by='{.metadata.creationTimestamp}' | tail -n 1 | cut -d" " -f 1)
else
    SNAPSHOT=$(oc get pipelinerun -o yaml $1 | yq '.metadata.ownerReferences[].name')
fi

RELNUM=$(kubectl get release --sort-by='{.metadata.creationTimestamp}' | tail -n 1 | awk -vx=$RELVER '/^kmm/{gsub(x, "",$1); print $1+1}')


cat << EOF | kubectl apply -f - -o yaml
apiVersion: appstudio.redhat.com/v1alpha1
kind: Release
metadata:
  name: ${RELVER}${RELNUM}
  namespace: rh-kmm-tenant
  labels:
    appstudio.openshift.io/application: ${APPLICATION}
spec:
  releasePlan: ${RELEASEPLAN}
  snapshot: ${SNAPSHOT}
EOF
