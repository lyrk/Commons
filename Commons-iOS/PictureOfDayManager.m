//
//  PictureOfDayManager.m
//  Commons-iOS
//
//  Created by Monte Hurd on 10/18/13.

#import "PictureOfDayManager.h"
#import "PictureOfTheDayImageView.h"
#import "CommonsApp.h"
#import "MWPromise.h"
#import "PictureOfDayCycler.h"
#import "AspectFillThumbFetcher.h"
#import "MWMessage.h"
#import "UILabelDynamicHeight.h"

// Note: to change the bundled picture of the day simply remove the existing one from the
// bundle, add the new one, then change is date to match the date from the newly bundled
// file name (Nice thing about this approach is the code doesn't have to know anything
// about a special-case file - it works normally with no extra checks)
#define DEFAULT_BUNDLED_PIC_OF_DAY_DATE @"2007-06-15"

// Change this to a plist later, but we're not bundling that many images.
#define BUNDLED_PIC_OF_DAY_DATES @"2007-06-15|2008-01-25|2008-11-14|2009-06-19|2010-05-24|2012-07-08|2013-04-21|2013-04-29|2013-09-03|2013-06-04"

#define DISABLE_POTD_FOR_DEBUGGING 0

// Pic of day transition settings
#define SECONDS_TO_SHOW_EACH_PIC_OF_DAY 6.0f
#define SECONDS_TO_TRANSITION_EACH_PIC_OF_DAY 2.3f

#define PIC_OF_THE_DAY_TO_DOWNLOAD_DAYS_AGO 0 //0 for today, 1 for yesterday, -1 for tomorrow etc

// Force the app to download and cache a particularly interesting picture of the day
// Note: use iPad to retrieve potd image cache files to be bundled
#define FORCE_PIC_OF_DAY_DOWNLOAD_FOR_DATE nil //@"2007-11-12"

@implementation PictureOfDayManager{
    NSMutableArray *cachedPotdDateStrings_;
    AspectFillThumbFetcher *pictureOfTheDayGetter_;
}

-(void)viewWillAppear
{
    // The wikimedia picture of the day urls use yyyy-MM-dd format - get such a string
    NSString *dateString = [self getDateStringForDaysAgo:PIC_OF_THE_DAY_TO_DOWNLOAD_DAYS_AGO];
    
    if(FORCE_PIC_OF_DAY_DOWNLOAD_FOR_DATE != nil){
        dateString = FORCE_PIC_OF_DAY_DOWNLOAD_FOR_DATE;
    }

    // Populate array cachedPotdDateStrings_ with all cached potd file date strings
    [self loadArrayOfCachedPotdDateStrings];
    
    // Show the first pic of day
    [self showPictureOfTheDayForDateString:[cachedPotdDateStrings_ firstObject] done:^{}];
    
    // Begin image cycling with second image (since first one is already shows by default)
    self.pictureOfDayCycler.currentDateStringIndex = 1;
    // Kick off the image cycling
    [self.pictureOfDayCycler start];
    
    // If dateString not already in cachedPotdDateStrings_ 
    if (![cachedPotdDateStrings_ containsObject:dateString]) {
        [self downloadAndSchedulePictureOfTheDayForDateString:dateString];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        self.pictureOfTheDayUser = nil;
        self.pictureOfTheDayDateString = nil;
        self.pictureOfTheDayLicense = nil;
        self.pictureOfTheDayLicenseUrl = nil;
        self.pictureOfTheDayWikiUrl = nil;
        self.screenSize = CGSizeZero;
        pictureOfTheDayGetter_ = [[AspectFillThumbFetcher alloc] init];
        cachedPotdDateStrings_ = [[NSMutableArray alloc] init];
        
        if (!DISABLE_POTD_FOR_DEBUGGING) {
            self.pictureOfDayCycler = [[PictureOfDayCycler alloc] init];
            self.pictureOfDayCycler.dateStrings = cachedPotdDateStrings_;
            self.pictureOfDayCycler.transitionDuration = SECONDS_TO_TRANSITION_EACH_PIC_OF_DAY;
            self.pictureOfDayCycler.displayInterval = SECONDS_TO_SHOW_EACH_PIC_OF_DAY;
        }

    }
    return self;
}

