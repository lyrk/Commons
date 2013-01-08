//
//  MWApiProgressListener.h
//  mwapi
//
//  Created by Brion on 11/6/12.
//  Copyright (c) 2012 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWApi.h"

@protocol MWApiProgressListener <NSObject>

@required
- (void) mwApi: (MWApi *) progress: (float)percentage;

@end