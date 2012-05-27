#import "FTASyncParent.h"

@implementation FTASyncParent

@synthesize remoteObject = _remoteObject;
@synthesize traversing = _traversing;

#pragma - Custom Accessors

- (PFObject *)remoteObject {
    //Need this property so that the same PFObject can be used multiple places when I have a new local object and
    //  don't have an objectId to call (PFObject*)objectWithoutDataWithClassName:objectId:
    if (self.isTraversing) {
        return _remoteObject;
    }
    
    if (!_remoteObject || self.objectId) {
        _remoteObject = [PFObject objectWithClassName:NSStringFromClass([self class])];
        self.traversing = YES;
        [self FTA_updateRemoteObject:self.remoteObject];
        self.traversing = NO;
    }
    
    return _remoteObject;
}

#pragma - Helpers

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

#pragma - Object Conversion

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

- (void)FTA_updateRemoteObject:(PFObject *)parseObject {
    NSArray *attributes = [[[self entity] attributesByName] allKeys];
    NSArray *relationships = [[[self entity] relationshipsByName] allKeys];
    //PFObject *parseObject = [PFObject objectWithClassName:NSStringFromClass([self class])];
    
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
    for (NSString *relationship in relationships) {
        NSObject *value = [self valueForKey:relationship];
        //TODO: Will the actual classes be preserved through here??
        
        if ([value isKindOfClass:[NSSet class]]) {
            //To-many relationship            
            NSSet *relatedObjects = (NSSet *)value;
            NSMutableArray *objectArray = [[NSMutableArray alloc] initWithCapacity:[relatedObjects count]];
            
            //Build an array of PFObject pointers or new PFObjects
            for (FTASyncParent *relatedObject in relatedObjects) {
                //TODO: Update Parse SDK and use the new PFRelation
                PFObject *relatedRemoteObject = nil;
                if (!relatedObject.objectId) {
                    relatedRemoteObject = relatedObject.remoteObject;
                    relatedObject.syncStatusValue = 3;
                }
                else {
                    relatedRemoteObject = [PFObject objectWithoutDataWithClassName:NSStringFromClass([relatedObject class]) objectId:relatedObject.objectId];
                }
                
                [objectArray addObject:relatedRemoteObject];
            }
            
            [parseObject setObject:objectArray forKey:relationship];
        }
        else if ([value isKindOfClass:[FTASyncParent class]]) {
            //To-one relationship
            FTASyncParent *relatedObject = (FTASyncParent *) value;
            PFObject *relatedRemoteObject = nil;
            if (!relatedObject.objectId) {
                relatedRemoteObject = relatedObject.remoteObject;
                relatedObject.syncStatusValue = 3;
            }
            else {
                relatedRemoteObject = [PFObject objectWithoutDataWithClassName:NSStringFromClass([relatedObject class]) objectId:relatedObject.objectId];
            }
            [parseObject setObject:relatedRemoteObject forKey:relationship];
        }
    }
}

