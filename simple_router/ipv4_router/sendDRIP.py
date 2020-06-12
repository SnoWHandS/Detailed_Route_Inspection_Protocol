#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import Ether, IP, UDP, TCP

#Import libraries for handeling header fields
from scapy.all import IntField, FieldListField, FieldLenField, ShortField, PacketListField
from scapy.layers.inet import _IPOption_HDR

#Import time for sleeping
from time import sleep

def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface

#Create a class to hold switch trace information
class SwitchTrace(Packet):
    fields_desc = [ IntField("swid", 0),
                  IntField("qdepth", 0),
                  IntField("qtdelta", 0)]
    def extract_padding(self, p):
                return "", p

#Create a calls to handle IPOptions header
class IPOption_DRIP(IPOption):
    name = "DRIP"
    option = 13
    fields_desc = [ _IPOption_HDR,
                    FieldLenField("length", None, fmt="B",
                                  length_of="swtraces",
                                  adjust=lambda pkt,l:l*2+4),
                    ShortField("count", 0),
                    PacketListField("swtraces",
                                   [],
                                   SwitchTrace,
                                   count_from=lambda pkt:(pkt.count*1)) ]











def main():

    if len(sys.argv)<3:
        print 'pass 2 arguments: <destination> "<message>"'
        exit(1)

    addr = socket.gethostbyname(sys.argv[1])
    iface = get_if()

    print "sending on interface %s to %s" % (iface, str(addr))
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    pkt = pkt /IP(dst=addr, options =IPOption_DRIP(count=0,swtraces=[])) / UDP(dport=4321, sport=1234) / sys.argv[2] #random.randint(49152,65535) for sport
    pkt.show2()

    #Wrap this in a repeated loop for how long the timer indicates
    try:
      for i in range(int(sys.argv[3])):
        sendp(pkt, iface=iface)
        sleep(1)
    except KeyboardInterrupt:
        raise

if __name__ == '__main__':
    main()
