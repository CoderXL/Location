//
//  LocationFile.m
//  Location
//
//  Created by zhangjunbo on 14/12/17.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "LocationFile.h"

#import <pthread.h>
#import <objc/runtime.h>
#import <mach/mach_host.h>
#import <mach/host_info.h>
#import <libkern/OSAtomic.h>
#import <Availability.h>
#import <UIKit/UIDevice.h>

static dispatch_semaphore_t _queueSemaphore;

static dispatch_queue_t _locationFileQueue;

static void * kLocationFileQueueKey = "LocationFile";

@interface LocationFile ()


@end

@implementation LocationFile

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _locationFileQueue = dispatch_queue_create("com.zhangjunbo.locationfile", NULL);
        
        dispatch_queue_set_specific(_locationFileQueue, kLocationFileQueueKey, (void *)kLocationFileQueueKey, NULL);
        
        _queueSemaphore = dispatch_semaphore_create(1000);
    });
    
}

+ (LocationFile *)sharedFile {
    static LocationFile *sharedFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFile = [[LocationFile alloc] init];
    });
    return sharedFile;
}

- (BOOL)createLocationFile:(NSString *)filePath {
    
    BOOL result = YES;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        // create it
        result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        if (result) {
            JBLog(JL_ERROR, @"succ to creating LocationFile.txt");
        } else {
            JBLog(JL_DEBUG, @"error when creating LocationFile.txt");
        }
        
    }
    
    return result;
}

+ (void)writeToFile:(LocationInfo *)info {
    dispatch_semaphore_wait(_queueSemaphore, DISPATCH_TIME_FOREVER);
    
    dispatch_block_t writeBlock = ^{
        @autoreleasepool {
            
            NSString *filePath = [[NSString getDocumentDirectory] stringByAppendingPathComponent:@"LocationFile.txt"];
            if (![[self sharedFile] createLocationFile:filePath]) {
                return ;
            }
            
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
            [fileHandle seekToEndOfFile];
            
            JBLog(JL_DEBUG, @"%@", [info toString]);
            
            NSData *infoData = [[info toString] dataUsingEncoding:NSUTF8StringEncoding];
            
//            if (_numProcessors > 1) {
//                dispatch_group_async(_locationFileGroup, _locationFileQueue, ^{ @autoreleasepool {
//                    [fileHandle writeData:infoData];
//                } });
//                
//                dispatch_group_wait(_locationFileGroup, DISPATCH_TIME_FOREVER);
//            } else {
//                dispatch_sync(_locationFileQueue, ^{ @autoreleasepool {
            [fileHandle writeData:infoData];
            [fileHandle closeFile];
//                } });
//            }
            
            dispatch_semaphore_signal(_queueSemaphore);
        }
    };
    
    dispatch_async(_locationFileQueue, writeBlock);
}



+ (void)readFromFile {
    
    dispatch_semaphore_wait(_queueSemaphore, DISPATCH_TIME_FOREVER);

    dispatch_block_t readBlock = ^{
        @autoreleasepool {
            
            NSString *filePath = [[NSString getDocumentDirectory] stringByAppendingPathComponent:@"LocationFile.txt"];
            NSData *infoData = [NSData dataWithContentsOfFile:filePath];
            
            NSMutableArray *locations = [NSMutableArray array];
            NSString *infoString = [[NSString alloc] initWithData:infoData encoding:NSUTF8StringEncoding];
            
            JBLog(JL_DEBUG, @"%@", infoString);
            
            NSArray *infos = [infoString componentsSeparatedByString:@"\n"];
            if (!infos || infos.count==0) {
                return;
            }
            
            for (NSString *locationInfoStr in infos) {
                if (locationInfoStr.length <= 0) {
                    continue;
                }
                LocationInfo *info = [[LocationInfo alloc] initWithString:locationInfoStr];
                [locations addObject:info];
            }
            
            if ([[LocationManager shareInstance].locationDB insertLocations:locations]) {
                NSFileManager * fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:filePath error:nil];
            }
            
            dispatch_semaphore_signal(_queueSemaphore);
        }
    };
    
    dispatch_async(_locationFileQueue, readBlock);
    
}

@end
