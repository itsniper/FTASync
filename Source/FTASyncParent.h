//
//  FTASyncParent.h
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

#import "_FTASyncParent.h"
#import <Parse/Parse.h>

@interface FTASyncParent : _FTASyncParent {}

@property (strong, nonatomic) PFObject *remoteObject;

+ (BOOL)readOnly;

+ (FTASyncParent *)FTA_localObjectForClass:(NSEntityDescription *)entityDesc WithRemoteId:(NSString *)objectId;
+ (NSArray *)FTA_localObjectsForClass:(NSEntityDescription *)entityDesc WithRemoteIds:(NSArray *)objectIds;
+ (NSDate *)FTA_lastUpdateForClass:(NSEntityDescription *)entityDesc;

+ (NSArray *)allDescendants;
+ (BOOL)isParentOfEntity:(NSEntityDescription *)entityDesc;

+ (FTASyncParent *)FTA_newObjectForClass:(NSEntityDescription *)entityDesc WithRemoteObject:(PFObject *)parseObject;
- (void)FTA_updateObjectMetadataWithRemoteObject:(PFObject *)parseObject andResetSyncStatus:(BOOL)resetStatus;

+ (void)FTA_newObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;
+ (void)FTA_updateObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;
+ (void)FTA_deleteObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;

@end
