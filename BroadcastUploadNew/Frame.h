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
@property CVImageBufferRef imageBuffer;
@property CMTime presentationTime;
-(Frame*)createFrameWithImageBuffer:(CVImageBufferRef)imageBuffer AndPresentationTime:(CMTime)presentationTime;
-(void)destroyFrame;
@end
