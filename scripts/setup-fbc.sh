#!/bin/bash

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

echo opm alpha render-template basic fbc/op-catalog-template.json --migrate-level=bundle-object-to-csv-metadata
opm alpha render-template basic fbc/op-catalog-template.json --migrate-level=bundle-object-to-csv-metadata > fbc/op-migrated/kernel-module-management/catalog.json

echo opm alpha render-template basic fbc/hub-catalog-template.json
opm alpha render-template basic fbc/hub-catalog-template.json > fbc/hub/kernel-module-management-hub/catalog.json

echo opm alpha render-template basic fbc/hub-catalog-template.json --migrate-level=bundle-object-to-csv-metadata
opm alpha render-template basic fbc/hub-catalog-template.json --migrate-level=bundle-object-to-csv-metadata > fbc/hub-migrated/kernel-module-management-hub/catalog.json


exit
