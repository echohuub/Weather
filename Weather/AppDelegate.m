//
//  AppDelegate.m
//  Weather
//
//  Created by HeQingbao on 14-6-28.
//  Copyright (c) 2014年 HeQingbao. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import <TSMessage.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // 设置rootViewController
    self.window.rootViewController = [[MainViewController alloc] init];

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // 设置TSMessages
    [TSMessage setDefaultViewController:self.window.rootViewController];

    return YES;
}
@end
