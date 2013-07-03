//
//  FTASyncDemoTests.m
//  FTASyncDemoTests
//
//  Created by Justin Bergen on 4/1/12.
//  Copyright (c) 2012 Five3 Apps. All rights reserved.
//

#import "FTASyncTests.h"
#import "CoreData+MagicalRecord.h"
#import <Parse/Parse.h>
#import "ParseKeys.h"

@implementation FTASyncDemoTests

- (void)setUp {
  [super setUp];
  [MagicalRecord setupAutoMigratingCoreDataStack];

  [Parse setApplicationId:kParseAppId
                clientKey:kParseClientKey];
  [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];
}

- (void)tearDown {
  [super tearDown];
  [MagicalRecord cleanUp];
}

- (void)testUploadParseFromLocalObject {
  [self deleteAllPerseObject];
  PFObject *person = [PFObject objectWithClassName:@"person"];
  [person setObject:@"ichiro" forKey:@"name"];
  assert([person save]);
}

- (void) deleteAllPerseObject {
  PFQuery *query = [PFQuery queryWithClassName:@"person"];
  query.limit = 1000;
  NSArray *persons = [query findObjects];
  for (PFObject *person in persons) {
    assert([person delete]);
  }
}

@end
