//
//  Frame.h
//  BroadcastUploadNew
//
//  Created by Anirban on 2/19/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Frame : NSObject
@property uint64_t timestamp;
@property NSData *jpegData;
@end
