//
//  Category.h
//  Commons-iOS
//
//  Created by Brion on 5/8/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Category : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSNumber * timesUsed;

- (void)touch;
- (void)incTimedUsed;

@end