-(void)setupPOTD
{
    if (DISABLE_POTD_FOR_DEBUGGING) return;

    self.potdImageView.useFilter = NO;
    // Ensure bundled pic of day is in cache
    [self copyToCacheBundledPotdsNamed:BUNDLED_PIC_OF_DAY_DATES extension:@"dict"];
    [self copyToCacheBundledPotdsNamed:BUNDLED_PIC_OF_DAY_DATES extension:@"jpg"];

    // The "cycle" callback below is invoked by self.pictureOfDayCycler to change which picture of the day is showing
    __weak PictureOfDayManager *weakSelf = self;
    __weak NSMutableArray *weakCachedPotdDateStrings_ = cachedPotdDateStrings_;
    // todayDateString must be set *inside* cycle callback! it's used to see if midnight rolled around while the images
    // were transitioning. if so it adds a date string for the new day to cachedPotdDateStrings_ so the new day's image
    // will load (previously you had to leave the login page and go back to see the new day's image)
    __block NSString *todayDateString = nil;
    self.pictureOfDayCycler.cycle = ^(NSString *dateString){
        [weakSelf showPictureOfTheDayForDateString:dateString done:^{}];
        
        // If today's date string is not in cachedPotdDateStrings_ (can happen if the login page is displaying and
        // midnight occurs) add it so it will be downloaded.
        todayDateString = [weakSelf getDateStringForDaysAgo:0];
        if(![weakCachedPotdDateStrings_ containsObject:todayDateString]){
            [weakSelf downloadAndSchedulePictureOfTheDayForDateString:todayDateString];
        }
    };
}

-(void)copyToCacheBundledPotdsNamed:(NSString *)defaultBundledPotdsDates extension:(NSString *)extension
{
    NSArray *dates = [defaultBundledPotdsDates componentsSeparatedByString:@"|"];
    for (NSString *bundledPotdDateString in dates) {
        // Copy bundled default picture of the day to the cache (if it's not already there)
        // so there's a pic of the day shows even if today's image can't download
        NSString *defaultBundledPotdFileName = [NSString stringWithFormat:@"POTD-%@.%@", bundledPotdDateString, extension];
        NSString *defaultBundledPath = [[NSBundle mainBundle] pathForResource:defaultBundledPotdFileName ofType:nil];
        if (defaultBundledPath){
            //Bundled File Found! See: http://stackoverflow.com/a/7487235
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *cachePotdPath = [[CommonsApp singleton] potdPath:defaultBundledPotdFileName];
            if (![fm fileExistsAtPath:cachePotdPath]) {
                // Cached version of bundle file not found, so copy bundle file to cache!
                [fm copyItemAtPath:defaultBundledPath toPath:cachePotdPath error:nil];
            }else{
                // Cached version was found, so check if bundled file differs from existing cached file by comparing last modified dates
                NSError *error = nil;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:defaultBundledPath error:&error];
                NSDate *bundledFileModDate = [fileAttributes objectForKey:NSFileModificationDate];
                fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePotdPath error:&error];
                NSDate *cachedFileModDate = [fileAttributes objectForKey:NSFileModificationDate];
                if (![cachedFileModDate isEqualToDate:bundledFileModDate]) {
                    // Remove the cached version
                    [fm removeItemAtPath:cachePotdPath error:&error];
                    // Bundled version newer than cached version, so copy bundle file to cache
                    [fm copyItemAtPath:defaultBundledPath toPath:cachePotdPath error:&error];
                }
            }
        }
    }
}

