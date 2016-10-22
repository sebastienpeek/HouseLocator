//
//  HLLocationManager.m
//  HouseLocator
//
//  Created by Sebastien Peek on 10/21/16.
//  Copyright © 2016 prototype. All rights reserved.
//

#import "HLLocationManager.h"

@interface HLLocationManager() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *lastLocation;

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
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager setDelegate:self];
    }
    
    return self;
    
}

- (void) start {
    [self.locationManager startUpdatingLocation];
}

- (void) stop {
    [self.locationManager stopUpdatingLocation];
}


#pragma mark - CLLocationManagerDelegate Methods

- (void) locationManager:(CLLocationManager *)manager
      didUpdateLocations:(NSArray *)locations {
    
    // Here we need to determine whether or not they're at home, so let's look into a few ways.
    // First is what was recommended, time based option, ie late at night.
    
    // Second option would to be only check on certain days at night. So during the week, not
    // necessarily Fridays or Saturdays.
    
    NSDate *currentDate = [NSDate new];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour
                                fromDate:currentDate];
    
    bool isNight = ((hour >= 22) || (hour < 7));
    bool isDay = ((hour >= 7) && (hour <= 21));
    
    if (isDay) {
        // It's day time, should we stop checking for location updates? Probably.
        [self stop];
    } else if (isNight) {
        // It's night time, we should save the last location in the locations array.
        [self stop];
        self.lastLocation = [locations lastObject];
    } else {
       // Handle this gracefully.
    }

    if ([self.delegate respondsToSelector:@selector(didDetermineHouseLocation:)]) {
        [self.delegate didDetermineHouseLocation:self.lastLocation];
    }
    
}

- (void) locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error {
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        NSLog(@"User has not denied location access");
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
