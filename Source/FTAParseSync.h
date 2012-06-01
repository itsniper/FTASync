//
//  FTAParseSync.h
//  FTASync
//
//  Created by Justin Bergen on 3/16/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "FTASyncParent.h"
#import "KSReachability.h"

@interface FTAParseSync : NSObject

@property (strong, nonatomic) KSReachability *reachability;

- (BOOL)canSync;

- (NSArray *)getObjectsOfClass:(NSString *)className updatedSince:(NSDate *)lastUpdate;
- (BOOL)putUpdatedObjects:(NSArray *)updatedObjects forClass:(NSEntityDescription *)entityDesc error:(NSError **)error;

- (BOOL)deleteObjects:(NSArray *)objects olderThan:(NSDate *)date;

@end
