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
echo "" > tcplog.txt
echo "" > prog.txt
scan(){
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

for ((i=$start; $i<=$end; i++))
do
    scan $net $i "$final_ports" &
done

until [[ $(wc -l prog.txt | awk '{ print $1 }') == $tc ]]
do
    cc=$(wc -l prog.txt | awk '{ print $1 }')
    perc="$((cc/$tc*100))"
    sec=$((sec+1))
    echo -ne "Total port scans: $tc. Completed $cc. $sec seconds have elapsed\r"
    sleep 1
done
    
wait

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
        #timeout 2 /bin/bash -c "exec 3<>/dev/tcp/$k/$i; echo EOF>&3; cat<&3" 2> /dev/null

        # if [[ $i == 22 ]]
        # then
        #     echo "Try to SSH? (y/n)"
        #     read sshyn
        #     if [ $sshyn = "y" ]
        #     then
        #         terminator -T "SSH to $k" -e "ssh $k"
        #     fi
        # fi
    fi
done

# while IFS= read -r line
# do
#   echo "$line"
# done < distros.txt
#cat tcplog.txt
rm tcplog.txt
rm prog.txt