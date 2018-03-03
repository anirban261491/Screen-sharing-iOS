//
//  Streamer.h
//  BroadcastUploadNew
//
//  Created by Anirban on 2/26/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SenderBuffer.h"

@interface Streamer : NSObject
-(void)stream;
-(Streamer *)createStreamerWithWatcherIP:(char*)ip port:(int)port senderBuffer:(SenderBuffer *)buffer;
@end
