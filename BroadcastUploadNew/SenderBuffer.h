//
//  SenderBuffer.h
//  BroadcastUploadNew
//
//  Created by Anirban on 2/13/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Frame.h"
@interface SenderBuffer : NSObject

-(SenderBuffer*) initWithSize:(int)s;
-(BOOL)isEmpty;
-(BOOL)isFull;
-(void)enQueue:(Frame *)jpegData;
-(Frame *)deQueue;

@end
