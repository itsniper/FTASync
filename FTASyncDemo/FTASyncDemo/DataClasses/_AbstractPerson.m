// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to AbstractPerson.m instead.

#import "_AbstractPerson.h"

const struct AbstractPersonAttributes AbstractPersonAttributes = {
	.name = @"name",
};

const struct AbstractPersonRelationships AbstractPersonRelationships = {
};

const struct AbstractPersonFetchedProperties AbstractPersonFetchedProperties = {
};

@implementation AbstractPersonID
@end

@implementation _AbstractPerson

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"AbstractPerson" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"AbstractPerson";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"AbstractPerson" inManagedObjectContext:moc_];
}

- (AbstractPersonID*)objectID {
	return (AbstractPersonID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;











@end
