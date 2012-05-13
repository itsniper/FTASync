//
//  FTASyncHandler.m
//  FTASync
//
//  Created by Justin Bergen on 3/13/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import "FTASyncHandler.h"


@implementation FTASyncHandler

@synthesize remoteInterface = _remoteInterface;

#pragma mark - Singleton

+ (FTASyncHandler *)sharedInstance {
    static dispatch_once_t pred;
    static FTASyncHandler *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[FTASyncHandler alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:shared selector:@selector(contextWasSaved:) name:NSManagedObjectContextDidSaveNotification object:[NSManagedObjectContext MR_defaultContext]];
    });
    
    return shared;
}

//May not need these two methods since I'm using dispatch_once()
/*+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}*/

#pragma mark - Custom Accessors

- (FTAParseSync *)remoteInterface {
    if (!_remoteInterface) {
        _remoteInterface = [[FTAParseSync alloc] init];
    }
    
    return _remoteInterface;
}

#pragma mark - CoreData Maintenance

- (void)contextWasSaved:(NSNotification *)notification {
    DLog(@"%@", @"contextWasSaved:");
    if (_syncInProgress) {
        DLog(@"%@", @"syncInProgress == YES");
        return;
    }
    DLog(@"%@", @"syncInProgress == NO");
    
    NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    
    for (NSManagedObject *updatedObject in updatedObjects) {
        NSString *parentEntity = [[[updatedObject entity] superentity] name];
        
        if ([parentEntity isEqualToString:@"FTASyncParent"]) {
            [updatedObject setValue:[NSNumber numberWithInt:1] forKey:@"syncStatus"];
            DLog(@"Updated Object: %@", updatedObject);
        }
    }
    
    for (NSManagedObject *deletedObject in deletedObjects) {
        DLog(@"Object was deleted from MOC: %@", deletedObject);
        NSString *parentEntity = [[[deletedObject entity] superentity] name];
        
        if ([parentEntity isEqualToString:@"FTASyncParent"] && [deletedObject valueForKey:@"objectId"] != nil) {
            NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [[deletedObject entity] name]];
            NSArray *deletedFromDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
            NSMutableArray *localDeletedObjects = [[NSMutableArray alloc] initWithArray:deletedFromDefaults];
            
            [localDeletedObjects addObject:[deletedObject valueForKey:@"objectId"]];
            [[NSUserDefaults standardUserDefaults] setObject:localDeletedObjects forKey:defaultsKey];
            DLog(@"Deleted Object: %@", deletedObject);
            DLog(@"Deleted objects sent to prefs: %@", localDeletedObjects);
        }
    }
}

#pragma mark - Sync Lock
//TODO: Include code to lock and unlock sync on the remote server. Probably an attribute of the parent PFUser.


#pragma mark - Sync

- (void)syncAll {
    NSManagedObjectModel *dataModel = [NSManagedObjectModel MR_defaultManagedObjectModel];
    
    for (NSEntityDescription *anEntity in dataModel) {
        NSString *parentEntity = [[anEntity superentity] name];
        
        if ([parentEntity isEqualToString:@"FTASyncParent"]) {
            DLog(@"Requesting sync for entity: %@", anEntity);
            [self syncEntity:anEntity];
        }
    }
}

- (void)syncEntity:(NSEntityDescription *)entityDesc {
    NSString *parentEntity = [[entityDesc superentity] name];
    if (![parentEntity isEqualToString:@"FTASyncParent"]) {
        ALog(@"Requested a sync for an entity (%@) that does not inherit from FTASyncParent!", [entityDesc name]);
        return;
    }
    
    NSMutableArray *objectsToSync = [[NSMutableArray alloc] initWithCapacity:1];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDesc];
    
    //Get the time of the most recently sync'd object
    NSDate *lastUpdate = [NSManagedObject FTA_lastUpdateForClass:entityDesc];
    DLog(@"Last update: %@", lastUpdate);
    
    //Add new local objects
    [request setPredicate:[NSPredicate predicateWithFormat:@"syncStatus == 2 OR syncStatus == nil"]];
    NSArray *newLocalObjects = [NSManagedObject MR_executeFetchRequest:request];
    DLog(@"Number of new local objects: %i", [newLocalObjects count]);
    if ([newLocalObjects count] > 0) {
        [objectsToSync addObjectsFromArray:newLocalObjects];
    }
    
    //Get updated remote objects
    NSMutableArray *remoteObjectsForSync = [NSMutableArray arrayWithArray:[self.remoteInterface getObjectsOfClass:[entityDesc name] updatedSince:lastUpdate]];
