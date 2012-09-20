// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to FTASyncParent.h instead.

#import <CoreData/CoreData.h>


extern const struct FTASyncParentAttributes {
	__unsafe_unretained NSString *createdHere;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *syncStatus;
	__unsafe_unretained NSString *updatedAt;
} FTASyncParentAttributes;

extern const struct FTASyncParentRelationships {
} FTASyncParentRelationships;

extern const struct FTASyncParentFetchedProperties {
} FTASyncParentFetchedProperties;







@interface FTASyncParentID : NSManagedObjectID {}
@end

@interface _FTASyncParent : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (FTASyncParentID*)objectID;




@property (nonatomic, strong) NSNumber *createdHere;


@property BOOL createdHereValue;
- (BOOL)createdHereValue;
- (void)setCreatedHereValue:(BOOL)value_;

//- (BOOL)validateCreatedHere:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *objectId;


//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *syncStatus;


@property int16_t syncStatusValue;
- (int16_t)syncStatusValue;
- (void)setSyncStatusValue:(int16_t)value_;

//- (BOOL)validateSyncStatus:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate *updatedAt;


//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;






@end

@interface _FTASyncParent (CoreDataGeneratedAccessors)

@end

@interface _FTASyncParent (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber *)primitiveCreatedHere;
- (void)setPrimitiveCreatedHere:(NSNumber *)value;

- (BOOL)primitiveCreatedHereValue;
- (void)setPrimitiveCreatedHereValue:(BOOL)value_;




- (NSString *)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString *)value;




- (NSNumber *)primitiveSyncStatus;
- (void)setPrimitiveSyncStatus:(NSNumber *)value;

- (int16_t)primitiveSyncStatusValue;
- (void)setPrimitiveSyncStatusValue:(int16_t)value_;




- (NSDate *)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate *)value;




@end
