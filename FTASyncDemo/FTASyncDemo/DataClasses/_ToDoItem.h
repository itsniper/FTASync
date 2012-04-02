// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ToDoItem.h instead.

#import <CoreData/CoreData.h>


extern const struct ToDoItemAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *priority;
} ToDoItemAttributes;

extern const struct ToDoItemRelationships {
} ToDoItemRelationships;

extern const struct ToDoItemFetchedProperties {
} ToDoItemFetchedProperties;





@interface ToDoItemID : NSManagedObjectID {}
@end

@interface _ToDoItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ToDoItemID*)objectID;




@property (nonatomic, strong) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *priority;


@property short priorityValue;
- (short)priorityValue;
- (void)setPriorityValue:(short)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;





@end

@interface _ToDoItem (CoreDataGeneratedAccessors)

@end

@interface _ToDoItem (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitivePriority;
- (void)setPrimitivePriority:(NSNumber*)value;

- (short)primitivePriorityValue;
- (void)setPrimitivePriorityValue:(short)value_;




@end
