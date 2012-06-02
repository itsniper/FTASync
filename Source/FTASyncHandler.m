//
//  FTASyncHandler.m
//  FTASync
//
//  Created by Justin Bergen on 3/13/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import "FTASyncHandler.h"
#import "FTASyncParent.h"
#import "CoreData+MagicalRecord.h"

#define kFTASyncDeletedObjectAging 30 //TODO: Create a method to clean out deleted objects on Parse after above # of days
#define kSyncAutomatically  NO //TODO: Create methods to sync automatically after context save
#define kAutoSyncDelay 30


@implementation FTASyncHandler

@synthesize remoteInterface = _remoteInterface;
<<<<<<< HEAD
=======
@synthesize syncInProgress = _syncInProgress;
@synthesize progress = _progress;
@synthesize progressBlock = _progressBlock;
//@synthesize errorHandler = _errorHandler;
@synthesize ignoreContextSave = _ignoreContextSave;

//- (id)init {
//    self = [super init];
//    if (!self) {
//        return nil;
//    }
//    
//    //Need to set the errorHandler property so that it can be reused
//    self.errorHandler = ^(NSError *error, NSManagedObjectContext *context){
//        [context rollback];
//        
//        
//        NSDictionary *userInfo = [error userInfo];
//        for (NSArray *detailedError in [userInfo allValues])
//        {
//            if ([detailedError isKindOfClass:[NSArray class]])
//            {
//                for (NSError *e in detailedError)
//                {
//                    if ([e respondsToSelector:@selector(userInfo)])
//                    {
//                        DLog(@"Error Details: %@", [e userInfo]);
//                    }
//                    else
//                    {
//                        DLog(@"Error Details: %@", e);
//                    }
//                }
//            }
//            else
//            {
//                DLog(@"Error: %@", detailedError);
//            }
//        }
//        DLog(@"Error Message: %@", [error localizedDescription]);
//        DLog(@"Error Domain: %@", [error domain]);
//        DLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
//    };
//    
//    return self;
//}
>>>>>>> 1de9e8e... Moved the sync to a background thread

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
    if (![NSThread isMainThread]) {
        //If this is not on a main thread it is a sync save
        return;
    }
    
    if (self.isIgnoreContextSave) {
        DLog(@"%@", @"ignoreContextSave == YES");
        return;
    }
    
    NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    
    for (NSManagedObject *updatedObject in updatedObjects) {
        NSString *parentEntity = [[[updatedObject entity] superentity] name];
        
        if ([parentEntity isEqualToString:@"FTASyncParent"] && [updatedObject valueForKey:@"syncStatus"] == [NSNumber numberWithInt:0]) {
            [updatedObject setValue:[NSNumber numberWithInt:1] forKey:@"syncStatus"];
            DLog(@"Updated Object: %@", updatedObject);
        }
    }
    self.ignoreContextSave = YES;
    [[NSManagedObjectContext MR_defaultContext] MR_save];
    self.ignoreContextSave = NO;
    
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

- (void)syncEntity:(NSEntityDescription *)entityDesc {
    if ([NSThread isMainThread]) {
        ALog(@"%@", @"This should NEVER be run on the main thread!!");
        return;
    }
    
    NSString *parentEntity = [[entityDesc superentity] name];
    if (![parentEntity isEqualToString:@"FTASyncParent"]) {
        ALog(@"Requested a sync for an entity (%@) that does not inherit from FTASyncParent!", [entityDesc name]);
        return;
    }
    
    NSMutableArray *objectsToSync = [[NSMutableArray alloc] initWithCapacity:1];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDesc];
    
    //Get the time of the most recently sync'd object
    NSDate *lastUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];
    DLog(@"Last update: %@", lastUpdate);
    
    //Add new local objects
    [request setPredicate:[NSPredicate predicateWithFormat:@"syncStatus = nil OR syncStatus = 2 OR syncStatus = 3"]];
    NSArray *newLocalObjects = [NSManagedObject MR_executeFetchRequest:request];
    DLog(@"Number of new local objects: %i", [newLocalObjects count]);
