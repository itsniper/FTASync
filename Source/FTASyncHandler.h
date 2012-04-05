//
//  FTASyncHandler.h
//  FTASync
//
//  Created by Justin Bergen on 3/13/12.
//  Copyright (c) 2012 Five3 Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Parse/Parse.h>
#import "CoreData+MagicalRecord.h"
#import "FTAParseSync.h"
#import "FTASyncParent.h"
#import "NSManagedObject+FTAParseSync.h"

#define kFTASyncDeletedObjectAging 30
//TODO: Create a method to clean out deleted objects on Parse after above # of days

@interface FTASyncHandler : NSObject {
    BOOL _syncInProgress;
}

@property (strong, nonatomic) FTAParseSync *remoteInterface;

+(FTASyncHandler *)sharedInstance;

- (void)contextWasSaved:(NSNotification *)notification;

- (void)syncAll;
- (void)syncEntity:(NSEntityDescription *)entityName;

@end
