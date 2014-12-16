//
//  LocationDB.m
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "LocationDB.h"
#import <FMDB.h>

static NSString *sqlCreateTable = @"CREATE TABLE LocationInfoList (Latitude double, Longitude double, LocationTime text, CreatTime date)";
static NSString *sqlInsertTable = @"INSERT INTO LocationInfoList (Latitude, Longitude, LocationTime, CreatTime) values(?, ?, ?, ?)";
static NSString *sqlQueryAllTable = @"SELECT * FROM LocationInfoList order by LocationTime asc";
static NSString *sqlQueryTable = @"SELECT * FROM LocationInfoList WHERE LocationTime >= ? and LocationTime < ? order by LocationTime asc";

@implementation LocationInfo

@end

@interface LocationDB ()

@property (nonatomic, copy) NSString *dbPath;
@property (nonatomic, strong) FMDatabase *dbBase;
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation LocationDB

- (id)init {
    self = [super init];
    if (self) {
        self.dbPath = [[NSString getDocumentDirectory] stringByAppendingPathComponent:@"LocationInfo.sqlite"];
        [self createLocationInfoTable:self.dbPath];
        self.dbBase = [FMDatabase databaseWithPath:self.dbPath];
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:self.dbPath];
    }
    
    return self;
}


- (BOOL)createLocationInfoTable:(NSString *)dbPath {
    
    BOOL result = YES;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:dbPath] == NO) {
        // create it
        FMDatabase * db = [FMDatabase databaseWithPath:dbPath];
        if ([db open]) {
            BOOL res = [db executeUpdate:sqlCreateTable];
            if (!res) {
                result = NO;
                JBLog(JL_ERROR, @"error when creating db table");
            } else {
                result = YES;
                JBLog(JL_DEBUG, @"succ to creating db table");
            }
            [db close];
        } else {
            result = NO;
            JBLog(JL_ERROR, @"error when open db");
        }
    }
    
    return result;
}

- (BOOL)insertLocation:(LocationInfo *)info {
    __block BOOL result = NO;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sqlInsertTable,
         [NSNumber numberWithDouble:info.coordinate.latitude],
         [NSNumber numberWithDouble:info.coordinate.longitude],
         info.date,
         [NSDate date]];
        
        if ([db hadError]) {
            JBLog(JL_ERROR, @"Fail to insert customerInfo to customerInfo.sqlite, %d, %@", [db lastErrorCode], [db lastErrorMessage]);
            *rollback = YES;
            result = NO;
        }
        result = YES;
    }];
    
    return result;
}

- (NSArray *)queryLocationInfosWithDate:(NSString *)date {
    __block NSMutableArray *locationInfos = [NSMutableArray array];
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *resultSet = [db executeQuery:sqlQueryTable, [NSString stringWithFormat:@"%@ 00:00:00", date], [NSString stringWithFormat:@"%@ 23:59:59", date]];
        if ([db hadError]) {
            JBLog(JL_ERROR, @"Fail to insert customerInfo to customerInfo.sqlite, %d, %@", [db lastErrorCode], [db lastErrorMessage]);
            *rollback = YES;
            return;
        }
        
        while([resultSet next]) {
            LocationInfo *info = [[LocationInfo alloc] init];
            info.coordinate = CLLocationCoordinate2DMake([resultSet doubleForColumn:@"Latitude"],
                                                         [resultSet doubleForColumn:@"Longitude"]);
            info.date = [resultSet stringForColumn:@"LocationTime"];
            [locationInfos addObject:info];
        }
        [resultSet close];
    }];
    
    return locationInfos;
}

@end

@implementation NSString (Addition)

+ (NSString *)getDocumentDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    return documentDir;
}

@end

@implementation NSDate (Addition)

+ (NSDateFormatter *)defaultDateFormatterWithFormatYYYYMMddHHmmssSSS {
    static NSDateFormatter *staticDateFormatterWithFormatYYYYMMddHHmmssSSS;
    if (!staticDateFormatterWithFormatYYYYMMddHHmmssSSS) {
        staticDateFormatterWithFormatYYYYMMddHHmmssSSS = [[NSDateFormatter alloc] init];
        [staticDateFormatterWithFormatYYYYMMddHHmmssSSS setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
    }
    
    return staticDateFormatterWithFormatYYYYMMddHHmmssSSS;
}

+ (NSDateFormatter *)defaultDateFormatterWithFormatYYYYMMdd {
    static NSDateFormatter *staticDateFormatterWithFormatYYYYMMdd;
    if (!staticDateFormatterWithFormatYYYYMMdd) {
        staticDateFormatterWithFormatYYYYMMdd = [[NSDateFormatter alloc] init];
        [staticDateFormatterWithFormatYYYYMMdd setDateFormat:@"YYYY-MM-dd"];
    }
    
    return staticDateFormatterWithFormatYYYYMMdd;
}

- (NSString *)stringOfDateWithFormatYYYYMMddHHmmssSSS {
    return [[NSDate defaultDateFormatterWithFormatYYYYMMddHHmmssSSS] stringFromDate:self];
}

- (NSString *)stringOfDateWithFormatYYYYMMdd {
    return [[NSDate defaultDateFormatterWithFormatYYYYMMdd] stringFromDate:self];
}

@end
