//
//  FTASetupTableViewController.m
//  FTASyncDemo
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import "FTAPersonTableViewController.h"
#import "Person.h"
#import "FTASync.h"


@interface FTAPersonTableViewController ()
@property (strong, nonatomic, readwrite) FTAPersonDetailViewController *detailViewController;
@end

@implementation FTAPersonTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize detailViewController = _detailViewController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(syncPerson)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPerson)];
    
    self.title = NSLocalizedString(@"People", @"");    
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
        _fetchedResultsController = [Person MR_fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"name" ascending:YES delegate:self];
    }
    
    return _fetchedResultsController;
}

- (FTAPersonDetailViewController *)detailViewController {
    if (!_detailViewController) {
        _detailViewController = [[FTAPersonDetailViewController alloc] initWithNibName:@"FTAPersonDetailViewController" bundle:nil];
    }
    
    return _detailViewController;
}

#pragma mark - Controller

- (void)addPerson {
    NSLog(@"%@", @"INSERT PERSON");
    [self.detailViewController setCurrentPerson:nil];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

- (void)syncPerson {
    DCLog(@"SYNCING PERSON");
    //[[FTASyncHandler sharedInstance] syncEntity:[NSEntityDescription entityForName:@"Reward" inManagedObjectContext:[NSManagedObjectContext MR_context]]];
    [[FTASyncHandler sharedInstance] syncWithCompletionBlock:nil progressBlock:nil];
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
    static NSString *CellIdentifier = @"PersonTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    Person *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [managedObject valueForKey:@"name"];
    cell.imageView.image = [UIImage imageWithData:managedObject.photo];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *selectedPerson = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.detailViewController setCurrentPerson:selectedPerson];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"PersonInsert");
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"PersonDelete");
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"PersonMove From: %@ To:%@", indexPath, newIndexPath);
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationTop];
            break;
        case NSFetchedResultsChangeUpdate: {
            NSLog(@"PersonUpdate");
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            Person *managedObject = [controller objectAtIndexPath:indexPath];
            cell.textLabel.text = [managedObject valueForKey:@"name"];
            cell.imageView.image = [UIImage imageWithData:managedObject.photo];
            break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
