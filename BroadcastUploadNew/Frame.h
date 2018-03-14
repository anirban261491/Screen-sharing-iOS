//
//  Frame.h
//  BroadcastUploadNew
//
//  Created by Anirban on 2/19/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
@interface Frame : NSObject
@property int fid;
@property uint32_t frame_size;
@property uint32_t packet_size;
@property uint32_t total_packets;
@property NSMutableArray *frame_seg;
@property int nr_segs;
@end
