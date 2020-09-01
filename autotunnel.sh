#!/bin/bash
########################################################################
# This header measures out 72 Characters of line length
# File Name : autotunnel.sh
# Author : Gabriel Akonom
# Creation Date : 01Sep2020
# Last Modified : Tue 01 Sep 2020 04:55:27 PM UTC
# Description:
#
########################################################################

echo "Please input: <user>@<ipaddress>"
read ipadd
echo "What local port would you like to open?"
read lport
echo "What ip address will this tunnel be POINTING to? (Enter localhost if you want to loopback)"
read pipadd
echo "Finally, what port is this tunnel pointing to at $pipadd? (22 for normal ssh, 23 for telnet, 80 for http, etc..)"
read pport

hname=$(ssh $ipadd hostname)

echo "#!/bin/bash" > tunnel.sh
echo "echo 'Opening tunnel using local port $lport...'" >> tunnel.sh
echo "echo 'Hostname is ${hname}'" >> tunnel.sh
echo "ssh $ipadd -L $lport:$pipadd:$pport -NT" >> tunnel.sh
chmod +x tunnel.sh

xterm -e 'bash tunnel.sh | less' & 






