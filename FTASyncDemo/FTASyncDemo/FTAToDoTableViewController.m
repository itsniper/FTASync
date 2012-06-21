//
//  FTAToDoTableViewController.m
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

#import "FTAToDoTableViewController.h"
#import "ToDoItem.h"
#import "FTASync.h"

@interface FTAToDoTableViewController ()
@property (strong, nonatomic, readwrite) FTAToDoDetailViewController *detailViewController;
@end

@implementation FTAToDoTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize detailViewController = _detailViewController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
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

- (void)dealloc {
    [self.fetchedResultsController setDelegate:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(syncToDo)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addToDo)];
    
    self.title = NSLocalizedString(@"ToDo", @"");    
    self.tableView.backgroundColor = [UIColor lightGrayColor];
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
    
    //Remove blank cells at the bottom of the table view
    if ([[self.fetchedResultsController sections] count] < 9) {
        UIView *footer =
        [[UIView alloc] initWithFrame:CGRectZero];
        self.tableView.tableFooterView = footer;
    }

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

#pragma mark - Custom Accessors

- (NSFetchedResultsController *)fetchedResultsController {
    if (!_fetchedResultsController ) {
        _fetchedResultsController = [ToDoItem MR_fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"priority" ascending:YES delegate:self];
    }
    
    return _fetchedResultsController;
}

- (FTAToDoDetailViewController *)detailViewController {
    if (!_detailViewController) {
        _detailViewController = [[FTAToDoDetailViewController alloc] initWithNibName:@"FTAToDoDetailViewController" bundle:nil];
    }
    
    return _detailViewController;
}

#pragma mark - Controller

- (void)addToDo {
    NSLog(@"%@", @"INSERT");
    [self.detailViewController setCurrentToDo:nil];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

- (void)syncToDo {
    DCLog(@"SYNCING TODO");
    //[[FTASyncHandler sharedInstance] syncEntity:[NSEntityDescription entityForName:@"Reward" inManagedObjectContext:[NSManagedObjectContext MR_context]]];
    [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
        DCLog(@"Completion Block Called");
    } progressBlock:^(float progress, NSString *message) {
        DLog(@"PROGRESS UPDATE: %f - %@", progress, message);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ToDoTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [managedObject valueForKey:@"name"];
    cell.detailTextLabel.text = [[managedObject valueForKey:@"priority"] stringValue];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [[self.fetchedResultsController objectAtIndexPath:indexPath] MR_deleteEntity];
        [[NSManagedObjectContext MR_defaultContext] MR_save];
        //TODO: Handle the error
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ToDoItem *selectedToDo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.detailViewController setCurrentToDo:selectedToDo];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

#pragma mark - Fetched results controller delegate

//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView beginUpdates];
//}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    [self.tableView reloadData];
//    switch (type) {
//        case NSFetchedResultsChangeInsert:
//            NSLog(@"ToDoInsert");
//            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
//            break;
//        case NSFetchedResultsChangeDelete:
//            NSLog(@"ToDoDelete");
//            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
//            break;
//        case NSFetchedResultsChangeMove:
//            NSLog(@"ToDoMove From: %@ To:%@", indexPath, newIndexPath);
//            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
//            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationTop];
//            break;
//        case NSFetchedResultsChangeUpdate: {
//            NSLog(@"ToDoUpdate");
//            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//            NSManagedObject *managedObject = [controller objectAtIndexPath:indexPath];
//            cell.textLabel.text = [managedObject valueForKey:@"name"];
//            cell.detailTextLabel.text = [[managedObject valueForKey:@"priority"] stringValue];
//            break;
//        }
//    }
}

//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    //[self.tableView reloadData];
//    [self.tableView endUpdates];
//}

@end
