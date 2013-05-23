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
    UITapGestureRecognizer *tapRecognizer;
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
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
	[self.view addGestureRecognizer:tapRecognizer];

    [[UIPageControl appearance] setCurrentPageIndicatorTintColor:[UIColor colorWithRed:0.60 green:0.75 blue:0.83 alpha:0.9]];

    [[UIPageControl appearance] setPageIndicatorTintColor:[UIColor colorWithRed:0.13 green:0.31 blue:0.49 alpha:0.8]];

    self.pageControl.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
    
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
    
    [self.view bringSubviewToFront:self.pageControl];
    
	[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView2
{
    self.pageControl.currentPage = [self getCurrentPageIndex];

    [self triggerChildViewControllersAppearanceMethods];
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView2
{
    self.pageControl.currentPage = [self getCurrentPageIndex];
    
    [self triggerChildViewControllersAppearanceMethods];
}

-(void)triggerChildViewControllersAppearanceMethods
{
    int currentPageIndex = [self getCurrentPageIndex];
    
    if (currentPageIndex == lastPageIndex) return;
    
    UIViewController *vc = [self.childViewControllers objectAtIndex:currentPageIndex];
    UIViewController *lastVc = [self.childViewControllers objectAtIndex:lastPageIndex];
    
    [lastVc beginAppearanceTransition:NO animated:YES];
    [lastVc endAppearanceTransition];
 
    [vc beginAppearanceTransition:YES animated:YES];
    [vc endAppearanceTransition];

    lastPageIndex = currentPageIndex;    
}

-(int)getCurrentPageIndex
{
    CGFloat pageWidth = scrollView.frame.size.width;
    return floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

-(void)handleTap
{
    int nextPageIndex = self.pageControl.currentPage + 1;

    if (nextPageIndex == 3) return;
    
    [self scrollToPage:nextPageIndex];
}

-(void)scrollToPage:(int)pageIndex
{
    if (pageIndex == [self getCurrentPageIndex]) return;
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];    
}

- (void)changePage:(id)sender
{
    [self scrollToPage:self.pageControl.currentPage];
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
