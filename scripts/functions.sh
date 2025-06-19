
function get_base_path {
    git rev-parse --show-toplevel
}

function version_hyphen {
    git branch --show-current | awk '{gsub("[a-zA-Z\\-]*","");gsub("\\.","-");print $1}'
}

function version_zstream {
    git branch --show-current | awk '{gsub("[a-zA-Z\\-\\.]*","");print $1"0"}'
}

function latest_commit {
    local SHORT=""
    if [ "$1" == "-s" ]; then
        SHORT="--short"
        shift
    fi
    local COMMIT=${1:-HEAD}
    git rev-parse $SHORT $COMMIT

}

function latest_kmm {
    MODULE=${1:-kernel-module-management}
    git submodule status | awk -v module=$MODULE '$2==module{gsub("[+-U]","",$1);print substr($1,0,7)}'
}


function snapshots {
    local APP=$1
    local COMMIT=$2

    if [ -n "$APP" ]; then
        oc get snapshot -o custom-columns=NAME:.metadata.name --no-headers -l pac.test.appstudio.openshift.io/sha=$COMMIT,appstudio.openshift.io/application=$APP --sort-by='{.metadata.creationTimestamp}' | tail -n 1
        #oc get snapshot -o custom-columns=NAME:.metadata.name --no-headers -l pac.test.appstudio.openshift.io/sha=$COMMIT,appstudio.openshift.io/application=$APP
    elif [ -n "$COMMIT" ]; then
        oc get snapshot -o custom-columns=NAME:.metadata.name --no-headers -l pac.test.appstudio.openshift.io/sha=$COMMIT --sort-by='{.metadata.creationTimestamp}' | tail -n 1
    else
        #oc get snapshot -o custom-columns=NAME:.metadata.name --no-headers
        oc get snapshot  --sort-by='{.metadata.creationTimestamp}' --no-headers -o custom-columns=NAME:.metadata.name   | tail -n 1

    fi
}

function check_snapshot {
    local SNAPSHOT=$1

    oc describe snapshot $SNAPSHOT | awk 'BEGIN{ while(("cat bundle-hack/*.yaml" | getline x) != 0){a[x]=1;}}/Container Image:/{if(a[$3]!=1){print $3} }'

}


function update_pullspecs {
    local VERSION=$(version_hyphen)

    oc get component --no-headers -o custom-columns=NAME:.metadata.name,IMAGE:.status.lastPromotedImage | awk -v x=$VERSION '$2!~/\<none\>/{gsub("\\-?v?"x,"",$1); print $2 > "bundle-hack/" $1 ".yaml"}'

}

function pipelineruns {
    local COMMIT=$1
    if [ -n "$COMMIT" ]; then
        oc get pipelineruns -l pipelinesascode.tekton.dev/sha=$COMMIT --sort-by='{.metadata.creationTimestamp}'
        ## enterprise-contracts use as different label grrr
        oc get pipelineruns --no-headers -l pac.test.appstudio.openshift.io/sha=$COMMIT --sort-by='{.metadata.creationTimestamp}'
    else
        oc get pipelineruns --sort-by='{.metadata.creationTimestamp}'
    fi
}


#function next_release {
#    PATTERN=${1:-kmm}
#    VERSION=${2:-$(version_zstream)}
#    oc get release --sort-by='{.metadata.creationTimestamp}' | awk -v r="${PATTERN}-${VERSION}-r" '$1~r{gsub(r, "",$1); if( (int($1)+1) > l){l=int($1)+1}}END{print r l}'
#}
function next_release {
    local KMM=${1/kmm-2-4/kmm-240}
    local APP=${2/kmm-2-4/kmm-240}
    oc get release --sort-by='{.metadata.creationTimestamp}' | 
        awk -v kmm=$KMM -v app=$APP '
                BEGIN{
                    if(app==""){app=kmm}
                }
                $1~app{
                     release[$1]++
                }   
                $1~r"-r"{
                    gsub(kmm"-r", "",$1);
                    if(int($1) > l){
                        l=int($1)
                    }
                }
                END{
                    if(kmm == app){
                        print app "-r" l+1
                        exit
                    }
                    p=1 ; 
                    while(1){
                        if(release[app "-r" l"-" p]=="") {
                            print app "-r" l "-"p;
                            exit
                        };
                        p++
                    }}'
}

function releaseplan {
    local APPLICATION=$1
    local ENVIRO=${2:-stage}

    if [ "$ENVIRO" != "prod" ]; then
        oc get releaseplan | awk -v app=$APPLICATION '$1~/prod/{next}  $2==app{print $1}'
    else
        oc get releaseplan | awk -v app=$APPLICATION '$1!~/prod/{next}  $2==app{print $1}'
    fi

}


function latest_releases {
    local RELEASE=$1  #e.g r30

    oc get release  | awk -v v=$RELEASE ' 
            $1~".*"v {
                status[$1]=$4;
                match($1,"(.*" v ")-([0-9]+)", parts);
                if(length(parts) ==0){
                    parts[1]=$1; 
                    parts[2]=""
                };
                if(parts[2] > arr[parts[1]]){
                    arr[parts[1]]=parts[2]} 
                }
                END{ 
                    for(i in arr){
                        if(arr[i]==""){
                            print i " " status[i]
                        }else{
                            print i"-"arr[i]" " status[i"-"arr[i]]
                        }
                    }}' | sort
}
