//
//  AppDelegate.m
//  JustPromisesDemo
//
//  Created by Alberto De Bortoli on 21/01/2015.
//  Copyright (c) 2015 JUST EAT. All rights reserved.
//

#import "AppDelegate.h"
#import "JEDemoExamples.h"

@interface AppDelegate ()

@property (nonatomic, strong) JEDemoExamples *examples;

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.examples = [JEDemoExamples new];
    
    [self.examples runSucceedingExample];
    
    [self.examples runFailingExample];
    
    [self.examples runWhenAllExample];
    
    return YES;
}

@end