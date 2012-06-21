//
//  FTASelectionTableViewController.h
//  ChorePro
//
//  Created by Justin Bergen on 2/21/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
