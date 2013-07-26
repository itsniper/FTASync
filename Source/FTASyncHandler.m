//
//  FTASyncHandler.m
//  FTASync
//
//  Created by Justin Bergen on 3/13/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "FTASync.h"

#define kFTASyncDeletedObjectAging 30 //TODO: Create a method to clean out deleted objects on Parse after above # of days
#define kSyncAutomatically  NO //TODO: Create methods to sync automatically after context save
#define kAutoSyncDelay 30

@interface FTASyncHandler ()

@property (strong, nonatomic) FTAParseSync *remoteInterface;
@property (atomic) float progress;
@property (atomic, copy) FTASyncProgressBlock progressBlock;

- (void)contextWasSaved:(NSNotification *)notification;

- (NSArray *)entitiesToSync;

- (BOOL)resetAllSyncStatusAndDeleteRemote:(BOOL)delete inContext:(NSManagedObjectContext *)context;

- (void)handleError:(NSError *)error;

@end


@implementation FTASyncHandler

@synthesize remoteInterface = _remoteInterface;
@synthesize syncInProgress = _syncInProgress;
@synthesize progress = _progress;
@synthesize progressBlock = _progressBlock;
@synthesize ignoreContextSave = _ignoreContextSave;

#pragma mark - Singleton

+ (FTASyncHandler *)sharedInstance {
    static dispatch_once_t pred;
    static FTASyncHandler *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[FTASyncHandler alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:shared selector:@selector(contextWasSaved:) name:NSManagedObjectContextDidSaveNotification object:[NSManagedObjectContext MR_defaultContext]];
        shared.queryLimit = 10;
        shared.receivedPFObjectDictionary = @{};
    });

    return shared;
}

#pragma mark - Custom Accessors

- (FTAParseSync *)remoteInterface {
    if (!_remoteInterface) {
        _remoteInterface = [[FTAParseSync alloc] init];
    }

    return _remoteInterface;
}

- (NSArray *) receivedPFObjects:(NSString *) entityName {
  return self.receivedPFObjectDictionary[entityName];
}

- (void) setReceivedPFObjects:(NSArray *)receivedPFObjects entityName:(NSString *) entityName {
  NSMutableDictionary *dic = [self.receivedPFObjectDictionary mutableCopy];
  dic[entityName] = receivedPFObjects;
  self.receivedPFObjectDictionary = dic;
}

#pragma mark - CoreData Maintenance

- (void)contextWasSaved:(NSNotification *)notification {
    if (![NSThread isMainThread]) {
        //If this is not on a main thread it is a sync save
        return;
    }

    if (self.isIgnoreContextSave) {
        FSLog(@"%@", @"ignoreContextSave == YES");
        return;
    }

    NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];

    for (NSManagedObject *deletedObject in deletedObjects) {
        FSLog(@"Object was deleted from MOC: %@", deletedObject);
        if ([[deletedObject class] isSubclassOfClass:[FTASyncParent class]] && [deletedObject valueForKey:@"objectId"] != nil) {
            NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [[deletedObject entity] name]];
            NSArray *deletedFromDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
            NSMutableArray *localDeletedObjects = [[NSMutableArray alloc] initWithArray:deletedFromDefaults];

            [localDeletedObjects addObject:[deletedObject valueForKey:@"objectId"]];
            [[NSUserDefaults standardUserDefaults] setObject:localDeletedObjects forKey:defaultsKey];
            FSLog(@"Deleted Object: %@", deletedObject);
            FSLog(@"Deleted objects sent to prefs: %@", localDeletedObjects);
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Metadata

+ (id)getMetadataForKey:(NSString *)key forEntity:(NSString *)entityName inContext:(NSManagedObjectContext *)context {
    NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
    id store = [coordinator persistentStoreForURL:[NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]]];
    NSDictionary *metadata = [coordinator metadataForPersistentStore:store];

    NSDictionary *entityMetadata = [metadata objectForKey:entityName];
    if (!entityMetadata) {
        return nil;
    }

    if (!key) {
        return entityMetadata;
    }

    return [entityMetadata objectForKey:key];
}

