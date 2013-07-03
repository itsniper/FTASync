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

@implementation FTASyncDemoTests {
  BOOL _isFinished;
}

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
  if (![PFUser currentUser]) {
    [user signUp];
  }
  _isFinished = NO;
}

- (void)tearDown {
  // wait for using multi thread
  do {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  } while (!_isFinished);
  [super tearDown];
  [self deleteAllPerseObjects];
  [self deleteAllLocalObjects];
  [MagicalRecord cleanUp];
}

- (void)testUploadParseFromCreatedLocalObject {
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  Person *person = [Person MR_createInContext:editingContext];
  person.name = @"taro";
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 1);
  assert([[persons[0] syncStatus] isEqualToNumber:@2]);


  NSEntityDescription *entity =[NSEntityDescription entityForName:@"CDParson" inManagedObjectContext: [NSManagedObjectContext MR_defaultContext]];
  NSDate *lastUpdate = [FTASyncParent FTA_lastUpdateForClass:entity];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"taro"]);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    //nowUpdate and lastUpdate is same because the parse objects aren't imported
    NSDate *nowUpdate = [FTASyncParent FTA_lastUpdateForClass:entity];
    assert([lastUpdate compare:nowUpdate] == NSOrderedSame);
  } progressBlock:nil];
}

//- (void)testUploadParseFromUpdatedLocalObject {
  //NSLog(@"next");
//}


- (void) deleteAllPerseObjects {
  NSArray *entityNames = @[@"CDPerson"];
  for (NSString *name in entityNames) {
    PFQuery *query = [PFQuery queryWithClassName:name];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    for (PFObject *person in persons) {
      assert([person delete]);
    }
  }
}

-(void) deleteAllLocalObjects {
  [FTASyncHandler sharedInstance].ignoreContextSave = YES;
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_context];
  [Person MR_truncateAllInContext:editingContext];
  [editingContext MR_saveToPersistentStoreAndWait];
  [FTASyncHandler sharedInstance].ignoreContextSave = NO;
  [[NSUserDefaults standardUserDefaults] setObject:[[NSMutableArray alloc] init] forKey:@"FTASyncDeletedCDPerson"];
}

@end
