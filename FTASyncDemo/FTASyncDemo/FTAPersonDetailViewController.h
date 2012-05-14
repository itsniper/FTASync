//
//  FTAPersonDetailViewController.h
//  FTASyncDemo
//
//  Created by Justin Bergen on 5/13/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface FTAPersonDetailViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *userPic;
@property (weak, nonatomic) IBOutlet UITextField *personName;

@property (strong, nonatomic) NSManagedObjectContext *editingContext;
@property (strong, nonatomic) Person *currentPerson;

- (void)updateInterfaceForCurrentPerson;
- (IBAction)cancelPerson:(id)sender;
- (IBAction)savePerson:(id)sender;

@end
