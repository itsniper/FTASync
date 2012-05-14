//
//  NSManagedObject+FTAParseSync.h
//  FTASync
//
//  Created by Justin Bergen on 3/14/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Parse/Parse.h>

@interface NSManagedObject (FTAParseSync)

+ (void)FTA_newObjectForClass:(NSEntityDescription *)entityDesc WithRemoteObject:(PFObject *)parseObject;
+ (NSDate *)FTA_lastUpdateForClass:(NSEntityDescription *)entityDesc;

- (PFObject *)FTA_remoteObjectForObject;
- (void)FTA_updateObjectWithRemoteObject:(PFObject *)parseObject;
- (void)FTA_updateObjectMetadataWithRemoteObject:(PFObject *)parseObject;

@end