-(void)loadArrayOfCachedPotdDateStrings
{
    [cachedPotdDateStrings_ removeAllObjects];
    
    // Get array cachedPotdDateStrings_ of cached potd date strings
    // Uses reverseObjectEnumerator so most recently downloaded images show first
    NSArray *allFileInPotdFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[CommonsApp singleton] potdPath:@""] error:nil];
    for (NSString *fileName in [allFileInPotdFolder reverseObjectEnumerator]) {
        if ([fileName hasPrefix:@"POTD-"] && [fileName hasSuffix:@"dict"]) {
            NSString *dateString = [fileName substringWithRange:NSMakeRange(5, 10)];
            [cachedPotdDateStrings_ addObject:dateString];
        }
    }

    // Ensure default image shows first
    [cachedPotdDateStrings_ removeObject:DEFAULT_BUNDLED_PIC_OF_DAY_DATE];
    [cachedPotdDateStrings_ insertObject:DEFAULT_BUNDLED_PIC_OF_DAY_DATE atIndex:0];

    //NSLog(@"\n\ncachedPotdDateStrings_ = \n\n%@\n\n", cachedPotdDateStrings_);
}

-(NSString *)getDateStringForDaysAgo:(int)daysAgo
{
    NSDate *date = [[NSDate alloc] init];
    date = [date dateByAddingTimeInterval: -(86400.0 * daysAgo)];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:date];
}

-(MWPromise *)downloadPictureOfTheDayForDateString:(NSString *)dateString
{
    MWDeferred *deferred = [[MWDeferred alloc] init];

    // Determine the resolution of the picture of the day to request
    // For now leave scale at one - retina iPads would request too high a resolution otherwise
    NSAssert(!CGSizeEqualToSize(self.screenSize, CGSizeZero), @"Must set screen sizd!");

    CGFloat scale = 1.0f; //[[UIScreen mainScreen] scale];
    
    MWPromise *fetch = [pictureOfTheDayGetter_ fetchPictureOfDay:dateString size:CGSizeMake(self.screenSize.width * scale, self.screenSize.height * scale) withQueuePriority:NSOperationQueuePriorityHigh];
    
    [fetch done:^(NSDictionary *dict) {
        [deferred resolve:dict];
    }];
    [fetch fail:^(NSError *error) {
        [deferred reject:error];
    }];
    return deferred.promise;
}

-(void)showPictureOfTheDayForDateString:(NSString *)dateString done:(void(^)(void)) done
{
    MWPromise *retrieve = [self downloadPictureOfTheDayForDateString:dateString];
    [retrieve done:^(NSDictionary *dict) {
        if (dict == nil) return;
        NSData *imageData = dict[@"image"];

        if (imageData && (imageData.length > 0)) {
            UIImage *image = [UIImage imageWithData:imageData scale:1.0];
            
            self.pictureOfTheDayUser = dict[@"user"];
            self.pictureOfTheDayDateString = dict[@"potd_date"];
            self.pictureOfTheDayLicense = dict[@"license"];
            self.pictureOfTheDayLicenseUrl = dict[@"licenseurl"];
            self.pictureOfTheDayWikiUrl = dict[@"descriptionurl"];
            
            // Animate attribution label resizing for its new text
            [UIView animateWithDuration:self.pictureOfDayCycler.transitionDuration / 4.0f
                                  delay:0
                                options: UIViewAnimationCurveLinear
                             animations:^{
                                 // Update attribution label text
                                 self.attributionLabel.attributedText = [self getAttributionLabelText];
                             }
                             completion:^(BOOL finished){
                             }];
            
            // Cross-fade between pictures of the day
            [CATransaction begin];
            CATransition *crossFade = [CATransition animation];
            crossFade.type = kCATransitionFade;
            crossFade.duration = self.pictureOfDayCycler.transitionDuration;
            crossFade.removedOnCompletion = YES;
            [CATransaction setCompletionBlock:^{
                if(done) done();
            }];
            [[self.potdImageView layer] addAnimation:crossFade forKey:@"Fade"];
            [CATransaction commit];
            
            self.potdImageView.image = image;
        }
    }];
    // Cycle through cached images even of there was problem downloading a new one
    [retrieve fail:^(NSError *error) {
        NSLog(@"PictureOfTheDay Error: %@", error.description);
        if(done) done();
    }];
}

