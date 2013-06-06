//
//  FTASyncParent.m
//  FTASyncParent
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


@interface FTASyncParent ()

@property (nonatomic, getter = isTraversing) BOOL traversing;
@property (nonatomic, getter = isFromRelationship) BOOL fromRelationship;

- (void)setupRelationshipObservation;
- (void)teardownRelationshipObservation;

- (NSString *)parseClassname;
- (NSString *)localEntityName;
- (BOOL)shouldUseRemoteObject:(PFObject *)remoteObject insteadOfLocal:(FTASyncParent *)localObject forToMany:(BOOL)isToMany relationship:(NSString *)relationship;

+ (NSArray *)allDecendentsOfEntity:(NSEntityDescription *)entity;

- (void)updateRemoteObject:(PFObject *)parseObject;
- (void)updateObjectWithRemoteObject:(PFObject *)parseObject;


@end


@implementation FTASyncParent

@synthesize remoteObject = _remoteObject;
@synthesize traversing = _traversing;
@synthesize fromRelationship = _fromRelationship;

#pragma mark - Overridden Methods

- (void)awakeFromInsert {
    if ([self managedObjectContext] == [NSManagedObjectContext MR_defaultContext]) {
        [self setupRelationshipObservation];
    }
}

- (void)awakeFromFetch {
    if ([self managedObjectContext] == [NSManagedObjectContext MR_defaultContext]) {
        [self setupRelationshipObservation];
    }
}

- (void)willTurnIntoFault {
    [super willTurnIntoFault];
    
    if ([self managedObjectContext] == [NSManagedObjectContext MR_defaultContext]) {
        [self teardownRelationshipObservation];
    }
}

#pragma mark - Custom Accessors

- (PFObject *)remoteObject {
    //Need this property so that the same PFObject can be used multiple places when I have a new local object and
    //  don't have an objectId to call (PFObject*)objectWithoutDataWithClassName:objectId:
    if (self.isTraversing) {
        return _remoteObject;
    }
    
    if (!_remoteObject || self.objectId) {
        _remoteObject = [PFObject objectWithClassName:[self parseClassname]];
        self.traversing = YES;
        [self updateRemoteObject:self.remoteObject];
        self.traversing = NO;
    }
    
    return _remoteObject;
}

#pragma mark - KVO

