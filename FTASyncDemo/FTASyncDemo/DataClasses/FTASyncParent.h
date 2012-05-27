#import "_FTASyncParent.h"
#import <Parse/Parse.h>

@interface FTASyncParent : _FTASyncParent {}

@property (strong, nonatomic) PFObject *remoteObject;
@property (nonatomic, getter = isTraversing) BOOL traversing;

+ (FTASyncParent *)FTA_localObjectForClass:(NSEntityDescription *)entityDesc WithRemoteId:(NSString *)objectId;
+ (NSArray *)FTA_localObjectsForClass:(NSEntityDescription *)entityDesc WithRemoteIds:(NSArray *)objectIds;
+ (NSDate *)FTA_lastUpdateForClass:(NSEntityDescription *)entityDesc;

+ (FTASyncParent *)FTA_newObjectForClass:(NSEntityDescription *)entityDesc WithRemoteObject:(PFObject *)parseObject;
- (void)FTA_updateRemoteObject:(PFObject *)parseObject;
- (void)FTA_updateObjectWithRemoteObject:(PFObject *)parseObject;
- (void)FTA_updateObjectMetadataWithRemoteObject:(PFObject *)parseObject;

+ (void)FTA_newObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;
+ (void)FTA_updateObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;
+ (void)FTA_deleteObjectsForClass:(NSEntityDescription *)entityDesc withRemoteObjects:(NSArray *)parseObjects;

@end
