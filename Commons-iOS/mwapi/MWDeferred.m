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
    id result_;
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
        isDone_ = NO;
        isResolved_ = NO;
        isRejected_ = NO;
        result_ = nil;
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
        if (!isDone_) {
            [doneCallbacks_ addObject:doneCallback];
        } else if (isResolved_) {
            doneCallback(result_);
        }
    }
}

- (void)fail:(MWPromiseBlock)failCallback
{
    if (failCallback) {
        if (!isDone_) {
            [failCallbacks_ addObject:failCallback];
        } else if (isRejected_) {
            failCallback(result_);
        }
    }
}

- (void)progress:(MWPromiseBlock)progressCallback
{
    // fixme does this need to call if we're already done? probably not.
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
    isDone_ = YES;
    isResolved_ = NO;
    isRejected_ = YES;
    result_ = arg;
    for (MWPromiseBlock block in failCallbacks_) {
        block(arg);
    }
}

- (void)resolve:(id)arg
{
    isDone_ = YES;
    isResolved_ = YES;
    isRejected_ = NO;
    result_ = arg;
    for (MWPromiseBlock block in doneCallbacks_) {
        block(arg);
    }
}

@end
