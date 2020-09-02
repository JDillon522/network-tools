#!/bin/bash
########################################################################
# This header measures out 72 Characters of line length
# File Name : autotunnel.sh
# Author : Gabriel Akonom
# Creation Date : 01Sep2020
# Last Modified : Wed 02 Sep 2020 06:00:34 AM UTC
# Description:
#
########################################################################

#what's the scenario?
echo "Are you creating an initial tunnel, building upon another, or creating a remote tunnel?"
echo -e "1 for initial\n2 for building on existing tunnel\n3 for remote(not operational yet)"
read scen
if [ $scen -eq 1 ]
then
    #retrieve username and ip address
    echo "Please input: <user>@<ipaddress>"
    read ipadd

    #retrieve ssh port to use
    echo "What SSH port should be used to log into $ipadd? (DEFAULT: 22)"
    read altport
elif [ $scen -eq 3 ]
then
    echo "WARNING: The rest of this script assumes that you've already set up a tunnel pointing at the telnet port of the remote machine"
    echo "What port is the correct tunnel using?"
    read altport
else
    #retrieve username and ip address
    echo "Please input username"
    read uname
    ipadd=$uname@localhost

    #retrieve ssh port to use
    echo "What port is your tunnel using?"
    read altport
fi

if [ -z $altport ]
then
    altport="22"
fi


#get the local host name
currname=$(hostname)

#test connection and get remote hostname
echo -e "\nTesting connection to $ipadd\n" 
hname=$(ssh -p $altport $ipadd hostname)

#error handling for initial connection
if [ $? -eq 0 ]
then
    echo -e "\nSuccess: Connected to $hname\n"
else
    echo -e "\nFailure: connection unsuccessful. Script failed\n" >&2
    exit 1
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
            echo "What local port would you like to open?"
            read lport
            
            echo -e "Will this tunnel be ending in this box, or pointing to another?)\n1 for ending here\n2 for pointing onwards\n3 to set the standard loopback of localhost:22"
            read tunend
            
            #set remote ip address to localhost if yes, or prompt for other if no
            if [ $tunend -eq 1 ]
            then
                pipadd=localhost
                echo "Finally, what port is this tunnel pointing to at $pipadd? (DEFAULT: 22)"
                read pport
                if [ -z $pport ]
                then
                    pport="22"
                fi
            elif [ $tunend -eq 3 ]
            then   
                pipadd=localhost
                pport=22
            else
                echo "What ip address will this tunnel be POINTING to? (DEFAULT: localhost)"
                read pipadd

                echo "Finally, what port is this tunnel pointing to at $pipadd? (DEFAULT: 22)"
                read pport
            
                if [ -z $pport ]
                then
                    pport="22"
                fi
                
                echo "#!/bin/bash" > LOCAL_tmp.sh
                echo "echo 'Opening PASS-THRU tunnel using port $lport...'" >> LOCAL_tmp.sh
                echo "echo 'Pointing at $pipadd port $pport'" >> LOCAL_tmp.sh
                echo "echo 'Hostname is ${hname}'" >> LOCAL_tmp.sh
                echo "ssh -p $altport $ipadd -L $lport:$pipadd:$pport -NT" >> LOCAL_tmp.sh
                chmod +x LOCAL_tmp.sh
            
                echo "$currname:$lport ---> $hname ---> $pipadd:$pport" >> tuntable.txt
                xterm -T "$lport-PASS-THRU-$hname" -e 'bash LOCAL_tmp.sh | less' &
            fi
            
            if [ -z $pipadd ]
            then
                pipadd="localhost"
            fi

            #test connection and get remote hostname
            echo -e "\nTesting connection to $ipadd\nPlease input password in the new terminal window popup" 
            sleep 11
            hname=$(ssh -p $lport $ipadd hostname)
            
            l2port=$((lport+1))
            echo "#!/bin/bash" > STATIC_tmp.sh
            echo "echo 'Port $l2port is STATIC at localhost:$pport...'" >> STATIC_tmp.sh
            echo "echo 'Hostname is ${hname}'" >> STATIC_tmp.sh
            echo "ssh -p $lport $ipadd -L $l2port:localhost:$pport -NT" >> STATIC_tmp.sh
            chmod +x STATIC_tmp.sh
                        
            echo "$currname:$l2port ---> $hname ---> localhost:$pport" >> tuntable.txt
            xterm -T "$l2port-STATIC-$hname" -e 'bash STATIC_tmp.sh | less' &

            ;;
#option d creates a dynamic connection
        d)

            echo "#!/bin/bash" > DYNAMIC_tmp.sh
            echo "echo 'Opening DYNAMIC tunnel using port $lport...'" >> DYNAMIC_tmp.sh
            echo "echo 'Hostname is ${hname}'" >> DYNAMIC_tmp.sh
            echo "ssh -p $altport $ipadd -D 9050 -NT" >> DYNAMIC_tmp.sh
            chmod +x DYNAMIC_tmp.sh
        
            xterm -T "DYNAMIC-$lport-$hname" -e 'bash DYNAMIC_tmp.sh | less' & 
            ;;

#error handling for unsupported options
        *) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
    esac
done

echo ""
cat tuntable.txt
echo -e "\nCleaning Up...\n"

sleep 3
rm LOCAL_tmp.sh
rm DYNAMIC_tmp.sh
rm STATIC_tmp.sh
