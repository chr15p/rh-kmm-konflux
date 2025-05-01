#!/usr/bin/env bash
VERSION=2.4
ZVERSION=0
REPLACE_VERSION=2.3.0

RELEASE_VERSION=${VERSION}.${ZVERSION}

CSV_FILE=${1:-"kernel-module-management/bundle/manifests/kernel-module-management.clusterserviceversion.yaml"}
ANNOTATION_FILE=${2:-"kernel-module-management/bundle/metadata/annotations.yaml"}
OUTPUT_FILE=${3:-"kernel-module-management/bundle/manifests/kernel-module-management.RELEASE_VERSION.clusterserviceversion.yaml"}

OUTPUT_FILE_REL=$(echo $OUTPUT_FILE |sed "s/RELEASE_VERSION/$VERSION/")

WORKER_PULLSPEC=$(cat bundle-hack/worker.yaml)
MUSTGATHER_PULLSPEC=$(cat bundle-hack/must-gather.yaml)
SIGNING_PULLSPEC=$(cat bundle-hack/signing.yaml)

WEBHOOK_PULLSPEC=$(cat bundle-hack/webhook.yaml)
OPERATOR_PULLSPEC=$(cat bundle-hack/operator.yaml)
HUB_OPERATOR_PULLSPEC=$(cat bundle-hack/hub-operator.yaml)

mv $CSV_FILE $OUTPUT_FILE_REL 

sed -i "
    /RELEASE_VERSION/s|{{RELEASE_VERSION}}|${RELEASE_VERSION}|
    /REPLACE_VERSION/s|{{REPLACE_VERSION}}|${REPLACE_VERSION}|

    /WORKER_IMAGE/s|{{WORKER_IMAGE}}|${WORKER_PULLSPEC}|
    /MUST_GATHER_IMAGE/s|{{MUST_GATHER_IMAGE}}|${MUST_GATHER_PULLSPEC}|
    /SIGNING_IMAGE/s|{{SIGNING_IMAGE}}|${SIGNING_PULLSPEC}|
    
    /OPERATOR_IMAGE/s|{{OPERATOR_IMAGE}}|${OPERATOR_PULLSPEC}|
    /HUB_OPERATOR_IMAGE/s|{{HUB_OPERATOR_IMAGE}}|${HUB_OPERATOR_PULLSPEC}|
    /WEBHOOK_IMAGE/s|{{WEBHOOK_IMAGE}}|${WEBHOOK_PULLSPEC}|

    " $OUTPUT_FILE_REL

sed -i "
    /operators.operatorframework.io.bundle.channels.v1:/{
        s|v1:|v1: stable,release-$VERSION|
        a\  operators.operatorframework.io.bundle.channel.default.v1: stable
    }
    " $ANNOTATION_FILE
