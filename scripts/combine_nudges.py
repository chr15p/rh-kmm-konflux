#!/usr/bin/python
import json
import subprocess
import argparse
import time

def call_git(*args, **kwargs):
    """
        wrapper for calls to git
        *args: one or more strings to be arguements to the git command
    """
    params=["git"]
    for i in args:
        if isinstance(i, list):
            params+=i
        else:
            params.append(i)

    #subprocess.run(params, check=True)
    p = subprocess.Popen(params,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.STDOUT)
    return p.stdout.read()


def call_gh(*args, **kwargs):
    """
        wrapper for calls to git
        *args: one or more strings to be arguements to the git command
    """
    params=["gh"]
    for i in args:
        if isinstance(i, list):
            params+=i
        else:
            params.append(i)

    #subprocess.run(params, check=True)
    p = subprocess.Popen(params,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.STDOUT)

    return p.stdout.read()


MASTER_COMPONENT="operator"

parser = argparse.ArgumentParser()

parser.add_argument('--branch', action='store', required=True, default=None, help='csv template')

opt = parser.parse_args()
curr_branch = opt.branch

if not curr_branch.startswith(f"konflux/component-updates/component-update-{ MASTER_COMPONENT}-"):
    print(f"not the master component ({ MASTER_COMPONENT})")
    exit(0)

pr_list={}
to_merge = []
curr_id = 0
retries=0
interval=60

while len(pr_list) != 6:
    time.sleep(interval)

    retries += 1
    if retries >= 60:
        print(f"script timed out after {retries*interval} seconds")
        exit(1)

    raw_prs = call_gh("pr","list","--json","number,headRefName", "--search", "label:konflux-nudge")
    pr_list = json.loads(raw_prs)
    print(f"{retries} found {len(pr_list)} nudges")
    

for pr in pr_list:
    print(pr)

    ## ignore any non-nudge PRs that might have snuck in
    if not pr["headRefName"].startswith("konflux/component-updates/component-update-"):
        continue

    print(f"check {pr['headRefName']} == {curr_branch}")
    if pr["headRefName"] == curr_branch:
        print(f"setting curr_branch={curr_branch}")
        curr_id = str(pr["number"])
        continue


    to_merge.append(str(pr['number']))

if curr_id == 0:
    print(f"not found this PR! ({curr_branch})")
    exit(1)

if len(to_merge) == 5:
    for pr_number in to_merge:
        print("call_gh", "pr", "edit", pr_number, "--base", curr_branch)
        out=call_gh("pr", "edit", pr_number, "--base", curr_branch)
        print(out)

        print("call_gh", "pr", "merge", pr_number, "--merge")
        out=call_gh("pr", "merge", pr_number, "--merge")
        print(out)

    print("call_gh", "pr", "edit", curr_id, "--add-label", "ok-to-build")
    call_gh("pr", "edit", str(curr_id), "--add-label", "ok-to-build")
else:
    print(f"wrong number of PRs to merge found! ERROR: {to_merge}")

#
#"""
#  {
#    "baseRefName": "release-2.4",
#    "files": [
#      {
#        "path": "bundle-hack/operator.yaml",
#        "additions": 1,
#        "deletions": 1
#      }
#    ],
#    "headRefName": "konflux/component-updates/component-update-operator-2-4",
#    "number": 648,
#    "title": "Update operator-2-4 to 72ac364"
#  },
#"""
