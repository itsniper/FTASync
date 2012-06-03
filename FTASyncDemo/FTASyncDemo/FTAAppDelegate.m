//
//  FTAAppDelegate.m
//  FTASyncDemo
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import "FTAAppDelegate.h"
#import "FTAToDoTableViewController.h"
#import "FTAPersonTableViewController.h"
#import <Parse/Parse.h>
#import "FTASync.h"
#import "ParseKeys.h"


@implementation FTAAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize todoNavController = _todoNavController;
@synthesize setupNavController = _setupNavController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultPrefs" ofType:@"plist"]]];
    
    [MagicalRecordHelpers setupAutoMigratingCoreDataStack];
    
    [Parse setApplicationId:kParseAppId 
                  clientKey:kParseClientKey];
    [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];
    
    //Need to make sure FTASyncHandler gets initialized immediately so it's registered for notifications
    [FTASyncHandler sharedInstance];
    
    self.window.rootViewController = self.tabBarController;
    
    FTAToDoTableViewController *todoTableViewController = [[FTAToDoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.todoNavController pushViewController:todoTableViewController animated:NO];
    
    FTAPersonTableViewController *setupTableViewController = [[FTAPersonTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.setupNavController pushViewController:setupTableViewController animated:NO];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [MagicalRecordHelpers cleanUp];
}

@end