- (void)FTA_updateObjectWithRemoteObject:(PFObject *)parseObject {
    NSDictionary *attributes = [[self entity] attributesByName];
    NSDictionary *relationships = [[self entity] relationshipsByName];
    
    //Set all the attributes
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
    
    //Set all the relationships
    for (NSString *relationship in relationships) {
        NSObject *value = [self valueForKey:relationship];
        NSEntityDescription *destEntity = [[relationships objectForKey:relationship] destinationEntity];
        //TODO: Will the actual classes be preserved through here??
        
        if ([value isKindOfClass:[NSSet class]]) {
            //To-many relationship
            NSMutableArray *relatedLocalObjects = [NSMutableArray arrayWithArray:[(NSSet *)value allObjects]];
            NSArray *relatedRemoteObjects = [parseObject objectForKey:relationship];
            
            //Empty relationships in a PFObject will return an NSNull object
            if ([relatedRemoteObjects isKindOfClass:[NSNull class]]) {
                continue;
            }
            
            //First need to remove objects no longer in this releationship
            NSMutableArray *remoteObjectIds = [NSMutableArray arrayWithCapacity:[relatedRemoteObjects count]];
            for (PFObject *remoteObject in relatedRemoteObjects) {
                [remoteObjectIds addObject:remoteObject.objectId];
            }
            NSArray *localObjectsForRemoteIds = [FTASyncParent FTA_localObjectsForClass:destEntity WithRemoteIds:remoteObjectIds];
            [relatedLocalObjects removeObjectsInArray:localObjectsForRemoteIds];
            for (NSManagedObject *localObject in relatedLocalObjects) {
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"remove%@Object:", [destEntity name]]);
                if ([self respondsToSelector:selector]) {
                    [self performSelector:selector withObject:localObject];
                } 
                //[(NSMutableSet *)value removeObject:localObject];
            }
            
            for (PFObject *relatedRemoteObject in relatedRemoteObjects) {
                FTASyncParent *localObject = [FTASyncParent FTA_localObjectForClass:destEntity WithRemoteId:relatedRemoteObject.objectId];
                
                if (!localObject) {
                    //Object on the other side of the relationship doesn't exist
                    DLog(@"Local object with remoteId %@ in relationship %@ was not found", relatedRemoteObject.objectId, relationship);
                    localObject = [FTASyncParent FTA_newObjectForClass:destEntity WithRemoteObject:relatedRemoteObject];
                    //localObject.syncStatusValue = 3;
                }
                else if ([(NSMutableSet *)value containsObject:localObject]) {
                    continue;
                }
                
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:", [destEntity name]]);
                if ([self respondsToSelector:selector]) {
                    [self performSelector:selector withObject:localObject];
                } 
                //[(NSMutableSet *)value addObject:localObject];
            }
        }
        else if ([value isKindOfClass:[FTASyncParent class]]) {
            //To-one relationship
            PFObject *relatedRemoteObject = [parseObject objectForKey:relationship];
            FTASyncParent *localRelatedObject = [FTASyncParent FTA_localObjectForClass:destEntity WithRemoteId:relatedRemoteObject.objectId];
            
            if (!localRelatedObject) {
                //Object on the other side of the relationship doesn't exist
                DLog(@"Local object with remoteId %@ in relationship %@ was not found", relatedRemoteObject.objectId, relationship);
                localRelatedObject = [FTASyncParent FTA_newObjectForClass:destEntity WithRemoteObject:relatedRemoteObject];
                //localRelatedObject.syncStatusValue = 3;
            }
            
            [self setValue:localRelatedObject forKey:relationship];
        }
    }
    
    [self FTA_updateObjectMetadataWithRemoteObject:parseObject];
}

- (void)FTA_updateObjectMetadataWithRemoteObject:(PFObject *)parseObject {
    if (!self.objectId) {
        self.objectId = parseObject.objectId;
    }
    else if (![[self valueForKey:@"objectId"] isEqualToString:parseObject.objectId]) {
        ALog(@"%@ and %@ values for objectId do not match!!", [self valueForKey:@"objectId"], [parseObject valueForKey:@"objectId"]);
        return;
    }
    
    self.updatedAt = parseObject.updatedAt;
    self.syncStatusValue = 0;
    
    DLog(@"%@ after updating metadata with Parse object: %@", [[self entity] name], self);
}

#pragma - Batch Updates

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
        [localObject FTA_updateObjectWithRemoteObject:newRemoteObject];
    }
}

+ (void)FTA_updateObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects {
    for (PFObject *remoteObject in parseObjects) {
        FTASyncParent *localObject = [self FTA_localObjectForClass:entityDesc WithRemoteId:remoteObject.objectId];
        if (!localObject) {
            ALog(@"Could not find local object matching remote object: @%", remoteObject);
            break;
        }
        
        //Local changes take priority over remote changes
        if (localObject.syncStatusValue != 1) {
            [localObject FTA_updateObjectWithRemoteObject:remoteObject];
        }
    }
}

+ (void)FTA_deleteObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects {
    for (PFObject *remoteObject in parseObjects) {
        FTASyncParent *localObject = [self FTA_localObjectForClass:entityDesc WithRemoteId:remoteObject.objectId];
        if (!localObject) {
            DLog(@"Object already removed locally: %@", remoteObject);
        }
        
        [localObject MR_deleteEntity];
    }
}

@end
