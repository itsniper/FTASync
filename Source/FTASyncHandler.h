//
//  FTASyncHandler.h
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

typedef void (^FTASyncProgressBlock)(float progress, NSString* message);
typedef void (^FTACompletionBlock)(void);
typedef void (^FTABoolCompletionBlock)(BOOL success, NSError* error);


@interface FTASyncHandler : NSObject {
    
}

@property (atomic, getter = isSyncInProgress) BOOL syncInProgress;
@property (nonatomic, getter = isIgnoreContextSave) BOOL ignoreContextSave;
@property (atomic) NSInteger queryLimit;
@property (strong, atomic) NSDictionary *receivedPFObjectDictionary;

+ (FTASyncHandler *)sharedInstance;

+ (NSString *)getMetadataForKey:(NSString *)key forEntity:(NSString *)entityName inContext:(NSManagedObjectContext *)context;
+ (void)setMetadataValue:(id)value forKey:(NSString *)key forEntity:(NSString *)entityName inContext:(NSManagedObjectContext *)context;

- (NSArray *) receivedPFObjects:(NSString *) entityName;
- (void) setReceivedPFObjects:(NSArray *)receivedPFObjects entityName:(NSString *) entityName;

- (void)syncWithCompletionBlock:(FTABoolCompletionBlock)completion progressBlock:(FTASyncProgressBlock)progress;

- (void)resetAllSyncStatusAndDeleteRemote:(BOOL)delete withCompletionBlock:(FTABoolCompletionBlock)completion progressBlock:(FTASyncProgressBlock)progress;

-(void)deleteAllDeletedByRemote:(FTABoolCompletionBlock)completion;

-(void)updateByRemote:(FTABoolCompletionBlock)completion withParseObjects:(NSArray *)parseObjects withEnityName:(NSString *) entityName;



@end
