//
//  FTAPersonDetailViewController.m
//  FTASyncDemo
//
//  Created by Justin Bergen on 5/13/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>
#import "FTAPersonDetailViewController.h"

@implementation FTAPersonDetailViewController

@synthesize userPic = _userPic;
@synthesize personName = _personName;

@synthesize editingContext = _editingContext;
@synthesize currentPerson = _currentPerson;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    DCLog(@"Initializing FTASetupChildViewController");
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.editingContext = [NSManagedObjectContext MR_contextThatPushesChangesToDefaultContext];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Person", @"Person");
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(savePerson:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPerson:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.userPic = nil;
    self.personName =nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateInterfaceForCurrentPerson];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Custom Accessors

- (void)setCurrentPerson:(Person *)aPerson {
    if (!aPerson) {
        self.title = @"Add Person";
        aPerson = [Person MR_createInContext:self.editingContext];
        aPerson.photo = UIImagePNGRepresentation([UIImage imageNamed:@"user"]);
    }
    else if (aPerson.managedObjectContext != self.editingContext) {
        self.title = @"Edit Person";
        aPerson = (id)[self.editingContext objectWithID:[aPerson objectID]];
    }
    
    if (_currentPerson != aPerson) {
        _currentPerson = aPerson;
    }
}

#pragma mark - Controller

- (void)updateInterfaceForCurrentPerson {
    self.userPic.image = [UIImage imageWithData:[self.currentPerson photo]];
    self.personName.text = [self.currentPerson valueForKey:@"name"];
}

- (IBAction)cancelPerson:(id)sender {
    [self becomeFirstResponder];
    [self.editingContext reset];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)savePerson:(id)sender {
    self.currentPerson.photo = UIImagePNGRepresentation(self.userPic.image);
    self.currentPerson.name = self.personName.text;
    
    [self.editingContext MR_save];
    //TODO: Handle the error
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Photo Picker
-(IBAction)showActionSheet:(id)sender {
    //Need to preserve current values since UI gets reset in viewWillAppear
    self.currentPerson.photo = UIImagePNGRepresentation(self.userPic.image);
    self.currentPerson.name = self.personName.text;
    
    UIActionSheet *photoSource = [[UIActionSheet alloc] initWithTitle:@"Choose the photo source" 
                                                             delegate:self 
                                                    cancelButtonTitle:@"Cancel" 
                                               destructiveButtonTitle:nil 
                                                    otherButtonTitles:@"Take Photo", @"Choose From Library", nil];
	
    photoSource.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
	[photoSource showInView:mainWindow];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    
    if (buttonIndex == 0) { // Take Photo
                            //Check if camera is available
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
            UIAlertView *noCamera = [[UIAlertView alloc] initWithTitle:@"No Camera Found" 
                                                               message:@"You cannot take a photo without a supported camera." 
                                                              delegate:self 
                                                     cancelButtonTitle:@"OK" 
                                                     otherButtonTitles:nil];
            [noCamera show];
            return;
        }
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	} else if (buttonIndex == 1) { // Choose From Library
		picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	} else if (buttonIndex == 2) { // Cancel
        return;
    }
    
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    [self presentModalViewController:picker animated:YES];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
    
    //Handle image sizing
	//---------------------------------------------------------\
	//Get current image size
	CGSize	currentSize = [image size];
    UIImage *newImage;
	
    //Resize if needed
	if (currentSize.width > 85) { //Image too wide
        float resizeRatio = currentSize.height / currentSize.width;
        CGSize newSize = CGSizeMake(85, 85 * resizeRatio);
        
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();    
        UIGraphicsEndImageContext();
	}
    else if (currentSize.height > 85) { //Image too tall
        float resizeRatio = currentSize.width / currentSize.height;
        CGSize newSize = CGSizeMake(85 * resizeRatio, 85);
        
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();    
        UIGraphicsEndImageContext();
    }
	else { //Image size OK
		newImage = image;
	}
	//---------------------------------------------------------/
    
    self.currentPerson.photo = UIImagePNGRepresentation(newImage);
    
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

@end
