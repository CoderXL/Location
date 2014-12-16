//
//  LocationDB.h
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationInfo : NSObject

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *date;

@end

@interface LocationDB : NSObject

- (BOOL)insertLocation:(LocationInfo *)info;

- (NSArray *)queryLocationInfosWithDate:(NSString *)date;

@end


@interface NSString (Addition)

+ (NSString *)getDocumentDirectory;

@end

@interface NSDate (Additions)

- (NSString *)stringOfDateWithFormatYYYYMMddHHmmssSSS;

- (NSString *)stringOfDateWithFormatYYYYMMdd;

@end
