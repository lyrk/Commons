//
//  AboutViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 4/12/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "AboutViewController.h"
#import "MWI18N/MWI18N.h"
#import "GradientButton.h"

// URLs for the about page buttons
#define URL_SOURCE         @"https://github.com/wikimedia/Commons-iOS"
#define URL_LICENSE        @"https://raw.github.com/wikimedia/Commons-iOS/master/COPYING"
#define URL_BUGS           @"https://bugzilla.wikimedia.org/buglist.cgi?product=Commons%20App"
#define URL_COMMONS        @"https://commons.wikimedia.org"
#define URL_CONTRIBUTORS   @"https://github.com/wikimedia/Commons-iOS/contributors"

@interface AboutViewController ()

- (void)scrollByMultiplier:(float)multiplier;

@end

@implementation AboutViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        // When rotating to landscape on non-iPads the page is going to need to be scrolled up a bit (so
        // more than just the logo is visible). To provide a scroll margin (to make scrolling possible) the
        // scrollView's contentSize height must be a bit larger than the scrollView's height
        self.scrollView.contentSize = CGSizeMake(
                                                 self.scrollView.frame.size.width,
                                                 self.scrollView.frame.size.height * 1.2
                                                 );
    }else{
        // On iPads add a little space above the logo to better center the scrollView
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(100, 0, 0, 0);
        [self.scrollView setContentInset:edgeInsets];
        [self.scrollView setScrollIndicatorInsets:edgeInsets];
    }

    // Set gradient button color scheme
    [self.sourceButton useBlackActionSheetStyle];
    [self.licenseButton useBlackActionSheetStyle];
    [self.commonsButton useBlackActionSheetStyle];
    [self.bugsButton useBlackActionSheetStyle];
    [self.contributorsButton useBlackActionSheetStyle];
    
    // i18n
    self.title = [MWMessage forKey:@"about-title"].text;
    [self.sourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    [self.licenseButton setTitle:[MWMessage forKey:@"about-license-button"].text forState:UIControlStateNormal];
    [self.commonsButton setTitle:[MWMessage forKey:@"about-commons-button"].text forState:UIControlStateNormal];
    [self.bugsButton setTitle:[MWMessage forKey:@"about-bugs-button"].text forState:UIControlStateNormal];
    [self.contributorsButton setTitle:[MWMessage forKey:@"about-contributors-button"].text forState:UIControlStateNormal];
    
    // Get bundle info dict for its app name and version settings
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];

    // Set the app name label
    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    [self.appNameLabel setText:appDisplayName];

    // Set the app version label
    NSString *shortVersionString = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *versionText = [MWMessage forKey:@"about-app-version-label" param:shortVersionString].text;
    
    [self.appVersionLabel setText:versionText];
    
    // If initial orientation is landscape (non-iPad) scroll down a bit so you see more than just the logo
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            [self scrollByMultiplier:1.2];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Scroll down a bit when rotating to landscape otherwise all you see is the logo and the user may not know to scroll
    // down. Don't scroll at all on iPads though
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            // Rotating to landscape so scroll down a bit so you see more than just the logo
            [self scrollByMultiplier:1.2];
        }else{
            // Rotating to portrait so scroll back up
            [self scrollByMultiplier:0.0];
        }
    }
}

- (IBAction)openSource:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_SOURCE]];
}

- (IBAction)openLicense:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_LICENSE]];
}

- (IBAction)openCommons:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_COMMONS]];
}

- (IBAction)openBugs:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_BUGS]];
}

- (IBAction)openContributors:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_CONTRIBUTORS]];
}

- (void)scrollByMultiplier:(float)multiplier
{
    CGRect frame = self.scrollView.frame;
    frame.origin.y = frame.size.height * multiplier;
    frame.origin.x = 0;
    [self.scrollView scrollRectToVisible:frame animated: NO];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
