//
//  MWPromise.h
//  Commons-iOS
//
//  Created by Brion on 2/11/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

// Based loosely on jQuery.Deferred

#import <Foundation/Foundation.h>

typedef void (^MWPromiseBlock)(id arg);
typedef id (^MWPromiseFilterBlock)(id arg);

@interface MWPromise : NSObject

- (id)initWithDeferred:(id)deferred;

// Methods for adding callbacks
- (void)always:(MWPromiseBlock)alwaysCallback;
- (void)done:(MWPromiseBlock)doneCallback;
- (void)fail:(MWPromiseBlock)failCallback;
- (void)progress:(MWPromiseBlock)progressCallback;

// Convenient multiple-callback methods
- (void)done:(MWPromiseBlock)doneCallback fail:(MWPromiseBlock)failCallback;
- (void)done:(MWPromiseBlock)doneCallback fail:(MWPromiseBlock)failCallback progress:(MWPromiseBlock)progressCallback;

- (void)pipe:(id)deferred;
- (void)pipe:(id)deferred withFilter:(MWPromiseFilterBlock)filterCallback;

@end
