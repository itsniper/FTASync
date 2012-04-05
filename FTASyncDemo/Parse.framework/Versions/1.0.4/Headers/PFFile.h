//
//  PFFile.h
//  Parse
//
//  Created by Ilya Sukhar on 10/11/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFConstants.h"

/*!
 A file of binary data stored on the Parse servers. This can be a image, video, or anything else
 that an application needs to reference in a non-relational way.
 */
@class PFCommand;
@class PF_AFURLConnectionOperation;

typedef enum {
    kPFFileDirty,                   // brand new, hasn't been saved
    kPFFileSaving,                  // currently saving to the server
    kPFFileAwaitingFetch,           // instantiated from pfobject, needs to get fetched
    kPFFileFetching,                // currently fetching from the server
    kPFFileDataAvailable,           // data fetched and ready for use
} PFFileState;

@interface PFFile : NSObject {
    PFFileState previousState;
    PFFileState state;
    
    NSString *name;
    NSString *url;
    NSData *data;
    
    // Book-keeping for requests to Parse
    PFCommand *currentCommand;
    
    // Book-keeping for reqeusts to S3
    PF_AFURLConnectionOperation *currentOperation;
    
    NSMutableArray *callbacks;
}

/*!
The name of the file.
 */
@property (readonly) NSString *name;

/*!
 The url of the file.
 */
@property (readonly) NSString *url;

/*!
 Whether the data is available in memory or needs to be downloaded.
*/
@property (readonly) BOOL isDataAvailable;

/*!
 Whether the file has been uploaded for the first time.
 */
@property (readonly) BOOL isDirty;

/*!
 Saves the file.
 @result Returns whether the save succeeded.
 */
- (BOOL)save;

/*!
 Saves the file and sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the save succeeded.
 */
- (BOOL)save:(NSError **)error;

/*!
 Saves the file asynchronously.
 @result Returns whether the save succeeded.
 */
- (void)saveInBackground;

/*!
 Saves the file asynchronously and calls the given callback.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError *)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
- (void)saveInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 Gets the data of the file and loads it in memory if it isn't already.
 @result The data. Returns nil if there was an error in fetching.
 */
- (NSData *)getData;

/*!
 Gets the data of the file and loads it in memory if it isn't already. Sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 @result The data. Returns nil if there was an error in fetching.
 */
- (NSData *)getData:(NSError **)error;

/*!
 Gets the data of the file asynchronously and loads it in memory if it isn't already.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSData *)result error:(NSError *)error. error will be nil on success and set if there was an error.
 */
- (void)getDataInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 Saves the file asynchronously and executes the given block.
 @param block The block should have the following argument signature: (BOOL succeeded, NSError *error)
 */
- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block;

/*!
 Saves the file asynchronously and executes the given resultBlock. Executes the progressBlock periodically with the percent
 progress. progressBlock will get called with 100 before resultBlock is called.
 @param block The block should have the following argument signature: (BOOL succeeded, NSError *error)
 @param progressBlock The block should have the following argument signature: (int percentDone)
 */
- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block progressBlock:(PFProgressBlock)progressBlock;

/*!
 Gets the data of the file asynchronously and loads it in memory if it isn't already. Executes the given block.
 @param block The block should have the following argument signature: (NSData *result, NSError *error)
 */
- (void)getDataInBackgroundWithBlock:(PFDataResultBlock)block;

/*!
 Gets the data of the file asynchronously and loads it in memory if it isn't already. Executes the resultBlock upon
 completion or error. Executes the progressBlock periodically with the percent progress. progressBlock will get called with 100 before resultBlock is called.
 @param block The block should have the following argument signature: (NSData *result, NSError *error)
 @param progressBlock The block should have the following argument signature: (int percentDone)
 */
- (void)getDataInBackgroundWithBlock:(PFDataResultBlock)resultBlock progressBlock:(PFProgressBlock)progressBlock;

/*!
 Cancels the current request (whether upload or download of file data).
 */
- (void)cancel;

/*!
 Creates a file with given data. A name will be assigned to it by the server.
 @result A PFFile.
 */
+ (PFFile *)fileWithData:(NSData *)data;

/*!
 Creates a file with given data and name.
 @result A PFFile.
 */
+ (PFFile *)fileWithName:(NSString *)name data:(NSData *)data;

@end