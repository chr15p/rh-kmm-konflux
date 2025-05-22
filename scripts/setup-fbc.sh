#!/bin/bash

FBC="fbc/catalog-template.json"

OPERATOR_BUNDLE=$(awk -F: '{print $2}' bundle-hack/operator-bundle.yaml)

sed  -i "
    /stage/{
        /kernel-module-management-operator-bundle/s/sha256:.*/sha256:$OPERATOR_BUNDLE\"/
    }
" $FBC

for i in $(ls -d v4.1?); do 

    cp $FBC  $i/

    if [[ $i =~ v4.1[456] ]]; then
        echo "$i -" 
        opm alpha render-template basic $i/catalog-template.json > $i/catalog/kernel-module-management/catalog.json
    else    
        echo "$i migrate"
        opm alpha render-template basic $i/catalog-template.json --migrate-level=bundle-object-to-csv-metadata > $i/catalog/kernel-module-management/catalog.json
    fi


done


