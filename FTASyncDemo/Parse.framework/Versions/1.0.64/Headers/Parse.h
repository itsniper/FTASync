//
//  Parse.h
//  Parse
//
//  Created by Ilya Sukhar on 9/29/11.
//  Copyright 2011 Parse, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFACL.h"
#import "PFAnonymousUtils.h"
#import "PFConstants.h"
#import "PFFacebookUtils.h"
#import "PFFile.h"
#import "PFGeoPoint.h"
#import "PFImageView.h"
#import "PFLogInViewController.h"
#import "PFObject.h"
#import "PFProduct.h"
#import "PFPush.h"
#import "PFPurchase.h"
#import "PFQuery.h"
#import "PFQueryTableViewController.h"
#import "PFInstallation.h"
#import "PFRelation.h"
#import "PFRole.h"
#import "PFSignUpViewController.h"
#import "PFTableViewCell.h"
#import "PFTwitterUtils.h"
#import "PFUser.h"
#import "PF_FBConnect.h"

@interface Parse : NSObject

/** @name Connecting to Parse */

/*!
 Sets the applicationId and clientKey of your application.
 @param applicationId The applicaiton id for your Parse application.
 @param applicationId The client key for your Parse application.
 */
+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey;

/** @name Configuring Facebook Settings */

/*!
 Sets the Facebook application id that you are using with your Parse application. You must set this in
 order to use the Facebook functionality in Parse.
 @param applicationId The Facebook application id that you are using with your Parse application.
 */
+ (void)setFacebookApplicationId:(NSString *)applicationId __attribute__ ((deprecated));

/*!
 Whether the Facebook application id has been set.
 */
+ (BOOL)hasFacebookApplicationId __attribute__ ((deprecated));

/** @name Configuring UI Settings */

/*!
 Set whether to show offline messages when using a Parse view or view controller related classes.
 @param enabled Whether a UIAlert should be shown when the device is offline and network access is required
                from a view or view controller.
 */
+ (void)offlineMessagesEnabled:(BOOL)enabled;

/*!
 Set whether to show an error message when using a Parse view or view controller related classes 
 and a Parse error was generated via a query.
 @param enabled Whether a UIAlert should be shown when a Parse error occurs.
 */
+ (void)errorMessagesEnabled:(BOOL)enabled;

+ (NSString *)getApplicationId;
+ (NSString *)getClientKey;
+ (NSString *)getFacebookApplicationId __attribute__ ((deprecated));

@end