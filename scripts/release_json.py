#!/usr/bin/python

import os
import json
import re
import argparse
import subprocess
from kubernetes import client, config
from openshift.dynamic import DynamicClient

def submodule_version():
    params=["git", "submodule"]
    p = subprocess.Popen(params, stdout=subprocess.PIPE)

    output = p.stdout.read().decode("utf-8")
    try:
        return output.split(" ")[1][:7]
    except IndexError:
        return "unknown"

def build_version(commit):
    params=["git", "rev-parse", commit]
    p = subprocess.Popen(params, stdout=subprocess.PIPE)

    output = p.stdout.read().decode("utf-8")
    print(output)
    try:
        return output[:7]
    except IndexError:
        return "unknown"



parser = argparse.ArgumentParser()

parser.add_argument('--release', default=None, help='release number to fetch (e.g. r31)')
parser.add_argument('--commit', default="HEAD", help='')
parser.add_argument('--output', default=None, help='file to write output to')
opt = parser.parse_args()

outputfile = opt.output

k8s_client = config.new_client_from_config(config_file=os.getenv("KUBECONFIG"))
dyn_client = DynamicClient(k8s_client)

releases = dyn_client.resources.get(api_version ='appstudio.redhat.com/v1alpha1',
                                     kind='Release')
releaseList = releases.get(namespace = "rh-kmm-tenant")

if opt.release is None:
    relnum =0
    for rel in releaseList['items']:
        if rel.metadata.name.startswith("kmm-240-r"):
            currrel = int(rel.metadata.name[len("kmm-240-r"):])
            if currrel > relnum:
                relnum = currrel

    relnum = f"r{relnum}"
else:
    relnum = opt.release




kmm = submodule_version()
build = build_version(opt.commit)
output = {"release": relnum, "build_commit": build, "kmm_commit": kmm,  "kmm": {}, "kmmhub": {}}
fbc={}
for rel in releaseList['items']:
    regexp = f"fbc-([a-z]+)-v2-4-([0-9]+)-{relnum}-([0-9]+)"
    match = re.match(f"(fbc-([a-z]+)-v2-4-([0-9]+)-{relnum})-([0-9]+)", rel.metadata.name) 
    if match:
        if int(match.group(4)) > fbc.get(match.group(1),0):
            fbc[match.group(1)]= int(match.group(4))  # fbc[fbc-op-v2-4-418-r31] = retry 3
        
            if match.group(2) == "op":
                operator = 'kmm'
            elif match.group(2) == "hub":
                operator = 'kmmhub'
            else:
                print("ERROR parsing rel.metadata.name!")

            try: 
                output[operator][f"ocp{match.group(3)}"] = rel.status.artifacts.index_image.index_image
            except AttributeError:
                output[operator][f"ocp{match.group(3)}"] = "" 


if outputfile:
    with open(outputfile, 'w') as file:
        json.dump(output, file, indent=4)
else:
    print(json.dumps(output, indent=4))


exit(0)
