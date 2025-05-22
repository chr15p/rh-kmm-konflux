#!/usr/bin/bash

MAJOR=2
MINOR=4
PATCH=0

KMMVER=${MAJOR}${MINOR}${PATCH}

APPLICATION=kmm-${MAJOR}-${MINOR}
RELEASEPLAN=kmm-releaseplan-${MAJOR}-${MINOR}

RELVER="kmm-${KMMVER}-r"
if [ -z "$1" ]; then
    echo -e "USAGE: $0 [-f FBC_VER] -p [PIPELINE]\n\t$0 -s [SNAPSHOT]"
    exit 0
    #    SNAPSHOT=$(kubectl get snapshot  --sort-by='{.metadata.creationTimestamp}' | tail -n 1 | cut -d" " -f 1)
else
    if [ "$1" == "-f" ]; then
        RELVAR=$2
        shift
        shift
    fi

    if [ "$1" == "-s" ]; then
        SNAPSHOT=$2
    elif [ "$1" == "-p" ]; then
        SNAPSHOT=$(oc get pipelinerun -o yaml $1 | yq '.metadata.ownerReferences[].name')
    else
        echo -e "USAGE: $0 -p [PIPELINE]\n\t$0 -s [SNAPSHOT]"
        exit 0
    fi
fi

#RELNUM=$(kubectl get release --sort-by='{.metadata.creationTimestamp}' | tail -n 1 | awk -vx=$RELVER '/^kmm/{gsub(x, "",$1); print $1+1}')
RELNUM=$(kubectl get release --sort-by='{.metadata.creationTimestamp}' | awk -vx=kmm-240-r '/^kmm/{gsub(x, "",$1); if( ($1+1) > l){l=$1+1}}END{print l}')


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
