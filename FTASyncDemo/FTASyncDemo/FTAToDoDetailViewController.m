//
//  FTAToDoDetailViewController.m
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

#import <QuartzCore/QuartzCore.h>
#import "FTAToDoDetailViewController.h"
#import "FTASelectionTableViewController.h"

@implementation FTAToDoDetailViewController

@synthesize todoName = _todoName;
@synthesize priorityValue = _priorityValue;
@synthesize priorityValueSlider = _priorityValueSlider;
@synthesize personButton = _personButton;

@synthesize editingContext = _editingContext;
@synthesize currentToDo = _currentToDo;

@synthesize people = _people;
@synthesize possiblePeople = _possiblePeople;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
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
    // Do any additional setup after loading the view from its nib.
    
    self.title = NSLocalizedString(@"ToDo Item", @""); 
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveToDo:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelToDo:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.todoName = nil;
    self.priorityValue = nil;
    self.priorityValueSlider = nil;
    self.personButton = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateInterfaceForCurrentToDo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Custom Accessors

- (void)setCurrentToDo:(ToDoItem *)aToDo {
    if (!aToDo) {
        self.title = @"Add ToDo Item";
        aToDo = [ToDoItem MR_createInContext:self.editingContext];
    }
    else if (aToDo.managedObjectContext != self.editingContext) {
        self.title = @"Edit ToDo Item";
        aToDo = (id)[self.editingContext objectWithID:[aToDo objectID]];
    }
    
    if (_currentToDo != aToDo) {
        _currentToDo = aToDo;
    }
}

- (NSArray *)people {
    _people = [Person MR_findAllSortedBy:@"name" ascending:YES inContext:self.editingContext];
    
    return _people;
}

- (NSDictionary *)possiblePeople {
    NSMutableDictionary *peopleDictionary = [NSMutableDictionary dictionaryWithCapacity:[self.people count]];
    NSInteger indexNum = 0;
    for (Person *aPerson in self.people) {
        [peopleDictionary setObject:aPerson.name forKey:[NSString stringWithFormat:@"%i", indexNum]];
        indexNum++;
    }
    _possiblePeople = peopleDictionary;
    
    return _possiblePeople;
}

#pragma mark - Controller

- (void)updateInterfaceForCurrentToDo {
    self.todoName.text = [self.currentToDo valueForKey:@"name"];
    self.priorityValue.text = [[self.currentToDo valueForKey:@"priority"] stringValue];
    self.priorityValueSlider.value = [[self.currentToDo valueForKey:@"priority"] intValue];
    if ([self.currentToDo person]) {
        self.personButton.titleLabel.text = [[self.currentToDo person] name];
    }
    else {
        self.personButton.titleLabel.text = @"Select a person";
    }
}

- (IBAction)priorityValueChanged:(UISlider *)sender {
    int value = sender.value;
    self.priorityValue.text = [NSString stringWithFormat:@"%i", value];
}

- (IBAction)cancelToDo:(id)sender {
    [self becomeFirstResponder];
    [self.editingContext reset];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveToDo:(id)sender {
    self.currentToDo.name = self.todoName.text;
    self.currentToDo.priority = [NSNumber numberWithInt:[self.priorityValue.text intValue]];
        
    [self.editingContext MR_save];
    //TODO: Handle the error
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)choosePerson:(id)sender {
    if ([self.possiblePeople count] < 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No People" message:@"You have not yet setup any people" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    FTASelectionTableViewController *detailViewController = [[FTASelectionTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [detailViewController setPossibleSelections:[NSArray arrayWithObject:self.possiblePeople]];
    [detailViewController setAllowMultipleSelection:[NSArray arrayWithObject:[NSNumber numberWithBool:NO]]];
    NSSet *peopleKeys = [self.possiblePeople keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        Person *person = [self.currentToDo person];
        if ([person.name isEqualToString:obj]) {
            return YES;
        }
        return NO;
    }];
    NSMutableArray *selections = [NSMutableArray arrayWithObjects:[NSMutableArray arrayWithObjects:[peopleKeys anyObject], nil], nil];
    [detailViewController setSelections:selections];
    [detailViewController setCallbackBlock:^(NSArray *array) {
        NSString *personIndex = [[array objectAtIndex:0] lastObject];
        [self.currentToDo setPerson:[self.people objectAtIndex:[personIndex intValue]]];
    }];
    
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

@end
