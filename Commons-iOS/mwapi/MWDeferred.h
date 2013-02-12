//
//  MWDeferred.h
//  Commons-iOS
//
//  Created by Brion on 2/11/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPromise.h"

@interface MWDeferred : NSObject

- (id)init;

// Retrieve the public-accessible promise object
- (MWPromise *)promise;

// Methods for adding callbacks
- (void)done:(MWPromiseBlock)doneCallback;
- (void)fail:(MWPromiseBlock)failCallback;
- (void)progress:(MWPromiseBlock)progressCallback;

// Convenient multiple-callback methods
- (void)always:(MWPromiseBlock)alwaysCallback;
- (void)done:(MWPromiseBlock)doneCallback fail:(MWPromiseBlock)failCallback;
- (void)done:(MWPromiseBlock)doneCallback fail:(MWPromiseBlock)failCallback progress:(MWPromiseBlock)progressCallback;

// Methods for triggering callbacks
- (void)notify:(id)arg; // progress
- (void)reject:(id)arg; // fail/always
- (void)resolve:(id)arg; // done/always

@end
