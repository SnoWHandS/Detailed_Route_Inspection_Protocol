#!/usr/bin/env python
import sys
import struct
import os
import re

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import PacketListField, ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import IP, TCP, UDP, Raw
from scapy.layers.inet import _IPOption_HDR

DRIPdata = []

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface

def writeToCSV(DRIPPackets):
    file = open("./Output/DRIPout.csv", "w")
    file.write("Switch 2,Switch 1\n")

    #[<IPOption_DRIP  copy_flag=0L optclass=control option=flow_control length=28 count=2 swtraces=[<SwitchTrace  swid=2 qdepth=0 qtdelta=32 |>, <SwitchTrace  swid=1 qdepth=0 qtdelta=46 |>] |>]


    for i in range(1,len(DRIPPackets)):
        #Convert to string
        DRIPinfo = str(DRIPPackets[i])
        #write to csv file
        file.write(str(DRIPinfo[DRIPinfo.find("<SwitchTrace"):-1])+"\n")

#Same classes as in sendDRIP.py
class SwitchTrace(Packet):
    fields_desc = [ IntField("swid", 0),
                  IntField("qdepth", 0),
                  IntField("qtdelta", 0)]
    def extract_padding(self, p):
                return "", p

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

def handle_pkt(pkt):
    print "got a packet"
    if pkt.haslayer(IP):
        #print pkt[IP].options
        DRIPdata.append(pkt[IP].options)
    pkt.show2()     
    sys.stdout.flush()


def main():
    ifaces = filter(lambda i: 'eth' in i, os.listdir('/sys/class/net/'))
    iface = ifaces[0]
    print "sniffing on %s" % iface
    sys.stdout.flush()
    sniff(filter="udp and port 4321", iface = iface,
          prn = lambda x: handle_pkt(x))
    writeToCSV(DRIPdata)

if __name__ == '__main__':
    main()
