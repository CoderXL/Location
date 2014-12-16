//
//  LocationManager.m
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "LocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "CoordinateTransform.h"

@interface LocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation LocationManager

+ (LocationManager *)shareInstance
{
    static LocationManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[LocationManager alloc] init];
    });
    return sharedManager;
}

- (id)init {
    if ((self = [super init])) {
        self.locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 10.0f;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        
        self.locationDB = [[LocationDB alloc] init];
    }
    
    return self;
}

- (void)startLocation {
    [_locationManager requestAlwaysAuthorization];
    [_locationManager startUpdatingLocation];
    [_locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopLocation {
    [_locationManager stopUpdatingLocation];
    [_locationManager stopMonitoringSignificantLocationChanges];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    JBLog(JL_ERROR, @"%@", error);
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    JBLog(JL_DEBUG, @"LocationManager Did Pause Location Updates");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    JBLog(JL_DEBUG, @"LocationManager Did Resume Location Updates");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    LocationInfo *info = [[LocationInfo alloc] init];
    info.coordinate = transformFromWGSToGCJ([[locations lastObject] coordinate]);
    info.date = [[NSDate date] stringOfDateWithFormatYYYYMMddHHmmssSSS];
    
    [_locationDB insertLocation:info];
}

@end
