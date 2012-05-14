//
//  FTASyncParent+FTAParseSync.m
//  FTASync
//
//  Created by Justin Bergen on 3/14/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import "FTASyncParent+FTAParseSync.h"

@implementation FTASyncParent (FTAParseSync)

#pragma - Helpers

+ (FTASyncParent *)FTA_localObjectForClass:(NSEntityDescription *)entityDesc WithRemoteId:(NSString *)objectId {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"objectId == %@", objectId]];
    FTASyncParent *localObject = [NSManagedObject MR_executeFetchRequestAndReturnFirstObject:request];
    
    return localObject;
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
    FTASyncParent *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entityDesc name] inManagedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    [newObject setValue:[NSNumber numberWithBool:NO] forKey:@"createdHere"];
    
    return newObject;
}

- (PFObject *)FTA_remoteObjectForObject {
    NSArray *attributes = [[[self entity] attributesByName] allKeys];
    PFObject *parseObject = [PFObject objectWithClassName:[[self entity] name]];
    
    for (NSString *attribute in attributes) {
        NSObject *value = [self valueForKey:attribute];
        
        if (value != nil && ![attribute isEqualToString:@"createdHere"] && ![attribute isEqualToString:@"updatedAt"] && ![attribute isEqualToString:@"syncStatus"] && ![attribute isEqualToString:@"objectId"]) {
            [parseObject setObject:value forKey:attribute];
        }
    }
    
    if ([self valueForKey:@"syncStatus"] != [NSNumber numberWithInt:2]) {
        parseObject.objectId = [self valueForKey:@"objectId"];
    }
    else {
        [parseObject setValue:[NSNumber numberWithInt:0] forKey:@"deleted"];
    }
        
    return parseObject;
}

- (void)FTA_updateObjectWithRemoteObject:(PFObject *)parseObject {
    NSArray *attributes = [[[self entity] attributesByName] allKeys];
    for (NSString *attribute in attributes) {
        if (![attribute isEqualToString:@"createdHere"] && ![attribute isEqualToString:@"updatedAt"] && ![attribute isEqualToString:@"syncStatus"] && ![attribute isEqualToString:@"objectId"]) {
            //TODO: Catch NSUndefinedKeyException if key does not exist on PFObject
            [self setValue:[parseObject valueForKey:attribute] forKey:attribute];
        }
    }
    
    [self FTA_updateObjectMetadataWithRemoteObject:parseObject];
}

- (void)FTA_updateObjectMetadataWithRemoteObject:(PFObject *)parseObject {
    if ([self valueForKey:@"syncStatus"] == [NSNumber numberWithInt:2] || [self valueForKey:@"syncStatus"] == nil) {
        [self setValue:parseObject.objectId forKey:@"objectId"];
    }
    else if (![[self valueForKey:@"objectId"] isEqualToString:parseObject.objectId]) {
        ALog(@"%@ and %@ values for objectId do not match!!", [self valueForKey:@"objectId"], [parseObject valueForKey:@"objectId"]);
        return;
    }

    [self setValue:parseObject.updatedAt forKey:@"updatedAt"];
    [self setValue:[NSNumber numberWithInt:0] forKey:@"syncStatus"];
    
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
        if (![localObject.syncStatus intValue] == 1) {
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
