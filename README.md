# Detailed Route Inspection Protocol simulation

A protocol design project for EEE4121F-B 
Author: Dillon Heald - HLDDIL001

Acknowledgement and reference: A number of items from this project's implementation were adapted from the outputs of the Multi-hop route inspection exercise in P4.
For further works relating to the source of what this project is based on, please refer to the following P4 tutorial repository [here.](https://github.com/davidcawork/P4Tutorial "P4 Tutorial")

## Execution
To execute, run the "run.sh" script using ```bash sudo ./run.sh ```. This will run the simulation and upon closing the mininet terminal, stop the mininet background session.

## Mininet Setup
Once mininet is running, simply type "pingall" to verify end to end connectivity.
Thereafter, execute xterms on all hosts by running
```bash
 xterm h1 h11 h2 h22
```
In the mininet terminal which will spawn shells on each host.

## DRIP usage
To send a series of DRIP packets, the sending and receiving scripts must be executed on both the Host Under Test (HUT) and the Problematic Host Under Test (PHUT). To do so, first run the receive script on the PHUT by executing:
```bash
./receiveDRIP.py
```
Once the terminal is ready, execute the sending script with the relevant information of the PHUT on the HUT by:
```bash
./sendDRIP.py <PHUT_IP_ADDRESS> "<DEBUG_MESSAGE>" <TIME>
```
One should see the switch ID, queue length and queue time of each switch the packet went through in the network to reach the PHUT.
The fields in the <> should be replaced with the described information (without the <>). For example:
```bash
./sendDRIP.py 10.0.2.2 "Sending DRIP to h2 from h1" 15
```
## Experimentation
To demonstrate how this could be useful in debugging a network, a load can be simulated on the network. 
To do so, execute the receive and send scripts as above, however; once packets are being received, load the network with a iperf test:
On host h22 execute the following to setup the iperf server:
```bash
iperf -s -u
```
To setup the iperf client, execute the following on h11:
```bash
iperf -c 10.0.2.22 -t 10 -u
```
This will stress the network for 10 seconds and you should see the queue times (in micro seconds) and queue depth at switch 1 increase.

Upon completion of the test; the results will be written to a file titled "DRIPout.csv" in the Output directory. This csv will contain the DRIP information relating to each switch including queue time and queue depth.

## Closing
Type exit to close the mininet terminal

Note: If you didn't execute the program with the "run.sh" bash script, the following applies:
Once back at the bash terminal run "make stop" to close the background mininet process if you didn't run "run.sh".

If you wish to clean the directory, type "make clean" to clear the directory of all captures and logs.
