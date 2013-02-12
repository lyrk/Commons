//
//  MWDeferred.m
//  Commons-iOS
//
//  Created by Brion on 2/11/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "MWDeferred.h"

@interface MWDeferred() {
    NSMutableArray *doneCallbacks_;
    NSMutableArray *failCallbacks_;
    NSMutableArray *progressCallbacks_;
    BOOL isDone_;
    BOOL isResolved_;
    BOOL isRejected_;
}
@end

@implementation MWDeferred

- (id)init
{
    self = [super init];
    if (self) {
        doneCallbacks_ = [[NSMutableArray alloc] init];
        failCallbacks_ = [[NSMutableArray alloc] init];
        progressCallbacks_ = [[NSMutableArray alloc] init];
    }
    return self;
}

- (MWPromise *)promise
{
    MWPromise *promise = [[MWPromise alloc] initWithDeferred:self];
    return promise;
}

- (void)done:(MWPromiseBlock)doneCallback
{
    if (doneCallback) {
        [doneCallbacks_ addObject:doneCallback];
    }
}

- (void)fail:(MWPromiseBlock)failCallback
{
    if (failCallback) {
        [failCallbacks_ addObject:failCallback];
    }
}

- (void)progress:(MWPromiseBlock)progressCallback
{
    if (progressCallback) {
        [progressCallbacks_ addObject:progressCallback];
    }
}

#pragma mark Convenient multiple-callback methods

- (void)always:(MWPromiseBlock)alwaysCallback
{
    [self done:alwaysCallback];
    [self fail:alwaysCallback];
}

- (void)done:(MWPromiseBlock)doneCallback fail:(MWPromiseBlock)failCallback
{
    [self done:doneCallback];
    [self fail:failCallback];
}

- (void)done:(MWPromiseBlock)doneCallback fail:(MWPromiseBlock)failCallback progress:(MWPromiseBlock)progressCallback
{
    [self done:doneCallback];
    [self fail:failCallback];
    [self progress:progressCallback];
}

#pragma mark Methods for triggering callbacks

- (void)notify:(id)arg
{
    for (MWPromiseBlock block in progressCallbacks_) {
        block(arg);
    }
}

- (void)reject:(id)arg
{
    for (MWPromiseBlock block in failCallbacks_) {
        block(arg);
    }
}

- (void)resolve:(id)arg
{
    for (MWPromiseBlock block in doneCallbacks_) {
        block(arg);
    }
}

@end
