//
//  NPReachability.h
//
//  Updated and converted to ARC by Abizer Nasir.
//  
//  Copyright (c) 2011, Nick Paulson
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//  
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  Neither the name of the Nick Paulson nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
@class NPReachability;
extern NSString * const NPReachabilityChangedNotification;

// Handler for changes in reachability.
typedef void (^ReachabilityHandler)(NPReachability *curReach);

typedef enum {
	NPRNotReachable = 0,
	NPRReachableViaWiFi,
	NPRReachableViaWWAN
} NPRNetworkStatus;

@interface NPReachability : NSObject 

// Allows KVO for `currentlyReachable` and `currentReachabilityFlags`
@property (nonatomic, readonly, getter=isCurrentlyReachable) BOOL currentlyReachable;
@property (nonatomic, readonly) SCNetworkReachabilityFlags currentReachabilityFlags;
@property (nonatomic, readonly) NPRNetworkStatus currentNetworkStatus;

// Singleton initialiser
+ (NPReachability *)sharedInstance;

// A handy class method:
+ (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags;


// Returns an opaque object used for removal later. Caution: this copies the 
// block. If the block retains an object, you may end up with a retain cycle.
// In that case, consider using KVO or NSNotifications instead.
- (id)addHandler:(ReachabilityHandler)handler;
- (void)removeHandler:(id)opaqueObject;


@end
