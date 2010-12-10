//
//  MTStatusBar.h
//  MTHelper
//
//  Created by Matthias Tretter on 27.09.10.
//  Copyright 2010 YellowSoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MTStatusBarOverlay : UIWindow {
	// holds all subviews, is touchable to change size of Status Bar
	UIControl *backgroundView_;
	
	// background of Status Bar Black or gray
	UIImageView *statusBarBackgroundImageView_;
	// for displaying Text information
	UILabel* statusLabel_;
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
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, assign) CGRect smallRect;

// adds a subview to the overlay and automatically sets its user interaction to disabled
// so that the user interaction is handled by the backgroundView
- (void)addSubviewToBackgroundView:(UIView *)view;

- (void)showWithMessage:(NSString *)message;
- (void)hide;

@end
