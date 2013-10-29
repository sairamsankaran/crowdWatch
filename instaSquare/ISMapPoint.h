//
//  ISMapPoint.h
//  instaSquare
//
//  Created by Sairam Sankaran on 10/26/13.
//  Copyright (c) 2013 Robert & Sairam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ISMapPoint : NSObject <MKAnnotation>

@property (nonatomic, copy) NSString *title;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title;

@end