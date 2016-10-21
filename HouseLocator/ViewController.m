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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.manager = [HLLocationManager shared];
    [self.manager setDelegate:self];
    
    [self.manager start];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
