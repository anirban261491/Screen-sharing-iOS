//
//  Streamer.m
//  BroadcastUploadNew
//
//  Created by Anirban on 2/26/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import "Streamer.h"
#import <netinet/in.h>
#import <arpa/inet.h>
#import <UIKit/UIKit.h>
#import "Frame.h"
@interface Streamer()
{
    char *watcher_ip;
    int watcher_port;
    SenderBuffer *senderBuffer;
    int fps;
    int period;
}
@end

#define PACKET_MAGIC          0x87654321
#define PACKET_TYPE_FRAME    0x01

const unsigned int packet_size_default = 1024;
const unsigned int packet_per_frame_max = 256;

struct packet_header {
    
    uint32_t magic;            // magic number
    uint16_t type;            // type of this packet
    uint16_t length;        // length of this packet, including the header
    
};

struct frame_packet {
    
    struct packet_header hdr;
    
    uint32_t fid;                // frame ID
    uint32_t total_length;        // total length of this frame for transmission in byte
    
    uint32_t pid;                // packet ID
    uint32_t total_packets;        // total number of packets
    uint32_t offset;            // offset of this packet in the frame in byte
    uint32_t length;            // payload length of this packet
    
    uint64_t timestamp;
    uint64_t flag;
    
    char data[0];                // "pointer" to the payload
};

@implementation Streamer

-(Streamer *)createStreamerWithWatcherIP:(char*)ip port:(int)port senderBuffer:(SenderBuffer *)buffer
{
    watcher_ip = ip;
    watcher_port = port;
    senderBuffer = buffer;
    fps = 15;
    period = 1000000 / fps;
    return self;
}

-(void)stream
{
    struct sockaddr_in watcher_addr;
    int watcher_fd;
    // prepare regular wake up
    // CAUTION: always sleep 1ms as an small interval
    struct timespec idle;
    idle.tv_sec = 0;
    idle.tv_nsec = 1000 * 1000;
    
    
    // prepare the UDP socket
    watcher_fd = socket(AF_INET, SOCK_DGRAM, 0);
    
    memset(&watcher_addr, 0, sizeof(watcher_addr));
    watcher_addr.sin_family = AF_INET;
    watcher_addr.sin_addr.s_addr = inet_addr(watcher_ip);
    watcher_addr.sin_port = htons(watcher_port);
    
    uint64_t init_ts = get_us();
    uint32_t fid;
    uint32_t pid_offset;
    uint32_t byte_offset;
    
    for (fid = 0; ; fid++) {
        
        //uint64_t expected_streamer_ts = init_ts + period * fid;
        
        //uint64_t streamer_ts = get_us();
        
        //Grab JPEG data
        
        Frame *f;
        if(![senderBuffer isEmpty])
        {
            @autoreleasepool{
                f = [senderBuffer deQueue];
            }
        }
        else
        {
            fid --;
            continue;
        }
        
        f.fid = fid;
        
        
        int ret = send_frame(f, watcher_fd, watcher_addr);
        if (ret < 0) {
            
            NSLog(@"Error in send_frame()");
        }
        
        
        //uint64_t sender_ts = get_us();
        
        uint64_t next_streamer_ts = init_ts + period * (fid + 1);
        uint64_t ts = get_us();
        
        while(ts < next_streamer_ts) {
            
            nanosleep(&idle, NULL);
            ts = get_us();
        }
    }
}

int send_frame(Frame *f, int watcher_fd, struct sockaddr_in watcher_addr) {
    
    uint32_t pid_offset = 0;
    uint32_t byte_offset = 0;
    
    if(f.frame_size == 0)
    {
        send_empty_frame(f, watcher_fd, watcher_addr);
        pid_offset++;
    }
    else
    {
        int packet_size = packet_size_default;
        f.packet_size = packet_size;
        int total_packets = 0;
        for (int i = 0; i < f.nr_segs; i++) {
            
            int seg_size = [f.frame_seg[i] length];
            total_packets += seg_size / packet_size + (seg_size % packet_size > 0);
        }
        
        if (total_packets == 0)
            total_packets = 1;

        for (int i = 0; i < f.nr_segs; i++) {
            int nr_packets_sent = send_frame_seg(f, pid_offset, byte_offset, i, watcher_fd, watcher_addr);
            pid_offset += nr_packets_sent;
            byte_offset += [f.frame_seg[i] length];
        }
    }
    
    return (int) pid_offset;
}


