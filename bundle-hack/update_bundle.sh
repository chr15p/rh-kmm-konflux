#!/usr/bin/env bash
VERSION=2.4
ZVERSION=0
REPLACE_VERSION=2.3.0
REPOSITORY="registry.redhat.io/kmm"

RELEASE_VERSION=${VERSION}.${ZVERSION}

CSV_FILE=${1:-"kernel-module-management/bundle/manifests/kernel-module-management.clusterserviceversion.yaml"}
ANNOTATION_FILE=${2:-"kernel-module-management/bundle/metadata/annotations.yaml"}
OUTPUT_FILE=${3:-"kernel-module-management/bundle/manifests/kernel-module-management.RELEASE_VERSION.clusterserviceversion.yaml"}

OUTPUT_FILE_REL=$(echo $OUTPUT_FILE |sed "s/RELEASE_VERSION/$VERSION/")

OPERATOR_REPO="$REPOSITORY/kernel-module-management-rhel9-operator"
HUB_OPERATOR_REPO="$REPOSITORY/kernel-module-management-hub-rhel9-operator"
MUST_GATHER_REPO="$REPOSITORY/kernel-module-management-must-gather-rhel9"
SIGNING_REPO="$REPOSITORY/kernel-module-management-signing-rhel9"
WEBHOOK_REPO="$REPOSITORY/kernel-module-management-webhook-server-rhel9"
WORKER_REPO="$REPOSITORY/kernel-module-management-worker-rhel9"

WORKER_PULLSPEC=$(awk -F: -v REPO=$WORKER_REPO '{print REPO"@sha256:"$2;exit}'  bundle-hack/worker.yaml)
MUSTGATHER_PULLSPEC=$(awk -F: -v REPO=$MUST_GATHER_REPO '{print REPO"@sha256:"$2;exit}'  bundle-hack/must-gather.yaml)
SIGNING_PULLSPEC=$(awk -F: -v REPO=$SIGNING_REPO '{print REPO"@sha256:"$2;exit}'  bundle-hack/signing.yaml)

WEBHOOK_PULLSPEC=$(awk -F: -v REPO=$WEBHOOK_REPO '{print REPO"@sha256:"$2;exit}'  bundle-hack/webhook.yaml)
OPERATOR_PULLSPEC=$(awk -F: -v REPO=$OPERATOR_REPO '{print REPO"@sha256:"$2;exit}'  bundle-hack/operator.yaml)
HUB_OPERATOR_PULLSPEC=$(awk -F: -v REPO=$HUB_OPERATOR_REP '{print REPO"@sha256:"$2;exit}'  bundle-hack/hub-operator.yaml)

echo WORKER_PULLSPEC=$WORKER_PULLSPEC
echo MUSTGATHER_PULLSPEC=$MUSTGATHER_PULLSPEC
echo SIGNING_PULLSPEC=$SIGNING_PULLSPEC

echo WEBHOOK_PULLSPEC=$WEBHOOK_PULLSPEC
echo OPERATOR_PULLSPEC=$OPERATOR_PULLSPEC
echo HUB_OPERATOR_PULLSPEC=$HUB_OPERATOR_PULLSPEC

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
