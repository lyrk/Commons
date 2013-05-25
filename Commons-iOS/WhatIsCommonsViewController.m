//
//  WhatIsCommonsViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/23/13.

#import "WhatIsCommonsViewController.h"
#import "GettingStartedConstants.h"
#import "MWI18N.h"

@interface WhatIsCommonsViewController ()

@end

@implementation WhatIsCommonsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = GETTING_STARTED_BG_COLOR;
    
    self.contributeLabel.text = [MWMessage forKey:@"getting-started-what-is-commons-contribute-label"].text;
    self.imagesLabel.text = [MWMessage forKey:@"getting-started-what-is-commons-images-label"].text;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
