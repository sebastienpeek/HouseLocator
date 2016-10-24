//
//  HLLocationManager.m
//  HouseLocator
//
//  Created by Sebastien Peek on 10/21/16.
//  Copyright © 2016 prototype. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKMath.h>
#import "HLLocationManager.h"

@interface HLLocationManager() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *houseLocation;

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) NSMutableDictionary *locationsForDays;

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
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"kLocationsForDaysObject"]) {
            NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"kLocationsForDaysObject"];
            self.locationsForDays = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        } else {
            self.locationsForDays = [NSMutableDictionary new];
        }
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
    
    NSMutableArray *allLocationObjects = [NSMutableArray new];
    for (NSArray *locationArrayPerDay in [self.locationsForDays allValues]) {
        for (CLLocation *location in locationArrayPerDay) {
            [allLocationObjects addObject:location];
        }
    }
    
    // We want to get the center point of all coordinates.
    // Thanks to http://stackoverflow.com/q/6671183/455929 I was able to find the algorithm to get
    // the centre point of the array of locations.
    
    double x = 0;
    double y = 0;
    double z = 0;
    
    for (CLLocation *location in allLocationObjects) {
        
        CLLocationCoordinate2D coordinate = location.coordinate;
        double lat = GLKMathDegreesToRadians(coordinate.latitude);
        double lon = GLKMathDegreesToRadians(coordinate.longitude);
        
        x += cos(lat) * cos(lon);
        y += cos(lat) * sin(lon);
        z += sin(lat);
        
    }
    
    x = x / (double)allLocationObjects.count;
    y = y / (double)allLocationObjects.count;
    z = z / (double)allLocationObjects.count;
    
    double resultLon = atan2(y, x);
    double resultHyp = sqrt(x * x + y * y);
    double resultLat = atan2(z, resultHyp);
    
    CLLocationCoordinate2D result = CLLocationCoordinate2DMake(GLKMathRadiansToDegrees(resultLat),
                                                               GLKMathRadiansToDegrees(resultLon));
    
    // This result is a best guess, believing that the user is within their house at the times we are
    // getting the location data in locationManager:didUpdateLocations.
    
    self.houseLocation = [[CLLocation alloc] initWithCoordinate:result
                                                       altitude:0
                                             horizontalAccuracy:kCLLocationAccuracyHundredMeters
                                               verticalAccuracy:kCLLocationAccuracyHundredMeters
                                                      timestamp:[NSDate new]];
    
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
    
    // Implementation for background tracking. Persistence happening now.
    NSDate *currentDate = [NSDate new];
    NSInteger hour = [self.calendar component:NSCalendarUnitHour
                                     fromDate:currentDate];
    
//        bool isDay = ((hour >= 7) && (hour <= 21));
    bool isNight = ((hour >= 22) || (hour < 6));
    
    NSString *dayOfWeek = [self.dateFormatter stringFromDate:currentDate];
    bool shouldTrackLocation = (![dayOfWeek isEqual:@"Sat" ] &&
                                ![dayOfWeek  isEqual:@"Fri"] &&
                                isNight);
  
    if (shouldTrackLocation) {
        
        // Grab the current locations stored in the dictionary by day.
        NSMutableArray *locationsForDayOfWeek;
        if (![self.locationsForDays objectForKey:dayOfWeek]) {
            locationsForDayOfWeek = [NSMutableArray new];
        } else {
            locationsForDayOfWeek = [self.locationsForDays objectForKey:dayOfWeek];
        }
        
        // Check whether we already have enough data for that day.
        if ([locationsForDayOfWeek count] >= 100) {
            // Now we should check whether we have enough days to determine house location.
            if ([[self.locationsForDays allKeys] count] >= 3) {
                [self stop];
                [self determineHouseLocation];
            } else {
                NSLog(@"need more nights worth of data!");
            }
        } else {
            // Another way to minimise bad location data is to only record the data if the coordinates
            // are within say, twenty metres of each other.
            NSLog(@"Should track location: %@", [locations lastObject]);
            [locationsForDayOfWeek addObject:[locations lastObject]];
            [self.locationsForDays setObject:locationsForDayOfWeek forKey:dayOfWeek];
        }
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.locationsForDays];
        [[NSUserDefaults standardUserDefaults] setObject:data
                                                  forKey:@"kLocationsForDaysObject"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    } else {
        // Do a check for whether we can determine house location
        if ([[self.locationsForDays allKeys] count] >= 4) {
            [self stop];
            [self determineHouseLocation];
        } else {
            NSLog(@"need more nights worth of data!");
        }
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
        [self.locationManager startUpdatingLocation];
    }
    
}

@end
