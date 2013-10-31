//
//  ISStubViewController.m
//  instaSquare
//
//  Created by Robert Manson on 10/20/13.
//  Copyright (c) 2013 Robert & Sairam. All rights reserved.
//

#import "ISStubViewController.h"
#import "ISInstagramClient.h"
#import "ISFoursquareClient.h"
#import "ISCheckin.h"
#import "ISMapPoint.h"

#define NORTH_SOUTH_SPAN 1000
#define EAST_WEST_SPAN 500
#import "InstagramMediaVC.h"

@interface ISStubViewController ()

@property (nonatomic, strong) NSArray *media;

@end

@implementation ISStubViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.title = @"Insta Square";
        
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager setDelegate:self];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
//        [self.locationManager startUpdatingLocation]; //MKMapView takes care of this
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *searchButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                 target:self
                                                                                 action:@selector(searchLocation)];
    self.navigationItem.rightBarButtonItem = searchButtonItem;
    
    [self.nearbyMap setDelegate:self]; // set the delegate in viewDidLoad instead of init
    [self.nearbyMap setShowsUserLocation:YES];
    
// RMM: TODO Register a custom nib for the custom call out
//    UINib *venueAnnotationNib = [UINib nibWithNibName:@"VenueAnnotation" bundle:nil];
//    [self.view registerNib:venueAnnotationNib forCellReuseIdentifier:@"VenueAnnotation"];


    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Images" style:UIBarButtonItemStylePlain target:self action:@selector(onImagesButton)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma CLLocation Manager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Location manager updated location");
    int indexOfLatestLocation = [locations count] - 1;
    CLLocation *latestLocation = locations[indexOfLatestLocation];
    NSTimeInterval t = [[latestLocation timestamp] timeIntervalSinceNow];
    if (t < -180) {
        return;
    }
    [self foundLocation:latestLocation];
}

#pragma mark - MKMapView Delegate Methods

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    NSLog(@"Map view updated location");
    CLLocationCoordinate2D location = [userLocation coordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, NORTH_SOUTH_SPAN, EAST_WEST_SPAN);
    [self.nearbyMap setRegion:region animated:YES];
    
    CLLocation *latestLocation = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    [self foundLocation:latestLocation];
    [self findTrendingNearBy:latestLocation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
    NSLog(@"mapView:viewForAnnotation:");
    // try to dequeue an existing pin view first
    static NSString *BridgeAnnotationIdentifier = @"bridgeAnnotationIdentifier";
    
    MKPinAnnotationView *pinView =
    (MKPinAnnotationView *) [self.nearbyMap dequeueReusableAnnotationViewWithIdentifier:BridgeAnnotationIdentifier];
    if (pinView == nil)
    {
        // if an existing pin view was not available, create one
        MKPinAnnotationView *customPinView = [[MKPinAnnotationView alloc]
                                              initWithAnnotation:annotation reuseIdentifier:BridgeAnnotationIdentifier];
        customPinView.pinColor = MKPinAnnotationColorPurple;
        customPinView.animatesDrop = YES;
        customPinView.canShowCallout = YES;
        
        // add a detail disclosure button to the callout which will open a new view controller page
        //
        // note: when the detail disclosure button is tapped, we respond to it via:
        //       calloutAccessoryControlTapped delegate method
        //
        // by using "calloutAccessoryControlTapped", it's a convenient way to find out which annotation was tapped
        //
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
        customPinView.rightCalloutAccessoryView = rightButton;
        
        return customPinView;
    }
    
    return pinView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // here we illustrate how to detect which annotation type was clicked on for its callout
    ISMapPoint* annotation = (ISMapPoint*)[view annotation];

    InstagramMediaVC *vc = [[InstagramMediaVC alloc] initWithLatitude:annotation.coordinate.latitude andLongitude:annotation.coordinate.longitude];
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITextField Delegate Methods

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"Textfield returned");
    //[self findLocation];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - View Controller Methods

- (void)findLocation {
    NSLog(@"Find location");
    // find user location and when found call delegate method locationManager:didUpdateLocations:
    [self.locationManager startUpdatingLocation];
    [self.activityIndicator startAnimating];
    [self.locationTextField setHidden:YES];
    
}

- (void)foundLocation:(CLLocation *)loc {
    NSLog(@"Found location");
    CLLocationCoordinate2D coordinate = [loc coordinate];
    // create annotation for coordinate
//    ISMapPoint *mp = [[ISMapPoint alloc] initWithCoordinate:coordinate title:self.locationTextField.text];
    ISMapPoint *mp = [[ISMapPoint alloc] initWithCoordinate:coordinate title:@"Current Location"];
    [self.nearbyMap addAnnotation:mp];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
    [self.nearbyMap setRegion:region animated:YES]; // zoom into the location
    
//    [self.locationTextField setText:@""];
//    [self.activityIndicator stopAnimating];
//    [self.locationTextField setHidden:NO];
//    [self.locationManager stopUpdatingLocation];
}

// To search the location specified by the user in the search box
- (void)searchLocation {
    NSLog(@"Searching location...");
}

- (void)displayTrendingVenues:(NSArray *)checkins {
    NSLog(@"%@", checkins);
    for (ISCheckin *checkin in checkins) {
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:checkin.venueLatitude.doubleValue longitude:checkin.venueLongitude.doubleValue];
        CLLocationCoordinate2D coordinate = [loc coordinate];
        ISMapPoint *mp = [[ISMapPoint alloc] initWithCoordinate:coordinate title:checkin.venueName];
        [self.nearbyMap addAnnotation:mp];
    }
}


- (void)findTrendingNearBy:(CLLocation *)loc {
    NSLog(@"Find trending near by ...");
    CLLocationCoordinate2D coordinate = [loc coordinate];
    [[ISFoursquareClient sharedFSClient] checkinsAtLatitude:coordinate.latitude
                                               andLongitude:coordinate.longitude
                                                withSuccess:^(AFHTTPRequestOperation *operation, id response) {
                                                    NSLog(@"Fetched Trending Venues Nearby");
                                                    NSMutableArray *checkins = [ISCheckin checkinsWithArray:response];
                                                    [self displayTrendingVenues:checkins];
                                                    NSLog(@"%@", checkins);
                                                    //NSLog(@"%@", response);
                                                    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                    //message:@"Fetched Checkins"
                                                    //delegate:nil
                                                    //cancelButtonTitle:nil
                                                    //otherButtonTitles:nil];
                                                    //[alert show];
                                                    //[alert dismissWithClickedButtonIndex:0 animated:YES];
                                                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                    NSLog(@"%@", error);
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                    message:[error localizedDescription]
                                                                                                   delegate:nil
                                                                                          cancelButtonTitle:@"OK"
                                                                                          otherButtonTitles:nil
                                                                          ];
                                                    [alert show];
                                                }
     ];
}

- (void)onImagesButton {
    InstagramMediaVC *vc = [[InstagramMediaVC alloc] initWithLatitude:48.858844 andLongitude:2.294351];
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
















