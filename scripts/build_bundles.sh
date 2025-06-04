#!/usr/bin/bash

REPODIR=$(git rev-parse --show-toplevel)
. ${REPODIR}/scripts/functions.sh

if [ -z "$1" ]; then
    COMMIT=$(latest_commit)
else
    COMMIT=$1
fi

KMMVER=$(latest_kmm)

update_pullspecs $COMMIT

if [ $( git status -s | grep -v "^??" | grep -c bundle-hack ) -ne 0 ]; then
    git add ./bundle-hack/
    git commit -m "build bundles for kmm $KMMVER"
    git push
fi

latest_commit
