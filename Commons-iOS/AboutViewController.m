//
//  AboutViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 4/12/13.

#import "AboutViewController.h"
#import "MWI18N/MWI18N.h"
#import "GradientButton.h"
#import "WebViewController.h"

#pragma mark - URLs for the About page buttons.

#define URL_COMMONS                 @"https://commons.wikimedia.org"
#define URL_BUGS                    @"https://bugzilla.wikimedia.org/buglist.cgi?product=Commons%20App"
#define URL_PRIVACY                 @"https://commons.wikimedia.org/wiki/Commons:Privacy_policy"

#define URL_THIS_APP_SOURCE         @"https://github.com/wikimedia/Commons-iOS"
#define URL_THIS_APP_LICENSE        @"https://raw.github.com/wikimedia/Commons-iOS/master/COPYING"
#define URL_THIS_APP_CONTRIBUTORS   @"https://github.com/wikimedia/Commons-iOS/contributors"

#define URL_GRADIENT_BUTTON_SOURCE  @"https://code.google.com/p/iphonegradientbuttons/"
#define URL_GRADIENT_BUTTON_LICENSE @"http://opensource.org/licenses/mit-license.php"

@interface AboutViewController ()

- (void)toggleSourceDetailsContainerVisibility;
- (void)scrollToBottomOfAboutContainer;
- (void)scrollToTopOfAboutContainer;
- (void)scrollToShowSourceButton;

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

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        // On iPads add a little space above the logo to better center the scrollView
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(100, 0, 0, 0);
        [self.scrollView setContentInset:edgeInsets];
        [self.scrollView setScrollIndicatorInsets:edgeInsets];
    }

    // Set the content size of the scrollView
    self.scrollView.contentSize = self.aboutContainer.frame.size;

    // Set gradient button color scheme
    [self.sourceButton useBlackActionSheetStyle];
    [self.commonsButton useBlackActionSheetStyle];
    [self.bugsButton useBlackActionSheetStyle];
    [self.privacyButton useBlackActionSheetStyle];

    // Ensure button text doesn't get clipped if i18n is long string
    self.sourceButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.commonsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.bugsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.privacyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    // i18n for the main buttons
    self.title = [MWMessage forKey:@"about-title"].text;
    [self.commonsButton setTitle:[MWMessage forKey:@"about-commons-button"].text forState:UIControlStateNormal];
    [self.bugsButton setTitle:[MWMessage forKey:@"about-bugs-button"].text forState:UIControlStateNormal];
    [self.privacyButton setTitle:[MWMessage forKey:@"about-privacy-button"].text forState:UIControlStateNormal];
    [self.sourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    
    // i18n for the sub-items under the Source button
    [self.thisAppLabel setText:[MWMessage forKey:@"about-source-this-app-title"].text];
    [self.thisAppContributorsButton setTitle:[MWMessage forKey:@"about-source-this-app-contributors"].text forState:UIControlStateNormal];
    [self.thisAppSourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    [self.thisAppLicenseButton setTitle:[MWMessage forKey:@"about-license-button"].text forState:UIControlStateNormal];

    [self.gradientButtonsLabel setText:[MWMessage forKey:@"about-source-gradient-title"].text];
    [self.gradientButtonSourceButton setTitle:[MWMessage forKey:@"about-source-button"].text forState:UIControlStateNormal];
    [self.gradientButtonLicenseButton setTitle:[MWMessage forKey:@"about-license-button"].text forState:UIControlStateNormal];
    
    // Get bundle info dict for its app name and version settings
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];

    // Set the app name label
    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    [self.appNameLabel setText:appDisplayName];

    // Set the app version label
    NSString *shortVersionString = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *versionText = [MWMessage forKey:@"about-app-version-label" param:shortVersionString].text;
    
    [self.appVersionLabel setText:versionText];
    
}

-(void)viewDidLayoutSubviews
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        // If orientation is landscape...
        if(self.sourceDetailsContainer.alpha == 0.0){
            // If the source details container is not visible just scroll to show the source button
            [self scrollToShowSourceButton];
        }else{
            // Else the source details are visible so scroll all the way to the bottom so all of the details may be seen
            [self scrollToBottomOfAboutContainer];
        }
    }else{
        // If orientation is portrait just scroll to the top
        [self scrollToTopOfAboutContainer];
    }
}

