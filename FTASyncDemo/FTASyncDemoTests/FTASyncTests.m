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
  [self setUpClass];
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

- (void)testUploadImageDataToParse {
  NSArray *imageNames =  [NSArray arrayWithObjects:@"parse_small.png", @"parse_medium.png", @"parse_large.png", nil];

  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  for (NSString *imageName in imageNames) {
    Person *person = [Person MR_createInContext:editingContext];
    person.name = imageName;
    person.photo = UIImagePNGRepresentation([UIImage imageNamed:imageName]);
  }
  [editingContext MR_saveToPersistentStoreAndWait];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    for (NSString *imageName in imageNames) {
      PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
      [query whereKey:@"name" equalTo:imageName];
      PFObject *remotePerson = [query getFirstObject];
      assert([[[remotePerson objectForKey:@"photo"] getData] isEqualToData:UIImagePNGRepresentation([UIImage imageNamed:imageName])]);
    }
    _isFinished = YES;
  } progressBlock:nil];
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

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *remote_persons = [query findObjects];
    assert([remote_persons count] == 1);
    assert([[remote_persons[0] objectForKey:@"name"] isEqualToString:@"ichiro"]);

    NSArray *local_persons = [Person MR_findAll];
    assert([local_persons count] == 1);
    assert([[local_persons[0] syncStatus] isEqualToNumber:@0]);

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

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *remote_persons = [query findObjects];
    assert([remote_persons count] == 1);
    assert([[remote_persons[0] objectForKey:@"name"] isEqualToString:@"taro"]);
    assert([[remote_persons[0] objectForKey:@"deleted"] isEqualToNumber:@1]);

    NSArray *local_persons = [Person MR_findAll];
    assert([local_persons count] == 0);

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

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *remote_persons = [query findObjects];
    assert([remote_persons count] == 1);
    assert([[remote_persons[0] objectForKey:@"name"] isEqualToString:@"messi"]);

    NSArray *local_persons = [Person MR_findAll];
    assert([local_persons count] == 1);
    assert([[local_persons[0] name] isEqualToString:@"messi"]);
    assert([[local_persons[0] syncStatus] isEqualToNumber:@0]);

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

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *remote_persons = [query findObjects];
    assert([remote_persons count] == 1);
    assert([[remote_persons[0] objectForKey:@"name"] isEqualToString:@"ichiro"]);

    NSArray *local_persons = [Person MR_findAll];
    assert([local_persons count] == 1);
    assert([[local_persons[0] name] isEqualToString:@"ichiro"]);
    NSLog(@"person: %@", local_persons[0]);
    assert([[local_persons[0] syncStatus] isEqualToNumber:@0]);

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

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *remote_persons = [query findObjects];
    assert([remote_persons count] == 1);
    assert([[remote_persons[0] objectForKey:@"name"] isEqualToString:@"taro"]);
    assert([[remote_persons[0] objectForKey:@"deleted"] isEqualToNumber:@1]);

    NSArray *local_persons = [Person MR_findAll];
    assert([local_persons count] == 0);

    _isFinished = YES;
  } progressBlock:nil];
}

- (void)testIgnoreCompleteDeletedParseObject {
  [self createLocalObjectAndUploadToParse];

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  PFObject *person = persons[0];
  [person delete];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *persons = [query findObjects];
    assert([persons count] == 0);

    persons = [Person MR_findAll];
    assert([persons count] == 1);

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

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    _isFinished = YES;
  } progressBlock:nil];
}

-(void) testDeleteAllDeletedByRemote {
  [self createLocalObjectAndUploadToParse];

  PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
  NSArray *persons = [query findObjects];
  PFObject *person = persons[0];
  [person delete];

  [[FTASyncHandler sharedInstance] deleteAllDeletedByRemote:^(BOOL success, NSError *error) {
    assert(success);

    NSArray *localPersons = [Person MR_findAll];
    assert([localPersons count] == 0);

    [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
      assert(success);
      PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
      NSArray *persons = [query findObjects];
      assert([persons count] == 0);

      persons = [Person MR_findAll];
      assert([persons count] == 0);

      _isFinished = YES;
    } progressBlock:nil];
  }];
}

- (void) testSyncHandlerSomeTimes {
  for (NSInteger i = 0; i < 12; ++i) {
    PFObject *person = [PFObject objectWithClassName:@"CDPerson"];
    [person setObject:[NSString stringWithFormat:@"remote_person%d", i] forKey:@"name"];
    [person save];
  }
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  Person *person = [Person MR_createInContext:editingContext];
  person.name = @"local_person";
  [editingContext MR_saveToPersistentStoreAndWait];

  FTASyncHandler *shared = [FTASyncHandler sharedInstance];
  shared.queryLimit = 5;
  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    NSArray *persons = [Person MR_findAllSortedBy:@"updatedAt" ascending:NO];
    assert([persons count] == 6);
    assert([[persons[0] name] isEqualToString:@"local_person"]);
    assert([[persons[1] name] isEqualToString:@"remote_person4"]);

    shared.queryLimit = 5;
    [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
      assert(success);
      NSArray *persons = [Person MR_findAllSortedBy:@"updatedAt" ascending:NO];
      assert([persons count] == 11);
      assert([[persons[0] name] isEqualToString:@"local_person"]);
      assert([[persons[1] name] isEqualToString:@"remote_person9"]);

      shared.queryLimit = 10;
      [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
        assert(success);
        NSArray *persons = [Person MR_findAllSortedBy:@"updatedAt" ascending:NO];
        assert([persons count] == 13);
        assert([[persons[0] name] isEqualToString:@"local_person"]);
        assert([[persons[1] name] isEqualToString:@"remote_person11"]);

        _isFinished = YES;
      } progressBlock:nil];
    } progressBlock:nil];
  } progressBlock:nil];
}

- (void) testSyncFailWhileAnotherSyncInProgress {
  NSManagedObjectContext *editingContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
  Person *person = [Person MR_createInContext:editingContext];
  person.name = @"taro";
  [editingContext MR_saveToPersistentStoreAndWait];

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    _isFinished = YES;
  } progressBlock:nil];
  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(!success);
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
  [editingContext MR_saveToPersistentStoreAndWait];

  NSArray *persons = [Person MR_findAll];
  assert([persons count] == 1);
  assert([[persons[0] syncStatus] isEqualToNumber:@2]);

  [[FTASyncHandler sharedInstance] syncWithCompletionBlock:^(BOOL success, NSError *error) {
    assert(success);
    PFQuery *query = [PFQuery queryWithClassName:@"CDPerson"];
    query.limit = 1000;
    NSArray *persons = [query findObjects];
    assert([persons count] == 1);
    assert([[persons[0] objectForKey:@"name"] isEqualToString:@"taro"]);

    persons = [Person MR_findAll];
    assert([persons count] == 1);
    assert([[persons[0] syncStatus] isEqualToNumber:@0]);

    _isFinished = YES;
  } progressBlock:nil];

  do {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  } while (!_isFinished);
  
  _isFinished = NO;
}

@end