+ (void)setMetadataValue:(id)value forKey:(NSString *)key forEntity:(NSString *)entityName inContext:(NSManagedObjectContext *)context {
    NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
    id store = [coordinator persistentStoreForURL:[NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]]];
    NSMutableDictionary *metadata = [[coordinator metadataForPersistentStore:store] mutableCopy];

    if (!key) {
        [metadata setValue:value forKey:entityName];
        [coordinator setMetadata:metadata forPersistentStore:store];
        return;
    }

    NSMutableDictionary *entityMetadata = [[metadata valueForKey:entityName] mutableCopy];
    if (!entityMetadata) {
        entityMetadata = [NSMutableDictionary dictionary];
        [metadata setObject:entityMetadata forKey:entityName];
    }

    [entityMetadata setValue:value forKey:key];
    [metadata setObject:entityMetadata forKey:entityName];
    [coordinator setMetadata:metadata forPersistentStore:store];
}

#pragma mark - Sync Lock
//TODO: Possibly include code to lock and unlock sync on the remote server. Probably an attribute of the parent PFUser.

#pragma mark - Sync


- (NSArray *)entitiesToSync {
    return [FTASyncParent allDescedents];
}

- (BOOL)syncEntity:(NSEntityDescription *)entityDesc {
    if ([NSThread isMainThread]) {
        FSALog(@"%@", @"This should NEVER be run on the main thread!!");
        return NO;
    }

    if (![FTASyncParent isParentOfEntity:entityDesc]) {
        FSALog(@"Requested a sync for an entity (%@) that does not inherit from FTASyncParent!", [entityDesc name]);
        return NO;
    }

    NSMutableArray *objectsToSync = [[NSMutableArray alloc] initWithCapacity:1];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDesc];

    //Add new local objects
    [request setPredicate:[NSPredicate predicateWithFormat:@"syncStatus = nil OR syncStatus = 2 OR syncStatus = 3"]];
    NSArray *newLocalObjects = [NSManagedObject MR_executeFetchRequest:request inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    FSLog(@"Number of new local objects: %i %@", [newLocalObjects count], newLocalObjects);
#ifdef DEBUG
    for (FTASyncParent *object in newLocalObjects) {
        if (object.syncStatusValue == 3) {
            FSLog(@"!!!!!!!OBJECT WITH SYNC STATUS 3!!!!!! %@", object);
        }
    }
#endif
    if ([newLocalObjects count] > 0) {
        [objectsToSync addObjectsFromArray:newLocalObjects];
    }

    NSDate *lastUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];

    //Get updated remote objects
    NSError *error = nil;
    NSMutableArray *remoteObjectsForSync = [[self.remoteInterface getObjectsOfClass:[entityDesc name]
                                                                       updatedSince:lastUpdate
                                                                              error:&error] mutableCopy];

    if (error) {
        FSALog(@"Cannot get objects from parse server (error: %@)", [error description]);
        return NO;
    }

    NSDate *lastFetched = [[remoteObjectsForSync lastObject] updatedAt];

    FSLog(@"Number of remote objects: %i %@", [remoteObjectsForSync count], remoteObjectsForSync);
#ifdef DEBUG
    for (PFObject *object in remoteObjectsForSync) {
        FSLog(@"%@", object.updatedAt);
    }
