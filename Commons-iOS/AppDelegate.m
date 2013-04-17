//
//  AppDelegate.m
//  Commons-iOS
//
//  Created by Brion on 1/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import "AppDelegate.h"
#import "CommonsApp.h"
#import "Reachability.h"
#import "LoadingIndicator.h"
#import "MyUploadsViewController.h"
#import "LoginViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    // Listen for changes to which view controllers are on the navigation controller stack
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedUINavigationControllerDidShowViewControllerNotification:)
                                                 name:@"UINavigationControllerDidShowViewControllerNotification"
                                               object:nil];
    
    // allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.commons.wikimedia.org"];
    
    // tell the reachability that we DONT want to be reachable on 3G/EDGE/CDMA
    // reach.reachableOnWWAN = NO;
    
    // here we set up a NSNotification observer. The Reachability that caused the notification
    // is passed in the object parameter
   
    /* WORKING
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
     */
    
    [reach startNotifier];
    
    [CommonsApp.singleton initializeApp];

    CommonsApp *app = CommonsApp.singleton;
    [app initializeApp];

    // We seem to get a second ping after launching, wtf?
    /*
    NSLog(@"launch options: %@", launchOptions);
    NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
    if (url != nil) {
        [app processLaunchURL:url];
    }
    */

	_loadingIndicator = [[LoadingIndicator alloc] initWithFrame:_window.bounds];
	[_window addSubview: _loadingIndicator];
    
    return YES;
}

- (void)receivedUINavigationControllerDidShowViewControllerNotification:(NSNotification *)notification {
    // This is a convenient place to observe which view controller has just been pushed onto the
    // navigation controller's stack. The previously visible view controller can also be determined
    // here for logic dependent on that
    
    if ([notification.object isKindOfClass:[UINavigationController class]]) {
        
        NSDictionary *userInfo = [notification userInfo];
        UIViewController * fromVc = [userInfo objectForKey:@"UINavigationControllerLastVisibleViewController"];
        UIViewController * toVc = [userInfo objectForKey:@"UINavigationControllerNextVisibleViewController"];
        //NSLog(@"Switching from %@ to %@", [fromVc class], [toVc class]);
        
        // Get the nav controller
        UINavigationController *navController = ([self.window.rootViewController isKindOfClass:[UINavigationController class]])
        ?
        (UINavigationController *) self.window.rootViewController
        :
        nil
        ;

        if (!navController) return;
        
        // From here it shold be safe to make adjustments to the view controllers on the navController's stack
        
        // Potentially send user directly to MyUploadsViewController
        // Only do so when the app starts (fromVC will be nil and toVc will be LoginViewController)
        if ((fromVc == nil) && ([toVc isKindOfClass:[LoginViewController class]])) {
            
            // Check credentials
            CommonsApp *app = CommonsApp.singleton;
            if ([app.username length] && [app.password length]){
                
                // Only skip to MyUploadsViewController if credentials found
                MyUploadsViewController *myUploadsVC = [navController.storyboard instantiateViewControllerWithIdentifier:@"MyUploadsViewController"];
                [navController pushViewController:myUploadsVC animated:NO];
            }
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    CommonsApp *app = CommonsApp.singleton;
    return [app processLaunchURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


/* -> Use this method if you want "no internet" alerts in any part of the app.

-(void)reachabilityChanged:(NSNotification*)note {
    NSLog(@"reachabilityChanged");
    
    Reachability * reach = [note object];
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    
//    if([reach isReachable])
    if (netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN)
    {
        // optional alert informing you if you are connected to the internet.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Yay" message:@"Your are connected to the internet" delegate:nil cancelButtonTitle:@"okay" otherButtonTitles:nil, nil];
        [alert show];
    }
    else if (netStatus == NotReachable)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please check your internet connection" delegate:nil cancelButtonTitle:@"okay" otherButtonTitles:nil, nil];
        [alert show];
    }
}
*/

@end
