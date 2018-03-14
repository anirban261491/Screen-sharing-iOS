//
//  Timestamp.m
//  BroadcastUploadNew
//
//  Created by Anirban on 3/14/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import "TimeManager.h"

@implementation TimeManager

uint64_t init_ts = 0;
uint64_t grabber_ts = 0;

+ (id)sharedManager {
    static TimeManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        init_ts = get_us();
    }
    return self;
}

- (uint64_t)getTimestamp
{
    return get_us();
}

static inline uint64_t get_us() {
    
    struct timespec spec;
    
    clock_gettime(CLOCK_MONOTONIC, &spec);
    
    uint64_t s  = spec.tv_sec;
    uint64_t us = spec.tv_nsec / 1000 + s * 1000 * 1000;
    
    return us;
}
@end
