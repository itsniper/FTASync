//
//  FTASelectionTableViewController.m
//  ChorePro
//
//  Created by Justin Bergen on 1/21/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "FTASelectionTableViewController.h"


@interface FTASelectionTableViewController()
@property (strong, nonatomic) NSMutableArray *possibleSelectionsArray;
@end


@implementation FTASelectionTableViewController

@synthesize possibleSelections = _possibleSelections;
@synthesize allowMultipleSelection = _allowMultipleSelection;
@synthesize selections = _selections;
@synthesize callbackBlock = _callbackBlock;

@synthesize possibleSelectionsArray = _possibleSelectionsArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.title = NSLocalizedString(@"Recurrence", @"Recurrence");
    self.tableView.backgroundColor = [UIColor lightGrayColor];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveSelections:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelections:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Custom accessors

- (NSArray *)possibleSelections {
    if (!_possibleSelections) {
        _possibleSelections = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Default Item" forKey:@"0"]];
        ALog(@"%@", @"!!!MUST PROVIDE POSSIBLE SELECTIONS!!!");
    }
    
    return _possibleSelections;
}

- (void)setPossibleSelections:(NSArray *)possibleSelections {
    NSMutableArray *masterArray = [NSMutableArray arrayWithCapacity:[possibleSelections count]];
    
    for (NSDictionary *dict in possibleSelections) {
        NSMutableArray* tempArray = [NSMutableArray arrayWithArray:[dict allKeys]];
        [tempArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [masterArray addObject:tempArray];
    }
    _possibleSelectionsArray = masterArray;
    
    _possibleSelections = possibleSelections;
}

- (NSArray *)allowMultipleSelection {
    if (!_allowMultipleSelection) {
        NSMutableArray *defaultMultiSelection = [NSMutableArray arrayWithCapacity:[self.possibleSelections count]];
        for (NSArray *array in self.possibleSelections) {
            [defaultMultiSelection addObject:[NSNumber numberWithBool:NO]];
        }
        _allowMultipleSelection = defaultMultiSelection;
    }
    
    return _allowMultipleSelection;
}

#pragma mark - Controller

- (BOOL)isSelectedForIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *selectionsForSection = [self.selections objectAtIndex:indexPath.section];
    NSMutableArray *possibleSelectionsForSection = [self.possibleSelectionsArray objectAtIndex:indexPath.section];
    
    return [selectionsForSection containsObject:[possibleSelectionsForSection objectAtIndex:indexPath.row]];
}

- (void)setSelectedForIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *selectionsForSection = [self.selections objectAtIndex:indexPath.section];
    NSMutableArray *possibleSelectionsForSection = [self.possibleSelectionsArray objectAtIndex:indexPath.section];
        
    if (![[self.allowMultipleSelection objectAtIndex:indexPath.section] boolValue]) {
        NSMutableArray *selectionArray = [NSMutableArray arrayWithObject:[possibleSelectionsForSection objectAtIndex:indexPath.row]];
        [self.selections replaceObjectAtIndex:indexPath.section withObject:selectionArray];
    }
    else if ([selectionsForSection containsObject:[possibleSelectionsForSection objectAtIndex:indexPath.row]]) {
        [[self.selections objectAtIndex:indexPath.section] removeObject:[possibleSelectionsForSection objectAtIndex:indexPath.row]];
    }
    else {
        [[self.selections objectAtIndex:indexPath.section] addObject:[possibleSelectionsForSection objectAtIndex:indexPath.row]];
    }
    
    [self.tableView reloadData];
}

- (IBAction)cancelSelections:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveSelections:(id)sender {
    DLog(@"%@", self.selections);
    self.callbackBlock(self.selections);
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.possibleSelectionsArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.possibleSelectionsArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RecurrenceTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if ([self isSelectedForIndexPath:indexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    NSString *key = [[self.possibleSelectionsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text = [[self.possibleSelections objectAtIndex:indexPath.section] valueForKey:key];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setSelectedForIndexPath:indexPath];
}

@end
