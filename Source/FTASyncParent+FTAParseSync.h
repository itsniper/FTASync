//
//  FTASyncParent+FTAParseSync.h
//  FTASync
//
//  Created by Justin Bergen on 3/14/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Parse/Parse.h>
#import "FTASyncParent.h"

@interface FTASyncParent (FTAParseSync)

+ (FTASyncParent *)FTA_localObjectForClass:(NSEntityDescription *)entityDesc WithRemoteId:(NSString *)objectId;
+ (NSDate *)FTA_lastUpdateForClass:(NSEntityDescription *)entityDesc;

+ (FTASyncParent *)FTA_newObjectForClass:(NSEntityDescription *)entityDesc WithRemoteObject:(PFObject *)parseObject;
- (PFObject *)FTA_remoteObjectForObject;
- (void)FTA_updateObjectWithRemoteObject:(PFObject *)parseObject;
- (void)FTA_updateObjectMetadataWithRemoteObject:(PFObject *)parseObject;

+ (void)FTA_newObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;
+ (void)FTA_updateObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;
+ (void)FTA_deleteObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;

@end
