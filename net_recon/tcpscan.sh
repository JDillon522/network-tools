#!/bin/bash
########################################################################
# This header measures out 72 Characters of line length
# File Name : tcpscan.sh
# Author : Gabriel Akonom
# Creation Date : 09Sep2020
# Last Modified : Wed Sep  9 08:37:33 2020
# Description:
#
########################################################################
function cleanup(){ ## Cleanup function for exiting

    echo ""
    ##RESULTS------------------------------------------
    echo "Organizing and displaying current results..."
    echo $(cat tcplog.txt | sort | uniq -u) > tcplog.txt
    sleep 2

    k=""
    hcount=0
    pcount=0
    for i in $(cat tcplog.txt)
    do
        if [[ $i =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]
        then
            if [[ $i != $k ]]
            then
                if [[ $k == "" ]]
                then 
                    edge=""
                fi
                k=$i
                hcount=$((hcount+1))
                msg="| $i"             
                lmsg=$((18-${#msg}))
                for s in $(seq $lmsg)
                do
                    msg=$msg" "
                done
                echo -e "$edge-\n"
                edge=$(echo "$msg" | sed 's/./-/g')
                echo -e "$edge-"
                echo "$msg|"
                echo "$edge-"
                #echo -e "\n---------------\n$i\n---------------"
            fi
        else
            printf "%-1s\t%3s\n" "|- $i (open)" "|"
            pcount=$((pcount+1))
        fi
        
    done
    echo "$edge-"
    #--------------------------------------------------
    echo -e "\nScanned for $sec seconds / $hcount hosts found / $pcount ports open"
    echo -ne "Cleaning...                                \r"
    sleep 1
    proc_pid=$$
    echo -ne "Killing children...                         \r"
    sleep 1
    #for i in $(ps -elf | awk '{if ($5 == $proc_pid) {print $4}}')
    for i in ${pids[@]}
    do
        (kill -9 $i &> /dev/null && sleep 0.5) &
    done
    echo -ne "Killing orphans...                                  \r"
    sleep 1
    for i in $(ps -elf | awk '{if ($5 == 1 && $3 == "student") {print $4}}')
    do
        (kill -9 $i &> /dev/null && sleep 0.5) &
    done
    
    echo -ne "Removing temporary files...                                \r"
    sleep 1
    if [ -f "tcplog.txt" ]
    then
        rm tcplog.txt
    fi
    if [ -f "prog.txt" ]
    then
        rm prog.txt
    fi
    echo -ne "Cleaning complete...                                    \r"
    echo ""
    kill -9 $$
}

scan(){ #perform scan in background
    fn=$1
    fi=$2
    fp=$3
    fadd=$1.$2
    fo=""
    for p in $fp
    do
        timeout 2.5 /bin/bash -c "(echo > /dev/tcp/$fadd/$p)" > /dev/null 2>&1 \
            && fo="$fo$fadd $p\n" || echo "" > /dev/null
        echo 1 >> prog.txt
    done
    echo -e "$fo\n" >> tcplog.txt
}

trap cleanup SIGINT EXIT ## trap CTRL-C and Exit signals

##Create temp files
echo "" > tcplog.txt
echo "" > prog.txt

echo "Enter network address (default: 192.168.0): "

read net 

if [ -z $net ]
then
    net="192.168.0"
fi

echo "Enter starting host range (default: 1): "

read start

if [ -z $start ]
then
    start=1
fi

echo "Enter ending host range (default: 254): "

read end

if [ -z $end ]
then
    end=254
fi

echo "Enter ports space-delimited (e.g. 20 22 25 80): "
echo "defaults to list from: https://rb.gy/x86g6c"
read ports

if [ -z $ports ]
then
    ports="20 21 22 23 25 50 51 53 67 68 69 80 110 119 123 135-139 143 161 162 389 443 989 990 3389 2222 4444 8080"
fi

result_str=""

#this section allows the user to input ranges in the form 1-20 etc..
for i in $ports 
do
    if [[ "$i" == *"-"* ]]
    then
        res=$(seq -s ' ' $(sed -n 's#\([0-9]\+\)-\([0-9]\+\).*#\1 \2#p' <<< "$i"))
    else
        res="$i"
    fi
    result_str="$result_str $res"
done
final_ports=${result_str:1}

#create progress counters
cc=0
tc=1
sec=0
for ((i=$start; $i<=$end; i++))
do
    for cp in $final_ports
    do
        tc=$((tc+1))
    done
done

#call scan function for each IP to run in background
pids=()
for ((i=$start; $i<=$end; i++))
do
    scan $net $i "$final_ports" &
    pids+=($!)

done

#Begin progress counter
while [[ $cc -lt $tc ]]
do
    if [ -f "prog.txt" ]
    then
        cc=$(wc -l prog.txt | awk '{ print $1 }')
    else
        break
    fi
    perc="$((cc/$tc*100))"
    sec=$((sec+1))
    echo -ne "Parent Proc: $$ Total port scans: $tc. Completed $cc. $sec seconds have elapsed\r"
    sleep 1
done
    
wait

#When all child processes are done, script will print results and exit

