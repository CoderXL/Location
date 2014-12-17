//
//  LocationManager.m
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "LocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "CoordinateTransform.h"

@interface LocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;

@property (nonatomic, assign) MotionType motion;

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
        
        self.motionActivityManager = [[CMMotionActivityManager alloc] init];
        
        self.locationDB = [[LocationDB alloc] init];
        
        self.motion = Motion_Unknown;
    }
    
    return self;
}

- (void)startLocation {
    [_locationManager requestAlwaysAuthorization];
    [_locationManager startUpdatingLocation];
    [_locationManager startMonitoringSignificantLocationChanges];
    
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    [_motionActivityManager startActivityUpdatesToQueue:queue withHandler: ^(CMMotionActivity *activity) {
        
        if (activity.walking) {
            _motion = Motion_Walking;
        } else if (activity.running) {
            _motion = Motion_Running;
        } else if (activity.automotive) {
            _motion = Motion_Automotive;
        } else if (activity.stationary) {
            _motion = Motion_Stationary;
        } else {
            _motion = Motion_Unknown;
        }
    }];
}

- (void)stopLocation {
    [_locationManager stopUpdatingLocation];
    [_locationManager stopMonitoringSignificantLocationChanges];
    
    [_motionActivityManager stopActivityUpdates];
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
    
    CLLocation *location = [locations lastObject];
    
    LocationInfo *info = [[LocationInfo alloc] init];
    info.coordinate = transformFromWGSToGCJ([location coordinate]);
    info.date = [[NSDate date] stringOfDateWithFormatYYYYMMddHHmmssSSS];
    info.motion = _motion;
    info.speed = [location speed];
    
    [_locationDB insertLocation:info];
}

@end
