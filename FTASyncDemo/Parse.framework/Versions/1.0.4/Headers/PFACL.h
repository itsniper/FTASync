//  PFACL.h
//  Copyright 2011 Parse, Inc. All rights reserved.

#import <Foundation/Foundation.h>

@class PFUser;

/*!
 The PFACL is an access control list that can apply to a PFObject. The PFACL determines which users have
 read and write permissions to the object.
 */
@interface PFACL : NSObject <NSCopying> {
@private
    NSMutableDictionary *permissionsById;
    BOOL shared;
    PFUser *unresolvedUser;
    void (^userResolutionListener)(id result, NSError *error);
}

/*!
 Creates an ACL with no permissions granted.
 */
+ (PFACL *)ACL;

/*!
 Creates an ACL where only the provided user has access.
 */
+ (PFACL *)ACLWithUser:(PFUser *)user;

/*!
 Set whether the public is allowed to read this object.
 */
- (void)setPublicReadAccess:(BOOL)allowed;

/*!
 Gets whether the public is allowed to read this object.
 */
- (BOOL)getPublicReadAccess;

/*!
 Set whether the public is allowed to write this object.
 */
- (void)setPublicWriteAccess:(BOOL)allowed;

/*!
 Gets whether the public is allowed to write this object.
 */
- (BOOL)getPublicWriteAccess;

/*!
 Set whether the given user id is allowed to read this object.
 */
- (void)setReadAccess:(BOOL)allowed forUserId:(NSString *)userId;

/*!
 Gets whether the given user id is *explicitly* allowed to read this object.
 Even if this returns NO, the user may still be able to access it if getPublicReadAccess returns YES.
 */
- (BOOL)getReadAccessForUserId:(NSString *)userId;

/*!
 Set whether the given user id is allowed to write this object.
 */
- (void)setWriteAccess:(BOOL)allowed forUserId:(NSString *)userId;

/*!
 Gets whether the given user id is *explicitly* allowed to write this object.
 Even if this returns NO, the user may still be able to write it if getPublicWriteAccess returns YES.
 */
- (BOOL)getWriteAccessForUserId:(NSString *)userId;

/*!
 Set whether the given user is allowed to read this object.
 */
- (void)setReadAccess:(BOOL)allowed forUser:(PFUser *)user;

/*!
 Gets whether the given user is *explicitly* allowed to read this object.
 Even if this returns NO, the user may still be able to access it if getPublicReadAccess returns YES.
 */
- (BOOL)getReadAccessForUser:(PFUser *)user;

/*!
 Set whether the given user is allowed to write this object.
 */
- (void)setWriteAccess:(BOOL)allowed forUser:(PFUser *)user;

/*!
 Gets whether the given user is *explicitly* allowed to write this object.
 Even if this returns NO, the user may still be able to write it if getPublicWriteAccess returns YES.
 */
- (BOOL)getWriteAccessForUser:(PFUser *)user;

/*!
 Sets a default ACL that will be applied to all PFObjects when they are created.
 @param acl The ACL to use as a template for all PFObjects created after setDefaultACL has been called.
 This value will be copied and used as a template for the creation of new ACLs, so changes to the
 instance after setDefaultACL has been called will not be reflected in new PFObjects.
 @param currentUserAccess If true, the PFACL that is applied to newly-created PFObjects will
 provide read and write access to the currentUser at the time of creation. If false,
 the provided ACL will be used without modification. If acl is nil, this value is ignored.
 */
+ (void)setDefaultACL:(PFACL *)acl withAccessForCurrentUser:(BOOL)currentUserAccess;

@end
