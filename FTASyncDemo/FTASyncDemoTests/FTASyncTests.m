//
//  FTASyncDemoTests.m
//  FTASyncDemoTests
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import "FTASyncTests.h"
#import <CoreData/CoreData.h>
#import "CoreData+MagicalRecord.h"
#import <Parse/Parse.h>
#import "ParseKeys.h"
#import "Person.h"
#import "FTASyncHandler.h"

@implementation FTASyncDemoTests

- (void)setUp {
  [super setUp];
  [MagicalRecord setupAutoMigratingCoreDataStack];

  [Parse setApplicationId:kParseAppId
                clientKey:kParseClientKey];
  [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];

  [FTASyncHandler sharedInstance];

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
  NSString *username = [formatter stringFromDate:[NSDate date]];
  PFUser *user = [[PFUser alloc] init];
  user.username = username;
  user.password = @"test";
  [user signUp];
}

- (void)tearDown {
  [super tearDown];
  [MagicalRecord cleanUp];
}

- (void)testUploadParseFromLocalObject {
  [self deleteAllPerseObjects];
  [self deleteAllLocalObjects];

  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  Person *person = [Person MR_createInContext:editingContext];
  person.name = @"taro";
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 1);

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"person"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] name] isEqualToString:@"taro"]);
    NSLog(@"complete testUploadParseFromLocalObject");
  } progressBlock:nil];
}

- (void) deleteAllPerseObjects {
  PFQuery *query = [PFQuery queryWithClassName:@"person"];
  query.limit = 1000;
  NSArray *persons = [query findObjects];
  for (PFObject *person in persons) {
    assert([person delete]);
  }
}

-(void) deleteAllLocalObjects {
  NSArray *allEntities = [NSManagedObjectModel MR_defaultManagedObjectModel].entities;

  [allEntities enumerateObjectsUsingBlock:^(NSEntityDescription *entityDescription, NSUInteger idx, BOOL *stop) {
    [NSClassFromString([entityDescription managedObjectClassName]) MR_truncateAll];
  }];
}

@end
