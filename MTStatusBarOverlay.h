//
//  MTStatusBarOverlay.m
//
//  Created by Matthias Tretter on 27.09.10.
//  Copyright (c) 2009-2011  Matthias Tretter, @myell0w. All rights reserved.
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
// http://www.cocoabyss.com/uikit/custom-status-bar-ios/
// @reederapp for inspiration
// -------------------------------

#import <Foundation/Foundation.h>


//===========================================================
#pragma mark -
#pragma mark Definitions and Types
//===========================================================

// Animation that happens, when the user touches the status bar overlay
typedef enum MTStatusBarOverlayAnimation {
	MTStatusBarOverlayAnimationNone,      // nothing happens
	MTStatusBarOverlayAnimationShrink,    // the status bar shrinks to the right side and only shows the activity indicator
	MTStatusBarOverlayAnimationFallDown   // the status bar falls down and displays more information
} MTStatusBarOverlayAnimation;


// Mode of the detail view
typedef enum MTDetailViewMode {
	MTDetailViewModeHistory,			// History of messages is recorded and displayed in detailView
	MTDetailViewModeDetailText,			// a text can be displayed easily
	MTDetailViewModeCustom				// the detailView can be customized in the way the developer wants
} MTDetailViewMode;

// indicates the type of a message
typedef enum MTMessageType {
	MTMessageTypeActivity,				// shows actvity indicator
	MTMessageTypeFinish,				// shows checkmark
	MTMessageTypeError					// shows error-mark
} MTMessageType;


// keys used in the dictionary-representation of a status message
#define kMTStatusBarOverlayMessageKey			@"MessageText"
#define kMTStatusBarOverlayMessageTypeKey		@"MessageType"
#define kMTStatusBarOverlayDurationKey			@"MessageDuration"
#define kMTStatusBarOverlayAnimationKey			@"MessageAnimation"
#define kMTStatusBarOverlayImmediateKey			@"MessageImmediate"

// keys used for saving state to NSUserDefaults
#define kMTStatusBarOverlayStateShrinked        @"kMTStatusBarOverlayStateShrinked"


// forward-declaration of delegate-protocol
@protocol MTStatusBarOverlayDelegate;


//===========================================================
#pragma mark -
#pragma mark MTStatusBarOverlay Interface
//===========================================================

/**
 This class provides an overlay over the iOS Status Bar that can display information
 and perform an animation when you touch it:
 
 it can either shrink and only overlap the battery-icon (like in Reeder) or it can display
 a detail-view that shows additional information. You can show a history of all the previous
 messages for free by setting historyEnabled to YES
 */
@interface MTStatusBarOverlay : UIWindow <UITableViewDataSource> 

// the view that holds all the components of the overlay (except for the detailView)
@property (nonatomic, strong) UIView *backgroundView;
// the detailView is shown when animation is set to "FallDown"
@property (nonatomic, strong) UIView *detailView;
// the current progress
@property (nonatomic, assign) double progress;
// the frame of the status bar when animation is set to "Shrink" and it is shrinked
@property (nonatomic, assign) CGRect smallFrame;
// the current active animation
@property (nonatomic, assign) MTStatusBarOverlayAnimation animation;
// the label that holds the finished-indicator (either a checkmark, or a error-sign per default)
@property (nonatomic, strong) UILabel *finishedLabel;
// if this flag is set to YES, neither activityIndicator nor finishedLabel are shown
@property (nonatomic, assign) BOOL hidesActivity;
// the image used when the Status Bar Style is Default
@property (nonatomic, strong) UIImage *defaultStatusBarImage;
// the image used when the Status Bar Style is Default and the Overlay is shrinked
@property (nonatomic, strong) UIImage *defaultStatusBarImageShrinked;
// detect if status bar is currently shrinked
@property (nonatomic, readonly, getter=isShrinked) BOOL shrinked;
// detect if detailView is currently hidden
@property (nonatomic, readonly, getter=isDetailViewHidden) BOOL detailViewHidden;
// all messages that were displayed since the last finish-call
@property (nonatomic, strong, readonly) NSMutableArray *messageHistory;
// DEPRECATED: enable/disable history-tracking of messages
@property (nonatomic, assign, getter=isHistoryEnabled) BOOL historyEnabled;
// the last message that was visible
@property (nonatomic, copy) NSString *lastPostedMessage;
// determines if immediate messages in the queue get removed or stay in the queue, when a new immediate message gets posted
@property (nonatomic, assign) BOOL canRemoveImmediateMessagesFromQueue;
// the mode of the detailView
@property (nonatomic, assign) MTDetailViewMode detailViewMode;
// the text displayed in the detailView (alternative to history)
@property (nonatomic, copy) NSString *detailText;
// the delegate of the overlay
@property (nonatomic, unsafe_unretained) id<MTStatusBarOverlayDelegate> delegate;
@property(nonatomic, strong) UIColor *customTextColor;
//===========================================================
#pragma mark -
#pragma mark Class Methods
//===========================================================

// Singleton Instance
+ (MTStatusBarOverlay *)sharedInstance;
+ (MTStatusBarOverlay *)sharedOverlay;

//===========================================================
#pragma mark -
#pragma mark Instance Methods
//===========================================================

// for customizing appearance, automatically disabled userInteractionEnabled on view
- (void)addSubviewToBackgroundView:(UIView *)view;
- (void)addSubviewToBackgroundView:(UIView *)view atIndex:(NSInteger)index;

// Method to re-post a cleared message
- (void)postMessageDictionary:(NSDictionary *)messageDictionary;

// shows an activity indicator and the given message
- (void)postMessage:(NSString *)message;
- (void)postMessage:(NSString *)message duration:(NSTimeInterval)duration;
- (void)postMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated;
- (void)postMessage:(NSString *)message animated:(BOOL)animated;
// clears the message queue and shows this message instantly
- (void)postImmediateMessage:(NSString *)message animated:(BOOL)animated;
- (void)postImmediateMessage:(NSString *)message duration:(NSTimeInterval)duration;
- (void)postImmediateMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated;

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

// hides the status bar overlay and resets it
- (void)hide;
// hides the status bar overlay but doesn't reset it's values
// this is useful if e.g. you have a screen where you don't have
// a status bar, but the other screens have one
// then you can hide it temporary and show it again afterwards
- (void)hideTemporary;
// this shows the status bar overlay, if there is text to show
- (void)show;

// saves the state in NSUserDefaults and synchronizes them
- (void)saveState;
- (void)saveStateSynchronized:(BOOL)synchronizeAtEnd;
// restores the state from NSUserDefaults
- (void)restoreState;

@end



//===========================================================
#pragma mark -
#pragma mark Delegate Protocol
//===========================================================

@protocol MTStatusBarOverlayDelegate <NSObject>
@optional
// is called, when a gesture on the overlay is recognized
- (void)statusBarOverlayDidRecognizeGesture:(UIGestureRecognizer *)gestureRecognizer;
// is called when the status bar overlay gets hidden
- (void)statusBarOverlayDidHide;
// is called, when the status bar overlay changed it's displayed message from one message to another
- (void)statusBarOverlayDidSwitchFromOldMessage:(NSString *)oldMessage toNewMessage:(NSString *)newMessage;
// is called when an immediate message gets posted and therefore messages in the queue get lost
// it tells the delegate the lost messages and the delegate can then enqueue the messages again
- (void)statusBarOverlayDidClearMessageQueue:(NSArray *)messageQueue;
@end
