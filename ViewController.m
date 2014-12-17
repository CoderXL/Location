//
//  ViewController.m
//  Location
//
//  Created by zhangjunbo on 14/12/16.
//  Copyright (c) 2014年 ZhangJunbo. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <ActionSheetDatePicker.h>
#import "MKCustomerPolyline.h"

@interface ViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[LocationManager shareInstance] startLocation];
    
    _mapView.mapType = MKMapTypeStandard;
    _mapView.showsUserLocation = YES;
    _mapView.pitchEnabled = NO;
    _mapView.rotateEnabled = NO;
    
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)refresh {
    NSArray *locations = [[LocationManager shareInstance].locationDB queryLocationInfosWithDate:[[NSDate date] stringOfDateWithFormatYYYYMMdd]];
    if (locations) {
        [self addPathToMapWithLocationPoints:locations];
    }
}

- (void)addPathToMapWithLocationPoints:(NSArray *)locations
{
    [_mapView removeOverlays:_mapView.overlays];
    
    MKMapPoint *points = malloc(sizeof(MKMapPoint) * locations.count);
    for (int index = 0; index < locations.count; index++) {
        LocationInfo *info = [locations objectAtIndex:index];
        points[index] = MKMapPointForCoordinate(info.coordinate);
    }
    
    MKPolyline *pathLine = [MKPolyline polylineWithPoints:points count:locations.count];
    [_mapView addOverlay:pathLine];
    free(points);
    
    [_mapView setVisibleMapRect:pathLine.boundingMapRect edgePadding:UIEdgeInsetsMake(0, 0, 0, 0) animated:YES];

    NSMutableArray *motionArray = [NSMutableArray array];
    for (NSInteger index = 0; index < locations.count; index++) {
        if (index==0 ||
            ((LocationInfo*)locations[index-1]).motion != ((LocationInfo*)locations[index]).motion) {
            [motionArray addObject:[NSMutableArray array]];
        }
        
        [[motionArray lastObject] addObject:locations[index]];
    }
    
    for (NSMutableArray *array in motionArray) {
        MKMapPoint *points = malloc(sizeof(MKMapPoint) * array.count);
        for (int index = 0; index < array.count; index++) {
            LocationInfo *info = [array objectAtIndex:index];
            points[index] = MKMapPointForCoordinate(info.coordinate);
        }
        
        MKCustomerPolyline *pathLine = [MKCustomerPolyline polylineWithPoints:points count:array.count];
        pathLine.motionType = ((LocationInfo *)array[0]).motion;
        [_mapView addOverlay:pathLine];
        free(points);
    }
    
}

#pragma mark -
#pragma mark - Button Actions

- (IBAction)buttonPressed:(id)sender {
    [ActionSheetDatePicker showPickerWithTitle:@"日期"
                                datePickerMode:UIDatePickerModeDate
                                  selectedDate:[NSDate date]
                                     doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                         NSArray *locations = [[LocationManager shareInstance].locationDB queryLocationInfosWithDate:[(NSDate *)selectedDate stringOfDateWithFormatYYYYMMdd]];
                                         if (locations.count > 1) {
                                             [self addPathToMapWithLocationPoints:locations];
                                         }
                                     } cancelBlock:^(ActionSheetDatePicker *picker) {
                                         
                                     } origin:self.view];
}

#pragma mark -
#pragma mark - MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKCustomerPolyline class]]) {
        MKPolylineView *routeLineView = [[MKPolylineView alloc] initWithPolyline:(MKCustomerPolyline*)overlay];
        
        switch (((MKCustomerPolyline*)overlay).motionType) {
            case Motion_Stationary:
                routeLineView.fillColor = [UIColor blueColor];
                routeLineView.strokeColor = [UIColor blueColor];
                break;
            case Motion_Walking:
                routeLineView.fillColor = [UIColor greenColor];
                routeLineView.strokeColor = [UIColor greenColor];
                break;
            case Motion_Running:
                routeLineView.fillColor = [UIColor yellowColor];
                routeLineView.strokeColor = [UIColor yellowColor];
                break;
            case Motion_Automotive:
                routeLineView.fillColor = [UIColor redColor];
                routeLineView.strokeColor = [UIColor redColor];
                break;
            case Motion_Unknown:
                routeLineView.fillColor = [UIColor lightGrayColor];
                routeLineView.strokeColor = [UIColor lightGrayColor];
                break;
                
            default:
                routeLineView.fillColor = [UIColor clearColor];
                routeLineView.strokeColor = [UIColor clearColor];
                break;
        }
        
        routeLineView.lineWidth = 5;
        return routeLineView;
    } else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *routeLineView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
        routeLineView.fillColor = [UIColor purpleColor];
        routeLineView.strokeColor = [UIColor purpleColor];
        routeLineView.lineWidth = 5;
        
        return routeLineView;
        
    } else
    
    return nil;
}

@end
