//
//  FTAParseSync.m
//  FTASync
//
//  Created by Justin Bergen on 3/16/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "FTASync.h"
#import <Parse/Parse.h>
#import "NPReachability.h"


@implementation FTAParseSync

#pragma - Sync

- (BOOL)canSync {
    if (![[NPReachability sharedInstance] isCurrentlyReachable]) {
        FSCLog(@"No network connectivity");
        return NO;
    }
    

    /*
    if (![PFUser currentUser]) {
        //This can be enabled if you wish to alert the user that they are not signed in
//        UIAlertView *noLogin = [[UIAlertView alloc] initWithTitle:@"Cannot Sync" 
//                                                          message:@"You must by logged in to sync" 
//                                                         delegate:nil 
//                                                cancelButtonTitle:@"OK" 
//                                                otherButtonTitles:nil];
//        [noLogin show];
        FSCLog(@"No Parse user is logged in");
        return NO;
    }
     */
    
    return YES;
}

- (NSArray *)getObjectsOfClass:(NSString *)className updatedSince:(NSDate *)lastUpdate {
    PFQuery *query = [PFQuery queryWithClassName:className];
    query.limit = 1000;
    //Cache the query in case we need one of the objects for merging later
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    
    if (lastUpdate) {
        [query whereKey:@"updatedAt" greaterThan:lastUpdate];
    }
    
    NSArray *returnObjects = [query findObjects];
    
    return returnObjects;
}

- (BOOL)putUpdatedObjects:(NSArray *)updatedObjects forClass:(NSEntityDescription *)entityDesc error:(NSError **)error {
    NSMutableArray *updatedParseObjects = [[NSMutableArray alloc] initWithCapacity:[updatedObjects count]];
    
    //Get parse objects for all updated objects
    for (FTASyncParent *localObject in updatedObjects) {
        PFObject *parseObject = localObject.remoteObject;
        [updatedParseObjects addObject:parseObject];
    }
    NSUInteger updateCount = [updatedParseObjects count];
    
    //Get parse objects for all deleted objects
    NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [entityDesc name]];
    NSArray *deletedLocalObjects = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
    FSLog(@"Preparing to create PFObjects for deletion: %@", deletedLocalObjects);
    for (NSString *objectId in deletedLocalObjects) {
        PFObject *parseObject = [PFObject objectWithClassName:[entityDesc name]];
        parseObject.objectId = objectId;
        [parseObject setObject:[NSNumber numberWithInt:1] forKey:@"deleted"];
        [updatedParseObjects addObject:parseObject];
        FSLog(@"Deleting PFObject: %@", parseObject);
    }
    NSUInteger deleteCount = [updatedParseObjects count] - updateCount;
    
    //Update objects on remote
    FSLog(@"Sending objects to Parse: %@", updatedParseObjects);
    BOOL success = [PFObject saveAll:updatedParseObjects error:error];
    if (!success) {
        FSLog(@"saveAll failed with:");
        return NO;
    }
    FSLog(@"After sending objects to Parse: %@", updatedParseObjects);
    
    //Update local deleted objects with Parse results
    NSArray *deletedFromDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
    NSMutableArray *newDeletedLocalObjects = [[NSMutableArray alloc] initWithArray:deletedFromDefaults];
    [newDeletedLocalObjects removeObjectsInArray:deletedLocalObjects];
    [[NSUserDefaults standardUserDefaults] setObject:newDeletedLocalObjects forKey:defaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Update local updated objects with Parse results
    [updatedParseObjects removeObjectsInRange:NSMakeRange(updateCount, deleteCount)];
    if ([updatedObjects count] != [updatedParseObjects count]) {
        FSALog(@"%@", @"Local and Parse object arrays are out of sync!");
    }
    [updatedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj FTA_updateObjectMetadataWithRemoteObject:[updatedParseObjects objectAtIndex:idx] andResetSyncStatus:YES];
    }];
    
    //Update local objects created via relationship traversal with Parse results
    NSArray *traversedLocalObjects = [FTASyncParent MR_findByAttribute:@"syncStatus" withValue:[NSNumber numberWithInt:3]];
    for (FTASyncParent *traversedObject in traversedLocalObjects) {
        traversedObject.objectId = traversedObject.remoteObject.objectId;
        traversedObject.syncStatusValue = 2;
        FSLog(@"Traversed object after updating ID and syncStatus: %@", traversedObject);
    }
    
    return YES;
}

- (BOOL)deleteObjects:(NSArray *)objects olderThan:(NSDate *)date {
    //TODO: This is the remote server cleanup method
    return YES;
}

@end
