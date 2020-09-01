#!/bin/bash
echo 'Opening LOCAL tunnel using port 30101...'
echo 'Hostname is internet-host-student-1'
ssh -p 22 student@172.20.20.46 -L 30101:localhost:22 -NT
