//
//  CategoryLicenseExtractor.h
//  Commons-iOS
//
//  Created by Monte Hurd on 10/2/13.

#import <Foundation/Foundation.h>

@interface CategoryLicenseExtractor : NSObject

-(NSString *)getLicenseFromCategories:(NSMutableArray *)categories;
-(NSString *)getURLForLicense:(NSString *)license;

@end