#endif

    //Remove objects deleted locally from remote sync array (push to remote done in FTAParseSync)
    NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [entityDesc name]];
    NSArray *deletedLocalObjects = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
    FSLog(@"Deleted objects from prefs: %@", deletedLocalObjects);
    NSPredicate *deletedLocalInRemotePredicate = [NSPredicate predicateWithFormat: @"NOT (objectId IN %@)", deletedLocalObjects];
    [remoteObjectsForSync filterUsingPredicate:deletedLocalInRemotePredicate];

    //Add new remote objects
    NSPredicate *newRemotePredicate = nil;
    if (lastUpdate) {
        newRemotePredicate = [NSPredicate predicateWithFormat:@"createdAt > %@ AND (deleted = NO OR deleted = nil)", lastUpdate];
    } else {
        newRemotePredicate = [NSPredicate predicateWithFormat:@"deleted = NO OR deleted = nil"];
    }
    NSArray *newRemoteObjects = [remoteObjectsForSync filteredArrayUsingPredicate:newRemotePredicate];
    FSLog(@"Number of new remote objects: %i %@", [newRemoteObjects count], newRemoteObjects);
    [remoteObjectsForSync removeObjectsInArray:newRemoteObjects];
    [FTASyncParent FTA_newObjectsForClass:entityDesc withRemoteObjects:newRemoteObjects];

    //Remove objects removed on remote
    NSPredicate *deletedRemotePredicate = [NSPredicate predicateWithFormat:@"deleted = YES"];
    NSArray *deletedRemoteObjects = [remoteObjectsForSync filteredArrayUsingPredicate:deletedRemotePredicate];
    [remoteObjectsForSync removeObjectsInArray:deletedRemoteObjects];
    FSLog(@"Number of deleted remote objects: %i %@", [deletedRemoteObjects count], deletedRemoteObjects);
    [FTASyncParent FTA_deleteObjectsForClass:entityDesc withRemoteObjects:deletedRemoteObjects];

    NSMutableArray *remoteObjectsWithACL = [@[] mutableCopy];
    for (PFObject *remoteObject in remoteObjectsForSync) {
      if (remoteObject.ACL != nil){
        [remoteObjectsWithACL addObject:remoteObject];
      }
    }
    remoteObjectsForSync = remoteObjectsWithACL;

    //Sync objects changed on remote
    FSLog(@"Number of updated remote objects: %i", [remoteObjectsForSync count]);
    [FTASyncParent FTA_updateObjectsForClass:entityDesc withRemoteObjects:remoteObjectsForSync];

    if ([NSManagedObjectContext MR_contextForCurrentThread] == [NSManagedObjectContext MR_defaultContext]) {
        FSALog(@"%@", @"Should not be working with the main context!");
    }

    self.ignoreContextSave = YES;
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    self.ignoreContextSave = NO;

    //Sync objects changed locally
    [request setPredicate:[NSPredicate predicateWithFormat:@"syncStatus = 1"]];
    NSArray *updatedLocalObjects = [NSManagedObject MR_executeFetchRequest:request inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    FSLog(@"Number of updated local objects: %i", [updatedLocalObjects count]);
    [objectsToSync addObjectsFromArray:updatedLocalObjects];

    if ([objectsToSync count] < 1 && [deletedLocalObjects count] < 1) {
        FSLog(@"NO OBJECTS TO SYNC");
        if ([deletedRemoteObjects count] > 0) {
            self.ignoreContextSave = YES;
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
            self.ignoreContextSave = NO;
        }

        [FTASyncParent FTA_setLastUpdate:lastFetched forClass:entityDesc];
        return YES;
    }

    //Push changes to remote server and update local object's metadata
    FSLog(@"Total number of objects to sync: %i", [objectsToSync count]);
    error = nil;
    BOOL success = [self.remoteInterface putUpdatedObjects:objectsToSync forClass:entityDesc error:&error];
    if (!success) {
        [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
        self.syncInProgress = NO;
        self.progressBlock = nil;
        self.progress = 0;

        [self handleError:error];
        return NO;
    } else {
      self.ignoreContextSave = YES;
      [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
      self.ignoreContextSave = NO;
      [FTASyncParent FTA_setLastUpdate:lastFetched forClass:entityDesc];
      return YES;
    }
}

- (BOOL)syncAll {
    if ([NSThread isMainThread]) {
        FSALog(@"%@", @"This should NEVER be run on the main thread!!");
        return NO;
    }

    NSArray *entitiesToSync = [self entitiesToSync];

    FSLog(@"Syncing %i entities", [entitiesToSync count]);
    float increment = 0.8 / (float)[entitiesToSync count];
    self.progress = 0.1;
    if (self.progressBlock) {
        self.progressBlock(self.progress, @"Starting sync...");
    }

    for (NSEntityDescription *anEntity in entitiesToSync) {
        FSLog(@"Requesting sync for entity: %@", anEntity);
        BOOL success = [self syncEntity:anEntity];
        if (!success) {
            return NO;
        }

        if (!self.syncInProgress) {
            //Sync had an issue somewhere, so halt
            return NO;
        }

        self.progress += increment;
        if (self.progressBlock)
            self.progressBlock(self.progress, [NSString stringWithFormat:@"Finished sync of %@", [anEntity name]]);
    }

    //Since there is no rollback on the metadata this must not be cleared out until we know a full sync was successful
    for (NSEntityDescription *anEntity in entitiesToSync) {
        [FTASyncHandler setMetadataValue:[NSMutableDictionary dictionary] forKey:nil forEntity:[anEntity name] inContext:[NSManagedObjectContext MR_defaultContext]];
    }

#ifdef DEBUG
    NSPersistentStoreCoordinator *coordinator = [[NSManagedObjectContext MR_defaultContext] persistentStoreCoordinator];
    id store = [coordinator persistentStoreForURL:[NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]]];
    NSDictionary *metadata = [coordinator metadataForPersistentStore:store];
    FSLog(@"METADATA after clear: %@", metadata);
#endif

    return YES;
}

- (void)syncWithCompletionBlock:(FTABoolCompletionBlock)completion progressBlock:(FTASyncProgressBlock)progress {
    //Quick sanity check to fail early if a sync is in progress, or cannot be completed
    if (![self.remoteInterface canSync] || self.syncInProgress) {
        if (completion)
            completion(NO, nil);

        return;
    }

    self.syncInProgress = YES;
    self.progressBlock = progress;
    self.progress = 0.0;
    if (self.progressBlock) {
        self.progressBlock(self.progress, @"Initializing...");
    }

    //Setup background process tags so we can complete on app exit
    __block UIBackgroundTaskIdentifier bgTask = 0;
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        //Create a background task identifier and specify the exception handler
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Background sync on exit failed to complete in time limit");
            //TODO: This is the wrong context since this code will be running on main thread. Is there a way to get
            //   access to the context running [self syncAll] below??
            [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
            self.syncInProgress = NO;
            self.progressBlock = nil;
            self.progress = 0;
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    };

    __block BOOL syncAllResult = NO;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        //TODO: Is there any user setup needed??
        syncAllResult = [self syncAll];
    } completion:^(BOOL success, NSError *error) {
        if (!syncAllResult) {
            completion(NO, nil);
        }

        if (self.progressBlock)
            self.progressBlock(1.0, @"Complete");

        if (![NSThread isMainThread]) {
            FSALog(@"%@", @"Completion block must be called on main thread");
        }

        //Use this notification and user defaults key to update an "Last Updated" message in the UI
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"FTASyncLastSyncDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FTASyncDidSync" object:nil];
            if (completion)
              completion(YES, nil);
        });

        self.syncInProgress = NO;
        self.progressBlock = nil;
        self.progress = 0;

        //End background task
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            FSCLog(@"Completed sync.");
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }
    }];
}

