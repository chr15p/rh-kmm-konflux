#!/usr/bin/python
import yaml
import argparse
from string import Template

REPLACE_VERSION="2.3.0"
RELEASE_VERSION="2.4.0"

parser = argparse.ArgumentParser()

parser.add_argument('--csv', action='store', default="kernel-module-management/bundle/manifests/kernel-module-management.clusterserviceversion.yaml", help='csv template')
parser.add_argument('--out', action='store', default="kernel-module-management.clusterserviceversion.yaml", help='csv ouput')

opt = parser.parse_args()

CSV=opt.csv
outputfile=opt.out

annotations={
    "certified": "true",
    "containerImage": "${OPERATOR_IMAGE}",
    "olm.skipRange": '>=0.0.0 <${RELEASE_VERSION}',
    "operators.openshift.io/valid-subscription": """["OpenShift Kubernetes Engine", "OpenShift Container Platform", "OpenShift Platform Plus"]""",
    "features.operators.openshift.io/disconnected": "true",
    "features.operators.openshift.io/fips-compliant": "true",
    "features.operators.openshift.io/proxy-aware": "false",
    "features.operators.openshift.io/cnf": "false",
    "features.operators.openshift.io/cni": "false",
    "features.operators.openshift.io/csi": "false",
    "features.operators.openshift.io/tls-profiles": "false",
    "features.operators.openshift.io/token-auth-aws": "false",

    "features.operators.openshift.io/token-auth-azure": "false",
    "features.operators.openshift.io/token-auth-gcp": "false",
}

metadata ={
    "name": "${NAME}.v${RELEASE_VERSION}"
}

labels = {
    "operatorframework.io/arch.amd64": "supported",
    "operatorframework.io/arch.arm64": "supported",
    "operatorframework.io/arch.ppc64le": "supported",
    "operatorframework.io/os.linux": "supported",
}

spec = {
    "version": "${RELEASE_VERSION}",
    "provider": {"name": "Red Hat" , "url": "https://www.redhat.com"},
    "replaces": "${NAME}.v${REPLACE_VERSION}",
    "relatedImages": [
            {"name": "worker", "image": "{{WORKER_IMAGE}}" },
            {"name": "must-gather", "image": "{{MUST_GATHER_IMAGE}}" },
            {"name": "sign", "image": "{{SIGNING_IMAGE}}" },
            ],
}

labels_delete = {
    "app.kubernetes.io/component",
    "app.kubernetes.io/name",
    "app.kubernetes.io/part-of",
}

spec_delete = {
    "maturity",
}

replacements = {
    "quay.io/edge-infrastructure/kernel-module-management-worker:latest": "\"{{WORKER_IMAGE}}\"",
    "quay.io/edge-infrastructure/kernel-module-management-signimage:latest": "\"{{SIGNING_IMAGE}}\"",
    "quay.io/edge-infrastructure/kernel-module-management-operator:latest": "\"{{OPERATOR_IMAGE}}\"",
    "quay.io/edge-infrastructure/kernel-module-management-must-gather:latest": "\"{{MUST_GATHER_IMAGE}}\"",
    "quay.io/edge-infrastructure/kernel-module-management-webhook-server:latest": "\"{{WEBHOOK_IMAGE}}\"",
    "quay.io/edge-infrastructure/kernel-module-management-operator-hub:latest": "\"{{HUB_OPERATOR_IMAGE}}\"",
}


with open(CSV, 'r') as file:
    data = file.read()

#data = data.replace("quay.io/edge-infrastructure/kernel-module-management-webhook-server:latest", "\"{{WEBHOOK_IMAGE}}\"")

for k, v in replacements.items():
    data = data.replace(k, v)


#with open(CSV) as stream:
#    try:
#        template=yaml.safe_load(stream)
#    except yaml.YAMLError as exc:
#        print(exc)

try:
    template=yaml.safe_load(data)
except yaml.YAMLError as exc:
    print(exc)

name=template['metadata']['name'].split(".",1)[0]

for k,v in annotations.items():
    print(f"add/update metadata.annotations.{k}")
    template['metadata']['annotations'][k]=v

for k,v in labels.items():
    print(f"add/update metadata.labels.{k}")
    template['metadata']['labels'][k]=v

for k,v in metadata.items():
    print(f"add/update metadata.{k}")
    template['metadata'][k]=v

for k,v in spec.items():
    print(f"add/update spec.{k}")
    template['spec'][k]=v

for i in spec_delete:
    print(f"delete spec.{i}")
    if template['spec'].get(i):
        del template['spec'][i]

s = Template(yaml.dump(template, width=1000))

subs = {
    "NAME": name,
    "REPLACE_VERSION": REPLACE_VERSION,
    "RELEASE_VERSION": RELEASE_VERSION,
    "OPERATOR_IMAGE": "registry.redhat.io/kmm/kernel-module-management-rhel9-operator",
    "HUB_OPERATOR_IMAGE": "registry.redhat.io/kmm/kernel-module-management-hub-rhel9-operator",
    "MUST_GATHER_IMAGE": "registry.redhat.io/kmm/kernel-module-management-must-gather-rhel9",
    "SIGNING_IMAGE": "registry.redhat.io/kmm/kernel-module-management-signing-rhel9",
    "WEBHOOK_IMAGE": "registry.redhat.io/kmm/kernel-module-management-webhook-server-rhel9",
    "WORKER_IMAGE": "registry.redhat.io/kmm/kernel-module-management-worker-rhel9",
}
#out = s.safe_substitute(REPLACE_VERSION="2.3.0", RELEASE_VERSION="2.4.0")
out = s.safe_substitute(**subs)


with open(outputfile, 'w') as file:
    file.write(out)
    #outputs = yaml.dump(template, file)


