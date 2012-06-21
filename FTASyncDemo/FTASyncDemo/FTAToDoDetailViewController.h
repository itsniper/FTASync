//
//  FTAToDoDetailViewController.h
//  FTASyncDemo
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
