//
//  HCAppDelegate.m
//  HajjChatDemo
//
//  Created by Andy Rifken on 04/13/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "HCAppDelegate.h"
#import "ChatViewController.h"
#import "Constants.h"
#import "ChatNavigationController.h"

@implementation HCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [GMSServices provideAPIKey:(NSString *) kMapsAPIKey];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    UINavigationController *navigationController = [[ChatNavigationController alloc] init];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}


@end