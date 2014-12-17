//
//  LocationFile.h
//  Location
//
//  Created by zhangjunbo on 14/12/17.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationFile : NSObject

+ (LocationFile *)sharedFile;

+ (void)writeToFile:(LocationInfo *)info;
+ (void)readFromFile;

@end