#ifdef DEBUG
    for (FTASyncParent *object in newLocalObjects) {
        if (object.syncStatusValue == 3) {
            DLog(@"!!!!!!!OBJECT WITH SYNC STATUS 3!!!!!! %@", object);
        }
    }
#endif
    if ([newLocalObjects count] > 0) {
        [objectsToSync addObjectsFromArray:newLocalObjects];
    }
    
    //Get updated remote objects
    NSMutableArray *remoteObjectsForSync = [NSMutableArray arrayWithArray:[self.remoteInterface getObjectsOfClass:[entityDesc name] updatedSince:lastUpdate]];
    DLog(@"Number of remote objects: %i", [remoteObjectsForSync count]);
#ifdef DEBUG
    for (PFObject *object in remoteObjectsForSync) {
        DLog(@"%@", object.updatedAt);
    }   
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
        newRemotePredicate = [NSPredicate predicateWithFormat:@"deleted = NO OR deleted = nil", lastUpdate];
    }
    NSArray *newRemoteObjects = [remoteObjectsForSync filteredArrayUsingPredicate:newRemotePredicate];
    DLog(@"Number of new remote objects: %i", [newRemoteObjects count]);
    [remoteObjectsForSync removeObjectsInArray:newRemoteObjects];
    [FTASyncParent FTA_newObjectsForClass:entityDesc withRemoteObjects:newRemoteObjects];
    
    //Remove objects removed on remote
    NSPredicate *deletedRemotePredicate = [NSPredicate predicateWithFormat:@"deleted = YES"];
    NSArray *deletedRemoteObjects = [remoteObjectsForSync filteredArrayUsingPredicate:deletedRemotePredicate];
    [remoteObjectsForSync removeObjectsInArray:deletedRemoteObjects];
    DLog(@"Number of deleted remote objects: %i", [deletedRemoteObjects count]);
    [FTASyncParent FTA_deleteObjectsForClass:entityDesc withRemoteObjects:deletedRemoteObjects];
    
    //Sync objects changed on remote
    DLog(@"Number of updated remote objects: %i", [remoteObjectsForSync count]);
    [FTASyncParent FTA_updateObjectsForClass:entityDesc withRemoteObjects:remoteObjectsForSync];
<<<<<<< HEAD
    _syncInProgress = YES;
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_save];
    _syncInProgress = NO;
=======
    //TODO: Remove
    if ([NSManagedObjectContext MR_contextForCurrentThread] == [NSManagedObjectContext MR_defaultContext]) {
        ALog(@"%@", @"Should not be working with the main context!");
    }
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveWithErrorHandler:^(NSError *error){
        [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
        self.syncInProgress = NO;
        self.progressBlock = nil;
        self.progress = 0;
        
        [self handleError:error];
    }];
>>>>>>> 1de9e8e... Moved the sync to a background thread
    
    //Sync objects changed locally
    [request setPredicate:[NSPredicate predicateWithFormat:@"syncStatus = 1"]];
    NSArray *updatedLocalObjects = [NSManagedObject MR_executeFetchRequest:request];
    DLog(@"Number of updated local objects: %i", [updatedLocalObjects count]);
    [objectsToSync addObjectsFromArray:updatedLocalObjects];
    
    if ([objectsToSync count] < 1 && [deletedLocalObjects count] < 1) {
        DLog(@"NO OBJECTS TO SYNC");
        if ([deletedRemoteObjects count] > 0) {
<<<<<<< HEAD
            _syncInProgress = YES;
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_save];
            _syncInProgress = NO;
=======
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveWithErrorHandler:^(NSError *error){
                [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
                self.syncInProgress = NO;
                self.progressBlock = nil;
                self.progress = 0;
                
                [self handleError:error];
            }];
>>>>>>> 1de9e8e... Moved the sync to a background thread
        }
        
        return;
    }
    
    //Push changes to remote server and update local object's metadata
    DLog(@"Total number of objects to sync: %i", [objectsToSync count]);
    NSError *error = nil;
    BOOL success = [self.remoteInterface putUpdatedObjects:objectsToSync forClass:entityDesc error:&error];
    if (!success) {
        [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
        self.syncInProgress = NO;
        self.progressBlock = nil;
        self.progress = 0;
        
        [self handleError:error];
    } 
    else {
<<<<<<< HEAD
        _syncInProgress = YES;
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_save];
        _syncInProgress = NO;
=======
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveWithErrorHandler:^(NSError *error){
            [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
            self.syncInProgress = NO;
            self.progressBlock = nil;
            self.progress = 0;
            
            [self handleError:error];
        }];
    }
}

