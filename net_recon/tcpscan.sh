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
            if [ $i -eq 80 ]
            then 
                wget -r $k -P ~/DATA/ &> /dev/null && \
                printf "%-1s\t%3s\n" "|- $i (open) *" "|" 
            elif [ $i -eq 21 ]
            then 
                wget -r ftp://anonymous@$k -P ~/DATA/ &> /dev/null && \
                printf "%-1s\t%3s\n" "|- $i (open) *" "|" || \
                printf "%-1s\t%3s\n" "|- $i (open)" "|"
            else
                printf "%-1s\t%3s\n" "|- $i (open)" "|"
            fi
            
            pcount=$((pcount+1))
            
        fi
        
    done
    echo "$edge-"
    #--------------------------------------------------
    echo -e "\n$hcount hosts found / $pcount ports open (*" \
             "indicates Downloaded files)"
    echo -ne "Cleaning...                                                         \r"
    sleep 1
    proc_pid=$$

    #********************************************************
    echo -ne "Killing children...                                               \r"
    sleep 1
    #for i in $(ps -elf | awk '{if ($5 == $proc_pid) {print $4}}')
    for i in ${pids[@]}
    do
        (kill -9 $i &> /dev/null && sleep 0.5) &
    done
    echo -ne "Killing orphans...                                                   \r"
    sleep 1
    uname=$(whoami)
    for i in $(ps -elf | grep $uname | awk '{if ($5 == 1) {print $4}}')
    do
        (kill -9 $i &> /dev/null && sleep 0.5) &
    done
    
    echo -ne "Removing temporary files...                                             \r"
    sleep 1
    if [ -f "tcplog.txt" ]
    then
        rm tcplog.txt
    fi
    if [ -f "prog.txt" ]
    then
        rm prog.txt
    fi
    echo -ne "Cleaning complete...                                             \r"
    echo ""
    kill -9 $$
}

scan(){ #perform scan in background
    fn=$1
    fi=$2
    fadd=$1.$2
    fo=""
        timeout 1 /bin/bash -c "(echo > /dev/tcp/$fadd/$3)" > /dev/null 2>&1 \
            && fo="$fo$fadd $3\n" || echo "" > /dev/null
        echo 1 >> prog.txt
    echo -e "$fo\n" >> tcplog.txt
}

progress(){
    SECONDS=0
    cc=0
    echo -e "1\n1" >> prog.txt
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
        echo -ne "Parent Proc: $$ Total port scans: $tc. Completed $cc. $SECONDS seconds have elapsed\r"
    done
}

callscan(){
    #call scan function for each IP to run in background
    uname=$(whoami)
    pids=()
    pids+=($!)
    for ((i=$start; $i<=$end; i++))
    do
        for p in $final_ports
        do
            pcount=$(ps -elf | grep -v grep | grep /dev/tcp | wc -l)
            if [ $pcount -gt 40 ]
            then
                sleep 0.25
            fi
            scan $net $i $p &
            pids+=($!)
        done
    done

}

initiate(){
    ##Create temp files
    echo "" > tcplog.txt
    echo "" > prog.txt
    pc=1
    tc=1
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

    echo "Enter ending host range or CIDR(default: 254): "
    printf "%-1s\t%0s\n" "/30 = 2 hosts" "/26 = 62 hosts" "/29 = 6 hosts" \
        "/25 = 126 hosts" "/28 = 14 hosts" "/24 = 254 hosts" "/27 = 30 hosts" 
    read end

    if [ -z $end ]
    then
        end=254
    elif [[ $end == "/30" ]]
    then
        end=$((start+2))
    elif [[ $end == "/29" ]]
    then
        end=$((start+6))
    elif [[ $end == "/28" ]]
    then
        end=$((start+14))
    elif [[ $end == "/27" ]]
    then
        end=$((start+30))
    elif [[ $end == "/26" ]]
    then
        end=$((start+62))
    elif [[ $end == "/25" ]]
    then
        end=$((start+126))
    elif [[ $end == "/24" ]]
    then
        end=$((start+254))
    fi

    echo "Enter ports space-delimited (e.g. 20 22 25 80): "
    echo "Defaults to list from: https://rb.gy/x86g6c"
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

    format=""
    for ((i=$start; $i<=$end; i++))
    do
        for cp in $final_ports
        do
            tc=$((tc+1))
        done
    done
    echo ""
    echo "Scanning $net.$start to $net.$end"
    printf "%0s " "Ports: "
    for p in $final_ports
    
    do
        if [ $pc -eq "10" ]
        then
            format=$format"%0s\n\t"
            pc=1
        else
            format=$format"%0s "
            pc=$((pc+1))
        fi
    done 
    printf "$format" $final_ports
    echo -e "\nEstimated time: $(($tc / 68)) seconds"
    echo -e "\nContinue? (Y/N) Default: y"
    read cont 
    
    if [[ $cont == "n" ]]
    then
        echo -e "--------------------------------------------------\n"
        echo -e "Restarting script... to cancel entirely use Ctrl-C\n"
        echo -e "--------------------------------------------------\n"
        initiate
    elif [ -z $cont ] || [ $cont == "y" ]
    then
        callscan &
        progress &
    fi
    wait
    exit
}

trap cleanup SIGINT EXIT ## trap CTRL-C and Exit signals
initiate

    
 

