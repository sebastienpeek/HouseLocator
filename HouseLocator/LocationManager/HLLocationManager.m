//
//  HLLocationManager.m
//  HouseLocator
//
//  Created by Sebastien Peek on 10/21/16.
//  Copyright © 2016 prototype. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLLocationManager.h"

@interface HLLocationManager() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *houseLocation;

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSMutableArray *locations;

@end

@implementation HLLocationManager

+ (instancetype)shared {
    
    static HLLocationManager *_shared = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _shared = [[self alloc] init];
    });
    
    return _shared;
}

- (id) init {
    
    if (self = [super init]) {
        self.locationManager = [CLLocationManager new];
        [self.locationManager setDelegate:self];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        
        self.calendar = [NSCalendar currentCalendar];
        self.dateFormatter = [NSDateFormatter new];
        [self.dateFormatter setDateFormat:@"EE"];
        
        self.locations = [NSMutableArray new];
    }
    
    return self;
    
}

- (void) start {
    [self.locationManager startUpdatingLocation];
}

- (void) stop {
    [self.locationManager stopUpdatingLocation];
}

- (void) determineHouseLocation {
    
    NSLog(@"Locations: %@", self.locations);
    
    if ([self.delegate respondsToSelector:@selector(didDetermineHouseLocation:)]) {
        [self.delegate didDetermineHouseLocation:self.houseLocation];
    }
}

#pragma mark - CLLocationManagerDelegate Methods

- (void) locationManager:(CLLocationManager *)manager
      didUpdateLocations:(NSArray *)locations {
    
    // Here we need to determine whether or not they're at home, so let's look into a few ways.
    // First is what was recommended, time based option, ie late at night. We only want to record
    // updates then.
    
    // Implementation for background tracking. No persistence...
    NSDate *currentDate = [NSDate new];
    NSInteger hour = [self.calendar component:NSCalendarUnitHour
                                     fromDate:currentDate];
    
    bool isNight = ((hour >= 22) || (hour < 7));
    if (isNight) {
        [self.locations addObject:[locations lastObject]];
    }
    
    // So now that we're getting location updates at night time and just adding them to the array,
    // we should probably start filtering them to guess the users house location.
    if ([self.locations count] > 100) {
        NSLog(@"We should have enough location objects to determine house...");
        [self determineHouseLocation];
    } else {
        if ([self.delegate respondsToSelector:@selector(didDetermineHouseLocation:)]) {
            [self.delegate didDetermineHouseLocation:nil];
        }
    }
    
    // Second option would to be only check on certain days at night. So during the week, not
    // necessarily Fridays or Saturdays.
    
    /*
     NSString *dayOfWeek = [self.dateFormatter stringFromDate:currentDate];
    bool isAllowedNight = (![dayOfWeek isEqual:@"Sat" ] || ![dayOfWeek  isEqual:@"Fri"]);
    bool isDay = ((hour >= 7) && (hour <= 21));
    
    if (isDay) {
        // It's day time, should we stop checking for location updates? Probably.
        [self stop];
    } else if (isNight && isAllowedNight) {
        // It's night time during the week, we should save the last location in the locations array.
        [self stop];
        self.houseLocation = [locations lastObject];
    } else {
       // Handle this gracefully.
    }
     */
    
    
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        NSLog(@"App is backgrounded. New location is %@", [locations lastObject]);
    }
}

- (void) locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error {
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        NSLog(@"User has denied location access.");
    } else {
        NSLog(@"locationManager:didFailWithError: %@", error);
    }
    
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestAlwaysAuthorization];
        [self.locationManager stopUpdatingLocation];
    } else {
        // We are good to go!
    }
    
}

@end
