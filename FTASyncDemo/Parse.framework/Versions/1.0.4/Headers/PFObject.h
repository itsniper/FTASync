// PFObject.h
// Copyright 2011 Parse, Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import "PFACL.h"
#import "PFConstants.h"

/*!
 A Parse Framework Object that is a local representation of data persisted to the Parse cloud. This is the
 main class that is used to interact with objects in your app.
*/
@class PFCommand;
@interface PFObject : NSObject {
    BOOL dirty;
    BOOL hasBeenFetched;
    
    PFCommand *currentCommand;
    
    NSString *objectId;
    NSString *className;
    
    NSMutableDictionary *dataAvailability;
        
    NSMutableDictionary *data;    
    NSMutableDictionary *operations;
    
    // A dictionary that maps id (objects) => PFJSONCache 
    NSMutableDictionary *hashedObjectsCache;
    
    // A set of dirty keys (strings)
    NSMutableSet        *dirtyKeys;
    
    NSDate *updatedAt;
    NSDate *createdAt;
}

/*!
 The id of the object.
 */
@property (nonatomic, retain) NSString *objectId;

/*!
 When the object was last updated.
 */
@property (readonly) NSDate *updatedAt;

/*!
 When the object was created.
 */
@property (readonly) NSDate *createdAt;

/*!
 The class name of the object.
 */
@property (readonly) NSString *className;

/*!
 The ACL for this object.
 */
@property (nonatomic, retain) PFACL *ACL;

#pragma mark Constructors

/*!
 Initializes a new PFObject with a class name.
 @param newClassName A class name can be any alphanumeric string that begins with a letter. It represents an object in your app, like a User or a Document.
 @result Returns the object that is instantiated with the given class name.
*/
- (id)initWithClassName:(NSString *)newClassName;

/*!
 Creates a new PFObject with a class name.
 @param className A class name can be any alphanumeric string that begins with a letter. It represents an object in your app, like a User of a Document.
 @result Returns the object that is instantiated with the given class name.
 */
+ (PFObject *)objectWithClassName:(NSString *)className;

/*!
 Creates a reference to an existing PFObject for use in creating associations between PFObjects.  Calling isDataAvailable on this
 object will return NO until fetchIfNeeded or refresh has been called.  No network request will be made.
 
 @param className The object's class.
 @param objectId The object id for the referenced object.
 @result A PFObject without data.
 */
+ (PFObject *)objectWithoutDataWithClassName:(NSString *)className objectId:(NSString *)objectId;

#pragma mark -
#pragma mark Getters

/*!
 Returns an array of the keys contained in this object. This does not include
 createdAt, updatedAt, authData, or objectId. It does include things like username
 and ACL.
*/
- (NSArray *)allKeys;

#pragma mark -
#pragma mark Save
/*!
 Saves the PFObject.
 @result Returns whether the save succeeded.
 */
- (BOOL)save;

/*!
 Saves the PFObject and sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the save succeeded.
 */
- (BOOL)save:(NSError **)error;

/*!
 Saves the PFObject asynchronously.
 */
- (void)saveInBackground;

/*!
 Saves the PFObject asynchronously and calls the given callback.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError *)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
- (void)saveInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 Saves the PFObject asynchronously and executes the given callback block.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block;

/*!
 Saves this object to the server at some unspecified time in the future, even if Parse is currently inaccessible.
 Use this when you may not have a solid network connection, and don't need to know when the save completes.
 If there is some problem with the object such that it can't be saved, it will be silently discarded.

 Objects saved with this method will be stored locally in an on-disk cache until they can be delivered to Parse.
 They will be sent immediately if possible.  Otherwise, they will be sent the next time a network connection is
 available.  Objects saved this way will persist even after the app is closed, in which case they will be sent the
 next time the app is opened.  If more than 10MB of data is waiting to be sent, subsequent calls to saveEventually
 will cause old saves to be silently discarded until the connection can be re-established, and the queued objects
 can be saved.
 */
- (void)saveEventually;

#pragma mark -
#pragma mark Refresh

/*!
 Refreshes the PFObject with the current data from the server.
 */
- (void)refresh;

/*!
 Refreshes the PFObject with the current data from the server and sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 */
