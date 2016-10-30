//
//  ViewController.m
//  HouseLocator
//
//  Created by Sebastien Peek on 10/21/16.
//  Copyright © 2016 prototype. All rights reserved.
//

#import "ViewController.h"

#import "HLLocationManager.h"

@interface ViewController () <HLLocationManagerDelegate>

@property (strong, nonatomic) HLLocationManager *manager;

@property (weak, nonatomic) IBOutlet UILabel *lblLocation;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.manager = [HLLocationManager shared];
    [self.manager setDelegate:self];
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.manager start];
    [self.activityIndicator startAnimating];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - HLLocationManagerDelegate Methods

- (void)didDetermineHouseLocation:(CLLocation *)location {
    
    [self.activityIndicator stopAnimating];
    
    if (location != nil) {
        float lat = location.coordinate.latitude;
        float lon = location.coordinate.longitude;
        
        NSString *houseLocation = [NSString stringWithFormat:@"Lat: %f, Long: %f", lat, lon];
        [self.lblLocation setText:houseLocation];
    } else {
        [self.lblLocation setText:@"House not located, try later!"];
    }
    
}

@end
