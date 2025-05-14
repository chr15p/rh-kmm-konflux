#!/bin/bash

TEST=$1

for f in $(ls bundle-hack/*.yaml); do
    NAME=$(basename $f .yaml)

    PULLSPEC=$(kubectl get -o yaml component ${NAME}-2-4 | yq '.status.lastPromotedImage')
    if [ -z "$PULLSPEC" ]; then
        echo "$NAME failed"
        exit
    fi
    if [ -z "$TEST" ]; then
        echo $PULLSPEC > $f
    else
        echo $PULLSPEC
    fi
done 
