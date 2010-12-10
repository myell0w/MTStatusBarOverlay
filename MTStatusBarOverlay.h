//
//  MTStatusBar.h
//  MTHelper
//
//  Created by Matthias Tretter on 27.09.10.
//  Copyright 2010 YellowSoft. All rights reserved.
//

// Credits go to: 
// http://stackoverflow.com/questions/2833724/adding-view-on-statusbar-in-iphone
// http://cocoabyss.com/2010/ios-custom-status-bar/

#import <Foundation/Foundation.h>


@interface MTStatusBarOverlay : UIWindow {
	// holds all subviews, is touchable to change size of Status Bar
	UIControl *backgroundView_;
	
	// background of Status Bar Black or gray
	UIImageView *statusBarBackgroundImageView_;
	// for displaying Text information
	UILabel* statusLabel1_;
	UILabel* statusLabel2_;
	UILabel *hiddenStatusLabel_;
	// for displaying activity indication
	UIActivityIndicatorView* activityIndicator_;
	
	// Small size of Status Bar
	CGRect smallRect_;
	
	// Image of gray Status Bar
	UIImage *grayStatusBarImage_;
}

//=========================================================== 
#pragma mark -
#pragma mark Properties
//=========================================================== 
@property (nonatomic, retain) UIControl *backgroundView;
@property (nonatomic, assign) CGRect smallRect;

- (void)addSubviewToBackgroundView:(UIView *)view;

- (void)showWithMessage:(NSString *)message;
- (void)hide;

@end
