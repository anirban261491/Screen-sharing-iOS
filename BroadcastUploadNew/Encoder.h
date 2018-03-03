//
//  Encoder.h
//  BroadcastUploadNew
//
//  Created by Anirban on 2/12/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "SenderBuffer.h"
@interface Encoder : NSObject
-(void) initEncoder: (int) width height: (int) height senderBuffer:(SenderBuffer*)buffer;
- (void) encode:(CMSampleBufferRef)sampleBuffer;

@end
