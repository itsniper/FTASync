//
//  FTASelectionTableViewController.h
//  ChorePro
//
//  Created by Justin Bergen on 2/21/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^SelectionCallbackBlock)(NSArray *);

@interface FTASelectionTableViewController : UITableViewController

//Array of dictionaries, each index of array is a table view section
@property (strong, nonatomic) NSArray *possibleSelections;
//Array of BOOLs, each index of array is a table view section
@property (strong, nonatomic) NSArray *allowMultipleSelection;
//Mutable array of mutable arrays containing the selection(s) of each section
//Selections must be NSStrings matching the dictionary keys!
@property (strong, nonatomic) NSMutableArray *selections;
//Block to be called on save
@property (copy, nonatomic) SelectionCallbackBlock callbackBlock;

//Used internally to handle selection dictionary keys that aren't 0-based
@property (readonly, strong, nonatomic) NSMutableArray *possibleSelectionsArray;

- (BOOL)isSelectedForIndexPath:(NSIndexPath *)indexPath;
- (void)setSelectedForIndexPath:(NSIndexPath *)indexPath;
- (IBAction)saveSelections:(id)sender;
- (IBAction)cancelSelections:(id)sender;

@end
