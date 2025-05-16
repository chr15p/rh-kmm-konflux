#!/bin/bash


for i in $(ls -d v4.1?); do 

    cp fbc/catalog-template.json $i/

    if [[ $i =~ v4.1[456] ]]; then
        echo "$i -" 
        opm alpha render-template basic $i/catalog-template.json > $i/catalog/kernel-module-management/catalog.json
    else    
        echo "$i migrate"
        opm alpha render-template basic $i/catalog-template.json --migrate-level=bundle-object-to-csv-metadata > $i/catalog/kernel-module-management/catalog.json
    fi


done


