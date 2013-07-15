//
//  FTASync.h
//  FTASync
//
//  Created by Justin Bergen on 3/17/12.
//  Copyright (c) 2012 Five3 Apps, LCC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CoreData+MagicalRecord.h"
#import <CoreData/CoreData.h>

//#define FS_ENABLE_SYNC_LOGGING 0

#ifndef FS_ENABLE_SYNC_LOGGING
  #ifdef DEBUG
    #define FS_ENABLE_SYNC_LOGGING 1
  #else
    #define FS_ENABLE_SYNC_LOGGING 0
  #endif
#endif

#if FS_ENABLE_SYNC_LOGGING
  #define FSLog(...) NSLog(@"%s [%d]: (%p) %@", __PRETTY_FUNCTION__, __LINE__, self, [NSString stringWithFormat:__VA_ARGS__])
  #define FSCLog(...) NSLog(@"%@", [NSString stringWithFormat:__VA_ARGS__])
  #define FSALog(...) {NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__]);[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__];}
#else
  #define FSLog(...) do { } while (0)
  #define FSCLog(...) do { } while (0)
  #define FSALog(...) NSLog(@"%s [%d]: (%p) %@", __PRETTY_FUNCTION__, __LINE__, self, [NSString stringWithFormat:__VA_ARGS__])
#endif

#import "FTASyncParent.h"
#import "FTAParseSync.h"
#import "FTASyncHandler.h"
