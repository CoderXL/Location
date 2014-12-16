//
//  LocationManager.h
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationDB.h"

@interface LocationManager : NSObject

@property (nonatomic, strong) LocationDB *locationDB;

+ (LocationManager *)shareInstance;

- (void)startLocation;

- (void)stopLocation;

@end
