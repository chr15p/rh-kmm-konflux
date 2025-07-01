

The manual steps to build and release a version of KMM are:

# Setup
 1. checkout the correct branch
> git checkout release-2.4
 1. source the helper functions
> source scripts/functions.sh

# Build the operands

 1. update the submodules and CSVs  
> scripts/update-kmm.sh
 1. these changes should have been commited so we jkust need to push them
> git push
 1. This should trigger the build pipelines, wait until they are all finished (including the enterprise contracts). You can watch these if you have the SHA of the  commit:
> pipelineruns $COMMIT


# Build the bundles
 1. run the build_bundles script, which will update the pullspecs in bundle-hack/ , commit thgem and push the changes up to github. This triggeres the bundle build pipelines:
> scripts/build_bundles.sh
 1. wait for the bundle pipelines to complete.
> pipelineruns $BUNDLE_COMMIT

# Release the operands and bundles:
 1. create a release object with the latest snapshot and apply it to konflux
> scripts/make-release.sh kmm-2.4 $BUNDLE_COMMIT
 1. Find the release number that has just been created (this should look like r[0-9][0-9]  e.g. r41 r45 etc)
 2. this will trigger the release pipeline which you can watch
> latest_releases $RELEASE

# Build the catalgues
 1. update the bundle-hack/ pullspecs for the bundles we've built (id necessary)
> update_pullspecs
 1. update the FBC catalogue fragments and generate the full catalogues:
> scripts/setup-fbc.sh
 1. push the new FBC files into the repo
> git commit
 1. watch the fbc build pipelines run to their end
> pipelineruns $FBC_COMMIT


# release the catalogues
 1. for each FBC application run the make-release script
> for APP in $(oc get applications | awk '$1~/fbc/{print $1}'); do
>     scripts/make-release.sh $APP $FBC_COMMIT
> done
 1. watch the release run (using the same release number as the kmm release used)
> latest_releases $RELEASE
 2. If a release fails (which they do. A lot.) re run the release for that application. This will generate a new release object with an incremented try number (e.g. r45-1 r45-2 r45-3 etc). 
> scripts/make-release.sh $APP $FBC_COMMIT
 1. when all the releases have succeeded create the json file that QE consume
> scritps/release_json.py  --release $RELEASE --commit $FBC_COMMIT  --output releases.json
 1. send the `releases.json` to QE