- (void)syncAll {
    if ([NSThread isMainThread]) {
        ALog(@"%@", @"This should NEVER be run on the main thread!!");
        return;
    }
    
    NSManagedObjectModel *dataModel = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSMutableArray *entitiesToSync = [NSMutableArray arrayWithCapacity:1];
    
    for (NSEntityDescription *anEntity in dataModel) {
        NSString *parentEntity = [[anEntity superentity] name];
        
        if ([parentEntity isEqualToString:@"FTASyncParent"]) {
            [entitiesToSync addObject:anEntity];
        }
    }
    
    DLog(@"Syncing %i entities", [entitiesToSync count]);
    float increment = 0.8 / (float)[entitiesToSync count];
    self.progress = 0.1;
    if (self.progressBlock) {
        self.progressBlock(self.progress, @"Starting sync...");
    }
    
    for (NSEntityDescription *anEntity in entitiesToSync) {
        DLog(@"Requesting sync for entity: %@", anEntity);
        [self syncEntity:anEntity];
        
        self.progress += increment;
        if (self.progressBlock)
            self.progressBlock(self.progress, [NSString stringWithFormat:@"Finished sync of %@", [anEntity name]]);
    }
}

- (void)syncWithCompletionBlock:(FTACompletionBlock)completion progressBlock:(FTASyncProgressBlock)progress {
    //Quick sanity check to fail early if a sync is in progress, or cannot be completed
    if (![self.remoteInterface canSync] || self.syncInProgress) {
        return;
    }
    
    self.syncInProgress = YES;
    self.progressBlock = progress;
    self.progress = 0.0;
    if (self.progressBlock) {
        self.progressBlock(self.progress, @"Initializing...");
    }
    
    //Setup background process tags so we can complete on app exit
    UIBackgroundTaskIdentifier bgTask = 0;
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        //Create a background task identifier and specify the exception handler
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            DCLog(@"Background sync on exit failed to complete in time limit");
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            self.syncInProgress = NO;
        }];
    };
    
    [MagicalRecordHelpers performSaveDataOperationInBackgroundWithBlock:^(NSManagedObjectContext *context) {
        //TODO: Is there any user setup needed??
        [self syncAll];
    }completion:^{
        if (self.progressBlock)
            self.progressBlock(1.0, @"Complete");
        
        if (![NSThread isMainThread]) {
            ALog(@"%@", @"Completion block must be called on main thread");
        }
        
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            DCLog(@"Completed sync.");
        }
        
        //Use this notification and user defaults key to update an "Last Updated" message in the UI
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"FTASyncLastSyncDate"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FTASyncDidSync" object:nil];
        
        if (completion)
            completion();
        
        self.syncInProgress = NO;
        self.progressBlock = nil;
        self.progress = 0;
    }];
}

#pragma mark - Error Handling

-(void)handleError:(NSError *)error {
    NSDictionary *userInfo = [error userInfo];
    for (NSArray *detailedError in [userInfo allValues])
    {
        if ([detailedError isKindOfClass:[NSArray class]])
        {
            for (NSError *e in detailedError)
            {
                if ([e respondsToSelector:@selector(userInfo)])
                {
                    DLog(@"Error Details: %@", [e userInfo]);
                }
                else
                {
                    DLog(@"Error Details: %@", e);
                }
            }
        }
        else
        {
            DLog(@"Error: %@", detailedError);
        }
>>>>>>> 1de9e8e... Moved the sync to a background thread
    }
    DLog(@"Error Message: %@", [error localizedDescription]);
    DLog(@"Error Domain: %@", [error domain]);
    DLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

@end