- (BOOL)resetAllSyncStatusAndDeleteRemote:(BOOL)delete inContext:(NSManagedObjectContext *)context {
    NSArray *entitiesToSync = [[FTASyncParent entityInManagedObjectContext:context] subentities];

    FSLog(@"Resetting %i entities", [entitiesToSync count]);
    float increment = 0.8 / (float)[entitiesToSync count];
    self.progress = 0.1;
    if (self.progressBlock) {
        self.progressBlock(self.progress, @"Starting data reset...");
    }

    for (NSEntityDescription *anEntity in entitiesToSync) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:anEntity];
        NSArray *allLocalObjects = [NSManagedObject MR_executeFetchRequest:request inContext:context];

        for (FTASyncParent *object in allLocalObjects) {
            object.createdHereValue = YES;
            object.objectId = nil;
            object.syncStatusValue = 2;
            object.updatedAt = nil;
        }

        //Clear out any deleted objects in User Defaults
        NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [anEntity name]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];

        if (!delete) {
            self.progress += increment;
            if (self.progressBlock)
                self.progressBlock(self.progress, [NSString stringWithFormat:@"Finished reset of %@", [anEntity name]]);
            continue;
        }

        PFQuery *query = [PFQuery queryWithClassName:anEntity.name];
        NSError *error = nil;
        NSArray *allRemoteObjects = [query findObjects:&error];
        if (error) {
            NSLog(@"Query for all remote objects failed with: %@", error);
            [context rollback];
            self.syncInProgress = NO;
            self.progressBlock = nil;
            self.progress = 0;
            [self handleError:error];
            return NO;
        }

        for (PFObject *object in allRemoteObjects) {
            BOOL success = [object delete:&error];
            if (!success) {
                NSLog(@"Deletion of object with ID %@ failed with: %@", object.objectId, error);
                [context rollback];
                self.syncInProgress = NO;
                self.progressBlock = nil;
                self.progress = 0;
                [self handleError:error];
                return NO;
            }
        }

        self.progress += increment;
        if (self.progressBlock)
            self.progressBlock(self.progress, [NSString stringWithFormat:@"Finished reset of %@", [anEntity name]]);
    }

    //Since there is no rollback on the metadata this must not be cleared out until we know a full sync was successful
    for (NSEntityDescription *anEntity in entitiesToSync) {
        [FTASyncHandler setMetadataValue:[NSMutableDictionary dictionary] forKey:nil forEntity:[anEntity name] inContext:context];
    }

