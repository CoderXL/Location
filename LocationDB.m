//
//  LocationDB.m
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "LocationDB.h"
#import <FMDB.h>

static NSString *sqlCreateTable = @"CREATE TABLE LocationInfoList (Latitude double, Longitude double, Speed double, Motion int, LocationTime text, CreatTime date)";
static NSString *sqlInsertTable = @"INSERT INTO LocationInfoList (Latitude, Longitude, Speed, Motion, LocationTime, CreatTime) values(?, ?, ?, ?, ?, ?)";
static NSString *sqlQueryAllTable = @"SELECT * FROM LocationInfoList order by LocationTime asc";
static NSString *sqlQueryTable = @"SELECT * FROM LocationInfoList WHERE LocationTime >= ? and LocationTime <= ? order by LocationTime asc";

@implementation LocationInfo

- (void)setSpeed:(CGFloat)speed {
    _speed = speed * 3.6f;
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"%f,%f,%f,%zd,%@\n", self.coordinate.latitude, self.coordinate.longitude, self.speed, self.motion, self.date];
}

- (id)initWithString:(NSString *)string {
    if ((self = [super init])) {
        NSArray *array = [string componentsSeparatedByString:@","];
        _coordinate = CLLocationCoordinate2DMake([array[0] doubleValue], [array[1] doubleValue]);
        _speed = [array[2] doubleValue];
        _motion = [array[3] integerValue];
        _date = array[4];
    }
    
    return self;
}

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
//        [self.dbBase openWithFlags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE];
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:self.dbPath flags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_FILEPROTECTION_NONE];
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
         [NSNumber numberWithDouble:info.speed],
         [NSNumber numberWithInteger:info.motion],
         info.date,
         [NSDate date]];
        
        if ([db hadError]) {
            JBLog(JL_ERROR, @"Fail to insert LocationInfo to LocationInfo.sqlite, %d, %@", [db lastErrorCode], [db lastErrorMessage]);
            *rollback = YES;
            result = NO;
            
            [LocationFile writeToFile:info];
        }
        result = YES;
    }];
    
    return result;
}

- (BOOL)insertLocations:(NSArray *)infos {
    __block BOOL result = NO;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (LocationInfo *info in infos) {
            [db executeUpdate:sqlInsertTable,
             [NSNumber numberWithDouble:info.coordinate.latitude],
             [NSNumber numberWithDouble:info.coordinate.longitude],
             [NSNumber numberWithDouble:info.speed],
             [NSNumber numberWithInteger:info.motion],
             info.date,
             [NSDate date]];
        }
        
        if ([db hadError]) {
            JBLog(JL_ERROR, @"Fail to insert LocationInfo to LocationInfo.sqlite, %d, %@", [db lastErrorCode], [db lastErrorMessage]);
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
            JBLog(JL_ERROR, @"Fail to query LocationInfo from LocationInfo.sqlite, %d, %@", [db lastErrorCode], [db lastErrorMessage]);
            *rollback = YES;
            return;
        }
        
        while([resultSet next]) {
            LocationInfo *info = [[LocationInfo alloc] init];
            info.coordinate = CLLocationCoordinate2DMake([resultSet doubleForColumn:@"Latitude"],
                                                         [resultSet doubleForColumn:@"Longitude"]);
            info.date = [resultSet stringForColumn:@"LocationTime"];
            info.motion = [resultSet intForColumn:@"Motion"];
            info.speed = [resultSet doubleForColumn:@"Speed"];
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