- (void)refresh:(NSError **)error;

/*!
 Refreshes the PFObject asynchronously and calls the given callback.
 @param target The target on which the selector will be called.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(PFObject *)refreshedObject error:(NSError *)error. error will be nil on success and set if there was an error. refreshedObject will be the PFObject with the refreshed data.
 */
- (void)refreshInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 Refreshes the PFObject asynchronously and executes the given callback block.
 @param block The block to execute. The block should have the following argument signature: (PFObject *object, NSError *error) 
 */
- (void)refreshInBackgroundWithBlock:(PFObjectResultBlock)block;

/*!
 Fetches the PFObject with the current data from the server.
 */
- (void)fetch;

/*!
 Fetches all of the PFObjects with the current data from the server
 @param objects The list of objects to fetch.
 */
+ (void)fetchAll:(NSArray *)objects;

/*!
 Fetches all of the PFObjects with the current data from the server and sets an error if it occurs.
 @param objects The list of objects to fetch.
 @param error Pointer to an NSError that will be set  if necessary
 */
+ (void)fetchAll:(NSArray *)objects error:(NSError **)error;

/*!
 Fetches all of the PFObjects with the current data from the server asynchronously and calls the given callback.
 @param objects The list of objects to fetch.
 @param target The target on which the selector will be called.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSArray *)fetchedObjects error:(NSError *)error. error will be nil on success and set if there was an error. fetchedObjects will the array of PFObjects
     that were fetched.
 */
+ (void)fetchAllInBackground:(NSArray *)objects target:(id)target selector:(SEL)selector;

/*!
 Fetches all of the PFObjects with the current data from the server asynchronously and calls the given block.
 @param objects The list of objects to fetch.
 @param block The block to execute. The block should have the following argument signature: (NSArray *objects, NSError *error) 
 */
+ (void)fetchAllInBackground:(NSArray *)objects block:(PFArrayResultBlock)block;

/*!
 Fetches all of the PFObjects with the current data from the server
 @param objects The list of objects to fetch.
 */
+ (void)fetchAllIfNeeded:(NSArray *)objects;

/*!
 Fetches all of the PFObjects with the current data from the server and sets an error if it occurs.
 @param objects The list of objects to fetch.
 @param error Pointer to an NSError that will be set  if necessary
 */
+ (void)fetchAllIfNeeded:(NSArray *)objects error:(NSError **)error;

/*!
 Fetches all of the PFObjects with the current data from the server asynchronously and calls the given callback.
 @param objects The list of objects to fetch.
 @param target The target on which the selector will be called.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSArray *)fetchedObjects error:(NSError *)error. error will be nil on success and set if there was an error. fetchedObjects will the array of PFObjects
 that were fetched.
 */
+ (void)fetchAllIfNeededInBackground:(NSArray *)objects target:(id)target selector:(SEL)selector;

/*!
 Fetches all of the PFObjects with the current data from the server asynchronously and calls the given block.
 @param objects The list of objects to fetch.
 @param block The block to execute. The block should have the following argument signature: (NSArray *objects, NSError *error) 
 */
+ (void)fetchAllIfNeededInBackground:(NSArray *)objects block:(PFArrayResultBlock)block;
/*!
 Fetches the PFObject with the current data from the server and sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 */
- (void)fetch:(NSError **)error;

/*!
 Fetches the PFObject asynchronously and calls the given callback.
 @param target The target on which the selector will be called.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(PFObject *)refreshedObject error:(NSError *)error. error will be nil on success and set if there was an error. refreshedObject will be the PFObject with the refreshed data.
 */
- (void)fetchInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 Fetches the PFObject asynchronously and executes the given callback block.
 @param block The block to execute. The block should have the following argument signature: (PFObject *object, NSError *error) 
 */
- (void)fetchInBackgroundWithBlock:(PFObjectResultBlock)block;

/*!
 Fetches the PFObject's data from the server if isDataAvailable is false.
 */
- (PFObject *)fetchIfNeeded;

/*!
 Fetches the PFObject's data from the server if isDataAvailable is false.
 @param error Pointer to an NSError that will be set if necessary.
 */
- (PFObject *)fetchIfNeeded:(NSError **)error;

