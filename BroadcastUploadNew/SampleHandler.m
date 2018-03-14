//
//  SampleHandler.m
//  BroadcastUploadNew
//
//  Created by Anirban on 2/12/18.
//  Copyright © 2018 Anirban. All rights reserved.
//


#import "SampleHandler.h"
#import "Encoder.h"
#import "SenderBuffer.h"
#import "Streamer.h"
#import "TimeManager.h"

@interface SampleHandler()
{
    Encoder *encoder;
    int screenWidth, screenHeight;
    SenderBuffer *senderBuffer;
    NSThread *streamerThread;
    Streamer *streamer;
    TimeManager *timeManager;
}
@end
char *ip = "172.20.10.14";
int port = 32000;
int bufferSize = 30;
@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    
    [self createSenderBufferWithSize:bufferSize];
    [self initializeEncoder];
    [self createStreamer];
    [self createStreamerThread];
    [self startStreamingThread];
    [self createTimeManager];
}

-(void)createStreamer
{
    streamer = [[Streamer new] createStreamerWithWatcherIP:ip port:port senderBuffer:senderBuffer];
}

-(void)createStreamerThread
{
    streamerThread = [[NSThread alloc] initWithTarget:self selector:@selector(startStreaming) object:nil];
}

-(void)startStreamingThread
{
    [streamerThread start];
}

-(void)startStreaming
{
    [streamer stream];
}


-(void)initializeEncoder
{
    encoder = [Encoder new];
    
    screenWidth = [[UIScreen mainScreen] bounds].size.width;
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    [encoder initEncoder:screenWidth height:screenHeight senderBuffer:senderBuffer];
}

-(void)createSenderBufferWithSize:(int)size
{
    senderBuffer = [[SenderBuffer new] initWithSize:size];
}

- (void)createTimeManager{
    timeManager = [TimeManager sharedManager];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            grabber_ts = [timeManager getTimestamp];
            [encoder encode:sampleBuffer];
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

@end
