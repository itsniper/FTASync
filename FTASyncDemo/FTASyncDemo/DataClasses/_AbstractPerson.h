// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to AbstractPerson.h instead.

#import <CoreData/CoreData.h>
#import "FTASyncParent.h"

extern const struct AbstractPersonAttributes {
	__unsafe_unretained NSString *name;
} AbstractPersonAttributes;

extern const struct AbstractPersonRelationships {
} AbstractPersonRelationships;

extern const struct AbstractPersonFetchedProperties {
} AbstractPersonFetchedProperties;




@interface AbstractPersonID : NSManagedObjectID {}
@end

@interface _AbstractPerson : FTASyncParent {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (AbstractPersonID*)objectID;




@property (nonatomic, strong) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;






@end

@interface _AbstractPerson (CoreDataGeneratedAccessors)

@end

@interface _AbstractPerson (CoreDataGeneratedPrimitiveAccessors)


- (NSString *)primitiveName;
- (void)setPrimitiveName:(NSString *)value;




@end
