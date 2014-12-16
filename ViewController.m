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

@interface ViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[LocationManager shareInstance] startLocation];
    
    _mapView.mapType = MKMapTypeStandard;
    _mapView.showsUserLocation = YES;
    
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
        [self addPathToMapWithTripPoints:locations];
    }
}

- (void)addPathToMapWithTripPoints:(NSArray *)locations
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
    
    [_mapView setVisibleMapRect:pathLine.boundingMapRect edgePadding:UIEdgeInsetsMake(20, 20, 20, 20) animated:YES];
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
                                             [self addPathToMapWithTripPoints:locations];
                                         }
                                     } cancelBlock:^(ActionSheetDatePicker *picker) {
                                         
                                     } origin:self.view];
}

#pragma mark -
#pragma mark - MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *routeLineView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
        routeLineView.fillColor = [UIColor redColor];
        routeLineView.strokeColor = [UIColor redColor];
        routeLineView.lineWidth = 5;
        return routeLineView;
    }
    
    return nil;
}

@end
