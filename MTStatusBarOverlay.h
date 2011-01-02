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


//===========================================================
#pragma mark -
#pragma mark Definitions and Types
//===========================================================

// Animation that happens, when the user touches the status bar overlay
typedef enum MTStatusBarOverlayAnimation {
	MTStatusBarOverlayAnimationNone,	// nothing happens
	MTStatusBarOverlayAnimationShrink,  // the status bar shrinks to the right side and only shows the activity indicator
	MTStatusBarOverlayAnimationFallDown	// the status bar falls down and displays more information
} MTStatusBarOverlayAnimation;


// indicates the type of a message
typedef enum MTMessageType {
	MTMessageTypeActivity,				// shows actvity indicator
	MTMessageTypeFinish,				// shows checkmark
	MTMessageTypeError					// shows error-mark
} MTMessageType;


// forward-declaration of delegate-protocol
@protocol MTStatusBarOverlayDelegate;


#define kMTStatusBarOverlayMessageKey			@"MessageText"
#define kMTStatusBarOverlayMessageTypeKey		@"MessageType"
#define kMTStatusBarOverlayDurationKey			@"MessageDuration"
#define kMTStatusBarOverlayAnimationKey			@"MessageAnimation"


//===========================================================
#pragma mark -
#pragma mark MTStatusBarOverlay Interface
//===========================================================


// This class provides an overlay over the iOS Status Bar that can display information
// and perform an animation when you touch it:
// it can either shrink and only overlap the battery-icon (like in Reeder) or it can display
// a detail-view that shows additional information. You can show a history of all the previous
// messages for free by setting historyEnabled to YES
@interface MTStatusBarOverlay : UIWindow <UITableViewDataSource> {
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
	// flag that indicates whether currently a message is in the queue
	BOOL active_;

	// Queue stuff
	NSMutableArray *messageQueue_;

	// Message history (is reset when finish is called)
	BOOL historyEnabled_;
	NSMutableArray *messageHistory_;
	UITableView *historyTableView_;

	// the delegate
	id<MTStatusBarOverlayDelegate> delegate_;

	// interface orientations to rotate to:
	// they are only taken into consideration when automatic detection of current visible
	// view controller fails (currentVisibleViewController) so that the user can control
	// rotation on his own
	NSArray *interfaceOrientations_;
}

//===========================================================
#pragma mark -
#pragma mark Properties
//===========================================================
// the view that holds all the components of the overlay (except for the detailView)
@property (nonatomic, retain) UIControl *backgroundView;
// the detailView is shown when animation is set to "FallDown"
@property (nonatomic, retain) UIControl *detailView;
// the frame of the status bar when animation is set to "Shrink" and it is shrinked
@property (nonatomic, assign) CGRect smallFrame;
// the current active animation
@property (nonatomic, assign) MTStatusBarOverlayAnimation animation;
// the label that holds the finished-indicator (either a checkmark, or a error-sign per default)
@property (nonatomic, retain) UILabel *finishedLabel;
// detect if status bar is currently shrinked
@property (nonatomic, readonly, getter=isShrinked) BOOL shrinked;
// detect if detailView is currently hidden
@property (nonatomic, readonly, getter=isDetailViewHidden) BOOL detailViewHidden;
// all messages that were displayed since the last finish-call
@property (nonatomic, retain, readonly) NSMutableArray *messageHistory;
// enable/disable history-tracking of messages
@property (nonatomic, assign, getter=isHistoryEnabled) BOOL historyEnabled;
// the delegate of the overlay
@property (nonatomic, assign) id<MTStatusBarOverlayDelegate> delegate;
// the orientations to rotate to (only if currentVisibleViewController returns nil)
@property (nonatomic, copy) NSArray *interfaceOrientations;


//===========================================================
#pragma mark -
#pragma mark Class Methods
//===========================================================

// Singleton Instance
+ (MTStatusBarOverlay *)sharedInstance;

//===========================================================
#pragma mark -
#pragma mark Instance Methods
//===========================================================

// for customizing appearance, automatically disabled userInteractionEnabled on view
- (void)addSubviewToBackgroundView:(UIView *)view;

// shows an activity indicator and the given message
- (void)postMessage:(NSString *)message;
- (void)postMessage:(NSString *)message animated:(BOOL)animated;
// clears the message queue and shows this message instantly
- (void)postImmediateMessage:(NSString *)message animated:(BOOL)animated;

// shows a checkmark instead of the activity indicator and hides the status bar after the specified duration
- (void)postFinishMessage:(NSString *)message duration:(NSTimeInterval)duration;
- (void)postFinishMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated;
// clears the message queue and shows this message instantly
- (void)postImmediateFinishMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated;

// shows a error-sign instead of the activity indicator and hides the status bar after the specified duration
- (void)postErrorMessage:(NSString *)message duration:(NSTimeInterval)duration;
- (void)postErrorMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated;
// clears the message queue and shows this message instantly
- (void)postImmediateErrorMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated;

// hides the status bar overlay
- (void)hide;

@end




//===========================================================
#pragma mark -
#pragma mark Delegate Protocol
//===========================================================

@protocol MTStatusBarOverlayDelegate <NSObject>
@optional
// is called when the status bar overlay gets hidden
- (void)statusBarOverlayDidHide;
// is called, when the status bar overlay changed it's displayed message from one message to another
- (void)statusBarOverlayDidSwitchFromOldMessage:(NSString *)oldMessage toNewMessage:(NSString *)newMessage;
// is called when an immediate message gets posted and therefore messages in the queue get lost
// it tells the delegate the lost messages and the delegate can then enqueue the messages again
- (void)statusBarOverlayDidClearMessageQueue:(NSArray *)messageQueue;
@end