- (void)setupRelationshipObservation {
    NSDictionary *relationships = [[self entity] relationshipsByName];
    for (NSString *relationship in relationships) {
        [self addObserver:self forKeyPath:relationship options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    }
}

- (void)teardownRelationshipObservation {
    NSDictionary *relationships = [[self entity] relationshipsByName];
    for (NSString *relationship in relationships) {
        [self removeObserver:self forKeyPath:relationship];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context {
    if (![NSThread isMainThread] || [[FTASyncHandler sharedInstance] isSyncInProgress]) {
        //If this is not on a main thread it is a sync save
        return;
    }
    if ([[FTASyncHandler sharedInstance] isIgnoreContextSave]) {
        FSCLog(@"ignoreContextSave == YES");
        return;
    }
    //TODO: A temporary solution. Why does the ignoreContextSave not work??
    if (![self managedObjectContext]) {
        FSCLog(@"Missing context, likly an ignoreContextSave");
        return;
    }
    
    //Do not handle new objects
    if (self.syncStatus == nil || self.syncStatusValue == 2 || self.syncStatusValue == 3) {
        FSLog(@"New object (%i), skipping ...", self.syncStatusValue);
        FSLog(@"%@", self);
        return;
    }
    
    FSLog(@"Object for %@.%@ was: %@ Now is: %@", [self localEntityName], keyPath, [change objectForKey:NSKeyValueChangeOldKey], [change objectForKey:NSKeyValueChangeNewKey]);
    
    int changeKindKey = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
    NSString *metadataKey = [NSString stringWithFormat:@"%@.%@", self.objectId, keyPath];
    
    if (changeKindKey == NSKeyValueChangeSetting ) {
        FSLog(@"Changing a to-one relationship: %@", metadataKey);
        [FTASyncHandler setMetadataValue:[NSNumber numberWithBool:YES] forKey:metadataKey forEntity:[self localEntityName] inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    }
    else if (changeKindKey == NSKeyValueChangeInsertion || changeKindKey == NSKeyValueChangeRemoval) {
        FSLog(@"Changing a to-many relationship (insert): %@", metadataKey);
        NSMutableArray *currentChanges = [[FTASyncHandler getMetadataForKey:metadataKey forEntity:[self localEntityName] inContext:[NSManagedObjectContext MR_contextForCurrentThread]] mutableCopy];
        
        //Get the objectId for the inserted/removed related object
        NSString *changedObjectId = nil;
        if (changeKindKey == NSKeyValueChangeInsertion) {
            changedObjectId = [[[change objectForKey:NSKeyValueChangeNewKey] anyObject] objectId];
        }
        else {
            changedObjectId = [[[change objectForKey:NSKeyValueChangeOldKey] anyObject] objectId];
        }
        
        if (!changedObjectId) {
            //Relationships to new objects will not have an objectId yet (don't need to track)
            return;
        }
        
        //If needed add related object to the change list
        if (currentChanges == nil) {
            currentChanges = [NSMutableArray arrayWithObject:changedObjectId];
        }
        else {
            if ([currentChanges containsObject:changedObjectId]) {
                return;
            }
            
            [currentChanges addObject:changedObjectId];
        }
        [FTASyncHandler setMetadataValue:currentChanges forKey:metadataKey forEntity:[self localEntityName] inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    }
}

#pragma mark - Helpers

- (NSString *)parseClassname {
    return [self localEntityName];
}

- (NSString *)localEntityName {
    return [[self entity] name];
}

+ (FTASyncParent *)FTA_localObjectForClass:(NSEntityDescription *)entityDesc WithRemoteId:(NSString *)objectId {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"objectId = %@", objectId]];
    FTASyncParent *localObject = [NSManagedObject MR_executeFetchRequestAndReturnFirstObject:request];
    
    return localObject;
}

+ (NSArray *)FTA_localObjectsForClass:(NSEntityDescription *)entityDesc WithRemoteIds:(NSArray *)objectIds {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"objectId IN %@", objectIds]];
    NSArray *localObjects = [NSManagedObject MR_executeFetchRequest:request];
    
    return localObjects;
}

+ (NSDate *)FTA_lastUpdateForClass:(NSEntityDescription *)entityDesc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDesc];
    [fetchRequest setSortDescriptors:[NSManagedObject MR_descendingSortDescriptors:[NSArray arrayWithObject:@"updatedAt"]]];
    
    NSArray *results = [self MR_executeFetchRequest:fetchRequest];
    if([results count] == 0) {
        return nil;
    }
    
    return [[results objectAtIndex:0] valueForKey:@"updatedAt"];
}

