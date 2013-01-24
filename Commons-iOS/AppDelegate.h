//
//  AppDelegate.h
//  Commons-iOS
//
//  Created by Brion on 1/7/13.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "FileUpload.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
}

@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *password;
@property (strong, nonatomic) NSManagedObjectContext *context;

- (void)loadCredentials;
- (void)saveCredentials;
- (void)saveData;
- (FileUpload *)createUploadRecord;

@end
