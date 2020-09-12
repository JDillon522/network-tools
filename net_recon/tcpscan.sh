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

    echo "Cleaning up and exiting Script..."
    proc_pid=$$
    echo "Killing children..."

    for i in $(ps -elf | awk '{if ($5 == $proc_pid) {print $4}}')
    do
        kill -9 $i
    done
    
    echo "Killing orphans..."
    sleep 4
    for i in $(ps -elf | awk '{if ($5 == 1 && $3 == "student") {print $4}}')
    do
        kill -9 $i
    done
    sleep 2
    
    echo "Removing temporary files..."
    if [ -f "tcplog.txt" ]
    then
        rm tcplog.txt
    fi
    if [ -f "prog.txt" ]
    then
        rm prog.txt
    fi
    kill -9 $$
}
trap cleanup SIGINT EXIT ## trap CTRL-C and Exit signals

##Create temp files
echo "" > tcplog.txt
echo "" > prog.txt

scan(){ #perform scan in background
    fn=$1
    fi=$2
    fp=$3
    fadd=$1.$2
    fo=""
    for p in $fp
    do
        timeout 5 /bin/bash -c "(echo > /dev/tcp/$fadd/$p)" > /dev/null 2>&1 \
            && fo="$fo$fadd $p\n" || echo "" > /dev/null
        echo 1 >> prog.txt
    done
    echo -e "$fo\n" >> tcplog.txt
}


echo "Enter network address (e.g. 192.168.0): "

read net 

echo "Enter starting host range (e.g. 1): "

read start

echo "Enter ending host range (e.g. 254): "

read end

echo "Enter ports space-delimited (e.g. 20 22 25 80): "

read ports
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
for ((i=$start; $i<=$end; i++))
do
    scan $net $i "$final_ports" &
done

#Begin progress counter
until [[ $cc == $tc ]]
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

#When all child processes are done, print results
echo $(cat tcplog.txt | sort | uniq -u) > tcplog.txt
sleep 2

cc=$(wc -l prog.txt | awk '{ print $1 }')
echo -ne "Total port scans: $tc. Completed $cc.\r"

k=""
for i in $(cat tcplog.txt)
do
    if [[ $i =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]
    then
        if [[ $i != $k ]]
        then
            k=$i
            echo -e "\n----$i----"
        fi
    else
        echo "--$i (open)"
    fi
done