#ifdef DEBUG
    NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
    id store = [coordinator persistentStoreForURL:[NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]]];
    NSDictionary *metadata = [coordinator metadataForPersistentStore:store];
    FSLog(@"METADATA after clear: %@", metadata);
#endif

    return YES;
}

- (void)resetAllSyncStatusAndDeleteRemote:(BOOL)delete withCompletionBlock:(FTABoolCompletionBlock)completion progressBlock:(FTASyncProgressBlock)progress {
    if (![self.remoteInterface canSync] || self.syncInProgress) {
        if (completion)
            completion(NO, nil);

        return;
    }

    self.syncInProgress = YES;
    self.progressBlock = progress;
    self.progress = 0.0;
    if (self.progressBlock) {
        self.progressBlock(self.progress, @"Initializing...");
    }

    //Setup background process tags so we can complete on app exit
    __block UIBackgroundTaskIdentifier bgTask = 0;
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        //Create a background task identifier and specify the exception handler
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Background data reset on exit failed to complete in time limit");
            //TODO: This is the wrong context since this code will be running on main thread. Is there a way to get
            //   access to the context running in performSaveData... below??
            [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
            self.syncInProgress = NO;
            self.progressBlock = nil;
            self.progress = 0;
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    };

    __block BOOL didFail = NO;

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        didFail = ![self resetAllSyncStatusAndDeleteRemote:delete inContext:localContext];
    } completion:^(BOOL success, NSError *error) {
        if (self.progressBlock)
            self.progressBlock(1.0, @"Complete");

        if (![NSThread isMainThread]) {
            FSALog(@"%@", @"Completion block must be called on main thread");
        }

        if (completion && !didFail)
            completion(YES, nil);
        else if (completion && didFail)
            completion(NO, nil);

        self.syncInProgress = NO;
        self.progressBlock = nil;
        self.progress = 0;

        //End background task
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            FSCLog(@"Completed data reset sync.");
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }
    }];
}

-(void)deleteEntityDeletedByRemote:(NSEntityDescription *) entityDesc inContext:(NSManagedObjectContext *)context {
    if ([NSThread isMainThread]) {
      FSALog(@"%@", @"This should NEVER be run on the main thread!!");
      return;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];

    NSArray *localObjects = [NSManagedObject MR_executeFetchRequest:request inContext:context];

    NSMutableArray *objectIds = [@[] mutableCopy];
    for (FTASyncParent *object in localObjects) {
        [objectIds addObject:object.objectId];
    }

    PFQuery *query = [PFQuery queryWithClassName:[entityDesc name]];
    [query whereKey:@"objectId" containedIn:objectIds];
    NSArray *parseObjects = [query findObjects];

    NSMutableArray *existingObjectIds = [@[] mutableCopy];
    for (PFObject *parseObject in parseObjects) {
        [existingObjectIds addObject:parseObject.objectId];
    }

    for (FTASyncParent *object in localObjects) {
        if (![existingObjectIds containsObject:object.objectId]) {
            [object MR_deleteInContext:context];
        }
    }
}

