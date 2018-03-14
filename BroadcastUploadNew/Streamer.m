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
    for (fid = 0; ; fid++) {
        
        //uint64_t expected_streamer_ts = init_ts + period * fid;
        
        //uint64_t streamer_ts = get_us();
        
        //Grab JPEG data
        
        NSData *jpegData;
        if(![senderBuffer isEmpty])
        {
            @autoreleasepool{
                jpegData = [senderBuffer deQueue];
            }
        }
        
        //uint64_t grabber_ts = get_us();
        
        size_t frame_len_encoded = [jpegData length];

        //uint64_t encoder_ts = get_us();
        __block unsigned char *frame_buffer_final = NULL;
        [jpegData enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
            frame_buffer_final = (unsigned char *)bytes;
        }];
        
        uint32_t frame_size_final = frame_len_encoded;
        uint32_t total_packets = frame_size_final / packet_size_default
        + (frame_size_final % packet_size_default > 0);
        
        int ret = send_frame(fid, frame_buffer_final, frame_size_final, packet_size_default, watcher_fd, watcher_addr);
        
        if (ret < 0) {
            
            NSLog(@"error in send_frame()!!!");
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

int send_frame(uint32_t fid, unsigned char *frame, uint32_t frame_size, uint32_t packet_size,
               int watcher_fd, struct sockaddr_in watcher_addr) {
    
    // segment the frame, attach header, and send the frame to the designated address
    int ret = 0;
    uint32_t packet_id = 0;
    uint32_t total_packet = frame_size / packet_size + (frame_size % packet_size > 0);
    uint32_t remain = frame_size;
    uint32_t offset = 0;
    uint32_t len = (remain >= packet_size) ? packet_size : remain;
    
    char packet_buffer[64 * 1024];
    
    // UDP packet has the maximum payload size 64K, and here we reserve 64B for the header.
    if (packet_size > 64 * 1023)
        return -1;
    
    while(offset < frame_size) {
        
        // fill the packet header
        struct frame_packet *packet = (struct frame_packet *)packet_buffer;
        
        packet->hdr.magic = PACKET_MAGIC;
        packet->hdr.type = PACKET_TYPE_FRAME;
        packet->hdr.length = sizeof(struct frame_packet) + len;
        
        packet->fid = fid;
        packet->total_length = frame_size;
        packet->pid = packet_id;
        packet->total_packets = total_packet;
        packet->offset = offset;
        packet->length = len;
        
        memcpy(packet->data, frame + offset, len);
        
        NSData *data = [NSData dataWithBytes:packet length:len];
        
        ret = sendto(watcher_fd, packet, len + sizeof(struct frame_packet), 0,
                     (struct sockaddr *) &watcher_addr, sizeof(watcher_addr));
        
        uint64_t sender_ts = get_us();
        
        //printf("%d / %d, %d, %s\n", offset, frame_size, ret, strerror(errno));
        
        if (ret <= 0) {
            
            // TODO: handle error
            printf("error in send_frame(): %d, %s\n", ret, strerror(errno));
            return ret;
        }
        
        
        packet_id++;
        remain -= len;
        offset += len;
        len = (remain >= packet_size) ? packet_size : remain;
        
        
    }
    
    
    return packet_id;
}


static inline uint64_t get_us() {
    
    struct timespec spec;
    
    clock_gettime(CLOCK_MONOTONIC, &spec);
    
    uint64_t s  = spec.tv_sec;
    uint64_t us = spec.tv_nsec / 1000 + s * 1000 * 1000;
    
    return us;
}

@end