int send_empty_frame(Frame *f, int watcher_fd, struct sockaddr_in watcher_addr) {
    
    struct frame_packet packet_buffer;
    struct frame_packet *packet = &packet_buffer;
    
    uint32_t fid = f.fid;
    
    packet->hdr.magic = PACKET_MAGIC;
    packet->hdr.type = PACKET_TYPE_FRAME;
    packet->hdr.length = sizeof(struct frame_packet);
    
    packet->fid = fid;
    packet->total_length = 0;
    packet->pid = 0;
    packet->total_packets = 1;
    packet->offset = 0;
    packet->length = 0;
    
    // To do - add timestamp
    packet->timestamp =  0;
    
    
    int ret = sendto(watcher_fd, packet, sizeof(struct frame_packet), 0,
                     (struct sockaddr *) &watcher_addr, sizeof(watcher_addr));
    
    
    //uint64_t sender_ts = get_us();
    
    //printf("%d / %d, %d, %s\n", offset, frame_size, ret, strerror(errno));
    
    if (ret <= 0) {
        
        // TODO: handle error
        printf("error in send_frame(): %d, %s\n", ret, strerror(errno));
        return ret;
    }
    
    // record packet meta data
//    if (fid < fmeta_size) {
//
//        struct fb_meta *fm = fmeta + fid;
//        struct packet_meta *pm = fm->pmeta;
//
//        pm->fid = fid;
//        pm->pid = 0;
//        pm->state = 1;
//        pm->offset = 0;
//        pm->pad = 0;
//        pm->length = 0;
//
//        pm->sender_ts = sender_ts;
//
//    }
    
    return 0;
}

int send_frame_seg(Frame *f, uint32_t pid_offset, uint32_t byte_offset, int seg_id, int watcher_fd, struct sockaddr_in watcher_addr) {
    
    
    int ret = 0;
    uint32_t fid = f.fid;
    uint32_t packet_id = pid_offset;
    uint32_t seg_size = [f.frame_seg[seg_id] length];
    uint32_t packet_size = f.packet_size;
    uint32_t nr_packet = seg_size / packet_size
    + (seg_size % packet_size > 0);
    uint32_t remain = seg_size;
    uint32_t frame_offset = byte_offset;
    uint32_t seg_offset = 0;
    uint32_t len = (remain >= packet_size) ? packet_size : remain;
    __block unsigned char *frame_seg_bytes = NULL;
    [f.frame_seg[seg_id] enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        frame_seg_bytes = (unsigned char *)bytes;
    }];
    
    
    char packet_buffer[64 * 1024];
    
    // UDP packet has the maximum payload size 64K, and here we reserve 64B for the header.
    if (packet_size > 64 * 1023)
        return -1;
    
    
    while (seg_offset < seg_size) {
        
        len = (remain >= packet_size) ? packet_size : remain;
        
        // fill the packet header
        struct frame_packet *packet = (struct frame_packet *) packet_buffer;
        
        packet->hdr.magic = PACKET_MAGIC;
        packet->hdr.type = PACKET_TYPE_FRAME;
        packet->hdr.length = sizeof(struct frame_packet) + len;
        
        packet->fid = fid;
        packet->total_length = f.frame_size;
        packet->pid = packet_id;
        packet->total_packets = f.total_packets;
        packet->offset = frame_offset;
        packet->length = len;
        
        //packet->timestamp =  f.timestamp;
        
        
        memcpy(packet->data, frame_seg_bytes + seg_offset, len);
        
        ret = sendto(watcher_fd, packet, len + sizeof(struct frame_packet), 0,
                     (struct sockaddr *) &watcher_addr, sizeof(watcher_addr));
        
        uint64_t sender_ts = get_us();
        
        //printf("%d / %d, %d, %s\n", offset, frame_size, ret, strerror(errno));
        
        if (ret <= 0) {
            
            // TODO: handle error
            printf("error in send_frame(): %d, %s\n", ret, strerror(errno));
            return ret;
        }
        
        // record packet meta data
//        if (fid < fmeta_size) {
//
//            struct fb_meta *fm = fmeta + fid;
//            struct packet_meta *pm = fm->pmeta + packet_id;
//
//            pm->fid = fid;
//            pm->pid = packet_id;
//            pm->state = 1;
//            pm->offset = frame_offset;
//            pm->pad = 0;
//            pm->length = len;
//
//            pm->sender_ts = sender_ts;
//
//        }
        
        packet_id++;
//        remain -= len;
//        frame_offset += len;
//        seg_offset += len;
        
        
    }
    
    return nr_packet;
}


static inline uint64_t get_us() {
    
    struct timespec spec;
    
    clock_gettime(CLOCK_MONOTONIC, &spec);
    
    uint64_t s  = spec.tv_sec;
    uint64_t us = spec.tv_nsec / 1000 + s * 1000 * 1000;
    
    return us;
}

@end
