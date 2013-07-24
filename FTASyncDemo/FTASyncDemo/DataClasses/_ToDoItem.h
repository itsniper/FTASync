// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ToDoItem.h instead.

#import <CoreData/CoreData.h>
#import "FTASyncParent.h"

extern const struct ToDoItemAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *priority;
} ToDoItemAttributes;

extern const struct ToDoItemRelationships {
	__unsafe_unretained NSString *person;
} ToDoItemRelationships;

extern const struct ToDoItemFetchedProperties {
} ToDoItemFetchedProperties;

@class Person;




@interface ToDoItemID : NSManagedObjectID {}
@end

@interface _ToDoItem : FTASyncParent {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ToDoItemID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* priority;



@property int16_t priorityValue;
- (int16_t)priorityValue;
- (void)setPriorityValue:(int16_t)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Person *person;

//- (BOOL)validatePerson:(id*)value_ error:(NSError**)error_;





@end

@interface _ToDoItem (CoreDataGeneratedAccessors)

@end

@interface _ToDoItem (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitivePriority;
- (void)setPrimitivePriority:(NSNumber*)value;

- (int16_t)primitivePriorityValue;
- (void)setPrimitivePriorityValue:(int16_t)value_;





- (Person*)primitivePerson;
- (void)setPrimitivePerson:(Person*)value;


@end
