#!/bin/bash
########################################################################
# This header measures out 72 Characters of line length
# File Name : autotunnel.sh
# Author : Gabriel Akonom
# Creation Date : 01Sep2020
# Last Modified : Tue Sep  1 13:39:58 2020
# Description:
#
########################################################################

#retrieve username and ip address
echo "Please input: <user>@<ipaddress>"
read ipadd

#retrieve ssh port to use and set default
echo "What SSH port should be used to log into $ipadd? (DEFAULT: 22)"
read altport

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
while getopts “:cld” opt; do
    case $opt in

#option c clears the tunnel table
        c)
            echo "      LOCAL HOSTNAME:PORT           |          CONNECTION ADDRESS:PORT             |       REMOTE HOSTNAME    " > tuntable.txt
            echo "" >> tuntable.txt
            ;;

#option l creates a local tunnel
        l)
            echo "What local port would you like to open?"
            read lport
            echo "What ip address will this tunnel be POINTING to? (DEFAULT: localhost)"
            read pipadd
            if [ -z $pipadd ]
            then
                pipadd="localhost"
            fi
            echo "Finally, what port is this tunnel pointing to at $pipadd? (DEFAULT: 22)"
            read pport
            if [ -z $pport ]
            then
                pport="22"
            fi

            echo "#!/bin/bash" > LOCAL_tmp.sh
            echo "echo 'Opening LOCAL tunnel using port $lport...'" >> LOCAL_tmp.sh
            echo "echo 'Hostname is ${hname}'" >> LOCAL_tmp.sh
            echo "ssh -p $altport $ipadd -L $lport:$pipadd:$pport -NT" >> LOCAL_tmp.sh
            chmod +x LOCAL_tmp.sh
            
            echo "$currname:$lport     |   $ipadd:$pport    | $hname" >> tuntable.txt
            xterm -e 'bash LOCAL_tmp.sh | less' &
            ;;
#option d creates a dynamic connection
        d)
            
            echo "#!/bin/bash" > DYNAMIC_tmp.sh
            echo "echo 'Opening DYNAMIC tunnel using port $lport...'" >> DYNAMIC_tmp.sh
            echo "echo 'Hostname is ${hname}'" >> DYNAMIC_tmp.sh
            echo "ssh -p $altport $ipadd -D 9050 -NT" >> DYNAMIC_tmp.sh
            chmod +x DYNAMIC_tmp.sh
        
            xterm -e 'bash DYNAMIC_tmp.sh | less' & 
            ;;

#error handling for unsupported options
        *) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
    esac
done


cat tuntable.txt
