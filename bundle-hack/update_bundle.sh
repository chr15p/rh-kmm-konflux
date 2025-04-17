#!/usr/bin/env bash

export MUSTGATHER_IMAGE_PULLSPEC=$(kubectl get -o yaml component must-gather-2-4 -o json | jq '.status.lastPromotedImage')

export OPERATOR_IMAGE_PULLSPEC=$(kubectl get -o yaml component operator-2-4 -o json | jq '.status.lastPromotedImage')

export SIGNING_IMAGE_PULLSPEC=$(kubectl get -o yaml component signing-2-4 -o json | jq '.status.lastPromotedImage')

export WEBHOOK_IMAGE_PULLSPEC=$(kubectl get -o yaml component webhook-2-4 -o json | jq '.status.lastPromotedImage')

export WORKER_IMAGE_PULLSPEC=$(kubectl get -o yaml component worker-2-4 -o json | jq '.status.lastPromotedImage')

export CSV_FILE=/manifests/kernel-module-management.clusterserviceversion.yaml

sed -i \
    -e "s|quay.io/gatekeeper/must-gather-image:latest|\"${MUSTGATHER_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/operator-image:latest|\"${OPERATOR_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/signing-image:latest|\"${SIGNING_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/webhook-image:latest|\"${WEBHOOK_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/worker-image:latest|\"${WORKER_IMAGE_PULLSPEC}\"|g" \
	"${CSV_FILE}"

#export AMD64_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="amd64")')
#export ARM64_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="arm64")')
#export PPC64LE_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="ppc64le")')
#export S390X_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="s390x")')


export EPOC_TIMESTAMP=$(date +%s)
# time for some direct modifications to the csv
python3 - << CSV_UPDATE
import os
from collections import OrderedDict
from sys import exit as sys_exit
from datetime import datetime
from ruamel.yaml import YAML
yaml = YAML()
def load_manifest(pathn):
   if not pathn.endswith(".yaml"):
      return None
   try:
      with open(pathn, "r") as f:
         return yaml.load(f)
   except FileNotFoundError:
      print("File can not found")
      exit(2)

def dump_manifest(pathn, manifest):
   with open(pathn, "w") as f:
      yaml.dump(manifest, f)
   return
timestamp = int(os.getenv('EPOC_TIMESTAMP'))
datetime_time = datetime.fromtimestamp(timestamp)
gatekeeper_csv = load_manifest(os.getenv('CSV_FILE'))
# Add arch and os support labels
gatekeeper_csv['metadata']['labels'] = gatekeeper_csv['metadata'].get('labels', {})
if os.getenv('AMD64_BUILT'):
	gatekeeper_csv['metadata']['labels']['operatorframework.io/arch.amd64'] = 'supported'
if os.getenv('ARM64_BUILT'):
	gatekeeper_csv['metadata']['labels']['operatorframework.io/arch.arm64'] = 'supported'
if os.getenv('PPC64LE_BUILT'):
	gatekeeper_csv['metadata']['labels']['operatorframework.io/arch.ppc64le'] = 'supported'
if os.getenv('S390X_BUILT'):
	gatekeeper_csv['metadata']['labels']['operatorframework.io/arch.s390x'] = 'supported'
gatekeeper_csv['metadata']['labels']['operatorframework.io/os.linux'] = 'supported'
# Ensure that the created timestamp is current
gatekeeper_csv['metadata']['annotations']['createdAt'] = datetime_time.strftime('%d %b %Y, %H:%M')
# Add annotations for the openshift operator features
gatekeeper_csv['metadata']['annotations']['features.operators.openshift.io/disconnected'] = 'true'
gatekeeper_csv['metadata']['annotations']['features.operators.openshift.io/fips-compliant'] = 'true'
gatekeeper_csv['metadata']['annotations']['features.operators.openshift.io/proxy-aware'] = 'false'
gatekeeper_csv['metadata']['annotations']['features.operators.openshift.io/tls-profiles'] = 'false'
gatekeeper_csv['metadata']['annotations']['features.operators.openshift.io/token-auth-aws'] = 'false'
gatekeeper_csv['metadata']['annotations']['features.operators.openshift.io/token-auth-azure'] = 'false'
gatekeeper_csv['metadata']['annotations']['features.operators.openshift.io/token-auth-gcp'] = 'false'
# Ensure that other annotations are accurate
gatekeeper_csv['metadata']['annotations']['repository'] = 'https://github.com/stolostron/gatekeeper-operator'
gatekeeper_csv['metadata']['annotations']['containerImage'] = os.getenv('GATEKEEPER_OPERATOR_IMAGE_PULLSPEC') # fail if the get fails

# Ensure that any parameters are properly defined in the spec if you do not want to
# put them in the CSV itself
gatekeeper_csv['spec']['description'] = """Gatekeeper allows administrators to detect and reject non-compliant commits to an infrastructure-as-code system\'s source-of-truth. This strengthens compliance efforts and prevents a bad state from slowing down the organization."""

# Make sure that our latest nudged references are properly configured in the spec.relatedImages
# NOTE: the names should be unique
gatekeeper_csv['spec']['relatedImages'] = [
   {'name': 'gatekeeper', 'image': os.getenv('GATEKEEPER_IMAGE_PULLSPEC')},
   {'name': 'gatekeeper-operator', 'image': os.getenv('GATEKEEPER_OPERATOR_IMAGE_PULLSPEC')}
]

dump_manifest(os.getenv('CSV_FILE'), gatekeeper_csv)
CSV_UPDATE

cat $CSV_FILE
