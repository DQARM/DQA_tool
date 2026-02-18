from trex_stl_lib.api import *
import argparse
import random

class STLS1(object):

    def __init__ (self):
        self.fsize = 64

    def create_pkt_base (self, direction):
        # 1. 定義原始 IP
        ip_src = "192.168.3.230"
        ip_dst = "192.168.3.231"

        # 2. 如果是反向流量 (direction=1)，交換 IP
        if direction == 1:
            ip_src, ip_dst = ip_dst, ip_src

        # 3. 回傳封包
        return Ether()/IP(src=ip_src, dst=ip_dst)/UDP(dport=12, sport=1025)

    def create_stream (self, direction):
        # 計算 Padding 大小 (總長度 - FCS 4 bytes)
        size = self.fsize - 4
        base_pkt = self.create_pkt_base(direction)
        pad = max(0, size - len(base_pkt)) * 'x'
        
        # 定義 VM (Field Engine) 來隨機化 Port
        vm = [
            # 隨機 Source Port (1024-65535)
            STLVmFlowVar(name="sport_f", min_value=1024, max_value=65535, size=2, op="random"),
            STLVmWrFlowVar(fv_name="sport_f", pkt_offset="UDP.sport"),

            # 隨機 Destination Port (1024-65535)
            STLVmFlowVar(name="dport_f", min_value=1024, max_value=65535, size=2, op="random"),
            STLVmWrFlowVar(fv_name="dport_f", pkt_offset="UDP.dport"),

            # 自動修正 Checksum
            STLVmFixChecksumHw(l4_type=CTRexVmInsFixHwCs.L4_TYPE_UDP, l3_offset=14, l4_offset=34)
        ]

        pkt = STLPktBuilder(pkt=base_pkt/pad, vm=vm)
        #pkt = STLPktBuilder(pkt=base_pkt/pad, vm=[])
        return STLStream(packet=pkt, mode=STLTXCont())

    def get_streams (self, direction=0, tunables=[], **kwargs):
        parser = argparse.ArgumentParser(description='Argparser for {}'.format(os.path.basename(__file__)), 
                                         formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        args = parser.parse_args(tunables)
        
        # 傳遞 direction 參數給 create_stream
        return [ self.create_stream(direction) ]

def register():
    return STLS1()
