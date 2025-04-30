#!/usr/bin/env bash
VERSION=2.4
ZVERSION=0
XYZ_VERSION=${VERSION}.${ZVERSION}
REPLACES=2.3.0

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
    /RELATED_IMAGE_WORKER/{ n; s|value: .*|value: $WORKER_PULLSPEC|}
    /RELATED_IMAGE_MUST_GATHER/{ n; s|value: .*|value: $MUSTGATHER_PULLSPEC|}
    /RELATED_IMAGE_SIGN/{ n; s|value: .*|value: $SIGNING_PULLSPEC|}

    /image: .*kernel-module-management-webhook-server:latest/s|image:.*|image: $WEBHOOK_PULLSPEC|
    /image: .*kernel-module-management-operator:latest/s|image:.*|image: $OPERATOR_PULLSPEC|
    /image: .*kernel-module-management-operator-hub:latest/s|image:.*|image: $HUB_OPERATOR_PULLSPEC|
    /^spec:$/a\  replaces: kernel-module-management.v$REPLACES
    /^  name: kernel-module-management.v/s|v.*$|v$XYZ_VERSION|
    " $OUTPUT_FILE_REL

sed -i "
    /operators.operatorframework.io.bundle.channels.v1:/{
        s|v1:|v1: stable,release-$VERSION|
        a\  operators.operatorframework.io.bundle.channel.default.v1: stable
    }
    " $ANNOTATION_FILE
