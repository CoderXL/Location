//
//  JBLogger.m
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "JBLogger.h"

#import <DDLog.h>
#import <DDASLLogger.h>
#import <DDFileLogger.h>
#import <DDTTYLogger.h>

#import <iConsole.h>

#import "KSCrashInstallationFile.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation JBLogger

+(void)load {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *docDir = [paths objectAtIndex:0];
    
    DDLogFileManagerDefault *manager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:[docDir stringByAppendingPathComponent:@"Logs"]];
    manager.maximumNumberOfLogFiles = 7;
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:manager];
    fileLogger.rollingFrequency = 60*60*24;    //24h
    fileLogger.maximumFileSize = 1024*1024*5;//5M
    
    [DDLog addLogger:fileLogger];
    
    KSCrashInstallationFile* installation = [KSCrashInstallationFile sharedInstance];
    installation.fileDir = [docDir stringByAppendingPathComponent:@"Logs/Crash"];;
    [installation install];
    
    [installation sendAllReportsWithCompletion:^(NSArray* reports, BOOL completed, NSError* error) {
        if(completed) {
            NSLog(@"Sent %zd reports", (int)[reports count]);
            //            [self processCrashReport];
        } else {
            NSLog(@"Failed to send reports: %@", error);
        }
    }];
}

+ (void)logWithLevel:(JBLogLevel)logLevel andInfo:(NSString *)info;
{
    switch (logLevel) {
        case JL_ERROR:
            DDLogError(@"%@", [NSString stringWithFormat:@"[ERROR] %@",info]);
            [iConsole log:@"%@", [NSString stringWithFormat:@"[ERROR] %@",info]];
            break;
        case JL_WARNING:
            DDLogWarn(@"%@", [NSString stringWithFormat:@"[WARNING] %@",info]);
            [iConsole log:@"%@", [NSString stringWithFormat:@"[WARNING] %@",info]];
            break;
        case JL_INFO:
            DDLogInfo(@"%@", [NSString stringWithFormat:@"[INFO] %@",info]);
            [iConsole log:@"%@", [NSString stringWithFormat:@"[INFO] %@",info]];
            break;
        case JL_DEBUG:
            DDLogDebug(@"%@", [NSString stringWithFormat:@"[DEBUG] %@",info]);
            [iConsole log:@"%@", [NSString stringWithFormat:@"[DEBUG] %@",info]];
            break;
        case JL_VERBOSE:
            DDLogVerbose(@"%@", [NSString stringWithFormat:@"[VERBOSE] %@",info]);
            [iConsole log:@"%@", [NSString stringWithFormat:@"[VERBOSE] %@",info]];
            break;
            
        default:
            break;
    }
}

@end
