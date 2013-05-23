//
//  GettingStartedViewController.m
//  Commons-iOS
//
//  Created by Monte Hurd on 5/22/13.

#import "GettingStartedViewController.h"
#import "GotItViewController.h"

@interface GettingStartedViewController (){
    NSMutableArray *scrollViewControllers;
    UIScrollView *scrollView;
    int lastPageIndex;
}
@end

@implementation GettingStartedViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        scrollViewControllers = [[NSMutableArray alloc] init];
        scrollView = [[UIScrollView alloc] init];
        lastPageIndex = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    
    UIViewController *whatVC = [self.storyboard instantiateViewControllerWithIdentifier:@"WhatIsCommonsViewController"];
    [scrollViewControllers addObject:whatVC];
    
    UIViewController *whatPhotosVC = [self.storyboard instantiateViewControllerWithIdentifier:@"WhatPhotosViewController"];
    [scrollViewControllers addObject:whatPhotosVC];
    
    UIViewController *gotItVC = [self.storyboard instantiateViewControllerWithIdentifier:@"GotItViewController"];
    [scrollViewControllers addObject:gotItVC];

    for (UIViewController *vc in scrollViewControllers) {
        [scrollView addSubview:vc.view];
        [self addChildViewController:vc];
    }

    [[NSNotificationCenter defaultCenter] addObserverForName:@"dismissModalView" object:nil queue:nil usingBlock:^(NSNotification *notification){
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self.view addSubview:scrollView];
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationPortrait;
}

-(void)viewWillDisappear:(BOOL)animated
{
    for (UIViewController *vc in self.childViewControllers) {
        [vc removeFromParentViewController];
    }
}

- (BOOL) shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

-(void)viewWillAppear:(BOOL)animated{
    UIViewController *vc = [[self childViewControllers] objectAtIndex:0];
    [vc beginAppearanceTransition:YES animated:YES];
    [vc endAppearanceTransition];
    
	[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView2
{    
    // Determine the current page
    CGFloat pageWidth = scrollView2.frame.size.width;
    int currentPageIndex = floor((scrollView2.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    NSLog(@"currentPageIndex = %d lastPageIndex = %d", currentPageIndex, lastPageIndex);
    
    if (currentPageIndex == lastPageIndex) return;
    
    UIViewController *vc = [self.childViewControllers objectAtIndex:currentPageIndex];
    UIViewController *lastVc = [self.childViewControllers objectAtIndex:lastPageIndex];
    
    [lastVc beginAppearanceTransition:NO animated:YES];
    [lastVc endAppearanceTransition];
 
    [vc beginAppearanceTransition:YES animated:YES];
    [vc endAppearanceTransition];

    lastPageIndex = currentPageIndex;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    int counter = 0;
    for (UIViewController *vc in scrollViewControllers) {
        CGRect frame = scrollView.frame;
        frame.origin.y = 0;
        frame.origin.x = frame.size.width * counter;
        vc.view.frame = frame;
        counter++;
    }
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width * 3, self.view.frame.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
