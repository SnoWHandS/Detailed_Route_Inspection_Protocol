#!/bin/bash
#first arg is the ip of the destination Iperf server

#stress network for 15 for given IP

echo "running 1st test"
iperf -c $1 -t 15 -u
echo "sleeping"
sleep 15
echo "running 2nd test"
iperf -c $1 -t 15 -u
echo "sleeping"
sleep 20
echo "running 3rd test"
iperf -c $1 -t 15 -u
echo "sleeping"
sleep 25
echo "running 4th test"
iperf -c $1 -t 15 -u

#total runtime is 120 seconds

echo "stress test complete"
