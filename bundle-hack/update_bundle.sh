#!/usr/bin/env bash

export MUSTGATHER_IMAGE_PULLSPEC="quay.io/redhat-user-workloads/rh-kmm-tenant/must-gather-image@sha256:f0c75465f30d6a9a49d847749330fd04ddeba0177e9349ab0fd91678ca315d26"

export OPERATOR_IMAGE_PULLSPEC="quay.io/redhat-user-workloads/rh-kmm-tenant/operator-image@sha256:ba3b8c7053b93ecb9dd69d314e1eab466a6744c9d2002725f1b3bb1cbdf597f9"

export SIGNING_IMAGE_PULLSPEC="quay.io/redhat-user-workloads/rh-kmm-tenant/signing-image@sha256:6405f37d90acbe54a5e1821fea29d1c30ce7935aae0104a166cd72db934e768b"

export WEBHOOK_IMAGE_PULLSPEC="quay.io/redhat-user-workloads/rh-kmm-tenant/webhook-image@sha256:28d9acd6444ef3a34f8599e46e5f2fd59f30d36cc86edde7abfdd336ec53b693"

export WORKER_IMAGE_PULLSPEC="quay.io/redhat-user-workloads/rh-kmm-tenant/worker-image@sha256:de0caf44205937de482699b919d235bbcbd7e2b79500b3d4e3acc7a691e0324f"

export CSV_FILE=/kernel-module-management/bundle/manifests/kernel-module-management.clusterserviceversion.yaml

sed -i \
    -e "s|quay.io/gatekeeper/must-gather-image:v.*|\"${MUSTGATHER_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/operator-image:v.*|\"${OPERATOR_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/signing-image:v.*|\"${SIGNING_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/webhook-image:v.*|\"${WEBHOOK_IMAGE_PULLSPEC}\"|g" \
    -e "s|quay.io/gatekeeper/worker-image:v.*|\"${WORKER_IMAGE_PULLSPEC}\"|g" \
	"${CSV_FILE}"

export AMD64_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="amd64")')
export ARM64_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="arm64")')
export PPC64LE_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="ppc64le")')
export S390X_BUILT=$(skopeo inspect --raw docker://${GATEKEEPER_OPERATOR_IMAGE_PULLSPEC} | jq -e '.manifests[] | select(.platform.architecture=="s390x")')

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
