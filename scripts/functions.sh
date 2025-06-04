
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
    git rev-parse HEAD

}

function latest_kmm {
    git submodule status | awk '/kernel-module-management/{print substr($1,0,7)}'
}


function snapshots {
    COMMIT=$1
    APP=$2

    if [ -n "$APP" ]; then
        oc get snapshot -o custom-columns=NAME:.metadata.name --no-headers -l pac.test.appstudio.openshift.io/sha=$COMMIT,appstudio.openshift.io/application=$APP --sort-by='{.metadata.creationTimestamp}' | tail -n 1
    elif [ -n "$COMMIT" ]; then
        oc get snapshot -o custom-columns=NAME:.metadata.name --no-headers -l pac.test.appstudio.openshift.io/sha=$COMMIT --sort-by='{.metadata.creationTimestamp}' | tail -n 1
    else
        #oc get snapshot -o custom-columns=NAME:.metadata.name --no-headers
        oc get snapshot  --sort-by='{.metadata.creationTimestamp}' --no-headers -o custom-columns=NAME:.metadata.name   | tail -n 1

    fi
}

function check_snapshot {
    SNAPSHOT=$1

    oc describe snapshot $SNAPSHOT | awk 'BEGIN{ while(("cat bundle-hack/*.yaml" | getline x) != 0){a[x]=1;}}/Container Image:/{if(a[$3]!=1){print $3} }'

}


function update_pullspecs {
    VERSION=$(version_hyphen)

    oc get component --no-headers -o custom-columns=NAME:.metadata.name,IMAGE:.status.lastPromotedImage | awk -v x=$VERSION '$2!~/\<none\>/{gsub("\\-?v?"x,"",$1); print $2 > "bundle-hack/" $1 ".yaml"}'

}

function pipelineruns {
    COMMIT=$1
    if [ -n "$COMMIT" ]; then
        oc get pipelineruns -l pipelinesascode.tekton.dev/sha=$COMMIT
    else
        oc get pipelineruns
    fi
}

#function next_release {
#    PATTERN=${1:-kmm}
#    VERSION=${2:-$(version_zstream)}
#    oc get release --sort-by='{.metadata.creationTimestamp}' | awk -v r="${PATTERN}-${VERSION}-r" '$1~r{gsub(r, "",$1); if( (int($1)+1) > l){l=int($1)+1}}END{print r l}'
#}
function next_release {
    KMM=${1/kmm-2-4/kmm-240}
    APP=${2/kmm-2-4/kmm-240}
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
    APPLICATION=$1
    oc get releaseplan | awk -v app=$APPLICATION '$2==app{print $1}'

}
