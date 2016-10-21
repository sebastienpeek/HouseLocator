//
//  HLLocationManager.h
//  HouseLocator
//
//  Created by Sebastien Peek on 10/21/16.
//  Copyright © 2016 prototype. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol HLLocationManagerDelegate;

@interface HLLocationManager : NSObject

@property (unsafe_unretained, nonatomic) id<HLLocationManagerDelegate> delegate;

+ (instancetype) shared;

- (void) start;
- (void) stop;

@end

@protocol HLLocationManagerDelegate <NSObject>

- (void) didDetermineHouseLocation:(CLLocation *)location;

@end
