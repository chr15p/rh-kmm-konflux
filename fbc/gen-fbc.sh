#!/bin/bash -x

TEMPLATE=${1:-fbc/catalog-template.json}
OUTFILE=${2:-fbc/catalog/kernel-module-management/catalog.json}
touch ${OUTFILE}
if [[ $i =~ v4.1[456] ]]; then
    echo "$i -" 
    opm alpha render-template basic ${TEMPLATE} > ${OUTFILE}
else    
    echo "$i migrate"
    opm alpha render-template basic ${TEMPLATE} --migrate-level=bundle-object-to-csv-metadata > ${OUTFILE}
fi


