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
    OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264    , NULL, NULL, NULL, NULL, NULL,  &encodingSession);
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
    
    VTEncodeInfoFlags flags;
    
    VTCompressionSessionEncodeFrameWithOutputHandler(encodingSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, &flags, ^(OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef  _Nullable sampleBuffer) {
        
        if (status != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)status);
            
//            // End the session
//            VTCompressionSessionInvalidate(encodingSession);
//            CFRelease(encodingSession);
//            encodingSession = NULL;
            return;
        }
        
        if (!CMSampleBufferDataIsReady(sampleBuffer))
        {
            NSLog(@"H264 data is not ready ");
            return;
        }
        
        Frame *f = [Frame new];
        f.frame_seg = [NSMutableArray new];
        f.frame_size = 0;
        
        // Check if we have got a key frame first
        bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
        
        if (keyframe)
        {
            CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
            
            size_t sparameterSetSize, sparameterSetCount;
            const uint8_t *sparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                // Found sps and now check for pps
                size_t pparameterSetSize, pparameterSetCount;
                const uint8_t *pparameterSet;
                OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
                if (statusCode == noErr)
                {
                    // Found pps
                    NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                    NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                    
                    f.frame_size += sparameterSetSize + pparameterSetSize;
                    
                    [f.frame_seg addObject:sps];
                    [f.frame_seg addObject:pps];
                }
            }
        }
        
        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t length, totalLength;
        char *dataPointer;
        OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
        if (statusCodeRet == noErr) {
            
            size_t bufferOffset = 0;
            static const int AVCCHeaderLength = 4;
            while (bufferOffset < totalLength - AVCCHeaderLength) {
                
                // Read the NAL unit length
                uint32_t NALUnitLength = 0;
                memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
                
                // Convert the length value from Big-endian to Little-endian
                NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
                
                NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
                
                f.frame_size += NALUnitLength;
                [f.frame_seg addObject:data];
                
                // Move to the next NAL unit in the block buffer
                bufferOffset += AVCCHeaderLength + NALUnitLength;
            }
        }
        f.fid = 0;
        f.packet_size = 0;
        f.total_packets = 0;
        f.nr_segs = f.frame_seg.count;
        [senderBuffer enQueue:f];
    });
    
}




@end
