#!/usr/bin/env python3

import subprocess as sub
import re
import time
from html.parser import HTMLParser
from itertools import chain

intervals = []
interval_creation_i = 0

interval_execution_index = 0
nc_processes = []
interval_analyzed_results_count = 0
results = []
valid_net = False
time0 = time.time()

class LinkParser(HTMLParser):
	def reset(self):
		HTMLParser.reset(self)
		self.link = ''

	def handle_starttag(self, tag, attrs):
		if tag == 'a':
			for name, value in attrs:
				if name == 'href':
					self.link = re.sub('\.\/', '', value)
                    

while not valid_net:
	try:
		net = input('1) Enter network address with only 3 octets (e.g. 192.168.0): ') or '192.168.0'
		split_net = net.split('.')
		valid_octets = len([i for i in net.split('.') if i.isdigit()]) == len(split_net)

		if len(split_net) != 3 or not valid_octets:
			print('1) Your network address must have three valid octets... {} is invalid'.format(net))
		else:
			valid_net = True
	except ValueError as e:
		print('1) You did not enter in a valid network address')

valid_start = False
while not valid_start:
	try:
		start = input('2) Enter starting host range less than 254 (e.g. 1): ') or '1'
		
		if int(start) > 254:
			print('2) Your starting range must be less than 254')
		else:
			valid_start = True
	except ValueError as e:
		print('2) Your starting range is not valid')

valid_end = False
while not valid_end:
	try:
		end = input('3) Enter ending host range (e.g. 254): ') or '254'
		if int(end) > 254:
			print('3) Your ending host range must be less than 254')
		elif int(end) < int(start):
			print('3) Your ending host range must be greater than your start at {}'.format(start))
		else:
			valid_end = True
	except ValueError as e:
		print('Your ending host range must be a number')

# TODO add validation
ports = input('4) Enter ports space-delimited (e.g. 20 21 22 23 80): ') or '20 21 22 23 80'
# TODO add validation
interval_step = input('5) Enter the batch size for parallel execution. (default: 25)\n   (note: the larger the batch size, the more likely the target IP \n   will be unable to handle requests and drop connections.)') or '25'
interval_step = int(interval_step)
# TODO add validation
pause_time = input('6) Enter the desired pause time in seconds between intervals to try and prevent\n   too many open ssh connections. (defaults to 10) ') or '10'
pause_time = int(pause_time)

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
	return re.sub('\|S-chain\|-<>-|127.0.0.1:9050|-<><>-.+\(UNKNOWN\).+|\(UNKNOWN\)\s\[.+\]\s|open\s:\sOperation\snow\sin\sprogress|.+timeout\n|.+OK\n', '', output)

def analyze_results(i, nc):
	if 'open' in nc:
		wget_data = ''

		formatted = format_output(i, nc)
		# TODO if there is an open port on 80 or 23, go ahead and make a wget request
		# TODO if there is an active machine go ahead and scan for higher ports
		

		if '80 (http)' in formatted:
			wget_data = wget_http('{}.{}'.format(net, i))
	
		results.append('-------- IP: {}.{} ----------------\n{}'.format(net, i, formatted + wget_data))

	tick_counters()

def wget_http(ip):
	wget_res = sub.run(['wget', '-qO-', ip], stdout=sub.PIPE, stderr=sub.PIPE, universal_newlines=True)
	
	wget_res = '--- WGET response from Port 80:\n' + re.sub('^.+<>.+$\n', '', wget_res.stdout)

	if '<a href' in wget_res:
		parser = LinkParser()
		gen_link(wget_res, parser)
		
		wget_res += '-- Suggested additional request: `wget {}/{}\n'.format(ip, parser.link)
		parser.reset()

	return wget_res


def gen_link(f, parser):
    for line in f:
        parser.feed(line)

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
			if pause_time > 0:
				print('----- Pausing for {} seconds to try and avoid ssh sitting with too many open connections...\n'.format(pause_time))
				time.sleep(pause_time)
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

print('\nAll your IPs are belong to us...\n')
execute_interval(intervals[interval_execution_index])
	
time1 = time.time() - time0
print('\n-------- Final Rollup --------------------')
print('-------- Total Scan Time: {} ----------'.format(time.strftime("%M:%S", time.gmtime(time1))))
for res in results:
	print(res)