-(void)downloadAndSchedulePictureOfTheDayForDateString:(NSString *)dateString
{
    // Download the Pic of the Day for dateString and ensure that dateString appears in
    // cachedPotdDateStrings_ at the index after the index of the pic of the day presently
    // being shown by the pictureOfDayCycler
    MWPromise *retrieve = [self downloadPictureOfTheDayForDateString:dateString];
    [retrieve done:^(NSDictionary *dict) {
        if (dict == nil) return;
        NSData *imageData = dict[@"image"];
        if (imageData && (imageData.length > 0)) {
            [self scheduleDateStringForNextDisplay:dateString];
        }
    }];
    [retrieve fail:^(NSError *error) {
        NSLog(@"Pic of Day Download Fail: %@", error);
    }];
}

-(void)scheduleDateStringForNextDisplay:(NSString *)dateString
{
    // Update "cachedPotdDateStrings_" so it contains date string for the newly downloaded file
    [self loadArrayOfCachedPotdDateStrings];
    
    // Get the index of the currently displaying pic of day so this new one can be inserted after it
    NSUInteger indexOfCurrentImage = [cachedPotdDateStrings_ indexOfObject:self.pictureOfDayCycler.currentDateString];
    if (indexOfCurrentImage != NSNotFound) {
        // Remove the new dateString (which was added to cachedPotdDateStrings_ by
        // the "loadArrayOfCachedPotdDateStrings" method call above)
        [cachedPotdDateStrings_ removeObject:dateString];
        
        // Insertion should be just after current image index ("insertObject:atIndex:" takes care of this)
        NSUInteger insertionIndex = indexOfCurrentImage;
        [cachedPotdDateStrings_ insertObject:dateString atIndex:insertionIndex];
    }
}

-(NSAttributedString *)getAttributionLabelText
{
    // Convert the date string to an NSDate
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [dateFormatter dateFromString:self.pictureOfTheDayDateString];
    
    // Now get nice readable date for current locale
    NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EdMMMy" options:0 locale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:formatString];
    
    NSString *prettyDateString = [dateFormatter stringFromDate:date];
    NSString *picOfTheDayText = [MWMessage forKey:@"picture-of-day-label"].text;
    NSString *picOfTheAuthorText = [MWMessage forKey:@"picture-of-day-author"].text;

    /*
    // Random text for testing attribution label changes
    int randNum2 = rand() % (25 - 1) + 1;
    NSString *strToRepeat = @" abc";
    NSString * randStr = [@"" stringByPaddingToLength:randNum2 * [strToRepeat length] withString:strToRepeat startingAtIndex:0];
    picOfTheAuthorText = randStr;
    */
    
    NSString *picOfTheDayLicenseName = [self.pictureOfTheDayLicense uppercaseString];

    // If license was name was not retrieved change it to say "Tap for License" for now
    if (picOfTheDayLicenseName == nil){
        picOfTheDayLicenseName = [MWMessage forKey:@"picture-of-day-tap-for-license"].text;
    }

    float fontSize =            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 20.0f : 15.0f;
    float lineSpacing =         (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 10.0f : 6.0f;

    // Style attributes for labels
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.paragraphSpacing = lineSpacing;
    //paragraphStyle.lineSpacing = lineSpacing;

    NSString *string = [NSString stringWithFormat:@"%@\n%@\n%@ %@\n%@", picOfTheDayText, prettyDateString, picOfTheAuthorText, self.pictureOfTheDayUser, picOfTheDayLicenseName];

    return [[NSAttributedString alloc] initWithString:string attributes: @{
            NSFontAttributeName : [UIFont boldSystemFontOfSize:fontSize],
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0f alpha:1.0f]
    }];
}

@end
