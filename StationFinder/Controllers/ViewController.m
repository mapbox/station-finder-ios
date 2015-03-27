//
//  ViewController.m
//  Station Finder
//
//  Created by Scott Newman on 2/19/15.
//  Copyright (c) 2015 Example Company. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import "StationDotsView.h"
#import "FilterTableViewController.h"

#import "Mapbox.h"

@interface ViewController () <RMMapViewDelegate, StationFilterDelegate>

@property (nonatomic, strong) RMMapView *mapView;
@property (nonatomic, strong) NSMutableSet *selectedLines;
@property (nonatomic, strong) NSMutableSet *stationAnnotations;

@end

@implementation ViewController

#pragma mark - View Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    #warning Enter your own access token
    [[RMConfiguration sharedInstance] setAccessToken:@"<Your User Token>"];

    #warning Enter your map ID
    RMMapboxSource *tileSource = [[RMMapboxSource alloc] initWithMapID:@"<Your Map ID>"];
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(38.910003,
                                                               -77.015533);
    
    self.mapView = [[RMMapView alloc] initWithFrame:self.view.bounds
                                      andTilesource:tileSource];
    
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.mapView];
    
    self.mapView.zoom = 11;
    self.mapView.centerCoordinate = center;
    
    // Prevent panning outside the bounds of DC
    CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(38.560314,
                                                                  -77.370506);
    CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(39.357147,
                                                                  -76.793182);
    
    [self.mapView setConstraintsSouthWest:southWest northEast:northEast];
    
    self.selectedLines = [[NSMutableSet alloc] initWithArray:@[@"Blue", @"Green", @"Orange", @"Red", @"Silver", @"Yellow"]];
    self.stationAnnotations = [[NSMutableSet alloc] init];
    
    [self loadStations];
    
    // Add a button to our navigation controller
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(filterButtonPressed:)];
    self.navigationItem.rightBarButtonItem = filterButton;
    
}

#pragma mark - User Interface Handlers

- (void)filterButtonPressed:(id)sender
{
    FilterTableViewController *filterVC = [[FilterTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    filterVC.selectedLines = self.selectedLines;
    filterVC.title = @"Filter Lines";
    filterVC.delegate = self;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:filterVC];
    nav.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)annotationShouldBeHidden:(RMAnnotation *)annotation
{
    NSSet *stationLineColors = [NSSet setWithArray:annotation.userInfo[@"lines"]];
    BOOL doesIntersect = [stationLineColors intersectsSet:self.selectedLines];
    return !doesIntersect;
}

#pragma mark - Data Loading Methods

- (void)loadStations
{
    // Load the stations from the local geojson file
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"geojson"];
    
    // Make sure we can load the geojson file
    if (![[NSFileManager defaultManager] fileExistsAtPath:jsonPath]) {
        NSLog(@"Error! Could not find stations.geojson file.");
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    NSError *error = nil;
    
    // Deserialize the JSON into an array of features that we can iterate over
    NSDictionary *jsonDict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data
                                                                             options:0
                                                                               error:&error];
    
    // Create a background queue to perform our marker creation on
    dispatch_queue_t dataQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
    dispatch_async(dataQueue, ^(void)
                   {
                       NSArray *stationFeatures = jsonDict[@"features"];
                       
                       for (NSDictionary *feature in stationFeatures)
                       {
                           // We only support point features right now
                           if ([feature[@"geometry"][@"type"] isEqualToString:@"Point"])
                           {
                               // Create a CLLocationCoorinate2D with the long, lat values
                               CLLocationCoordinate2D coordinate = {
                                   .longitude = [feature[@"geometry"][@"coordinates"][0] floatValue],
                                   .latitude  = [feature[@"geometry"][@"coordinates"][1] floatValue]
                               };
                               
                               NSDictionary *properties = feature[@"properties"];
                               
                               // Create an RMPointAnnotation with our new coordinate and use the
                               // title from the properties
                               RMAnnotation *stationAnnotation =
                               [RMAnnotation annotationWithMapView:_mapView
                                                        coordinate:coordinate
                                                          andTitle:properties[@"title"]];
                               
                               // Store the properties object so we can refer to it later
                               stationAnnotation.userInfo = properties;
                               
                               [self.stationAnnotations addObject:stationAnnotation];
                               
                               dispatch_async(dispatch_get_main_queue(), ^(void)
                                              {
                                                  [_mapView addAnnotation:stationAnnotation];
                                              });
                           }
                       }
                   });
}

#pragma mark - RMMapViewDelegate methods

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    UIColor *metroBlue = [UIColor colorWithRed:0.01 green:0.22 blue:0.41 alpha:1];
    RMMarker *marker = [[RMMarker alloc] initWithMapboxMarkerImage:@"rail-metro"
                                                         tintColor:metroBlue];
    
    marker.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    NSSet *lines = annotation.userInfo[@"lines"];
    StationDotsView *dots = [[StationDotsView alloc] initWithLines:lines];
    marker.leftCalloutAccessoryView = dots;
    
    // We should show a callout when the user taps
    marker.canShowCallout = YES;
    
    // See if the marker should be hidden
    marker.hidden = [self annotationShouldBeHidden:annotation];
    
    return marker;
}

- (void)tapOnCalloutAccessoryControl:(UIControl *)control forAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
    WebViewController *webVC = [[WebViewController alloc] init];
    webVC.stationURL = [NSURL URLWithString:annotation.userInfo[@"url"]];
    webVC.title = annotation.userInfo[@"title"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webVC];
    nav.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Station Loader Delegate Methods

- (void)didUpdateLines:(NSMutableSet *)selectedLines;
{
    self.selectedLines = selectedLines;
    
    for (id annotation in self.stationAnnotations)
    {
        RMAnnotation *theAnnotation = (RMAnnotation *)annotation;
        NSLog(@"Should be hidden: %d", [self annotationShouldBeHidden:annotation]);
        theAnnotation.layer.hidden = [self annotationShouldBeHidden:annotation];
    }
    
}

@end