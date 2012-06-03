//
//  FTASyncHandler.h
//  FTASync
//
//  Created by Justin Bergen on 3/13/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FTAParseSync.h"

typedef void (^FTASyncProgressBlock)(float progress, NSString* message);
typedef void (^FTACompletionBlock)(void);


@interface FTASyncHandler : NSObject {
    
}

@property (strong, nonatomic) FTAParseSync *remoteInterface;
@property (atomic, getter = isSyncInProgress) BOOL syncInProgress;
@property (atomic) float progress;
@property (atomic, copy) FTASyncProgressBlock progressBlock;
@property (nonatomic, getter = isIgnoreContextSave) BOOL ignoreContextSave;

+(FTASyncHandler *)sharedInstance;

- (void)contextWasSaved:(NSNotification *)notification;

- (void)syncAll;
- (void)syncEntity:(NSEntityDescription *)entityName;
- (void)syncAll;
- (void)syncWithCompletionBlock:(FTACompletionBlock)completion progressBlock:(FTASyncProgressBlock)progress;

-(void)handleError:(NSError *)error;

@end
