//
//  Encoder.m
//  BroadcastUploadNew
//
//  Created by Anirban on 2/12/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import "Encoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>
#import "TimeManager.h"
#import "Frame.h"
@interface Encoder()
{
    VTCompressionSessionRef encodingSession;
    SenderBuffer *senderBuffer;
}
@end

@implementation Encoder

-(void) initEncoder: (int) width height: (int) height senderBuffer:(SenderBuffer *)buffer
{
    OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_JPEG, NULL, NULL, NULL, NULL, NULL,  &encodingSession);
    NSLog(@"H264: VTCompressionSessionCreate %d", (int)status);
    
    if (status != 0)
    {
        NSLog(@"H264: Unable to create a H264 session");
        return ;
    }
    VTSessionSetProperty(encodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    senderBuffer = buffer;
}

- (void) encode:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    Frame *f = [Frame new];
    f.timestamp = grabber_ts - init_ts;
    
    VTEncodeInfoFlags flags;
    
    VTCompressionSessionEncodeFrameWithOutputHandler(encodingSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, &flags, ^(OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef  _Nullable sampleBuffer) {
        
        if (status != noErr) {
            NSLog(@"JPEG: VTCompressionSessionEncodeFrame failed with %d", (int)status);
            
            // End the session
            VTCompressionSessionInvalidate(encodingSession);
            CFRelease(encodingSession);
            encodingSession = NULL;
            return;
        }
        
        if (!CMSampleBufferDataIsReady(sampleBuffer))
        {
            NSLog(@"jpeg data is not ready ");
            return;
        }
        
        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t length, totalLength;
        char *dataPointer;
        OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
        if(statusCodeRet == kCMBlockBufferNoErr)
        {
            f.jpegData = [[NSData alloc] initWithBytes:dataPointer length:totalLength];
            //UIImage *image = [UIImage imageWithData:jpegData];
            if(![senderBuffer isFull])
                [senderBuffer enQueue:f];
        }
    });
    
}




@end