- (BOOL)shouldUseRemoteObject:(PFObject *)remoteObject
               insteadOfLocal:(FTASyncParent *)localObject
                    forToMany:(BOOL)isToMany
                 relationship:(NSString *)relationship {
    FSLog(@"Should use remote: %@ or local: %@ for relationship: %@", remoteObject.objectId, localObject.objectId, relationship);
    //BOOL if we are checking a to-one relationship, or NSArray if it is a to-many relationship
    id localChanges = [FTASyncHandler getMetadataForKey:[NSString stringWithFormat:@"%@.%@", self.objectId, relationship] 
                                                    forEntity:[self localEntityName]
                                                    inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    FSLog(@"Local changes: %@", localChanges);
    
    if (self.syncStatusValue == 2 || self.syncStatusValue == 3) {
        FSLog(@"Parent object is new");
        return NO;
    }
    else if([localObject.objectId isEqualToString:remoteObject.objectId]) {
        FSLog(@"Related objects match");
        return NO;
    }
    else if((localObject != nil && localObject.syncStatus == nil) || localObject.syncStatusValue == 2 || localObject.syncStatusValue ==3) {
        //Related object is new locally
        FSLog(@"New local related object");
        return NO;
    }
    else if(localChanges == nil) {
        //No local change, so use remote
        FSLog(@"No local changes, use remote related object");
        return YES;
    }
    else if (isToMany && remoteObject != nil && ![localChanges containsObject:remoteObject.objectId]) {
        //No local change, so use remote
        FSLog(@"No local changes, use remote related object");
        return YES;
    }
    else if (isToMany && localObject != nil && ![localChanges containsObject:localObject.objectId]) {
        //No local change, so use remote
        FSLog(@"No local changes, use remote related object");
        return YES;
    }
    else {
        PFQuery *query = [PFQuery queryWithClassName:[localObject parseClassname]];
        //query.cachePolicy = kPFCachePolicyCacheElseNetwork;
        //TODO: Handle error
        PFObject *remoteForLocalRelatedObject = [query getObjectWithId:localObject.objectId];
        
        if ([[remoteForLocalRelatedObject valueForKey:@"deleted"] boolValue]) {
            //Do nothing and relationship will get set to remote
            FSLog(@"Remote related object is deleted");
        }
        else {
            FSLog(@"Local change trumps remote");
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Ancestry

+ (NSArray *)allDescedents {
    NSMutableArray *children = [NSMutableArray array];
    NSEntityDescription *parentEntity = [self entityInManagedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    [children addObjectsFromArray:[FTASyncParent allDecendentsOfEntity:parentEntity]];
    
    return children;
}

+ (NSArray *)allDecendentsOfEntity:(NSEntityDescription *)entity {
    NSMutableArray *children = [NSMutableArray array];
    for (NSEntityDescription *child in [entity subentities]) {
        if (![child isAbstract]) {
            [children addObject:child];
        }
        [children addObjectsFromArray:[FTASyncParent allDecendentsOfEntity:child]];
    }
    
    return children;
}

+ (BOOL)isParentOfEntity:(NSEntityDescription *)entityDesc {
    NSEntityDescription *parent = [FTASyncParent entityInManagedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    return [entityDesc isKindOfEntity:parent];
}

#pragma mark - Object Conversion

+ (FTASyncParent *)FTA_newObjectForClass:(NSEntityDescription *)entityDesc WithRemoteObject:(PFObject *)parseObject {
    //Make sure a local object doesn't already exist from traversing a relationship
    FTASyncParent *localObject = [FTASyncParent FTA_localObjectForClass:entityDesc WithRemoteId:parseObject.objectId];
    if (localObject) {
        return localObject;
    }
    
    FTASyncParent *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entityDesc name] inManagedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    [newObject setValue:[NSNumber numberWithBool:NO] forKey:@"createdHere"];
    
    //Make sure objectId is set
    newObject.objectId = parseObject.objectId;
    
    return newObject;
}

- (void)updateRemoteObject:(PFObject *)parseObject {
    NSDictionary *attributes = [[self entity] attributesByName];
    NSDictionary *relationships = [[self entity] relationshipsByName];
    
    if (self.objectId) {
        parseObject.objectId = self.objectId;
    }
    else { //New objects need to have the remote-only "deleted" attribute set to 0
        [parseObject setValue:[NSNumber numberWithInt:0] forKey:@"deleted"];
    }
    
    //Set all the attributes
    for (NSString *attribute in attributes) {
        NSObject *value = [self valueForKey:attribute];
        
        //If attribute is NSData, need to convert this to a PFFile
        if ([value isKindOfClass:[NSData class]]) {
            NSString *fileName = nil;
            if (parseObject.objectId) {
                fileName = [NSString stringWithFormat:@"%@-%@.png", parseObject.objectId, attribute];
            }
            else {
                fileName = [NSString stringWithFormat:@"newObj-%@.png", attribute];
            }
            
            PFFile *file = [PFFile fileWithName:fileName data:(NSData *)value];
            [file save];
            [parseObject setObject:file forKey:attribute];
            
            continue;
        }
        
        if (value != nil && ![attribute isEqualToString:@"createdHere"] && ![attribute isEqualToString:@"updatedAt"] && ![attribute isEqualToString:@"syncStatus"] && ![attribute isEqualToString:@"objectId"]) {
            [parseObject setObject:value forKey:attribute];
        }
    }
    
    //Set all the relationships
    if (self.isFromRelationship) {
        //Parse does not do a traversal check ... LAME!! So if we push relationships in both directions
        //   Parse will throw an Exception and crash the app. If we are coming from other entity via
        //   relationship, then skip this object's relationships.
        return;
    }
    for (NSString *relationship in relationships) {
        NSObject *value = [self valueForKey:relationship];
        
        if ([[relationships objectForKey:relationship] isToMany]) {
            //To-many relationship            
            NSSet *relatedObjects = (NSSet *)value;
            NSMutableArray *objectArray = [[NSMutableArray alloc] initWithCapacity:[relatedObjects count]];
            
            //Build an array of PFObject pointers or new PFObjects
            for (FTASyncParent *relatedObject in relatedObjects) {
                //TODO: Update Parse SDK and use the new PFRelation
                PFObject *relatedRemoteObject = nil;
                if (!relatedObject.objectId) {
                    relatedObject.fromRelationship = YES;
                    relatedRemoteObject = relatedObject.remoteObject;
                    relatedObject.fromRelationship = NO;
                    relatedObject.syncStatusValue = 3;
                }
                else {
                    relatedRemoteObject = [PFObject objectWithoutDataWithClassName:[relatedObject parseClassname] objectId:relatedObject.objectId];
                }
                
                [objectArray addObject:relatedRemoteObject];
            }
            
            [parseObject setObject:objectArray forKey:relationship];
        }
        else {
            //To-one relationship
            FTASyncParent *relatedObject = (FTASyncParent *) value;
            PFObject *relatedRemoteObject = nil;
            
            if (!relatedObject) {
                continue;
            }
            else if (!relatedObject.objectId) {
                relatedObject.fromRelationship = YES;
                relatedRemoteObject = relatedObject.remoteObject;
                relatedObject.fromRelationship = NO;
                relatedObject.syncStatusValue = 3;
            }
            else {
                relatedRemoteObject = [PFObject objectWithoutDataWithClassName:[relatedObject parseClassname] objectId:relatedObject.objectId];
            }
            [parseObject setObject:relatedRemoteObject forKey:relationship];
        }
    }
}

- (void)updateObjectWithRemoteObject:(PFObject *)parseObject {
    NSDictionary *attributes = [[self entity] attributesByName];
    NSDictionary *relationships = [[self entity] relationshipsByName];
    
    //Set all the attributes
    if (self.syncStatusValue != 1) { //Local changes take priority
        for (NSString *attribute in attributes) {
            NSString *className = [[attributes valueForKey:attribute] attributeValueClassName];
            
            if ([className isEqualToString:@"NSData"]) {
                PFFile* remoteFile = [parseObject objectForKey:attribute];
                [self setValue:[NSData dataWithData:[remoteFile getData]] forKey:attribute];
                continue;
            }
            
            if (![attribute isEqualToString:@"createdHere"] && ![attribute isEqualToString:@"updatedAt"] && ![attribute isEqualToString:@"syncStatus"] && ![attribute isEqualToString:@"objectId"]) {
                //TODO: Catch NSUndefinedKeyException if key does not exist on PFObject
                [self setValue:[parseObject valueForKey:attribute] forKey:attribute];
            }
        }
    }
    
    //Set all the relationships
    for (NSString *relationship in relationships) {
        NSObject *value = [self valueForKey:relationship];
        NSEntityDescription *destEntity = [[relationships objectForKey:relationship] destinationEntity];
        
        if ([[relationships objectForKey:relationship] isToMany]) {
            //To-many relationship
            NSMutableArray *relatedLocalObjects = [NSMutableArray arrayWithArray:[(NSSet *)value allObjects]];
            NSMutableArray *relatedRemoteObjects = [NSMutableArray arrayWithArray:[parseObject objectForKey:relationship]];
            
            //Empty relationships in a PFObject will return an NSNull object
            if ([relatedRemoteObjects isKindOfClass:[NSNull class]]) {
                continue;
            }
            
            //First need to remove objects no longer in this releationship
            NSMutableArray *remoteObjectIds = [NSMutableArray arrayWithCapacity:[relatedRemoteObjects count]];
            for (PFObject *remoteObject in relatedRemoteObjects) {
                [remoteObjectIds addObject:remoteObject.objectId];
            }
            FSLog(@"Remote Object IDs: %@", remoteObjectIds);
            NSArray *localObjectsForRemoteIds = [FTASyncParent FTA_localObjectsForClass:destEntity WithRemoteIds:remoteObjectIds];
            FSLog(@"Local objects for remote IDs: %@", localObjectsForRemoteIds);
            [relatedLocalObjects removeObjectsInArray:localObjectsForRemoteIds];
            FSLog(@"Walking through removing objects: %@", relatedLocalObjects);
            for (FTASyncParent *localObject in relatedLocalObjects) {
                if (![self shouldUseRemoteObject:nil insteadOfLocal:localObject forToMany:YES relationship:relationship]) {
                    FSLog(@"Keeping local related object");
                    continue;
                }
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@Set", relationship]);
                if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    NSMutableOrderedSet *theSet = [self performSelector:selector];
                    [theSet removeObject:localObject];
#pragma clang diagnostic pop
                }
                else {
                    NSString *selString = NSStringFromSelector(selector);
                    FSALog(@"%@ entity does not respond to selector: %@", [[self entity] name], selString);
                }
            }
            
            //Now add any remotely added objects to the relationship
            [relatedRemoteObjects removeObjectsInArray:localObjectsForRemoteIds];
            FSLog(@"Walking through adding objects: %@", relatedRemoteObjects);
            for (PFObject *relatedRemoteObject in relatedRemoteObjects) {
                FTASyncParent *localObject = [FTASyncParent FTA_localObjectForClass:destEntity WithRemoteId:relatedRemoteObject.objectId];
                
                if (!localObject) {
                    //Related object doesn't exist locally
                    NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [destEntity name]];
                    NSArray *deletedLocalObjects = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
                    if ([deletedLocalObjects containsObject:relatedRemoteObject.objectId]) {
                        FSCLog(@"Related object deleted locally");
                        continue;
                    }
                    
                    FSLog(@"Local object with remoteId %@ in relationship %@ was not found", relatedRemoteObject.objectId, relationship);
                    localObject = [FTASyncParent FTA_newObjectForClass:destEntity WithRemoteObject:relatedRemoteObject];
                    localObject.syncStatusValue = 0; //Object is not new local nor does it have local changes
                }
                else if (![self shouldUseRemoteObject:relatedRemoteObject insteadOfLocal:nil forToMany:YES relationship:relationship]) {
                    FSCLog(@"Using local related object");
                    continue;
                }
                
                //SEL selector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:", [destEntity name]]);
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@Set", relationship]);
                if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    //[self performSelector:selector withObject:localObject];
                    NSMutableOrderedSet *theSet = [self performSelector:selector];
                    [theSet addObject:localObject];
#pragma clang diagnostic pop
                }
                else {
                    NSString *selString = NSStringFromSelector(selector);
                    FSALog(@"%@ entity does not respond to selector: %@", [[self entity] name], selString);
                }
            }
        }
        else {
            //To-one relationship
            PFObject *relatedRemoteObject = [parseObject objectForKey:relationship];
            FTASyncParent *localRelatedObject = [FTASyncParent FTA_localObjectForClass:destEntity WithRemoteId:relatedRemoteObject.objectId];
            FTASyncParent *currentLocalRelatedObject = [self valueForKey:relationship];
            
            if (!localRelatedObject && relatedRemoteObject) {
                //Related object doesn't exist locally
                NSString *defaultsKey = [NSString stringWithFormat:@"FTASyncDeleted%@", [destEntity name]];
                NSArray *deletedLocalObjects = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
                if ([deletedLocalObjects containsObject:relatedRemoteObject.objectId]) {
                    FSCLog(@"Related object deleted locally");
                    continue;
                }
                
                FSLog(@"Local object with remoteId %@ in relationship %@ was not found", relatedRemoteObject.objectId, relationship);
                localRelatedObject = [FTASyncParent FTA_newObjectForClass:destEntity WithRemoteObject:relatedRemoteObject];
                localRelatedObject.syncStatusValue = 0;
            }
            else if(![self shouldUseRemoteObject:relatedRemoteObject insteadOfLocal:currentLocalRelatedObject forToMany:NO relationship:relationship]) {
                continue;
            }
            
            [self setValue:localRelatedObject forKey:relationship];
        }
    }
    
    if (self.syncStatusValue == 2) { 
        //This is a new object from remote so reset syncStatus
        [self FTA_updateObjectMetadataWithRemoteObject:parseObject andResetSyncStatus:YES];
    }
    else {
        //This object maybe be dirty locally so don't reset the syncStatus. This will get done
        //   in FTAParseSync after self gets pushed to remote.
        [self FTA_updateObjectMetadataWithRemoteObject:parseObject andResetSyncStatus:NO];
    }
}

- (void)FTA_updateObjectMetadataWithRemoteObject:(PFObject *)parseObject andResetSyncStatus:(BOOL)resetStatus {
    if (!self.objectId) {
        self.objectId = parseObject.objectId;
    }
    else if (![[self valueForKey:@"objectId"] isEqualToString:parseObject.objectId]) {
        FSALog(@"%@ and %@ values for objectId do not match!!", [self valueForKey:@"objectId"], [parseObject valueForKey:@"objectId"]);
        return;
    }
    
    self.updatedAt = parseObject.updatedAt;
    
    if (resetStatus) {
        self.syncStatusValue = 0;
    }
    
    FSLog(@"%@ after updating metadata with Parse object: %@", [self parseClassname], self);
}

#pragma mark - Batch Updates

+ (void)FTA_newObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects {
    NSMutableDictionary *newLocalObjects = [[NSMutableDictionary alloc] initWithCapacity:[parseObjects count]];
    
    //Create all objects first to ensure all objects exist when setting up relationships
    for (PFObject *newRemoteObject in parseObjects) {
        FTASyncParent *newLocalObject = [FTASyncParent FTA_newObjectForClass:entityDesc WithRemoteObject:newRemoteObject];
        [newLocalObjects setObject:newLocalObject forKey:newRemoteObject.objectId];
    }
    
    //Now that all objects are created locally, we can update attributes and relationships
    for (PFObject *newRemoteObject in parseObjects) {
        FTASyncParent *localObject = [newLocalObjects objectForKey:newRemoteObject.objectId];
        [localObject updateObjectWithRemoteObject:newRemoteObject];
    }
}

+ (void)FTA_updateObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects {
    for (PFObject *remoteObject in parseObjects) {
        FTASyncParent *localObject = [self FTA_localObjectForClass:entityDesc WithRemoteId:remoteObject.objectId];
        if (!localObject) {
            FSALog(@"Could not find local object matching remote object: %@", remoteObject);
            localObject = [FTASyncParent FTA_newObjectForClass:entityDesc WithRemoteObject:remoteObject];
            //break;
        }
        
        [localObject updateObjectWithRemoteObject:remoteObject];
    }
}

+ (void)FTA_deleteObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects {
    for (PFObject *remoteObject in parseObjects) {
        FTASyncParent *localObject = [self FTA_localObjectForClass:entityDesc WithRemoteId:remoteObject.objectId];
        if (!localObject) {
            FSLog(@"Object already removed locally: %@", remoteObject);
        }
        
        [localObject MR_deleteEntity];
    }
}

@end