/*!
 Fetches the PFObject's data asynchronously if isDataAvailable is false, then calls the callback.
 @param target The target on which the selector will be called.
 @param selector The selector to call.  It should have the following signature: (void)callbackWithResult:(PFObject *)fetchedObject error:(NSError *)error. error will be nil on success and set if there was an error. 
 */
- (void)fetchIfNeededInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 Fetches the PFObject's data asynchronously if isDataAvailable is false, then calls the callback block.
 @param block The block to execute.  The block should have the following argument signature: (PFObject *object, NSError *error)
 */
- (void)fetchIfNeededInBackgroundWithBlock:(PFObjectResultBlock)block;

/*!
 Gets whether the PFObject has been fetched.
 @result YES if the PFObject is new or has been fetched or refreshed.  NO otherwise.
 */
- (BOOL)isDataAvailable;

#pragma mark -
#pragma mark Delete

/*!
 Deletes the PFObject.
 @result Returns whether the delete succeeded.
 */
- (BOOL)delete;   

/*!
 Deletes the PFObject and sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the delete succeeded.
 */
- (BOOL)delete:(NSError **)error;

/*!
 Deletes the PFObject asynchronously.
 */
- (void)deleteInBackground;

/*!
 Deletes the PFObject asynchronously and calls the given callback.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError *)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
- (void)deleteInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 Deletes the PFObject asynchronously and executes the given callback block.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
- (void)deleteInBackgroundWithBlock:(PFBooleanResultBlock)block;

/*!
 Deletes this object from the server at some unspecified time in the future, even if Parse is currently inaccessible.
 Use this when you may not have a solid network connection, and don't need to know when the delete completes.
 If there is some problem with the object such that it can't be deleted, the request will be silently discarded.
 
 Delete instructions made with this method will be stored locally in an on-disk cache until they can be transmitted
 to Parse. They will be sent immediately if possible.  Otherwise, they will be sent the next time a network connection
 is available. Delete requests will persist even after the app is closed, in which case they will be sent the
 next time the app is opened.  If more than 10MB of saveEventually or deleteEventually commands are waiting to be sent,
 subsequent calls to saveEventually or deleteEventually will cause old requests to be silently discarded until the
 connection can be re-established, and the queued requests can go through.
 */
- (void)deleteEventually;

#pragma mark -
#pragma mark Get and set

/*!
 Returns the object associated with a given key.
 @param key The key that the object is associated with.
 @result The value associated with the given key, or nil if no value is associated with key.
 */
- (id)objectForKey:(NSString *)key;

/*!
 Sets the object associated with a given key.
 @param object The object.
 @param key The key.
*/
- (void)setObject:(id)object forKey:(NSString *)key;

/*!
 Unsets a key on the object.
 @param key The key.
*/
- (void)removeObjectForKey:(NSString *)key;

#pragma mark -
#pragma mark Increment

/*!
 Increments the given key by 1.
 @param key The key.
*/
- (void)incrementKey:(NSString *)key;

/*!
 Increments the given key by a number.
 @param key The key.
 @param amount The amount to increment.
 */
- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount;

#pragma mark -
#pragma mark Save all

/*!
 Saves a collection of objects all at once.
 @param objects The array of objects to save.
 @result Returns whether the save succeeded.
 */
+ (BOOL)saveAll:(NSArray *)objects;

/*!
 Saves a collection of objects all at once and sets an error if necessary.
 @param objects The array of objects to save.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the save succeeded.
 */
+ (BOOL)saveAll:(NSArray *)objects error:(NSError **)error;

/*!
 Saves a collection of objects all at once asynchronously.
 @param objects The array of objects to save.
 */
+ (void)saveAllInBackground:(NSArray *)objects;

/*!
 Saves a collection of objects all at once asynchronously and calls a callback when done.
 @param objects The array of objects to save.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithError:(NSError *)error. error will be nil on success and set if there was an error. 
 */
+ (void)saveAllInBackground:(NSArray *)objects target:(id)target selector:(SEL)selector;

/*!
 Saves a collection of objects all at once asynchronously and the block when done.
 @param objects The array of objects to save.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
+ (void)saveAllInBackground:(NSArray *)objects block:(PFBooleanResultBlock)block;

@end
