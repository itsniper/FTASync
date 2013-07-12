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
  [self deleteAllPerseObjects];
  [self deleteAllLocalObjects];
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

- (void)testUploadCreatedLocalObjectToParse {
  [self createLocalObjectAndUploadToParse];
  _isFinished = YES;
}

- (void)testUploadUpdatedLocalObjectToParse {
  [self createLocalObjectAndUploadToParse];
  Person *person = [Person MR_findFirst];
  
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  person = (id)[editingContext existingObjectWithID:[person objectID] error:nil];
  person.name = @"ichiro";
  [person syncUpdate];
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 1);
  assert([[persons[0] syncStatus] isEqualToNumber:@1]);

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  query.limit = 1000;
  persons = [query findObjects];
  assert([persons count] == 1);

  NSDate *lastUpdate = [self personUpdatedAt];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"ichiro"]);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([[persons[0] updatedAt] compare:nowUpdate] == NSOrderedSame);
    assert([lastUpdate compare:nowUpdate] == NSOrderedAscending);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void)testUploadDeletedLocalObjectToParse {
  [self createLocalObjectAndUploadToParse];
  Person *person = [Person MR_findFirst];

  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  person = (id)[editingContext existingObjectWithID:[person objectID] error:nil];
  [Person MR_truncateAllInContext:editingContext];
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 0);

  NSDate *lastUpdate = [self personUpdatedAt];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"taro"]);
    assert([[persons[0] objectForKey:@"deleted"] isEqualToNumber:@1]);

    persons = [Person MR_findAll];
    assert([persons count] == 0);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([lastUpdate compare:nowUpdate] == NSOrderedSame);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void)testStoreCreatedParseObject {
  PFObject *person = [PFObject objectWithClassName:@"CDPerson"];
  [person setObject:@"messi" forKey:@"name"];
  [person save];

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  assert([persons count] == 1);
  assert([[persons[0] objectForKey:@"name"] isEqualToString:@"messi"]);

  persons = [Person MR_findAll];
  assert([persons count] == 0);

  NSDate *lastUpdate = [self personUpdatedAt];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"messi"]);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] name] isEqualToString:@"messi"]);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([[persons[0] updatedAt] compare:nowUpdate] == NSOrderedSame);
    assert([lastUpdate compare:nowUpdate] == NSOrderedSame);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void)testStoreUpdatedParseObject {
  [self createLocalObjectAndUploadToParse];
  
  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  PFObject *person = persons[0];
  [person setObject:@"ichiro" forKey:@"name"];
  [person save];

  NSDate *lastUpdate = [self personUpdatedAt];
  
  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"ichiro"]);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] name] isEqualToString:@"ichiro"]);
    NSLog(@"person: %@", persons[0]);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([[persons[0] updatedAt] compare:nowUpdate] == NSOrderedSame);
    assert([lastUpdate compare:nowUpdate] == NSOrderedAscending);

    _isFinished = YES;
  } progressBlock:nil];
}


- (void)testStoreDeletedParseObject {
  [self createLocalObjectAndUploadToParse];

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  PFObject *person = persons[0];
  [person setObject:@1 forKey:@"deleted"];
  [person save];

  NSDate *lastUpdate = [self personUpdatedAt];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"taro"]);
    assert([[persons[0] objectForKey:@"deleted"] isEqualToNumber:@1]);

    persons = [Person MR_findAll];
    assert([persons count] == 0);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([lastUpdate compare:nowUpdate] == NSOrderedSame);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void)testIgnoreCompleteDeletedParseObject {
  [self createLocalObjectAndUploadToParse];

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  PFObject *person = persons[0];
  [person delete];

  NSDate *lastUpdate = [self personUpdatedAt];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *persons = [query findObjects];
    assert([persons count] == 0);

    persons = [Person MR_findAll];
    assert([persons count] == 1);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([lastUpdate compare:nowUpdate] == NSOrderedSame);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void)testUpdateLocalObjectDeletedInParse {
  [self createLocalObjectAndUploadToParse];

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  PFObject *person = persons[0];
  [person delete];

  Person *localPerson = [Person MR_findFirst];
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  localPerson = (id)[editingContext existingObjectWithID:[localPerson objectID] error:nil];
  localPerson.name = @"ichiro";
  [localPerson syncUpdate];
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *localPersons = [Person MR_findAll];
  assert([localPersons count] == 1);
  assert([[localPersons[0] syncStatus] isEqualToNumber:@1]);

  NSDate *lastUpdate = [self personUpdatedAt];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([lastUpdate compare:nowUpdate] == NSOrderedAscending);

    _isFinished = YES;
  } progressBlock:nil];
}

-(void) testDeleteAllDeletedByRemote {
  [self createLocalObjectAndUploadToParse];

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  PFObject *person = persons[0];
  [person delete];

  [[FTASyncHandler sharedInstance] deleteAllDeletedByRemote];

  NSArray *localPersons = [Person MR_findAll];
  assert([localPersons count] == 0);

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *persons = [query findObjects];
    assert([persons count] == 0);

    persons = [Person MR_findAll];
    assert([persons count] == 0);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void) testSomePFObjectToLocalObjects {
  for (NSInteger i = 0; i < 12; ++i) {
    PFObject *person = [PFObject objectWithClassName:@"CDPerson"];
    [person setObject:[NSString stringWithFormat:@"person%d", i] forKey:@"name"];
    [person save];
  }
  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    NSArray *persons = [Person MR_findAllSortedBy:@"updatedAt" ascending:NO];
    NSLog(@"persons: %@", persons);
    assert([persons count] == 10);
    assert([[persons[0] name] isEqualToString:@"person9"]);

    [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
      NSArray *persons = [Person MR_findAllSortedBy:@"updatedAt" ascending:NO];
      NSLog(@"persons: %@", persons);
      assert([persons count] == 12);
      assert([[persons[0] name] isEqualToString:@"person11"]);

      _isFinished = YES;
    } progressBlock:nil];
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

-(void) createLocalObjectAndUploadToParse {
  _isFinished = NO;
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  Person *person = [Person MR_createInContext:editingContext];
  person.name = @"taro";
  person.updatedAt = [NSDate date];
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 1);
  assert([[persons[0] syncStatus] isEqualToNumber:@2]);

  NSDate *lastUpdate = [self personUpdatedAt];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^{
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"taro"]);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    NSDate *nowUpdate = [self personUpdatedAt];
    assert([[persons[0] updatedAt] compare:nowUpdate] == NSOrderedSame);
    assert([lastUpdate compare:nowUpdate] == NSOrderedAscending);

    _isFinished = YES;
  } progressBlock:nil];

  do {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  } while (!_isFinished);
  
  _isFinished = NO;
}

-(NSDate*) personUpdatedAt {
  NSArray *entities = [FTASyncParent allDescedents];
  NSEntityDescription *entityDesc = entities[0];

  NSDate *lastUpdate = [FTASyncParent FTA_lastUpdateForClass:entityDesc];
  return lastUpdate;
}

@end
