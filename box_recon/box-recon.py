#!/usr/bin/env python3

# TODO MAKE THIS A THING

import subprocess as sub

ss_tcp = ['ss', '-lt'] # get all listening TCP connections
ss_udp = ['ss', '-lu'] # get all listening UDP connections

ip_addr = ['ip', 'addr']
ip_nei = ['ip', 'neighbor']

print('Running `ss`')
ss_tcp_run = sub.run(ss_tcp, stdout=sub.PIPE, stderr=sub.PIPE, universal_newlines=True)
ss_udp_run = sub.run(ss_udp, stdout=sub.PIPE, stderr=sub.PIPE, universal_newlines=True)

print('Running `ip addr`')
ip_addr_run = sub.run(ip_addr, stdout=sub.PIPE, stderr=sub.PIPE, universal_newlines=True)

print('Running `ip neighbor`')
ip_nei_run = sub.run(ip_nei, stdout=sub.PIPE, stderr=sub.PIPE, universal_newlines=True)

print('------ LISTENING TCP CONNECTIONS ----------- \n', ss_tcp_run.stdout)
print('------ LISTENING UDP CONNECTIONS ----------- \n', ss_udp_run.stdout)

print('------ Interfaces and IPs ------------------ \n', ip_addr_run.stdout)
print('------ Directly Connected Neighbors -------- \n', ip_nei_run.stdout)
