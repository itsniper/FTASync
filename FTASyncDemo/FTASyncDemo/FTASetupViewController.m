//
//  FTASetupViewController.m
//  FTASyncDemo
//
//  Created by Justin Bergen on 5/28/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import "FTASetupViewController.h"
#import "FTASyncParent.h"
#import "FTASyncHandler.h"

@implementation FTASetupViewController

@synthesize syncButton = _syncButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.syncButton = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([PFUser currentUser]) {
        [self.syncButton setTitle:@"Log out of sync" forState:UIControlStateNormal];
        //self.syncButton.titleLabel.text = @"Log out of sync";
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Controller

- (IBAction)showParseLoginView:(id)sender {
    if (![PFUser currentUser]) {
        PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
        logInController.delegate = self;
        logInController.signUpController.delegate = self;
        [self presentModalViewController:logInController animated:YES];
    }
    else {
        [PFUser logOut];
        [self resetData];
        [self.syncButton setTitle:@"Enable Sync" forState:UIControlStateNormal];
    }
}

- (void)resetData {
    [FTASyncParent MR_truncateAllInContext:[NSManagedObjectContext MR_defaultContext]];
    [FTASyncHandler sharedInstance].ignoreContextSave = YES;
    [[NSManagedObjectContext MR_defaultContext] MR_save];
    [FTASyncHandler sharedInstance].ignoreContextSave = NO;
}

#pragma mark - PFLogInViewControllerDelegate

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self.tabBarController dismissModalViewControllerAnimated:YES];
    DCLog(@"Login Success!");
    //[[FTASyncHandler sharedInstance] syncAll];
    
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.tabBarController dismissModalViewControllerAnimated:YES];
}

- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    //[self.tabBarController dismissModalViewControllerAnimated:YES];
    DLog(@"Failed to sign in Parse user with error: %@", error);
}

#pragma mark - PFSignUpViewControllerDelegate

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    DCLog(@"Signup Success!");
    [self.tabBarController dismissModalViewControllerAnimated:YES];
    [[FTASyncHandler sharedInstance] syncAll];
}

- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    [self.tabBarController dismissModalViewControllerAnimated:YES];
}

- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    [self.tabBarController dismissModalViewControllerAnimated:YES];
    DLog(@"Failed to sign up Parse user with error: %@", error);
}

@end
