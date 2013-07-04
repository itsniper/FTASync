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

- (void)setUpClass;
{
  [MagicalRecord setupAutoMigratingCoreDataStack];

  [Parse setApplicationId:kParseAppId
                clientKey:kParseClientKey];
  [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
  NSString *username = [formatter stringFromDate:[NSDate date]];
  PFUser *user = [[PFUser alloc] init];
  user.username = username;
  user.password = @"test";
  [user signUp];
  NSLog(@"username: %@ objectId: %@", username, user.objectId);

  [FTASyncHandler sharedInstance];
}

- (void)setUp {
  //[MagicalRecord setupAutoMigratingCoreDataStack];
  [super setUp];
  _isFinished = NO;
}

- (void)tearDown {
  // wait for using multi thread
  do {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  } while (!_isFinished);
  //[MagicalRecord cleanUp];
  [super tearDown];
}

- (void)testUploadParseFromCreatedLocalObject {
  [self deleteAllPerseObjects];
  [self deleteAllLocalObjects];

  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  Person *person = [Person MR_createInContext:editingContext];
  person.name = @"taro";
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 1);
  assert([[persons[0] syncStatus] isEqualToNumber:@2]);


  NSArray *entities = [FTASyncParent allDescedents];
  NSEntityDescription *entityDesc = entities[0];

  NSDate *lastUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];

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
    NSDate *nowUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];
    assert([lastUpdate compare:nowUpdate] == NSOrderedSame);

     _isFinished = YES;
  } progressBlock:nil];
}

- (void)testUploadParseFromUpdatedLocalObject {
  Person *person = [Person MR_findFirst];
  
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  person = (id)[editingContext existingObjectWithID:[person objectID] error:nil];
  person.name = @"ichiro";
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 1);
  assert([[persons[0] syncStatus] isEqualToNumber:@1]);

  NSArray *entities = [FTASyncParent allDescedents];
  NSEntityDescription *entityDesc = entities[0];

  NSDate *lastUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"ichiro"]);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    NSDate *nowUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];
    assert([lastUpdate compare:nowUpdate] == NSOrderedAscending);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void)testUploadParseFromDeletedLocalObject {
  Person *person = [Person MR_findFirst];

  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  person = (id)[editingContext existingObjectWithID:[person objectID] error:nil];
  [Person MR_truncateAllInContext:editingContext];
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 0);

  NSArray *entities = [FTASyncParent allDescedents];
  NSEntityDescription *entityDesc = entities[0];

  NSDate *lastUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"ichiro"]);
    assert([[persons[0] objectForKey:@"deleted"] isEqualToNumber:@1]);

    persons = [Person MR_findAll];
    assert([persons count] == 0);

    NSDate *nowUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];
    assert([lastUpdate compare:nowUpdate] == NSOrderedAscending);

    _isFinished = YES;
  } progressBlock:nil];
}

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
  NSArray *persons = [Person MR_findAll];
  for (Person *person in persons) {
    [person MR_deleteEntity];
  }
  [[NSUserDefaults standardUserDefaults] setObject:[[NSMutableArray alloc] init] forKey:@"FTASyncDeletedCDPerson"];
}


@end