#ifdef DEBUG
    for (PFObject *object in remoteObjectsForSync) {
        DLog(@"%@", object.updatedAt);
    }   
    DLog(@"Number of remote objects: %i", [remoteObjectsForSync count]);
#endif
    
    //Remove objects deleted locally from remote sync array (push to remote done in FTAParseSync)
    NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [entityDesc name]];
    NSArray *deletedLocalObjects = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
    DLog(@"Deleted objects from prefs: %@", deletedLocalObjects);
    NSPredicate *deletedLocalInRemotePredicate = [NSPredicate predicateWithFormat: @"NOT (objectId IN %@)", deletedLocalObjects];
    [remoteObjectsForSync filterUsingPredicate:deletedLocalInRemotePredicate];
    
    //Add new remote objects
    NSPredicate *newRemotePredicate = nil;
    if (lastUpdate) {
        newRemotePredicate = [NSPredicate predicateWithFormat:@"createdAt > %@", lastUpdate];
    }
    else {
        newRemotePredicate = [NSPredicate predicateWithFormat:@"deleted == NO OR deleted == nil", lastUpdate];
    }
    NSArray *newRemoteObjects = [remoteObjectsForSync filteredArrayUsingPredicate:newRemotePredicate];
    DLog(@"Number of new remote objects: %i", [newRemoteObjects count]);
    [remoteObjectsForSync removeObjectsInArray:newRemoteObjects];
    for (PFObject *remoteObject in newRemoteObjects) {
        [NSManagedObject FTA_newObjectForClass:entityDesc WithParseObject:remoteObject];
    }
    
    //Remove objects removed on remote
    NSPredicate *deletedRemotePredicate = [NSPredicate predicateWithFormat:@"deleted == YES"];
    NSArray *deletedRemoteObjects = [remoteObjectsForSync filteredArrayUsingPredicate:deletedRemotePredicate];
    [remoteObjectsForSync removeObjectsInArray:deletedRemoteObjects];
    DLog(@"Number of deleted remote objects: %i", [deletedRemoteObjects count]);
    for (PFObject *remoteObject in deletedRemoteObjects) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"objectId == %@", remoteObject.objectId]];
        FTASyncParent *localObject = [NSManagedObject MR_executeFetchRequestAndReturnFirstObject:request];
        if (!localObject) {
            DLog(@"Object already removed locally: %@", remoteObject);
        }
        
        [localObject MR_deleteEntity];
    }
    
    //Sync objects changed on remote
    DLog(@"Number of updated remote objects: %i", [remoteObjectsForSync count]);
    for (PFObject *remoteObject in remoteObjectsForSync) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"objectId == %@", remoteObject.objectId]];
        FTASyncParent *localObject = [NSManagedObject MR_executeFetchRequestAndReturnFirstObject:request];
        if (!localObject) {
            ALog(@"Could not find local object matching remote object: @%", remoteObject);
            break;
        }
        
        if ([localObject.syncStatus intValue] == 1) {
            [objectsToSync addObject:localObject];
        }
        else {
            [localObject FTA_updateObjectWithParseObject:remoteObject];
        }
    }
    _syncInProgress = YES;
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_save];
    _syncInProgress = NO;
    
    //Sync objects changed locally
    [request setPredicate:[NSPredicate predicateWithFormat:@"syncStatus == 1"]];
    NSArray *updatedLocalObjects = [NSManagedObject MR_executeFetchRequest:request];
    DLog(@"Number of updated local objects: %i", [updatedLocalObjects count]);
    [objectsToSync addObjectsFromArray:updatedLocalObjects];
    
    if ([objectsToSync count] < 1 && [deletedLocalObjects count] < 1) {
        DLog(@"NO OBJECTS TO SYNC");
        if ([deletedRemoteObjects count] > 0) {
            _syncInProgress = YES;
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_save];
            _syncInProgress = NO;
        }
        
        return;
    }
    
    //Push changes to remote server and update local object's metadata
    DLog(@"Total number of objects to sync: %i", [objectsToSync count]);
    NSError *error;
    BOOL success = [self.remoteInterface putUpdatedObjects:objectsToSync forClass:entityDesc error:&error];
    if (!success) {
        DLog(@"%@", error);
    } 
    else {
        _syncInProgress = YES;
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_save];
        _syncInProgress = NO;
    }
}

@end
