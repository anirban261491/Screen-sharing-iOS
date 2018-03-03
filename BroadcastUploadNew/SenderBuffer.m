
//
//  SenderBuffer.m
//  BroadcastUploadNew
//
//  Created by Anirban on 2/13/18.
//  Copyright © 2018 Anirban. All rights reserved.
//

#import "SenderBuffer.h"

@interface SenderBuffer()
{
    int front, rear;
    int size;
    NSMutableArray *arr;
    
}
@end
@implementation SenderBuffer

-(SenderBuffer*) initWithSize:(int)s
{
    front = rear = 0;
    size = s;
    arr = [[NSMutableArray alloc] initWithCapacity:s];
    return self;
}

-(BOOL)isEmpty
{
    return front == rear ? TRUE : FALSE;
}

-(BOOL)isFull
{
    return (rear + 1) % size == front ? TRUE : FALSE;
}

-(void)enQueue:(NSData *)jpegData
{
    if(arr.count < size)
    {
        [arr addObject:(jpegData)];
    }
    else
    {
        arr[rear] = (jpegData);
    }
    rear = (rear + 1) % size;
}

-(NSData *)deQueue
{
    NSData *jpegData = [arr objectAtIndex:front];
    front = (front + 1) % size;
    return jpegData;
}


// Not needed now

//-(CVPixelBufferRef)copyImageBuffer:(CVImageBufferRef)imageBuffer
//{
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    OSType format = CVPixelBufferGetPixelFormatType(imageBuffer);
//    CVPixelBufferRef pixelBufferCopy;
//    CVReturn status = CVPixelBufferCreate(nil, width, height, format, nil, &pixelBufferCopy);
//    if(status == kCVReturnSuccess)
//    {
//        status = CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
//        status = CVPixelBufferLockBaseAddress(pixelBufferCopy, 0);
//        for(int plane = 0; plane < CVPixelBufferGetPlaneCount(imageBuffer); plane ++)
//        {
//            void* destination = CVPixelBufferGetBaseAddressOfPlane(pixelBufferCopy, plane);
//            void* source = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, plane);
//            size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, plane);
//            size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, plane);
//            memcpy(destination, source, height * bytesPerRow);
//        }
//        CVPixelBufferUnlockBaseAddress(pixelBufferCopy, 0);
//        CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
//    }
//    return pixelBufferCopy;
//}


@end
