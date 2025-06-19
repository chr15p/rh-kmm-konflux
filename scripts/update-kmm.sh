#!/bin/bash

REPODIR=$(git rev-parse --show-toplevel)
. ${REPODIR}/scripts/functions.sh

git submodule update --remote

COMMIT=$(latest_kmm)

scripts/make-csv.py --csv kernel-module-management/bundle/manifests/kernel-module-management.clusterserviceversion.yaml --out kernel-module-management.clusterserviceversion.yaml
scripts/make-csv.py --csv kernel-module-management/bundle-hub/manifests/kernel-module-management-hub.clusterserviceversion.yaml --out kernel-module-management-hub.clusterserviceversion.yaml

git add kernel-module-management kernel-module-management.clusterserviceversion.yaml kernel-module-management-hub.clusterserviceversion.yaml
if [ $? -ne 0 -o -z "$COMMIT" ]; then
    echo "git add failed, nothing to add?"
    exit 0
fi

git commit -m "update kmm to $COMMIT"
echo "commited as $COMMIT"

#git push

latest_commit
