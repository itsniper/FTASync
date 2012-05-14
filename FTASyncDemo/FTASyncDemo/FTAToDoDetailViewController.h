//
//  FTAToDoDetailViewController.h
//  FTASyncDemo
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToDoItem.h"
#import "Person.h"

@interface FTAToDoDetailViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *todoName;
@property (strong, nonatomic) IBOutlet UITextField *priorityValue;
@property (strong, nonatomic) IBOutlet UISlider *priorityValueSlider;
@property (strong, nonatomic) IBOutlet UIButton *personButton;

@property (strong, nonatomic) NSManagedObjectContext *editingContext;
@property (strong, nonatomic) ToDoItem *currentToDo;

@property (readonly, strong, nonatomic) NSArray *people;
@property (readonly, strong, nonatomic) NSDictionary *possiblePeople;

- (void)updateInterfaceForCurrentToDo;
- (IBAction)priorityValueChanged:(id)sender;
- (IBAction)cancelToDo:(id)sender;
- (IBAction)saveToDo:(id)sender;
- (IBAction)choosePerson:(id)sender;

@end
