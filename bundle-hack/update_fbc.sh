#!/usr/bin/env bash

REPOSITORY="registry.redhat.io/kmm/kernel-module-management-operator-bundle"

TEMPLATE_FILE=${1:-"v4.18/catalog-template.json"}
PULLSPEC_FILE=${2:-"bundle-hack/operator-bundle.yaml"}

BUNDLE_PULLSPEC=$(awk -F: -v REPO=$REPOSITORY '{print REPO"@sha256:"$2;exit}' $PULLSPEC_FILE)

echo BUNDLE_PULLSPEC=$BUNDLE_PULLSPEC

sed -i "
    /LATEST_BUNDLE/s|{{LATEST_BUNDLE}}|${BUNDLE_PULLSPEC}|
    " $TEMPLATE_FILE


#opm alpha render-template basic ${TEMPLATE_FILE} --migrate-level=bundle-object-to-csv-metadata > v4.13/catalog/gatekeeper-operator/catalog.json

