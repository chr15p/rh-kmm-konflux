#!/bin/bash

TEST=""
if [ "$1" == "-t" -o "$1" == "--test" ]; then
    TEST="test"
fi

REPODIR=$(git rev-parse --show-toplevel)
. ${REPODIR}/scripts/functions.sh


OPFBC="fbc/op-catalog-template.json"
HUBFBC="fbc/hub-catalog-template.json"

OPERATOR_BUNDLE=$(awk -F: '{print $2}' bundle-hack/operator-bundle.yaml)
HUB_OPERATOR_BUNDLE=$(awk -F: '{print $2}' bundle-hack/hub-operator-bundle.yaml)

sed  -i "
    /stage/{
        /kernel-module-management-operator-bundle/s/sha256:.*/sha256:$OPERATOR_BUNDLE\"/
    }
" $OPFBC

sed  -i "
    /stage/{
        /kernel-module-management-hub-operator-bundle/s/sha256:.*/sha256:$HUB_OPERATOR_BUNDLE\"/
    }
" $HUBFBC

echo opm alpha render-template basic fbc/op-catalog-template.json
opm alpha render-template basic fbc/op-catalog-template.json > fbc/op/kernel-module-management/catalog.json

if [ $? -ne 0 ]; then
    echo "opm failed"
    exit 1
fi

echo opm alpha render-template basic fbc/op-catalog-template.json --migrate-level=bundle-object-to-csv-metadata
opm alpha render-template basic fbc/op-catalog-template.json --migrate-level=bundle-object-to-csv-metadata > fbc/op-migrated/kernel-module-management/catalog.json
if [ $? -ne 0 ]; then
    echo "opm failed"
    exit 1
fi

echo opm alpha render-template basic fbc/hub-catalog-template.json
opm alpha render-template basic fbc/hub-catalog-template.json > fbc/hub/kernel-module-management-hub/catalog.json
if [ $? -ne 0 ]; then
    echo "opm failed"
    exit 1
fi

echo opm alpha render-template basic fbc/hub-catalog-template.json --migrate-level=bundle-object-to-csv-metadata
opm alpha render-template basic fbc/hub-catalog-template.json --migrate-level=bundle-object-to-csv-metadata > fbc/hub-migrated/kernel-module-management-hub/catalog.json
if [ $? -ne 0 ]; then
    echo "opm failed"
    exit 1
fi

if [ -n  "$TEST" ]; then
    echo "running in test mode"
    exit 0
fi

KMM=$(latest_kmm)
git add bundle-hack/ fbc
git commit -m "build FBCs for kmm ${KMM}"

git rev-parse HEAD

exit
