#!/usr/bin/env bash

REPOSITORY="registry.redhat.io/kmm/kernel-module-management-operator-bundle"

PULLSPEC_FILE="bundle-hack/operator-bundle.yaml"

BUNDLE_PULLSPEC=$(awk -F: -v REPO=$REPOSITORY '{print REPO"@sha256:"$2;exit}' $PULLSPEC_FILE)
echo BUNDLE_PULLSPEC=$BUNDLE_PULLSPEC

TEMPLATE_FILE=catalog-template.json

for FBC in $(ls -d v4.*) ; do

    CATALOG_TEMPLATE=${FBC}/catalog-template.json

    sed  "
        /LATEST_BUNDLE/s|{{LATEST_BUNDLE}}|${BUNDLE_PULLSPEC}|
    " ${TEMPLATE_FILE} > ${CATALOG_TEMPLATE}

    if [[ "$FBC" =~ v4.1[1-6] ]]; then
        echo opm alpha render-template basic ${CATALOG_TEMPLATE} > ${FBC}/catalog/kernel-module-management/catalog.json
    else
        echo opm alpha render-template basic ${CATALOG_TEMPLATE} --migrate-level=bundle-object-to-csv-metadata > ${FBC}/catalog/kernel-module-management/catalog.json
    fi
done
