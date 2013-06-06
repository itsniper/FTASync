//
//  FTASetupViewController.m
//  FTASyncDemo
//
//  Created by Justin Bergen on 5/28/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
    //Clear out CoreData
    [FTASyncParent MR_truncateAllInContext:[NSManagedObjectContext MR_defaultContext]];
    [FTASyncHandler sharedInstance].ignoreContextSave = YES;
    [[NSManagedObjectContext MR_defaultContext] MR_save];
    [FTASyncHandler sharedInstance].ignoreContextSave = NO;

    //Clear out pending local deletions
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keys = [[[defaults dictionaryRepresentation] allKeys] copy];
    for(NSString *key in keys) {
        if([key hasPrefix:@"FTASyncDeleted"]) {
            [defaults removeObjectForKey:key];
        }
    }
    [defaults removeObjectForKey:@"FTASyncLastSyncDate"];
    [defaults synchronize];

    //Clean up metadata
    NSArray *entitiesToSync = [[FTASyncParent entityInManagedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]] subentities];
    for (NSEntityDescription *anEntity in entitiesToSync) {
        [FTASyncHandler setMetadataValue:[NSMutableDictionary dictionary] forKey:nil forEntity:[anEntity name] inContext:[NSManagedObjectContext MR_defaultContext]];
    }

    //TODO: Remove
    NSPersistentStoreCoordinator *coordinator = [[NSManagedObjectContext MR_defaultContext] persistentStoreCoordinator];
    id store = [coordinator persistentStoreForURL:[NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]]];
    NSDictionary *metadata = [coordinator metadataForPersistentStore:store];
    FSLog(@"METADATA after clear: %@", metadata);
}

#pragma mark - PFLogInViewControllerDelegate

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self.tabBarController dismissModalViewControllerAnimated:YES];
    DCLog(@"Login Success!");
    [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
        [[NSManagedObjectContext MR_defaultContext] MR_save];
        DCLog(@"Completion Block Called");
    } progressBlock:^(float progress, NSString *message) {
        DLog(@"PROGRESS UPDATE: %f - %@", progress, message);
    }];
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
    [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
        [[NSManagedObjectContext MR_defaultContext] MR_save];
        DCLog(@"Completion Block Called");
    } progressBlock:^(float progress, NSString *message) {
        DLog(@"PROGRESS UPDATE: %f - %@", progress, message);
    }];
}

- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    [self.tabBarController dismissModalViewControllerAnimated:YES];
}

- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    [self.tabBarController dismissModalViewControllerAnimated:YES];
    DLog(@"Failed to sign up Parse user with error: %@", error);
}

@end
