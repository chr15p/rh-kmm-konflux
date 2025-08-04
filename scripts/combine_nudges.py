#!/usr/bin/python
import json
import subprocess
import argparse

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

    #if DEBUG:
    #    print(' '.join(params))

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



parser = argparse.ArgumentParser()

parser.add_argument('--branch', action='store', required=True, default=None, help='csv template')

opt = parser.parse_args()
curr_branch = opt.branch


raw_prs = call_gh("pr","list","--json","number,headRefName,baseRefName,title,files", "--search", "label:konflux-nudge")
#print(raw_prs)

pr_list = json.loads(raw_prs)



to_merge = []
curr_id = 0
for pr in pr_list:
    print(pr)
    if len(pr['files']) != 1 :
        continue

    print(f"check {pr['headRefName']} == {curr_branch}")
    if pr["headRefName"] == curr_branch:
        print(f"setting curr_branch={curr_branch}")
        curr_id = pr["number"] 
        continue

    if not pr["headRefName"].startswith("konflux/component-updates/component-update-"):
        continue


    to_merge.append(pr['headRefName'])    

if curr_id == 0:
    print(f"not found this PR! ({curr_branch})")
    exit(1)

if len(to_merge) == 5:
    for branch in to_merge:
        print("call_git", "merge",branch, "-m", f"\"merge {branch}\"")
        call_git( "merge",branch, "-m", f"\"merge {branch}\"")


    print("call_git", "push")
    call_git("push")
    print("call_gh", "pr", "edit", curr_id, "--add-label", "ok-to-build")
    call_gh("pr", "edit", str(curr_id), "--add-label", "ok-to-build")

    #print(f"git merge origin/{pr['headRefName']} -m \"merge {pr['headRefName']}\"")
    #print("call_git", "merge",f"origin/{pr['headRefName']}", "-m", f"\"merge {pr['headRefName']}\"")
    #out=call_git("merge",f"origin/{pr['headRefName']}", "-m", f"\"merge {pr['headRefName']}\"")
    #print(out)
    #call_git("push")


#gh pr edit 657 --add-label ok-to-build
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
