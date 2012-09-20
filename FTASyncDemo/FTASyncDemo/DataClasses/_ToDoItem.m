// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ToDoItem.m instead.

#import "_ToDoItem.h"

const struct ToDoItemAttributes ToDoItemAttributes = {
	.name = @"name",
	.priority = @"priority",
};

const struct ToDoItemRelationships ToDoItemRelationships = {
	.person = @"person",
};

const struct ToDoItemFetchedProperties ToDoItemFetchedProperties = {
};

@implementation ToDoItemID
@end

@implementation _ToDoItem

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ToDoItem" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ToDoItem";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ToDoItem" inManagedObjectContext:moc_];
}

- (ToDoItemID*)objectID {
	return (ToDoItemID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"priorityValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"priority"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic name;






@dynamic priority;



- (int16_t)priorityValue {
	NSNumber *result = [self priority];
	return [result shortValue];
}

- (void)setPriorityValue:(int16_t)value_ {
	[self setPriority:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitivePriorityValue {
	NSNumber *result = [self primitivePriority];
	return [result shortValue];
}

- (void)setPrimitivePriorityValue:(int16_t)value_ {
	[self setPrimitivePriority:[NSNumber numberWithShort:value_]];
}





@dynamic person;

	






@end
