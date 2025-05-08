#!/usr/bin/bash

get_logfile () {

    if [ ! -e "$LOG" ]; then
        oc logs ${LOG}-verify-pod -c step-validate > ${LOG}.log
        LOG=${LOG}.log     
        TMPFILE=$LOG
    fi
}


METHOD="s"
LEVEL=2
KEEP=0
TMPFILE=

case "$1" in
-r)
    METHOD="r"
    shift
    ;;
-s)
    METHOD="s"
    shift
    ;;
-w)
    METHOD="d"
    LEVEL=1
    shift
    ;;
-v)
    METHOD="d"
    LEVEL=2
    shift
    ;;
-k)
    KEEP=1
    shift
    ;;
esac



if [ "$METHOD" == "s" ]; then
    for LOG in $@; do 
        if [ ! -e "$LOG" ]; then
            #oc logs fbc-v2-4-enterprise-contract-t82sq-verify-pod -c step-validate
            oc logs ${LOG}-verify-pod -c step-validate > ${LOG}.log
            LOG=${LOG}.log     
            TMPFILE=$LOG
        fi

        echo -e "\n=== Summary for $LOG ==="
        awk '/Components:/{flag=1} 
        flag==1 &&/Name/{
            name=$3
        }
        flag==1 &&/ImageRef:/{
            l=split($2,a,/\//)
            image=a[l]
        }
        flag==1 && /Violation/{printf("%-100s  %s\n",name, $0)}
        /Results:/{flag=0}
        ' $LOG
    done
elif [ "$METHOD" == "d" ]; then
    LOG=$1
    shift
    if [ ! -e "$LOG" ]; then
        oc logs ${LOG}-verify-pod -c step-validate > ${LOG}.log
        LOG=${LOG}.log     
        TMPFILE=$LOG
    fi
    for IMAGE in $@; do 
            echo -e "\n=== Details for $IMAGE ==="
            awk -v img=$IMAGE -v lvl=$LEVEL  '/Results:/{flag=1}
                BEGIN{lvl+=0}
                /\[Violation\]/{type=$0; t=2 ; show=0} 
                /\[Warning\]/{type=$0; t=1 ; show=0}
                flag==1 && $0~/^$/{show=0; t=0}
                flag==1 && show==1{
                    if(lvl== t){print $0}
                    next
                }
                flag==1 && /ImageRef/ && $2~img {
                    show=1; 
                    if(lvl==t){print "\n"type}
                    next
                }
                /STEP-REPORT-JSON/{flag=0; show=0}
            ' $LOG
    done
elif [ "$METHOD" == "r" ]; then
    JOB=$1
    oc logs ${JOB}-verify-pod -c step-validate
fi


