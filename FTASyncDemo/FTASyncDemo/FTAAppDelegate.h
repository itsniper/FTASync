//
//  FTAAppDelegate.h
//  FTASyncDemo
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FTAViewController;

@interface FTAAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;

@property (strong, nonatomic) IBOutlet UITabBarController *tabBarController;
@property (strong, nonatomic) IBOutlet UINavigationController *todoNavController;
@property (strong, nonatomic) IBOutlet UINavigationController *setupNavController;

//@property (strong, nonatomic) FTAViewController *viewController;

@end
