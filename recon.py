#!/usr/bin/env python3

import subprocess as sub
import re

valid_net = False
while not valid_net:
	try:
		net = input('Enter network address with only 3 octets (e.g. 192.168.0): ') or '192.168.0'
		split_net = net.split('.')
		valid_octets = len([i for i in net.split('.') if i.isdigit()]) == len(split_net)

		if len(split_net) != 3 or not valid_octets:
			print('Your network address must have three valid octets... {} is invalid'.format(net))
		else:
			valid_net = True
	except ValueError as e:
		print('You did not enter in a valid network address')

valid_start = False
while not valid_start:
	try:
		start = input('Enter starting host range less than 254 (e.g. 1): ') or '1'
		
		if int(start) > 254:
			print('Your starting range must be less than 254')
		else:
			valid_start = True
	except ValueError as e:
		print('Your starting range is not valid')

valid_end = False
while not valid_end:
	try:
		end = input('Enter ending host range (e.g. 254): ') or '254'
		if int(end) > 254:
			print('Your ending host range must be less than 254')
		elif int(end) < int(start):
			print('Your ending host range must be greater than your start at {}'.format(start))
		else:
			valid_end = True
	except ValueError as e:
		print('Your ending host range must be a number')

ports = input('Enter ports space-delimited (e.g. 20 21 22 23 80): ') or '20 21 22 23 80'

# TODO: split the nc calls into multiple simultaneious calls
# equal_ranges = int(end) // 3
# intervals = []
# other_i = 0

# for i in range(0, int(end), equal_ranges):
# 	start_range = i

# 	if len(intervals) > 0:
# 		start_range = intervals[other_i][1] + 1
# 		other_i += 1

# 	end_range = i + equal_ranges
# 	if end_range > int(end):
# 		end_range = int(end)

# 	interval = [start_range, end_range]
# 	intervals.append(interval)
	

def format_output(output):
	return re.sub('\|S-chain\|-<>-|127.0.0.1:9050|-<><>-|\(UNKNOWN\)\s\[.+\]\s|\open\s:\sOperation\snow\sin\sprogress|.+timeout\n|.+OK\n', '', output)

def analyze_results(nc):
	if 'open' in nc.stderr or 'open' in nc.stdout:
		formatted = format_output(nc.stderr)

		print('\n-------- Rolling Results: IP: {}.{} ---------------'.format(net, i))
		print(formatted)

		results.append('-------- IP: {}.{} ---------------\n{}'.format(net, i, formatted))

nc_processes = []
results = []

for i in range(int(start), int(end)+1):
	print('\r Trying {}.{} on ports: {}'.format(net, i, ports), end='')

	# (-v) running verbosely (-v on Linux, -vv on Windows),
	# (-n) not resolving names. numeric only IP(no D.S)
	# (-z) without sending any data. zero-I/O mode(used for scanning)
	#(-w1) waiting no more than 1second for a connection to occur
	

	nc_args = ['nc', '-n', '-v', '-z', '-w1', '{}.{}'.format(net, i)] +  ports.split(' ')
	
	nc = sub.run(nc_args, stdout=sub.PIPE, stderr=sub.PIPE, universal_newlines=True)
	
	analyze_results(nc)
	

print('-------- Final Rollup ---------------\n')
for res in results:
	print(res)
