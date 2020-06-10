/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<5>  IPV4_OPTION_DRIP = 13;

#define HOPS 9
/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

//DRIP types
typedef bit<32> switchID_t;
typedef bit<32> qdepth_t;
typedef bit<32> qtdelta_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}


//Create header to store ipv4 options fields
header ipv4_option_t {
    bit<1> copyFlag;
    bit<2> optClass;
    bit<5> option;
    bit<8> optionLength;
}

//Header for holding a counter
header drip_t {
    bit<16>  count;
}

//Header for holding DRIP switch metadata
header switch_t {
    switchID_t  swid;
    qdepth_t    qdepth;
    qtdelta_t   qtdelta;
}


//Store incoming count value
struct ingress_metadata_t {
    bit<16>  count;
}
//Store remaining values
struct parser_metadata_t {
    bit<16>  remaining;
}
//Hold all the metadatas in the metadata struct
struct metadata {
    ingress_metadata_t   ingress_metadata;
    parser_metadata_t   parser_metadata;
}

//Hold all the headers in the headers struct
struct headers {
    ethernet_t      ethernet;
    ipv4_t          ipv4;
    ipv4_option_t   ipv4_option;
    drip_t          drip;
    switch_t[HOPS]  swtraces;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        //Pull in the ethernet packet
        transition parse_Eth;
    }
    
    state parse_Eth {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        //Detect if the IPv4 Options field contains data
        transition select(hdr.ipv4.ihl){
            5           : accept;
            default     : parse_ipv4_option;
        }
    }

    //Handle the IPv4 Options header
    state parse_ipv4_option {
        packet.extract(hdr.ipv4_option);
        //Detect if Options filed indicates drip packet
        transition select(hdr.ipv4_option.option) {
            //If it does have DRIP information
            IPV4_OPTION_DRIP: parse_drip;
            default: accept;
        }
    }

    //Handle the DRIP header
    state parse_drip {
        packet.extract(hdr.drip);
        //Extract the count field
        meta.parser_metadata.remaining = hdr.drip.count;
        //If 0 counts remaining, move on, else; decrement and move on
        transition select(meta.parser_metadata.remaining) {
            0 : accept;
            default: parse_swtrace;
        }
    }

    //Handle the count remain handles
    state parse_swtrace {
        packet.extract(hdr.swtraces.next);
        meta.parser_metadata.remaining = meta.parser_metadata.remaining  - 1;
        transition select(meta.parser_metadata.remaining) {
            0 : accept;
            default: parse_swtrace;
        }
    }    
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        /* TODO: fill out code in action body */

        //Set egress port for next hop
        standard_metadata.egress_spec = port;
        //updates ethernet destination address of next hop
        hdr.ethernet.dstAddr = dstAddr;
        //updates ethernet source address with this switch
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        //decrememnt TTL
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }
    
    apply {
        if (hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    action add_swtrace(switchID_t swid){
        //Increment the drip count field
        hdr.drip.count = hdr.drip.count+1;
        hdr.swtraces.push_front(1);
        hdr.swtraces[0].setValid();
        //Assign metadata to fields
        hdr.swtraces[0].swid = swid;
        hdr.swtraces[0].qdepth = (qdepth_t)standard_metadata.deq_qdepth;
        hdr.swtraces[0].qtdelta = (qtdelta_t)standard_metadata.deq_timedelta;

        //Adjust header size counts and lengths
        hdr.ipv4.ihl = hdr.ipv4.ihl+3;  //Added 3 fields
        hdr.ipv4_option.optionLength = hdr.ipv4_option.optionLength + 12; //4*3 = 12
       	hdr.ipv4.totalLen = hdr.ipv4.totalLen + 12;
    }

    table swtrace {
        actions = {
            add_swtrace;
            NoAction;
        }
        default_action = NoAction();
    }
    apply{
        if (hdr.drip.isValid()){
            swtrace.apply();
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        //Need to additionally emit all the other fields we parsed
        packet.emit(hdr.ipv4_option);
        packet.emit(hdr.drip);
        packet.emit(hdr.swtraces);  
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
