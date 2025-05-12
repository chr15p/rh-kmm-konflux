#!/usr/bin/bash

LOG=$1
if [ -z "$LOG" ]; then
    echo "usage: $0 LOGFILE"
    exit 1
fi

regexps=$(awk 'BEGIN{RS=""; FS="\n"}
    /\[Warning\] trusted_task.current/{
        for(i=1;i<=NF;i++){
            if($i~/sha256/&&$i!~/ImageRef/){
                sub(/.*sha256:/,"",$i)
                sub(/"/,"",$i)
                if(key==""){ key=$i}else {val=$i}            
                #print $i
            }
        }
        a[key]=val
        key=""
        val=""
        #print "="
    }
    END{
        for(k in a){
            print "s|" k"|"a[k]"| "
        }
    }
    ' $LOG) 

for file in $(ls .tekton/*.yaml); do
    sed -i "$regexps" $file
done

exit
