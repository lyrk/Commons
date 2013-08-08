//
//  OpenInBrowserActivity.h
//  Commons-iOS
//
//  Created by Linas Valiukas on 2013-08-07.
//  Copyright (c) 2013 Wikimedia. All rights reserved.
//

@interface OpenInBrowserActivity : UIActivity

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems;
- (void)prepareWithActivityItems:(NSArray *)activityItems;
- (void)performActivity;

@end
