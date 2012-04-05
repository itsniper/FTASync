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

+ (void)FTA_newObjectForClass:(NSEntityDescription *)entityDesc WithParseObject:(PFObject *)parseObject;
+ (NSDate *)FTA_lastUpdateForClass:(NSEntityDescription *)entityDesc;

- (PFObject *)FTA_parseObjectForObject;
- (void)FTA_updateObjectWithParseObject:(PFObject *)parseObject;
- (void)FTA_updateObjectMetadataWithParseObject:(PFObject *)parseObject;

@end
