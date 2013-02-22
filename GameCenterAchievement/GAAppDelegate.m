//
//  GAAppDelegate.m
//  GameCenterAchievement
//
//  Created by Rex Sheng on 2/22/13.
//  Copyright (c) 2013 rexsheng.com. All rights reserved.
//

#import "GAAppDelegate.h"
#import "Achievement+GameCenter.h"

@implementation GAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
	[MagicalRecord setupAutoMigratingCoreDataStack];
    return YES;
}

@end
