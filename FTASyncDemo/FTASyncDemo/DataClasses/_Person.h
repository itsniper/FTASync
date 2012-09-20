// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Person.h instead.

#import <CoreData/CoreData.h>
#import "AbstractPerson.h"

extern const struct PersonAttributes {
	__unsafe_unretained NSString *photo;
} PersonAttributes;

extern const struct PersonRelationships {
	__unsafe_unretained NSString *toDoItem;
} PersonRelationships;

extern const struct PersonFetchedProperties {
} PersonFetchedProperties;

@class ToDoItem;



@interface PersonID : NSManagedObjectID {}
@end

@interface _Person : AbstractPerson {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (PersonID*)objectID;




@property (nonatomic, strong) NSData *photo;


//- (BOOL)validatePhoto:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* toDoItem;

- (NSMutableSet*)toDoItemSet;





@end

@interface _Person (CoreDataGeneratedAccessors)

- (void)addToDoItem:(NSSet*)value_;
- (void)removeToDoItem:(NSSet*)value_;
- (void)addToDoItemObject:(ToDoItem*)value_;
- (void)removeToDoItemObject:(ToDoItem*)value_;

@end

@interface _Person (CoreDataGeneratedPrimitiveAccessors)


- (NSData *)primitivePhoto;
- (void)setPrimitivePhoto:(NSData *)value;





- (NSMutableSet*)primitiveToDoItem;
- (void)setPrimitiveToDoItem:(NSMutableSet*)value;


@end
