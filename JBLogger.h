//
//  JBLogger.h
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOG_FILENAME   [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
#define LOG_LINE        __LINE__
#define LOG_FUNC       [NSString stringWithUTF8String:__PRETTY_FUNCTION__]

#if DEBUG
#define JBLog(iLevel, fmt, ...) \
[JBLogger logWithLevel:iLevel andInfo:[NSString stringWithFormat:@"[%@][%s][%d]"fmt, LOG_FILENAME, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]]
#else
#define JBLog(ilevel, fmt, ...)
#endif

typedef NS_ENUM(NSUInteger, JBLogLevel){
    JL_VERBOSE = 0,
    JL_DEBUG,
    JL_INFO,
    JL_WARNING,
    JL_ERROR,
    
    JL_RESERVED,
};

@interface JBLogger : NSObject

+ (void)logWithLevel:(JBLogLevel)logLevel andInfo:(NSString *)info;

@end
