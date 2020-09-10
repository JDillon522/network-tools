#!/bin/bash
########################################################################
# This header measures out 72 Characters of line length
# File Name : autotunnel.sh
# Author : Gabriel Akonom
# Creation Date : 01Sep2020
# Last Modified : Wed 02 Sep 2020 12:39:34 PM UTC
# Description:
#
########################################################################


# FUNCTIONS  ################################################
create_dynamic(){

    while ! nc -z localhost $l2port
    do
        echo "Waiting for tunnel to open....."
        sleep 4
    done

    echo "#!/bin/bash" > DYNAMIC_tmp.sh
    echo "echo 'Opening DYNAMIC tunnel using port $l2port...'" >> DYNAMIC_tmp.sh
    echo "echo 'Hostname is $hname'" >> DYNAMIC_tmp.sh
    echo "ssh -p $l2port $ipadd -D 9050 -NT" >> DYNAMIC_tmp.sh
    chmod +x DYNAMIC_tmp.sh
        
    xterm -T "DYNAMIC-$l2port-$hname" -e 'bash DYNAMIC_tmp.sh | less' & 

 
    #rm DYNAMIC_tmp.sh

}
create_static(){
    
    echo "#!/bin/bash" > LOCAL_tmp.sh
    echo "echo 'Opening STATIC tunnel using port $lport...'" >> LOCAL_tmp.sh
    echo "echo 'Hostname is ${hname}'" >> LOCAL_tmp.sh
    echo "ssh -p $altport $ipadd -L $lport:$pipadd:$pport -NT" >> LOCAL_tmp.sh
    chmod +x LOCAL_tmp.sh
            
    echo "$currname:$lport ---> $hname ---> $pipadd:$pport" >> tuntable.txt
    xterm -T "$lport-STATIC-$hname" -e 'bash LOCAL_tmp.sh | less' &

    while ! nc -z localhost $lport
    do
        sleep 0.01
    done

    #rm $lport_LOCAL_tmp.sh

}
create_passthru(){
    echo "#!/bin/bash
    echo 'Opening PASS-THRU tunnel using port $lport...'
    echo 'Pointing at $pipadd port $pport'
    echo 'Hostname is ${hname}'
    if [ $pport -eq 23 ]
    then
        echo \"while ! nc -z localhost $lport
        do
            echo \"Waiting for telnet Connection to $pipadd...\"
            sleep 2
        done
        telnet localhost $lport \"  > TELNET_tmp.sh
        chmod +x TELNET_tmp.sh
        echo \"$currname:$lport ---> $hname ---> TELNET-FOR-REVERSE\" >> tuntable.txt
        xterm -T \"$lport-TELNET-$hname\" -e \"bash TELNET_tmp.sh \" &
    fi
    ssh -p $altport $ipadd -L $lport:$pipadd:$pport -NT
    " > LOCAL_tmp.sh
    chmod +x LOCAL_tmp.sh
            
    echo "$currname:$lport ---> $hname ---> $pipadd:$pport" >> tuntable.txt
    xterm -T "$lport-PASS-THRU-$hname" -e 'bash LOCAL_tmp.sh | less' &

    while ! nc -z localhost $lport
    do
        sleep 0.01
    done
    #rm $lport_LOCAL_tmp.sh

}
create_altstatic(){
    echo "#!/bin/bash" > STATIC_tmp.sh
    echo "echo 'Port $l2port is STATIC at localhost:$pport...'" >> STATIC_tmp.sh
    echo "echo 'Hostname is ${hname}'" >> STATIC_tmp.sh
    echo "ssh -p $lport $ipadd -L $l2port:localhost:$pport -NT" >> STATIC_tmp.sh
    chmod +x STATIC_tmp.sh
                            
    echo "$currname:$l2port ---> $hname ---> localhost:$pport" >> tuntable.txt
    xterm -T "$l2port-STATIC-$hname" -e 'bash STATIC_tmp.sh | less' &
    
    sleep 1
    #rm STATIC_tmp.sh
}

