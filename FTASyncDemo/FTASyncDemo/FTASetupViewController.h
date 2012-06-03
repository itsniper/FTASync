//
//  FTASetupViewController.h
//  FTASyncDemo
//
//  Created by Justin Bergen on 5/28/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface FTASetupViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *syncButton;

- (IBAction)showParseLoginView:(id)sender;
- (void)resetData;

@end
