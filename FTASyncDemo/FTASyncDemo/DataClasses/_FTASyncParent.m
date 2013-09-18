// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to FTASyncParent.m instead.

#import "_FTASyncParent.h"

const struct FTASyncParentAttributes FTASyncParentAttributes = {
	.createdAt = @"createdAt",
	.createdHere = @"createdHere",
	.objectId = @"objectId",
	.syncStatus = @"syncStatus",
	.updatedAt = @"updatedAt",
};

const struct FTASyncParentRelationships FTASyncParentRelationships = {
};

const struct FTASyncParentFetchedProperties FTASyncParentFetchedProperties = {
};

@implementation FTASyncParentID
@end

@implementation _FTASyncParent

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"FTASyncParent" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"FTASyncParent";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"FTASyncParent" inManagedObjectContext:moc_];
}

- (FTASyncParentID*)objectID {
	return (FTASyncParentID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"createdHereValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"createdHere"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"syncStatusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"syncStatus"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic createdAt;






@dynamic createdHere;



- (BOOL)createdHereValue {
	NSNumber *result = [self createdHere];
	return [result boolValue];
}

- (void)setCreatedHereValue:(BOOL)value_ {
	[self setCreatedHere:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveCreatedHereValue {
	NSNumber *result = [self primitiveCreatedHere];
	return [result boolValue];
}

- (void)setPrimitiveCreatedHereValue:(BOOL)value_ {
	[self setPrimitiveCreatedHere:[NSNumber numberWithBool:value_]];
}





@dynamic objectId;






@dynamic syncStatus;



- (int16_t)syncStatusValue {
	NSNumber *result = [self syncStatus];
	return [result shortValue];
}

- (void)setSyncStatusValue:(int16_t)value_ {
	[self setSyncStatus:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveSyncStatusValue {
	NSNumber *result = [self primitiveSyncStatus];
	return [result shortValue];
}

- (void)setPrimitiveSyncStatusValue:(int16_t)value_ {
	[self setPrimitiveSyncStatus:[NSNumber numberWithShort:value_]];
}





@dynamic updatedAt;











@end
