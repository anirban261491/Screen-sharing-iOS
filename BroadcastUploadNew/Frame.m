//
//  Frame.m
//  BroadcastUploadNew
//
//  Created by Anirban on 2/19/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import "Frame.h"

@implementation Frame
-(Frame*)createFrameWithImageBuffer:(CVImageBufferRef)imageBuffer AndPresentationTime:(CMTime)presentationTime
{
    _imageBuffer = imageBuffer;
    _presentationTime = CMTimeMake(presentationTime.value, presentationTime.timescale);
    return self;
}

-(void)destroyFrame
{
    CFRelease(_imageBuffer);
}

@end
