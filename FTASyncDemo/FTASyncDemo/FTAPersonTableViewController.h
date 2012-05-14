//
//  FTASetupTableViewController.h
//  FTASyncDemo
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTAPersonDetailViewController.h"

@interface FTAPersonTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic, readonly) FTAPersonDetailViewController *detailViewController;

- (void)addPerson;
- (void)syncPerson;

@end