-(void)scrollToShowSourceButton
{
    // Add just a bit of padding so the button bottom comes to sit a bit above the bottom of the screen
    [self.scrollView scrollRectToVisible:CGRectOffset(self.sourceButton.frame, 0.0, 10) animated:YES];
}

-(void)scrollToBottomOfAboutContainer
{
    // Scroll to the bottom of the aboutContainer. OK to use self.scrollView.contentSize as it is set
    // to self.aboutContainer.frame.size in the viewDidLoad
    // (The rect passed to scrollRectToVisible must have its origin.y be less than self.scrollView.contentSize.height
    // or it won't scroll, hence the "- 1")
    [self.scrollView scrollRectToVisible:CGRectMake(0, self.scrollView.contentSize.height - 1, 1, 1) animated:YES];
}

-(void)scrollToTopOfAboutContainer
{
    // Scroll to the top of the aboutContainer
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}


-(IBAction)openURLinExternalBrowser:(id)sender
{
    // Detect which button was tapped and open its URL in external browser
    
    // Ensure the button doesn't remain in highlighted state
    if ([sender isKindOfClass:[UIButton class]]) {
        [sender setHighlighted:NO];
    }
    
    // Determine the target url based on which button was tapped
    
    NSString *urlStr = nil;
    
    if (sender == self.commonsButton) {

        urlStr = URL_COMMONS;

    }else if (sender == self.bugsButton) {
        
        urlStr = URL_BUGS;

    }else if (sender == self.privacyButton) {

        urlStr = URL_PRIVACY;

    }else if (sender == self.thisAppContributorsButton) {

        urlStr = URL_THIS_APP_CONTRIBUTORS;

    }else if (sender == self.thisAppSourceButton) {

        urlStr = URL_THIS_APP_SOURCE;
    
    }else if (sender == self.thisAppLicenseButton) {

        urlStr = URL_THIS_APP_LICENSE;
    
    }else if (sender == self.gradientButtonSourceButton) {

        urlStr = URL_GRADIENT_BUTTON_SOURCE;
    
    }else if (sender == self.gradientButtonLicenseButton) {

        urlStr = URL_GRADIENT_BUTTON_LICENSE;
    }
    
    // Go to the URL if one was set
    if (urlStr) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];

}

-(void)viewWillAppear:(BOOL)animated
{
    // Hide the bottom toolbar which appears when a button pushes to the UIWebview page (otherwise when
    // you come back to the About page the bottom toolbar is still there)
    [self.navigationController setToolbarHidden:YES animated:NO];
}

-(void)toggleSourceDetailsContainerVisibility
{
    CGRect sourceDetailsContainerStoryboardFrame = self.sourceDetailsContainer.frame;
    
    // This offset determines how far the details container will be moved up or down during the show or hide
    float offscreenFrameOffset = 110.0;
    
    if(self.sourceDetailsContainer.alpha == 0.0){
        // If the container is presently hidden, nudge it off the bottom of the screen so the show animation
        // can slide it back up into place. Nice as it's all relative to the container's storyboard position
        // so storyboard adjustments won't break the animation as movement is relative
        self.sourceDetailsContainer.frame = CGRectOffset(self.sourceDetailsContainer.frame, 0.0, offscreenFrameOffset);
    }
    
    [UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         if(self.sourceDetailsContainer.alpha == 1.0){
                             // If container is visible fade out alpha and move it offscreen
                             self.sourceDetailsContainer.alpha = 0.0;
                             self.sourceDetailsContainer.frame = CGRectOffset(self.sourceDetailsContainer.frame, 0.0, offscreenFrameOffset);
                         }else{
                             // If container is hidden fade in alpha and move it onscreen
                             self.sourceDetailsContainer.alpha = 1.0;
                             self.sourceDetailsContainer.frame = sourceDetailsContainerStoryboardFrame;

                             // Ensure the newly revealed sourceDetailsContainer is entirely on-screen
                             [self scrollToBottomOfAboutContainer];
                         }
					 }
					 completion:^(BOOL finished){
                         // When done with either show or hide put the container back so everything is where it was and
                         // everything's in a good state for next toggle animation
                         self.sourceDetailsContainer.frame = sourceDetailsContainerStoryboardFrame;
					 }];
}

-(IBAction)sourceButtonTap:(id)sender
{
    [self.sourceButton setHighlighted:NO];
    
    [self toggleSourceDetailsContainerVisibility];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
