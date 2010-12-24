//
//  MTStatusBarOverlay.m
//
//  Created by Matthias Tretter on 27.09.10.
//  Copyright (c) 2009-2010  Matthias Tretter, @myell0w. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Credits go to:
// -------------------------------
// http://stackoverflow.com/questions/2833724/adding-view-on-statusbar-in-iphone
// http://cocoabyss.com/2010/ios-custom-status-bar/
// @reederapp
// -------------------------------

#import <Foundation/Foundation.h>

// Animation that happens, when the user touches the status bar overlay
typedef enum MTStatusBarOverlayAnimation {
	// nothing happens
	MTStatusBarOverlayAnimationNone,
	// the status bar shrinks to the right side and only shows the activity indicator
	MTStatusBarOverlayAnimationShrink,
	// the status bar falls down and displays more information
	MTStatusBarOverlayAnimationFallDown
} MTStatusBarOverlayAnimation;


// This class provides an overlay over the iOS Status Bar that can display information
// and perform an animation when you touch it
@interface MTStatusBarOverlay : UIWindow {
	// holds all subviews, is touchable to change size of Status Bar
	UIControl *backgroundView_;
	// the view that is shown in animation mode "FallDown" when the user touches the status bar
	UIControl *detailView_;

	// background of Status Bar Black or gray
	UIImageView *statusBarBackgroundImageView_;
	// for displaying Text information
	UILabel *statusLabel1_;
	UILabel *statusLabel2_;
	UILabel *hiddenStatusLabel_;
	// for displaying activity indication
	UIActivityIndicatorView *activityIndicator_;
	UILabel *finishedLabel_;

	// Image of gray Status Bar
	UIImage *grayStatusBarImage_;
	UIImage *grayStatusBarImageSmall_;

	// Animation-Type
	MTStatusBarOverlayAnimation animation_;
	// Small size of Status Bar
	CGRect smallFrame_;
	// temporary variable used for rotation
	CGRect oldBackgroundViewFrame_;
	// is set when finishWithMessage is called and the statusBar is set to be hidden
	// after a specified amount of time
	BOOL hideInProgress_;

	// Queue stuff
	NSMutableArray *queuedMessages_;
	NSTimer *queueTimer_;
}

//===========================================================
#pragma mark -
#pragma mark Properties
//===========================================================
@property (nonatomic, retain) UIControl *backgroundView;
@property (nonatomic, retain) UIControl *detailView;
@property (nonatomic, assign) CGRect smallFrame;
@property (nonatomic, assign) MTStatusBarOverlayAnimation animation;
@property (nonatomic, retain) UILabel *finishedLabel;
// detect if status bar is currently shrinked
@property (nonatomic, readonly, getter=isShrinked) BOOL shrinked;
// detect if detailView is currently shown
@property (nonatomic, readonly, getter=isDetailViewVisible) BOOL detailViewVisible;
// shows if finishWithMessage was currently called
@property (readonly, getter=isHideInProgress) BOOL hideInProgress;


//===========================================================
#pragma mark -
#pragma mark Class Methods
//===========================================================

// Singleton
+ (MTStatusBarOverlay *)sharedInstance;

//===========================================================
#pragma mark -
#pragma mark Instance Methods
//===========================================================

// for customizing appearance, automatically disabled userInteractionEnabled on view
- (void)addSubviewToBackgroundView:(UIView *)view;

// shows the status bar overlay
- (void)show;
// hides the status bar overlay
- (void)hide;
// convenience-method, set Message and show
- (void)showWithMessage:(NSString *)message;
// shows a checkmark instead of the activity indicator and hides the status bar after the specified duration
- (void)finishWithMessage:(NSString *)message duration:(NSTimeInterval)duration;
// shows a error-sign instead of the activity indicator and hides the status bar after the specified duration
- (void)finishWithErrorMessage:(NSString *)message duration:(NSTimeInterval)duration;
// enables you to change the display Message on the status bar animated or w/o animation
- (void)setMessage:(NSString *)message animated:(BOOL)animated;
// shows the message for a specified interval before displaying the next queued item, or hiding the overlay if none are left
- (void)queueMessage:(NSString *)message forInterval:(NSTimeInterval)interval animated:(BOOL)animated;
- (void)queueFinalMessage:(NSString *)message forInterval:(NSTimeInterval)interval animated:(BOOL)animated;

@end