-(void)createEntityByRemote:(NSEntityDescription *) entityDesc inContext:(NSManagedObjectContext *)context withParseObjects:(NSMutableArray *)remoteObjectsForSync {
  if ([NSThread isMainThread]) {
    FSALog(@"%@", @"This should NEVER be run on the main thread!!");
    return;
  }

  [FTASyncParent FTA_updateObjectsForClass:entityDesc withRemoteObjects:remoteObjectsForSync];

  if ([NSManagedObjectContext MR_contextForCurrentThread] == [NSManagedObjectContext MR_defaultContext]) {
    FSALog(@"%@", @"Should not be working with the main context!");
  }

  self.ignoreContextSave = YES;
  [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
  self.ignoreContextSave = NO;
}

-(void)deleteAllDeletedByRemote:(FTABoolCompletionBlock)completion {
    if (![self.remoteInterface canSync] || self.syncInProgress) {
      if (completion)
        completion(NO, nil);
      return;
    }

    self.syncInProgress = YES;

    //Setup background process tags so we can complete on app exit
    __block UIBackgroundTaskIdentifier bgTask = 0;
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
      //Create a background task identifier and specify the exception handler
      bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"Background sync on exit failed to complete in time limit");
        //TODO: This is the wrong context since this code will be running on main thread. Is there a way to get
        //   access to the context running [self syncAll] below??
        [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
        self.syncInProgress = NO;
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
      }];
    };

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
      NSArray *entitiesToSync = [[FTASyncParent entityInManagedObjectContext:localContext] subentities];
      for (NSEntityDescription *anEntity in entitiesToSync) {
        [self deleteEntityDeletedByRemote: anEntity inContext:localContext];
      }
    } completion:^(BOOL success, NSError *error) {
      if (![NSThread isMainThread]) {
        FSALog(@"%@", @"Completion block must be called on main thread");
      }

      self.syncInProgress = NO;

      if (completion)
        completion(YES, nil);

      //End background task
      if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        FSCLog(@"Completed sync.");
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
      }
    }];
}

-(void)updateByRemote:(FTABoolCompletionBlock)completion withParseObjects:(NSArray *)parseObjects withEnityName:(NSString *) entityName {
  if (![self.remoteInterface canSync] || self.syncInProgress) {
    if (completion)
      completion(NO, nil);
    return;
  }

  self.syncInProgress = YES;

  //Setup background process tags so we can complete on app exit
  __block UIBackgroundTaskIdentifier bgTask = 0;
  if ([[UIDevice currentDevice] isMultitaskingSupported]) {
    //Create a background task identifier and specify the exception handler
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
      NSLog(@"Background sync on exit failed to complete in time limit");
      //TODO: This is the wrong context since this code will be running on main thread. Is there a way to get
      //   access to the context running [self syncAll] below??
      [[NSManagedObjectContext MR_contextForCurrentThread] rollback];
      self.syncInProgress = NO;
      [[UIApplication sharedApplication] endBackgroundTask:bgTask];
      bgTask = UIBackgroundTaskInvalid;
    }];
  };

  [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:localContext];
    [self createEntityByRemote:entity inContext:localContext withParseObjects:parseObjects];
  } completion:^(BOOL success, NSError *error) {
    if (![NSThread isMainThread]) {
      FSALog(@"%@", @"Completion block must be called on main thread");
    }

    self.syncInProgress = NO;

    if (completion)
      completion(YES, nil);

    //End background task
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
      FSCLog(@"Completed sync.");
      [[UIApplication sharedApplication] endBackgroundTask:bgTask];
      bgTask = UIBackgroundTaskInvalid;
    }
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
                    NSLog(@"Error Details: %@", [e userInfo]);
                }
                else
                {
                    NSLog(@"Error Details: %@", e);
                }
            }
        }
        else
        {
            NSLog(@"Error: %@", detailedError);
        }
    }
    NSLog(@"Error Message: %@", [error localizedDescription]);
    NSLog(@"Error Domain: %@", [error domain]);
    NSLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

@end
