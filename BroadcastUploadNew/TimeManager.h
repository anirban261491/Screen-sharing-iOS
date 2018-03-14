//
//  Timestamp.h
//  BroadcastUploadNew
//
//  Created by Anirban on 3/14/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeManager : NSObject
extern uint64_t init_ts;
extern uint64_t grabber_ts;

+ (id)sharedManager;
- (uint64_t)getTimestamp;


@end