# BEGIN ######################################################
    #what's the scenario?
    echo -e "\nAre you creating an initial tunnel, building upon another, or creating a remote tunnel?"
    echo -e "1 for initial\n2 for building on existing tunnel\n3 for remote(not operational yet)"
    read scen
    if [ $scen -eq 1 ]
    then
        #retrieve username and ip address
        echo -e "\nPlease input: <user>@<ipaddress>"
        read ipadd

        #retrieve ssh port to use
        echo -e "\nWhat SSH port should be used to log into $ipadd? (DEFAULT: 22)"
        read altport
                if [ -z $altport ]
        then
            altport="22"
        fi
        l2port=$altport

    elif [ $scen -eq 3 ]
    then
        echo "WARNING: The rest of this script assumes that you've already set up a tunnel pointing at the telnet port of the remote machine"
        echo "What port is the correct tunnel using?"
        read altport
        if [ -z $altport ]
        then
            altport="22"
        fi
        l2port=$altport
    else
        #retrieve username and ip address
        echo -e "\nPlease input username"
        read uname
        ipadd=$uname@localhost

        #retrieve ssh port to use
        echo -e "\nWhat port is your tunnel using?"
        read altport
                if [ -z $altport ]
        then
            altport="22"
        fi
        l2port=$altport
    fi

    #get the local host name
    currname=$(hostname)
    
    #test connection and get remote hostname
    echo -e "\nTesting connection to $ipadd\n" 
    hname=$(ssh -p $altport $ipadd -o ConnectTimeout=5 -o ConnectionAttempts=10 hostname)

    #error handling for initial connection
    if [ $? -eq 0 ]
    then
        echo -e "\nSuccess: Connected to $hname\n"
    else
        echo -e "\nFailure: connection unsuccessful. Maybe not an SSH connection?\n" >&2
        hname="UNKNOWN"
    fi

#handle options
while getopts “:crld” opt; do
    case $opt in

#option c clears the tunnel table
        c)
            echo "" > tuntable.txt
            echo "===================Tunnel Table=================" >> tuntable.txt
            echo "" >> tuntable.txt
            ;;

        #r)
            
            #echo "What is the <user>@<ip address> for the callback machine?"
            #read ipadd

            #echo "What port would you like to open on the callback machine?"
            #read rport
            #;;

#option l creates a local tunnel
        l)
            echo -e "\nWhat local port would you like to open?"
            read lport
            
            echo -e "\nWill this tunnel be ending in this box, or pointing to another?)
                    1 to end the tunnel here with a custom loopback port (ie: 5555)
                    2 for pointing onwards
                    3 to loopback to this box's localhost:22"
            read tunend
            
            #set remote ip address to localhost if yes, or prompt for other if no
            if [ $tunend -eq 1 ]
            then
                pipadd=localhost
                echo -e "\nFinally, what port is this tunnel pointing to at $pipadd? (DEFAULT: 22)"
                read pport

                if [ -z $pport ]
                then
                    pport="22"
                fi
                
                if [ -z $pipadd ]
                then
                    pipadd="localhost"
                fi

                create_static

            elif [ $tunend -eq 3 ]
            then   
                pipadd=localhost
                pport=22

                create_static
                l2port=$lport
            else
                echo -e "\nWhat ip address will this tunnel be POINTING to? (DEFAULT: localhost)"
                read pipadd

                echo -e "\nFinally, what port is this tunnel pointing to at $pipadd? (DEFAULT: 22)"
                read pport
            
                if [ -z $pport ]
                then
                    pport="22"
                fi
                
                if [ -z $pipadd ]
                then
                    pipadd="localhost"
                fi

                create_passthru
                l2port=$lport

                

            fi
            


            ;;
#option d creates a dynamic connection
        d)
            
            create_dynamic
             ;;

#error handling for unsupported options
        *) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
    esac
done


    echo -e "\n$(cat tuntable.txt)\n"


