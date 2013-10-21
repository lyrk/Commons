//
//  PictureOfDayManager.h
//  Commons-iOS
//
//  Created by Monte Hurd on 10/18/13.

#import <Foundation/Foundation.h>

@class PictureOfDayCycler, MWPromise, UILabelDynamicHeight, PictureOfTheDayImageView;

@interface PictureOfDayManager : NSObject

@property (strong, nonatomic) NSString *pictureOfTheDayUser;
@property (strong, nonatomic) NSString *pictureOfTheDayDateString;
@property (strong, nonatomic) NSString *pictureOfTheDayLicense;
@property (strong, nonatomic) NSString *pictureOfTheDayLicenseUrl;
@property (strong, nonatomic) NSString *pictureOfTheDayWikiUrl;
@property (strong, nonatomic) PictureOfDayCycler *pictureOfDayCycler;
@property (strong, nonatomic) UILabelDynamicHeight *attributionLabel;
@property (strong, nonatomic) PictureOfTheDayImageView *potdImageView;
@property (nonatomic) CGSize screenSize;

-(void)setupPOTD;
-(void)copyToCacheBundledPotdsNamed:(NSString *)defaultBundledPotdsDates extension:(NSString *)extension;
-(void)loadArrayOfCachedPotdDateStrings;
-(NSString *)getDateStringForDaysAgo:(int)daysAgo;
-(MWPromise *)downloadPictureOfTheDayForDateString:(NSString *)dateString;
-(void)showPictureOfTheDayForDateString:(NSString *)dateString done:(void(^)(void)) done;
-(void)downloadAndSchedulePictureOfTheDayForDateString:(NSString *)dateString;
-(void)scheduleDateStringForNextDisplay:(NSString *)dateString;
-(void)viewWillAppear;
-(NSAttributedString *)getAttributionLabelText;

@end
