# eee4121f-b-lab2

Protocol design project for EEE4121F-B

Dillon Heald - HLDDIL001

## Execution
To execute, run the "run.sh" script using ```bash sudo ./run.sh ```. This will run the simulation and upon closing the mininet terminal, stop the mininet background session.

## Mininet Setup
Once mininet is running, simply type "pingall" to verify end to end connectivity.
Thereafter, execute xterms on all hosts by running
```bash
 xterm h1 h2 h3 h4
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
./sendDRIP.py 10.0.4.4 "Sending DRIP to h4 from h1" 15
```
## Experimentation
To demonstrate how this could be useful in debugging a network, a load can be simulated on the network.
TODO: Describe how to use iperf to stress the network

## Closing
Type exit to close the mininet terminal

Note: If you didn't execute the program with the "run.sh" bash script, the following applies:
Once back at the bash terminal run "make stop" to close the background mininet process if you didn't run "run.sh".

If you wish to clean the directory, type "make clean" to clear the directory of all captures and logs.
