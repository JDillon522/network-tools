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
function canceld(){
    pkill -9 $scanpid
    pkill -9 $progpid
    cleanup
}

function cleanup(){ ## Cleanup function for exiting

    echo ""
    ##RESULTS------------------------------------------
    echo "Organizing and displaying current results..."
    echo $(cat tcplog.txt | sort | uniq -u) > tcplog.txt
    #sleep 2

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
                msg="$i"             
                lmsg=$((18-${#msg}))
                for s in $(seq $lmsg)
                do
                    msg=$msg" "
                done
                echo -e "$edge-"
                edge=$(echo "$msg" | sed 's/./-/g')
                echo "$msg"
                #echo -e "\n---------------\n$i\n---------------"
            fi
        else
            #banner grab
            ss=$(timeout 1 bash -c "exec 3<>/dev/tcp/$k/$i; echo EOF>&3; cat<&3")
            if [[ -z $ss ]]
            then
                ss="open"
            fi

            if [ $i -eq 80 ]
            then 
                wget -r $k -P ~/DATA/ &> /dev/null && \
                printf "%-1s\t%3s\n" "|-> $i ($(echo $ss | head -c 5)) *"
            elif [ $i -eq 21 ]
            then 
                wget -r ftp://anonymous@$k -P ~/DATA/ &> /dev/null && \
                printf "%-1s\t%3s\n" "|-> $i ($(echo $ss | head -c 5)) *" || \
                printf "%-1s\t%3s\n" "|-> $i ($(echo $ss | head -c 5))"
            else
                printf "%-1s\t%3s\n" "|-> $i ($(echo $ss | head -c 5))"
            fi
            
            pcount=$((pcount+1))
            $exec 3>&-
        fi
        
    done
    echo "$edge-"
    #--------------------------------------------------
    echo -e "\n$hcount hosts found / $pcount ports open (*" \
             "indicates Downloaded files)"
    echo -ne "Cleaning...                                                                                 \r"
    sleep 1
    proc_pid=$$

    #********************************************************
    echo -ne "Killing children...                                                                          \r"
    sleep 2
    #for i in $(ps -elf | awk '{if ($5 == $proc_pid) {print $4}}')
    for i in ${pids[@]}
    do
        (kill -9 $i &> /dev/null) &
        sleep 0.05
    done
    echo -ne "Killing orphans...                                                   \r"
    sleep 1
    uname=$(whoami)
    for i in $(ps -elf | grep $uname | awk '{if ($5 == 1) {print $4}}')
    do
        (kill -9 $i &> /dev/null) &
        sleep 0.05
    done
    
    echo -ne "Removing temporary files...                                                                     \r"
    sleep 1
    if [ -f "tcplog.txt" ]
    then
        rm tcplog.txt
    fi
    if [ -f "prog.txt" ]
    then
        rm prog.txt
    fi
    echo -ne "Cleaning complete...                                                                            \r"
    echo ""
    kill -9 $$
}

scan(){ #perform scan in background
    fn=$1
    fi=$2
    fadd=$1.$2
    fo=""
    p=$3
        #echo "Scanning port $p on $fadd"
        timeout 1 /bin/bash -c "(echo > /dev/tcp/$fadd/$p)" > /dev/null 2>&1 \
            && fo="$fo$fadd $p\n" || echo "" > /dev/null
        echo 1 >> prog.txt
    echo -e "$fo\n" >> tcplog.txt
    #echo $!
}


progress(){
    #Begin progress counter
    SECONDS=1
    cc=0
    perc=0
    echo -e "1\n1\n1\n1\n1\n" >> prog.txt
    echo -e "Parent Proc: $$"
    while [[ $cc -lt $tc ]]
    do
        #gpid=
        cc=$(cat prog.txt | wc -l)
        #perc=$(bc <<< "$cc/$tc*100")
        ((m=(${SECONDS}%3600)/60))
        ((s=${SECONDS}%60))
        av=$(bc <<< "$cc/$SECONDS")
        echo -ne "Total port scans: $tc. Completed $cc. $m min(s) $s second(s) have elapsed. ~$av ports/s    \r"
    done
}

callscan(){
    #call scan function for each IP to run in background
    uname=$(whoami)
    pcount=0.01
    pop=0
    for ((i=$start; $i<=$end; i++))
    do
        for p in $final_ports
        do
            pcount=$(bc <<< "$pcount+0.0002")
            if (( $(echo "$pcount > 0.05" | bc -l) ))
            then
                pcount=0
            else
                #pcount=$(ps -elf | grep -v grep | grep /dev/tcp | wc -l)
                #scan $net $i $p &
                scan $net $i $p &
                pids+=($!)
                sleep $pcount 
                #done
            fi
        done
        wait

    done
    pkill -9 $progpid
}

initiate(){
    ##Create temp files
    echo "" > tcplog.txt
    echo "" > prog.txt
    pc=1
    declare -g tc=1
    declare -g progpid=""
    declare -g scanpid=""
    pids=()
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
    printf "%0s\n" "Ports: $ports" "Total Port scans: $tc"
    # for p in $final_ports
    
    # do
    #     if [ $pc -eq "10" ]
    #     then
    #         format=$format"%0s\n\t"
    #         pc=1
    #     else
    #         format=$format"%0s "
    #         pc=$((pc+1))
    #     fi
    # done 
    ttime=$(($tc / 10))
    ((m=(${ttime}%3600)/60))
    ((s=${ttime}%60))
    printf "$format" $final_ports
    echo -e "\nEstimated time: $m min(s) and $s second(s)"
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
        progress &
        pids+=($!)
        progpid=$!

        callscan &
        pids+=($!)
        scanpid=$!
    fi
    wait
    exit
}

trap canceld SIGINT ## trap CTRL-C
trap cleanup EXIT ##exit activites
initiate
