//
//  CategoryLicenseExtractor.m
//  Commons-iOS
//
//  Created by Monte Hurd on 10/2/13.

#import "CategoryLicenseExtractor.h"

@implementation CategoryLicenseExtractor{
    NSDictionary *commonLicenses_;
}

- (id)init
{
    self = [super init];
    if (self) {
        commonLicenses_ = [self getLicenses];
    }
    return self;
}

-(NSString *)getLicenseFromCategories:(NSMutableArray *)categories
{
    // Sort the license names to be looked for by descending length
    // (prevents unwanted substring matches in the loop below)
    NSArray *licenseNamesSortedByDescendingLength = [[commonLicenses_ allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString* a, NSString* b) {
        return (a.length > b.length) ? NO : YES;
    }];

    // Look at each category checking whether it begins with the name of a common license
    for (NSString *license in licenseNamesSortedByDescendingLength) {
        for (NSString *category in categories) {
            NSRange foundRange = [category rangeOfString:license options:NSCaseInsensitiveSearch];
            //if(foundRange.location != NSNotFound){
            if(foundRange.location == 0){
                return license;
            }
        }
    }
    return nil;
}

-(NSDictionary *)getLicenses
{
    return @{
             @"cc-by-sa-3.0" :       @"//creativecommons.org/licenses/by-sa/3.0/",
             @"cc-by-sa-3.0-at" :    @"//creativecommons.org/licenses/by-sa/3.0/at/",
             @"cc-by-sa-3.0-de" :    @"//creativecommons.org/licenses/by-sa/3.0/de/",
             @"cc-by-sa-3.0-ee" :    @"//creativecommons.org/licenses/by-sa/3.0/ee/",
             @"cc-by-sa-3.0-es" :    @"//creativecommons.org/licenses/by-sa/3.0/es/",
             @"cc-by-sa-3.0-hr" :    @"//creativecommons.org/licenses/by-sa/3.0/hr/",
             @"cc-by-sa-3.0-lu" :    @"//creativecommons.org/licenses/by-sa/3.0/lu/",
             @"cc-by-sa-3.0-nl" :    @"//creativecommons.org/licenses/by-sa/3.0/nl/",
             @"cc-by-sa-3.0-no" :    @"//creativecommons.org/licenses/by-sa/3.0/no/",
             @"cc-by-sa-3.0-pl" :    @"//creativecommons.org/licenses/by-sa/3.0/pl/",
             @"cc-by-sa-3.0-ro" :    @"//creativecommons.org/licenses/by-sa/3.0/ro/",
             @"cc-by-3.0" :          @"//creativecommons.org/licenses/by/3.0/",
             @"cc-zero" :            @"//creativecommons.org/publicdomain/zero/1.0/",
             @"cc-by-sa-2.5" :       @"//creativecommons.org/licenses/by-sa/2.5/",
             @"cc-by-2.5" :          @"//creativecommons.org/licenses/by/2.5/",
             @"cc-by-sa-2.0" :       @"//creativecommons.org/licenses/by-sa/2.0/",
             @"cc-by-2.0" :          @"//creativecommons.org/licenses/by/2.0/"
             };
}

-(NSString *)getURLForLicense:(NSString *)license
{
    return commonLicenses_[license];
}

@end
