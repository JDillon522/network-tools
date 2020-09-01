#!/usr/bin/env python3

import subprocess as sub
import re

intervals = []
interval_creation_i = 0

interval_execution_index = 0
nc_processes = []
interval_analyzed_results_count = 0
results = []
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

# TODO add validation
ports = input('Enter ports space-delimited (e.g. 20 21 22 23 80): ') or '20 21 22 23 80'
# TODO add validation
interval_step = input('Enter the batch size for parallel execution. (default: 25)\n(note: the larger the batch size, the more likely the target IP \nwill be unable to handle requests and drop connections.)') or '25'
interval_step = int(interval_step)


# Build intervals in steps of 5
for i in range(0, int(end), interval_step):
	start_range = i + 1

	if len(intervals) > 0:
		start_range = intervals[interval_creation_i][1] + 1
		interval_creation_i += 1

	end_range = start_range + interval_step
	if end_range > int(end):
		end_range = int(end)

	interval = [start_range, end_range]
	intervals.append(interval)
	
def format_output(i, output):
	return re.sub('\|S-chain\|-<>-|127.0.0.1:9050|-<><>-|\(UNKNOWN\)\s\[.+\]\s|\open\s:\sOperation\snow\sin\sprogress|.+timeout\n|.+OK\n', '', output)

def analyze_results(i, nc):

	if 'open' in nc:
		formatted = format_output(i, nc)
		# TODO if there is an open port on 80 or 23, go ahead and make a wget request
		# TODO if there is an active machine go ahead and scan for higher ports
		results.append('-------- IP: {}.{} ---------------\n{}'.format(net, i, formatted))
	tick_counters()

def tick_counters():
	global interval_analyzed_results_count
	global interval_execution_index
	global nc_processes

	interval_analyzed_results_count += 1

	if interval_analyzed_results_count == interval_step:
		interval_analyzed_results_count = 0
		interval_execution_index += 1
		nc_processes = []

		if interval_execution_index < len(intervals):
			execute_interval(intervals[interval_execution_index])
	
def execute_interval(interval):
	print('Running scans on IPs {}.{} to {}.{} in parallel....'.format(net, interval[0], net, interval[1]))

	for i in range(interval[0], interval[1]):
		# (-v) running verbosely (-v on Linux, -vv on Windows),
		# (-n) not resolving names. numeric only IP(no D.S)
		# (-z) without sending any data. zero-I/O mode(used for scanning)
		#(-w1) waiting no more than 1second for a connection to occur
		

		nc_args = ['nc', '-n', '-v', '-z', '-w1', '{}.{}'.format(net, i)] +  ports.split(' ')
		
		nc_processes.append([i, sub.Popen(nc_args, stdout=sub.PIPE, stderr=sub.PIPE, universal_newlines=True)])

	for proc in nc_processes:
		proc[1].wait()
		nc_out, nc_errs = proc[1].communicate()
		analyze_results(proc[0], nc_errs)


execute_interval(intervals[interval_execution_index])
	

print('\n-------- Final Rollup ---------------\n')
for res in results:
	print(res)
