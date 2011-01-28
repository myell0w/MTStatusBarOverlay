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
// http://cocoabyss.com/2010/ios-custom-status-bar/
// @reederapp
// -------------------------------

#import "MTStatusBarOverlay.h"
#import <QuartzCore/QuartzCore.h>



//===========================================================
#pragma mark -
#pragma mark Function Headers
//===========================================================

NSData* MTStatusBarBackgroundImageData(BOOL shrinked);
unsigned char* MTStatusBarBackgroundImageArray(BOOL shrinked);
unsigned int MTStatusBarBackgroundImageLength(BOOL shrinked);

//===========================================================
#pragma mark -
#pragma mark Defines
//===========================================================

// the height of the status bar
#define kStatusBarHeight 20
// width of the screen in portrait-orientation
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
// height of the screen in portrait-orientation
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
// macro for checking if we are on the iPad
#define IsIPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
// macro for checking if we are on the iPad in iPhone-Emulation mode
#define IsIPhoneEmulationMode (!IsIPad && \
			MAX([UIApplication sharedApplication].statusBarFrame.size.width, [UIApplication sharedApplication].statusBarFrame.size.height) > 480)



//===========================================================
#pragma mark -
#pragma mark Customize Section
//===========================================================

///////////////////////////////////////////////////////
// Light Theme (for UIStatusBarStyleDefault)
///////////////////////////////////////////////////////

#define kLightThemeTextColor						[UIColor blackColor]
#define kLightThemeActivityIndicatorViewStyle		UIActivityIndicatorViewStyleGray
#define kLightThemeDetailViewBackgroundColor		[UIColor blackColor]
#define kLightThemeDetailViewBorderColor			[UIColor darkGrayColor]
#define kLightThemeHistoryTextColor					[UIColor colorWithRed:0.749f green:0.749f blue:0.749f alpha:1.0f]


///////////////////////////////////////////////////////
// Dark Theme (for UIStatusBarStyleBlackOpaque)
///////////////////////////////////////////////////////

#define kDarkThemeTextColor							[UIColor colorWithRed:0.749f green:0.749f blue:0.749f alpha:1.0f]
#define kDarkThemeActivityIndicatorViewStyle		UIActivityIndicatorViewStyleWhite
#define kDarkThemeDetailViewBackgroundColor			[UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.0f]
#define kDarkThemeDetailViewBorderColor				[UIColor whiteColor]
#define kDarkThemeHistoryTextColor					[UIColor whiteColor]


///////////////////////////////////////////////////////
// Animations
///////////////////////////////////////////////////////

// minimum time that a message is shown, when messages are queued
#define kMinimumMessageVisibleTime				0.5f

// duration of the animation to show next status message in seconds
#define kNextStatusAnimationDuration			0.8f

// duration the statusBarOverlay takes to appear when it was hidden
#define kAppearAnimationDuration				0.5f

// animation duration of animation mode shrink
#define kAnimationDurationShrink				0.3f

// animation duration of animation mode fallDown
#define kAnimationDurationFallDown				0.4f

// delay after that the status bar gets visible again after rotation
#define kRotationAppearDelay					[UIApplication sharedApplication].statusBarOrientationAnimationDuration


///////////////////////////////////////////////////////
// Text
///////////////////////////////////////////////////////

// Text that is displayed in the finished-Label when the finish was successful
#define kFinishedText		@"✔"
#define kFinishedFontSize	22.f

// Text that is displayed when an error occured
#define kErrorText			@"✗"
#define kErrorFontSize		19.f



///////////////////////////////////////////////////////
// Detail View
///////////////////////////////////////////////////////

#define kHistoryTableRowHeight		25
#define kMaxHistoryTableRowCount	5

#define kDetailViewAlpha			0.9f
#define kDetailViewWidth			(IsIPad ? 400 : 280)
// default frame of detail view when it is hidden
#define kDefaultDetailViewFrame CGRectMake((kScreenWidth - kDetailViewWidth)/2, -(kHistoryTableRowHeight*kMaxHistoryTableRowCount + kStatusBarHeight),\
										    kDetailViewWidth, kHistoryTableRowHeight*kMaxHistoryTableRowCount + kStatusBarHeight)


///////////////////////////////////////////////////////
// Size
///////////////////////////////////////////////////////

// Size of the text in the status labels
#define kStatusLabelSize				12.f

// default-width of the small-mode
#define kWidthSmall						26



//===========================================================
#pragma mark -
#pragma mark Private Class Extension
//===========================================================

@interface MTStatusBarOverlay ()

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UIImageView *statusBarBackgroundImageView;
@property (nonatomic, retain) UILabel *statusLabel1;
@property (nonatomic, retain) UILabel *statusLabel2;
@property (nonatomic, assign) UILabel *hiddenStatusLabel;
@property (nonatomic, readonly) UILabel *visibleStatusLabel;
@property (nonatomic, assign) CGRect oldBackgroundViewFrame;
// overwrite property for read-write-access
@property (assign, getter=isHideInProgress) BOOL hideInProgress;
@property (assign, getter=isActive) BOOL active;
// read out hidden-state using alpha-value and hidden-property
@property (nonatomic, readonly, getter=isReallyHidden) BOOL reallyHidden;
@property (nonatomic, retain) UITextView *detailTextView;
@property (nonatomic, retain) NSMutableArray *messageQueue;
// overwrite property for read-write-access
@property (nonatomic, retain) NSMutableArray *messageHistory;
@property (nonatomic, retain) UITableView *historyTableView;

// intern method that posts a new entry to the message-queue
- (void)postMessage:(NSString *)message type:(MTMessageType)messageType duration:(NSTimeInterval)duration animated:(BOOL)animated immediate:(BOOL)immediate;
// intern method that clears the messageQueue and then posts a new entry to it
- (void)postImmediateMessage:(NSString *)message type:(MTMessageType)messageType duration:(NSTimeInterval)duration animated:(BOOL)animated;
// intern method that does all the work of showing the next message in the queue
- (void)showNextMessage;

// is called when the user touches the statusbar
- (IBAction)contentViewClicked:(id)sender;
// updates the current status bar background image for the given style and current size
- (void)setStatusBarBackgroundForStyle:(UIStatusBarStyle)style;
// updates the text-colors of the labels for the given style
- (void)setColorSchemeForStatusBarStyle:(UIStatusBarStyle)style;
// updates the visiblity of the activity indicator and finished-label depending on the type
- (void)updateUIForMessageType:(MTMessageType)messageType duration:(NSTimeInterval)duration;
// calls the delegate when a switch from one message to another one occured
- (void)callDelegateWithNewMessage:(NSString *)newMessage;
// update the height of the detail text view according to new text
- (void)updateDetailTextViewHeight;
// shrink/expand the overlay
- (void)setShrinked:(BOOL)shrinked animated:(BOOL)animated;

// set hidden-state using alpha-value instead of hidden-property
- (void)setHidden:(BOOL)hidden useAlpha:(BOOL)useAlpha;
// used for performSelector:withObject:
- (void)setHiddenUsingAlpha:(BOOL)hidden;
// set hidden-state of detailView
- (void)setDetailViewHidden:(BOOL)hidden animated:(BOOL)animated;

// History-tracking
- (void)addMessageToHistory:(NSString *)message;
- (void)clearHistory;

// selectors
- (void)rotateToStatusBarFrame:(NSValue *)statusBarFrameValue;
- (void)didChangeStatusBarFrame:(NSNotification *)notification;

@end



@implementation MTStatusBarOverlay

//===========================================================
#pragma mark -
#pragma mark Synthesizing
//===========================================================
@synthesize backgroundView = backgroundView_;
@synthesize detailView = detailView_;
@synthesize statusBarBackgroundImageView = statusBarBackgroundImageView_;
@synthesize statusLabel1 = statusLabel1_;
@synthesize statusLabel2 = statusLabel2_;
@synthesize hiddenStatusLabel = hiddenStatusLabel_;
@synthesize activityIndicator = activityIndicator_;
@synthesize finishedLabel = finishedLabel_;
@synthesize hidesActivity = hidesActivity_;
@synthesize defaultStatusBarImage = defaultStatusBarImage_;
@synthesize defaultStatusBarImageShrinked = defaultStatusBarImageShrinked_;
@synthesize smallFrame = smallFrame_;
@synthesize oldBackgroundViewFrame = oldBackgroundViewFrame_;
@synthesize animation = animation_;
@synthesize hideInProgress = hideInProgress_;
@synthesize active = active_;
@synthesize messageQueue = messageQueue_;
@synthesize canRemoveImmediateMessagesFromQueue = canRemoveImmediateMessagesFromQueue_;
@synthesize detailViewMode = detailViewMode_;
@synthesize detailText = detailText_;
@synthesize detailTextView = detailTextView_;
@synthesize messageHistory = messageHistory_;
@synthesize historyTableView = historyTableView_;
@synthesize delegate = delegate_;

//===========================================================
#pragma mark -
#pragma mark Lifecycle
//===========================================================

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;

		// only use height of 20px even is status bar is doubled
		statusBarFrame.size.height = statusBarFrame.size.height == 2*kStatusBarHeight ? kStatusBarHeight : statusBarFrame.size.height;
		// if we are on the iPad but in iPhone-Mode (non-universal-app) correct the width
		if(IsIPhoneEmulationMode) {
			statusBarFrame.size.width = 320;
		}

		// Place the window on the correct level and position
        self.windowLevel = UIWindowLevelStatusBar+1.0f;
        self.frame = statusBarFrame;
		self.alpha = 0.0f;
		self.hidden = NO;

		// Default Small size: just show Activity Indicator
		smallFrame_ = CGRectMake(self.frame.size.width - kWidthSmall, 0.0f, kWidthSmall, self.frame.size.height);

		// Default-values
		animation_ = MTStatusBarOverlayAnimationNone;
		active_ = NO;
		hidesActivity_ = NO;

		// the detail view that is shown when the user touches the status bar in animation mode "FallDown"
		detailView_ = [[UIControl alloc] initWithFrame:kDefaultDetailViewFrame];
		detailView_.backgroundColor = [UIColor blackColor];
		detailView_.alpha = kDetailViewAlpha;
		detailView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		detailViewMode_ = MTDetailViewModeCustom;

		// add rounded corners to detail-view
		detailView_.layer.masksToBounds = YES;
		detailView_.layer.cornerRadius = 10.0f;
		detailView_.layer.borderWidth = 2.5f;
		// add shadow
		/*detailView_.layer.shadowColor = [UIColor blackColor].CGColor;
		detailView_.layer.shadowOpacity = 1.0f;
		detailView_.layer.shadowRadius = 6.0f;
		detailView_.layer.shadowOffset = CGSizeMake(0, 3);*/

		// Detail Text label
		detailTextView_ = [[UITextView alloc] initWithFrame:CGRectMake(0, kStatusBarHeight,
																	 kDefaultDetailViewFrame.size.width, kDefaultDetailViewFrame.size.height - kStatusBarHeight)];
		detailTextView_.backgroundColor = [UIColor clearColor];
		detailTextView_.hidden = detailViewMode_ != MTDetailViewModeDetailText;
		[detailView_ addSubview:detailTextView_];

		// Message History
		messageHistory_ = [[NSMutableArray alloc] init];

		historyTableView_ = [[UITableView alloc] initWithFrame:CGRectMake(0, kStatusBarHeight,
																		  kDefaultDetailViewFrame.size.width, kDefaultDetailViewFrame.size.height - kStatusBarHeight)];
		historyTableView_.dataSource = self;
		historyTableView_.delegate = nil;
		historyTableView_.rowHeight = kHistoryTableRowHeight;
		historyTableView_.separatorStyle = UITableViewCellSeparatorStyleNone;
		// make table view-background transparent
		historyTableView_.backgroundColor = [UIColor clearColor];
		historyTableView_.opaque = NO;
		historyTableView_.hidden = detailViewMode_ != MTDetailViewModeHistory;
		historyTableView_.backgroundView = nil;

		[detailView_ addSubview:historyTableView_];
		[self addSubview:detailView_];


        // Create view that stores all the content
        backgroundView_ = [[UIControl alloc] initWithFrame:self.frame];
		[backgroundView_ addTarget:self action:@selector(contentViewClicked:) forControlEvents:UIControlEventTouchUpInside];
		backgroundView_.clipsToBounds = YES;
		backgroundView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		// Images used as background when status bar style is Default
		defaultStatusBarImage_ = [[UIImage imageWithData:MTStatusBarBackgroundImageData(NO)] retain];
		defaultStatusBarImageShrinked_ = [[UIImage imageWithData:MTStatusBarBackgroundImageData(YES)] retain];

		// Background-Image of the Content View
		statusBarBackgroundImageView_ = [[UIImageView alloc] initWithFrame:self.frame];
		statusBarBackgroundImageView_.backgroundColor = [UIColor blackColor];
		statusBarBackgroundImageView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubviewToBackgroundView:statusBarBackgroundImageView_];

		// Activity Indicator
		activityIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityIndicator_.frame = CGRectMake(6.0f, 3.0f, self.frame.size.height - 6, self.frame.size.height - 6);
		activityIndicator_.hidesWhenStopped = YES;
		[self addSubviewToBackgroundView:activityIndicator_];

		// Finished-Label
		finishedLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(4,1,self.frame.size.height, self.frame.size.height-1)];
		finishedLabel_.backgroundColor = [UIColor clearColor];
		finishedLabel_.hidden = YES;
		finishedLabel_.text = kFinishedText;
		finishedLabel_.textAlignment = UITextAlignmentCenter;
		finishedLabel_.font = [UIFont boldSystemFontOfSize:kFinishedFontSize];
		[self addSubviewToBackgroundView:finishedLabel_];

		// Status Label 1 is first visible
		statusLabel1_ = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, 0.0f, self.frame.size.width - 60.0f, self.frame.size.height-1)];
		statusLabel1_.backgroundColor = [UIColor clearColor];
		statusLabel1_.font = [UIFont boldSystemFontOfSize:kStatusLabelSize];
		statusLabel1_.textAlignment = UITextAlignmentCenter;
		statusLabel1_.numberOfLines = 1;
		statusLabel1_.lineBreakMode = UILineBreakModeTailTruncation;
		statusLabel1_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubviewToBackgroundView:statusLabel1_];

		// Status Label 2 is hidden
		statusLabel2_ = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, self.frame.size.height,self.frame.size.width - 60.0f , self.frame.size.height-1)];
		statusLabel2_.backgroundColor = [UIColor clearColor];
		statusLabel2_.font = [UIFont boldSystemFontOfSize:kStatusLabelSize];
		statusLabel2_.textAlignment = UITextAlignmentCenter;
		statusLabel2_.numberOfLines = 1;
		statusLabel2_.lineBreakMode = UILineBreakModeTailTruncation;
		statusLabel2_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubviewToBackgroundView:statusLabel2_];

		// the hidden status label at the beginning
		hiddenStatusLabel_ = statusLabel2_;

		messageQueue_ = [[NSMutableArray alloc] init];
		canRemoveImmediateMessagesFromQueue_ = YES;

        [self addSubview:backgroundView_];

		// listen for changes of status bar frame
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didChangeStatusBarFrame:)
													 name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    }

	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[backgroundView_ release], backgroundView_ = nil;
	[detailView_ release], detailView_ = nil;
	[statusBarBackgroundImageView_ release], statusBarBackgroundImageView_ = nil;
	[statusLabel1_ release], statusLabel1_ = nil;
	[statusLabel2_ release], statusLabel2_ = nil;
	[activityIndicator_ release], activityIndicator_ = nil;
	[finishedLabel_ release], finishedLabel_ = nil;
	[defaultStatusBarImage_ release], defaultStatusBarImage_ = nil;
	[defaultStatusBarImageShrinked_ release], defaultStatusBarImageShrinked_ = nil;
	[detailText_ release], detailText_ = nil;
	[detailTextView_ release], detailTextView_ = nil;
	[messageQueue_ release], messageQueue_ = nil;
	[messageHistory_ release], messageHistory_ = nil;
	delegate_ = nil;

	[super dealloc];
}


//===========================================================
#pragma mark -
#pragma mark Change status bar appearance and behavior
//===========================================================

- (void)addSubviewToBackgroundView:(UIView *)view {
	view.userInteractionEnabled = NO;
	[self.backgroundView addSubview:view];
}

- (void)addSubviewToBackgroundView:(UIView *)view atIndex:(NSInteger)index {
	view.userInteractionEnabled = NO;
	[self.backgroundView insertSubview:view atIndex:index];
}

- (void)postMessage:(NSString *)message {
	[self postMessage:message animated:YES];
}

- (void)postMessage:(NSString *)message animated:(BOOL)animated {
	[self postMessage:message type:MTMessageTypeActivity duration:0 animated:animated immediate:NO];
}

- (void)postImmediateMessage:(NSString *)message animated:(BOOL)animated {
	[self postImmediateMessage:message type:MTMessageTypeActivity duration:0 animated:animated];
}

- (void)postFinishMessage:(NSString *)message duration:(NSTimeInterval)duration {
	[self postFinishMessage:message duration:duration animated:YES];
}

- (void)postFinishMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated {
	[self postMessage:message type:MTMessageTypeFinish duration:duration animated:animated immediate:NO];
}

- (void)postImmediateFinishMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated {
	[self postImmediateMessage:message type:MTMessageTypeFinish duration:duration animated:animated];
}

- (void)postErrorMessage:(NSString *)message duration:(NSTimeInterval)duration {
	[self postErrorMessage:message duration:duration animated:YES];
}

- (void)postErrorMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated {
	[self postMessage:message type:MTMessageTypeError duration:duration animated:animated immediate:NO];
}

- (void)postImmediateErrorMessage:(NSString *)message duration:(NSTimeInterval)duration animated:(BOOL)animated {
	[self postImmediateMessage:message type:MTMessageTypeError duration:duration animated:animated];
}

- (void)postMessage:(NSString *)message type:(MTMessageType)messageType duration:(NSTimeInterval)duration animated:(BOOL)animated immediate:(BOOL)immediate {
	// don't add to queue when message is empty
	if (message == nil) {
		return;
	}

	NSDictionary *messageDictionaryRepresentation = [NSDictionary dictionaryWithObjectsAndKeys:message, kMTStatusBarOverlayMessageKey,
													 [NSNumber numberWithInt:messageType], kMTStatusBarOverlayMessageTypeKey,
													 [NSNumber numberWithDouble:duration], kMTStatusBarOverlayDurationKey,
													 [NSNumber numberWithBool:animated],  kMTStatusBarOverlayAnimationKey,
													 [NSNumber numberWithBool:immediate], kMTStatusBarOverlayImmediateKey, nil];

	@synchronized (self.messageQueue) {
		[self.messageQueue insertObject:messageDictionaryRepresentation atIndex:0];
	}

	// if the overlay is currently not active, begin with showing of messages
	if (!self.active) {
		[self showNextMessage];
	}
}

- (void)postImmediateMessage:(NSString *)message type:(MTMessageType)messageType duration:(NSTimeInterval)duration animated:(BOOL)animated {
	@synchronized(self.messageQueue) {
		NSMutableArray *clearedMessages = [NSMutableArray array];

		for (id messageDictionary in self.messageQueue) {
			if (messageDictionary != [self.messageQueue lastObject] &&
				(self.canRemoveImmediateMessagesFromQueue || [[messageDictionary valueForKey:kMTStatusBarOverlayImmediateKey] boolValue] == NO)) {
				[clearedMessages addObject:messageDictionary];
			}
		}

		[self.messageQueue removeObjectsInArray:clearedMessages];

		// call delegate
		if (self.delegate != nil && [self.delegate respondsToSelector:@selector(statusBarOverlayDidHide)] && clearedMessages.count > 0) {
			[self.delegate statusBarOverlayDidClearMessageQueue:clearedMessages];
		}
	}

	[self postMessage:message type:messageType duration:duration animated:animated immediate:YES];
}


- (void)showNextMessage {
	// if there is no next message to show overlay is not active anymore
	@synchronized(self.messageQueue) {
		if([self.messageQueue count] < 1) {
			self.active = NO;
			return;
		}
	}

	// there is a next message, overlay is active
	self.active = YES;

	NSDictionary *nextMessageDictionary = nil;

	// read out next message
	@synchronized(self.messageQueue) {
		nextMessageDictionary = [self.messageQueue lastObject];
	}

	NSString *message = [nextMessageDictionary valueForKey:kMTStatusBarOverlayMessageKey];
	MTMessageType messageType = (MTMessageType)[[nextMessageDictionary valueForKey:kMTStatusBarOverlayMessageTypeKey] intValue];
	NSTimeInterval duration = (NSTimeInterval)[[nextMessageDictionary valueForKey:kMTStatusBarOverlayDurationKey] doubleValue];
	BOOL animated = [[nextMessageDictionary valueForKey:kMTStatusBarOverlayAnimationKey] boolValue];

	// don't show anything if status bar is hidden (queue gets cleared)
	if([UIApplication sharedApplication].statusBarHidden) {
		@synchronized(self.messageQueue) {
			[self.messageQueue removeAllObjects];
		}

		self.active = NO;

		return;
	}

	// don't duplicate animation if already displaying with text
	if (!self.reallyHidden && [self.visibleStatusLabel.text isEqualToString:message]) {
		// remove unneccesary message
		@synchronized(self.messageQueue) {
			[self.messageQueue removeLastObject];
		}

		// show the next message w/o delay
		[self showNextMessage];

		return;
	}

	// cancel previous hide- and clear requests
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearHistory) object:nil];

	// update UI depending on current status bar style
	UIStatusBarStyle statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
	[self setStatusBarBackgroundForStyle:statusBarStyle];
	[self setColorSchemeForStatusBarStyle:statusBarStyle];
	[self updateUIForMessageType:messageType duration:duration];

	// if status bar is currently hidden, show it
	if (self.reallyHidden) {
		// set text of visible status label
		self.visibleStatusLabel.text = message;

		// show status bar overlay with animation
		[UIView animateWithDuration:self.shrinked ? 0 : kAppearAnimationDuration
						 animations:^{
							 [self setHidden:NO useAlpha:YES];
						 }
						 completion:^(BOOL finished) {
							 // add old message to history
							 [self addMessageToHistory:self.hiddenStatusLabel.text];

							 // remove the message from the queue
							 @synchronized(self.messageQueue) {
								 [self.messageQueue removeLastObject];
							 }

							 // inform delegate about message-switch
							 [self callDelegateWithNewMessage:message];

							 // show the next message
							 [self performSelector:@selector(showNextMessage) withObject:nil afterDelay:kMinimumMessageVisibleTime];
						 }];
	}

	// status bar is currently visible
	else {
		if (animated) {
			// set text of currently not visible label to new text
			self.hiddenStatusLabel.text = message;

			// position hidden status label under visible status label
			self.hiddenStatusLabel.frame = CGRectMake(self.hiddenStatusLabel.frame.origin.x,
													  kStatusBarHeight,
													  self.hiddenStatusLabel.frame.size.width,
													  self.hiddenStatusLabel.frame.size.height);


			// animate hidden label into user view and visible status label out of view
			[UIView animateWithDuration:kNextStatusAnimationDuration
								  delay:0
								options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
							 animations:^{
								 // move both status labels up
								 self.statusLabel1.frame = CGRectMake(self.statusLabel1.frame.origin.x,
																	  self.statusLabel1.frame.origin.y - kStatusBarHeight,
																	  self.statusLabel1.frame.size.width,
																	  self.statusLabel1.frame.size.height);
								 self.statusLabel2.frame = CGRectMake(self.statusLabel2.frame.origin.x,
																	  self.statusLabel2.frame.origin.y - kStatusBarHeight,
																	  self.statusLabel2.frame.size.width,
																	  self.statusLabel2.frame.size.height);
							 }
							 completion:^(BOOL finished) {
								 // add old message to history
								 [self addMessageToHistory:self.visibleStatusLabel.text];

								 // after animation, set new hidden status label indicator
								 if (self.hiddenStatusLabel == self.statusLabel1) {
									 self.hiddenStatusLabel = self.statusLabel2;
								 } else {
									 self.hiddenStatusLabel = self.statusLabel1;
								 }

								 // remove the message from the queue
								 @synchronized(self.messageQueue) {
									 [self.messageQueue removeLastObject];
								 }

								 // inform delegate about message-switch
								 [self callDelegateWithNewMessage:message];

								 // show the next message
								 [self performSelector:@selector(showNextMessage) withObject:nil afterDelay:kMinimumMessageVisibleTime];
							 }];
		}

		// w/o animation just save old text and set new one
		else {
			// add old message to history
			[self addMessageToHistory:self.visibleStatusLabel.text];
			// set new text
			self.visibleStatusLabel.text = message;

			// remove the message from the queue
			@synchronized(self.messageQueue) {
				[self.messageQueue removeLastObject];
			}

			// inform delegate about message-switch
			[self callDelegateWithNewMessage:message];

			// show next message
			[self performSelector:@selector(showNextMessage) withObject:nil afterDelay:kMinimumMessageVisibleTime];
		}
	}
}

- (void)hide {
	[self.activityIndicator stopAnimating];
	self.statusLabel1.text = @"";
	self.statusLabel2.text = @"";

	self.hideInProgress = NO;
	// cancel previous hide- and clear requests
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];

	// hide status bar overlay with animation
	[UIView animateWithDuration:self.shrinked ? 0 : kAppearAnimationDuration animations:^{
		[self setHidden:YES useAlpha:YES];
	} completion:^(BOOL finished) {
		// hide detailView
		[self setDetailViewHidden:YES animated:NO];

		// call delegate
		if (self.delegate != nil && [self.delegate respondsToSelector:@selector(statusBarOverlayDidHide)]) {
			[self.delegate statusBarOverlayDidHide];
		}
	}];
}


//===========================================================
#pragma mark -
#pragma mark Rotation Stuff
//===========================================================

- (void)didChangeStatusBarFrame:(NSNotification *)notification {
	NSValue * statusBarFrameValue = [notification.userInfo valueForKey:UIApplicationStatusBarFrameUserInfoKey];

	// TODO: react on changes of status bar height (e.g. incoming call, tethering, ...)
	// NSLog(@"Status bar frame changed: %@", NSStringFromCGRect([statusBarFrameValue CGRectValue]));

	// have to use performSelector to prohibit animation of rotation
	[self performSelector:@selector(rotateToStatusBarFrame:) withObject:statusBarFrameValue afterDelay:0];
}

- (void)rotateToStatusBarFrame:(NSValue *)statusBarFrameValue {
	// current device orientation
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	// is the statusBar visible before rotation?
	BOOL visibleBeforeTransformation = !self.reallyHidden;
	// store a flag, if the StatusBar is currently shrinked
	BOOL shrinkedBeforeTransformation = self.shrinked;


	// hide and then unhide after rotation
	if (visibleBeforeTransformation) {
		[self setHidden:YES useAlpha:YES];
		[self setDetailViewHidden:YES animated:NO];
	}

	CGFloat pi = (CGFloat)M_PI;
	if (orientation == UIDeviceOrientationPortrait) {
		self.transform = CGAffineTransformIdentity;
		self.frame = CGRectMake(0,0,kScreenWidth,kStatusBarHeight);
		self.smallFrame = CGRectMake(self.frame.size.width - kWidthSmall, 0.0f, kWidthSmall, self.frame.size.height);
	}else if (orientation == UIDeviceOrientationLandscapeLeft) {
		self.transform = CGAffineTransformMakeRotation(pi * (90) / 180.0f);
		self.frame = CGRectMake(kScreenWidth - kStatusBarHeight,0, kStatusBarHeight, kScreenHeight);
		self.smallFrame = CGRectMake(kScreenHeight-kWidthSmall,0,kWidthSmall,kStatusBarHeight);
	} else if (orientation == UIDeviceOrientationLandscapeRight) {
		self.transform = CGAffineTransformMakeRotation(pi * (-90) / 180.0f);
		self.frame = CGRectMake(0,0, kStatusBarHeight, kScreenHeight);
		self.smallFrame = CGRectMake(kScreenHeight-kWidthSmall,0, kWidthSmall, kStatusBarHeight);
	} else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
		self.transform = CGAffineTransformMakeRotation(pi);
		self.frame = CGRectMake(0,kScreenHeight - kStatusBarHeight,kScreenWidth,kStatusBarHeight);
		self.smallFrame = CGRectMake(self.frame.size.width - kWidthSmall, 0.0f, kWidthSmall, self.frame.size.height);
	}

	// if the statusBar is currently shrinked, update the frames for the new rotation state
	if (shrinkedBeforeTransformation) {
		// the oldBackgroundViewFrame is the frame of the whole StatusBar
		self.oldBackgroundViewFrame = CGRectMake(0,0,UIInterfaceOrientationIsPortrait(orientation) ? kScreenWidth : kScreenHeight,kStatusBarHeight);
		// the backgroundView gets the newly computed smallFrame
		self.backgroundView.frame = self.smallFrame;
	}

	// make visible after given time
	if (visibleBeforeTransformation) {
		// TODO:
		// somehow this doesn't work anymore since rotation-method was changed from
		// DeviceDidRotate-Notification to StatusBarFrameChanged-Notification
		// therefore iplemented it with a UIView-Animation instead
		//[self performSelector:@selector(setHiddenUsingAlpha:) withObject:[NSNumber numberWithBool:NO] afterDelay:kRotationAppearDelay];

		[UIView animateWithDuration:kAppearAnimationDuration
							  delay:kRotationAppearDelay
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^{
							 [self setHiddenUsingAlpha:NO];
							}
						 completion:NULL];
	}
}

//===========================================================
#pragma mark -
#pragma mark Setter/Getter
//===========================================================

- (void)setDetailText:(NSString *)detailText {
	// custom setter Memory Mgmt
	if (detailText_ != detailText) {
        [detailText_ release];
        detailText_ = [detailText copy];
    }

	// update text in label
	self.detailTextView.text = detailText;

	// update height of detailText-View
	[self updateDetailTextViewHeight];
	// update height of detailView
	[self setDetailViewHidden:self.detailViewHidden animated:YES];
}

- (void)setDetailViewMode:(MTDetailViewMode)detailViewMode {
	detailViewMode_ = detailViewMode;

	// update UI
	self.historyTableView.hidden = detailViewMode != MTDetailViewModeHistory;
	self.detailTextView.hidden = detailViewMode != MTDetailViewModeDetailText;
}

- (void)setAnimation:(MTStatusBarOverlayAnimation)animation {
	animation_ = animation;

	// update appearance according to new animation-mode

	// if new animation mode is shrink or none, the detailView mustn't be visible
	if (animation == MTStatusBarOverlayAnimationShrink || animation == MTStatusBarOverlayAnimationNone) {
		// detailView currently visible -> hide it
		if (!self.detailViewHidden) {
			[self setDetailViewHidden:YES animated:YES];
		}
	}

	// if new animation mode is fallDown, the overlay must be extended
	if (animation == MTStatusBarOverlayAnimationFallDown) {
		if (self.shrinked) {
			[self setShrinked:NO animated:YES];
		}
	}
}

- (BOOL)isShrinked {
	return self.backgroundView.frame.size.width == self.smallFrame.size.width;
}

- (void)setShrinked:(BOOL)shrinked animated:(BOOL)animated {
	[UIView animateWithDuration:animated ? kAnimationDurationShrink : 0
					 animations:^{
						 // shrink the overlay
						 if (shrinked) {
							 self.oldBackgroundViewFrame = self.backgroundView.frame;
							 self.backgroundView.frame = self.smallFrame;

							 self.statusLabel1.hidden = YES;
							 self.statusLabel2.hidden = YES;
						 }
						 // expand the overlay
						 else {
							 self.backgroundView.frame = self.oldBackgroundViewFrame;

							 self.statusLabel1.hidden = NO;
							 self.statusLabel2.hidden = NO;
						 }

						 // update status bar background
						 [self setStatusBarBackgroundForStyle:[UIApplication sharedApplication].statusBarStyle];
					 }];
}


- (BOOL)isDetailViewHidden {
	return self.detailView.hidden == YES || self.detailView.alpha == 0.0 ||
		   self.detailView.frame.origin.y + self.detailView.frame.size.height < kStatusBarHeight;
}

- (void)setDetailViewHidden:(BOOL)hidden animated:(BOOL)animated {
	// hide detail view
	if (hidden) {
		[UIView animateWithDuration:animated ? kAnimationDurationFallDown : 0
							  delay:0
							options:UIViewAnimationOptionCurveEaseOut
						 animations: ^{
							 self.detailView.frame = CGRectMake(self.detailView.frame.origin.x, - self.detailView.frame.size.height,
																self.detailView.frame.size.width, self.detailView.frame.size.height);
						 }
						 completion:NULL];
	}
	// show detail view
	else {
		[UIView animateWithDuration:animated ? kAnimationDurationFallDown : 0
							  delay:0
							options:UIViewAnimationOptionCurveEaseIn
						 animations: ^{
							 int y = 0;

							 // if history is enabled let the detailView "grow" with
							 // the number of messages in the history up until the set maximum
							 if (self.detailViewMode == MTDetailViewModeHistory) {
								 y = -(kMaxHistoryTableRowCount - MIN(self.messageHistory.count, kMaxHistoryTableRowCount)) * kHistoryTableRowHeight;

								 self.historyTableView.frame = CGRectMake(self.historyTableView.frame.origin.x, kStatusBarHeight - y,
																		  self.historyTableView.frame.size.width, self.historyTableView.frame.size.height);
							 }

							 if (self.detailViewMode == MTDetailViewModeDetailText) {
								 self.detailView.frame = CGRectMake(self.detailView.frame.origin.x, y,
																	self.detailView.frame.size.width, self.detailTextView.frame.size.height + kStatusBarHeight);
							 } else {
								 self.detailView.frame = CGRectMake(self.detailView.frame.origin.x, y,
																	self.detailView.frame.size.width, self.detailView.frame.size.height);
							 }
						 }
						 completion:NULL];
	}

}

- (UILabel *)visibleStatusLabel {
	if (self.hiddenStatusLabel == self.statusLabel1) {
		return self.statusLabel2;
	}

	return self.statusLabel1;
}

//===========================================================
#pragma mark -
#pragma mark Table View Data Source
//===========================================================

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.messageHistory.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellID = @"HistoryCellID";
	UITableViewCell *cell = nil;

	// step 1: is there a reusable cell?
	cell = [tableView dequeueReusableCellWithIdentifier:cellID];

	// step 2: no? -> create new cell
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] autorelease];

		cell.textLabel.font = [UIFont boldSystemFontOfSize:10];
		cell.textLabel.textColor = [UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleDefault ? kLightThemeHistoryTextColor : kDarkThemeHistoryTextColor;

		cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
		cell.detailTextLabel.textColor = [UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleDefault ? kLightThemeHistoryTextColor : kDarkThemeHistoryTextColor;
	}

	// step 3: set up cell value
	cell.textLabel.text = [self.messageHistory objectAtIndex:indexPath.row];
	cell.detailTextLabel.text = kFinishedText;

    return cell;
}


//===========================================================
#pragma mark -
#pragma mark Private Methods
//===========================================================

- (IBAction)contentViewClicked:(id)sender {
	switch (self.animation) {
		case MTStatusBarOverlayAnimationShrink:
			[self setShrinked:!self.shrinked animated:YES];
			break;

		case MTStatusBarOverlayAnimationFallDown:
			// detailView currently visible -> hide it
			[self setDetailViewHidden:!self.detailViewHidden animated:YES];
			break;
		case MTStatusBarOverlayAnimationNone:
			// ignore
			break;
	}
}

- (void)setStatusBarBackgroundForStyle:(UIStatusBarStyle)style {
	// gray status bar?
	// on iPad the Default Status Bar Style is black too
	if (style == UIStatusBarStyleDefault && !IsIPad && !IsIPhoneEmulationMode) {
		// choose image depending on size
		if (self.shrinked) {
			self.statusBarBackgroundImageView.image = [self.defaultStatusBarImageShrinked stretchableImageWithLeftCapWidth:2.0f topCapHeight:0.0f];
		} else {
			self.statusBarBackgroundImageView.image = [self.defaultStatusBarImage stretchableImageWithLeftCapWidth:2.0f topCapHeight:0.0f];
		}
	}

	// black status bar? -> no image
	else {
		self.statusBarBackgroundImageView.image = nil;
	}
}

- (void)setColorSchemeForStatusBarStyle:(UIStatusBarStyle)style {
	// gray status bar?
	// on iPad the Default Status Bar Style is black too
	if (style == UIStatusBarStyleDefault && !IsIPad && !IsIPhoneEmulationMode) {
		self.statusLabel1.textColor = kLightThemeTextColor;
		self.statusLabel2.textColor = kLightThemeTextColor;
		self.finishedLabel.textColor = kLightThemeTextColor;
		self.activityIndicator.activityIndicatorViewStyle = kLightThemeActivityIndicatorViewStyle;
		self.detailView.backgroundColor = kLightThemeDetailViewBackgroundColor;
		self.detailView.layer.borderColor = [kLightThemeDetailViewBorderColor CGColor];
		self.historyTableView.separatorColor = kLightThemeDetailViewBorderColor;
		self.detailTextView.textColor = kLightThemeHistoryTextColor;
	} else {
		self.statusLabel1.textColor = kDarkThemeTextColor;
		self.statusLabel2.textColor = kDarkThemeTextColor;
		self.finishedLabel.textColor = kDarkThemeTextColor;
		self.activityIndicator.activityIndicatorViewStyle = kDarkThemeActivityIndicatorViewStyle;
		self.detailView.backgroundColor = kDarkThemeDetailViewBackgroundColor;
		self.detailView.layer.borderColor = [kDarkThemeDetailViewBorderColor CGColor];
		self.historyTableView.separatorColor = kDarkThemeDetailViewBorderColor;
		self.detailTextView.textColor = kDarkThemeHistoryTextColor;
	}
}

- (void)updateUIForMessageType:(MTMessageType)messageType duration:(NSTimeInterval)duration {
	// set properties depending on message-type
	switch (messageType) {
		case MTMessageTypeActivity:
			// will not call hide after delay
			self.hideInProgress = NO;
			// show activity indicator, hide finished-label
			self.finishedLabel.hidden = YES;
			self.activityIndicator.hidden = self.hidesActivity;

			// start activity indicator
			if (!self.hidesActivity) {
				[self.activityIndicator startAnimating];
			}
			break;
		case MTMessageTypeFinish:
			// will call hide after delay
			self.hideInProgress = YES;
			// show finished-label, hide acitvity indicator
			self.finishedLabel.hidden = self.hidesActivity;
			self.activityIndicator.hidden = YES;

			// stop activity indicator
			[self.activityIndicator stopAnimating];

			// update font and text
			self.finishedLabel.font = [UIFont boldSystemFontOfSize:kFinishedFontSize];
			self.finishedLabel.text = kFinishedText;

			// hide after duration
			[self performSelector:@selector(hide) withObject:nil afterDelay:duration];
			// clear history after duration
			[self performSelector:@selector(clearHistory) withObject:nil afterDelay:duration];
			break;
		case MTMessageTypeError:
			// will call hide after delay
			self.hideInProgress = YES;
			// show finished-label, hide activity indicator
			self.finishedLabel.hidden = self.hidesActivity;
			self.activityIndicator.hidden = YES;

			// stop activity indicator
			[self.activityIndicator stopAnimating];

			// update font and text
			self.finishedLabel.font = [UIFont boldSystemFontOfSize:kErrorFontSize];
			self.finishedLabel.text = kErrorText;

			// hide after duration
			[self performSelector:@selector(hide) withObject:nil afterDelay:duration];
			// clear history after duration
			[self performSelector:@selector(clearHistory) withObject:nil afterDelay:duration];
			break;
	}
}

- (void)callDelegateWithNewMessage:(NSString *)newMessage {
	if (self.historyEnabled &&
		self.delegate != nil && [self.delegate respondsToSelector:@selector(statusBarOverlayDidHide)]) {
		NSString *oldMessage = nil;

		if (self.messageHistory.count > 0) {
			oldMessage = [self.messageHistory lastObject];
		}

		[self.delegate statusBarOverlayDidSwitchFromOldMessage:oldMessage
												  toNewMessage:newMessage];
	}
}

- (void)updateDetailTextViewHeight {
	CGRect f = self.detailTextView.frame;
	f.size.height = self.detailTextView.contentSize.height;
	self.detailTextView.frame = f;
}

//===========================================================
#pragma mark -
#pragma mark History Tracking
//===========================================================

- (BOOL)isHistoryEnabled {
	return self.detailViewMode == MTDetailViewModeHistory;
}

- (void)setHistoryEnabled:(BOOL)historyEnabled {
	if (historyEnabled) {
		self.detailViewMode = MTDetailViewModeHistory;
	} else {
		self.detailViewMode = MTDetailViewModeCustom;
	}

	self.historyTableView.hidden = !historyEnabled;
}

- (void)addMessageToHistory:(NSString *)message {
	if (self.historyEnabled	&& message != nil
		&& [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
		NSIndexPath *newHistoryMessageIndexPath = [NSIndexPath indexPathForRow:self.messageHistory.count inSection:0];

		// add message to history-array
		[self.messageHistory addObject:message];

		[self setDetailViewHidden:self.detailViewHidden animated:YES];

		// update history table-view
		[self.historyTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newHistoryMessageIndexPath]
									 withRowAnimation:UITableViewRowAnimationFade];
		[self.historyTableView scrollToRowAtIndexPath:newHistoryMessageIndexPath
									 atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
}

- (void)clearHistory {
	[self.messageHistory removeAllObjects];
	[self.historyTableView reloadData];
}

//===========================================================
#pragma mark -
#pragma mark Custom Hide-Methods using alpha instead of hidden-property (for animation)
//===========================================================

// used for performSelector:withObject
- (void)setHiddenUsingAlpha:(BOOL)hidden {
	[self setHidden:hidden useAlpha:YES];
}

- (void)setHidden:(BOOL)hidden useAlpha:(BOOL)useAlpha {
	if (useAlpha) {
		self.alpha = hidden ? 0.0f : 1.0f;
	} else {
		self.hidden = hidden;
	}
}

- (BOOL)isReallyHidden {
	return self.alpha == 0.0f || self.hidden;
}

//===========================================================
#pragma mark -
#pragma mark Singleton definitons
//===========================================================

static MTStatusBarOverlay *sharedMTStatusBarOverlay = nil;

+ (MTStatusBarOverlay *)sharedInstance {
	@synchronized(self) {
		if (sharedMTStatusBarOverlay == nil) {
			sharedMTStatusBarOverlay = [[self alloc] initWithFrame:CGRectZero];
		}
	}

	return sharedMTStatusBarOverlay;
}

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedMTStatusBarOverlay == nil) {
			sharedMTStatusBarOverlay = [super allocWithZone:zone];

			return sharedMTStatusBarOverlay;
		}
	}

	return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax;
}

- (void)release {
}

- (id)autorelease {
	return self;
}

@end





//===========================================================
#pragma mark -
#pragma mark Encoded Images
//===========================================================

unsigned char Silver_Base_png[] = {
	0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
	0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x14,
	0x08, 0x02, 0x00, 0x00, 0x00, 0xca, 0x87, 0x60, 0x8c, 0x00, 0x00, 0x00,
	0x66, 0x49, 0x44, 0x41, 0x54, 0x18, 0x19, 0x63, 0xc8, 0xca, 0xc9, 0xbd,
	0x7c, 0xe3, 0xf6, 0xfb, 0x6f, 0x3f, 0x81, 0x24, 0x90, 0xcd, 0x78, 0xf5,
	0xe6, 0x5d, 0x09, 0x19, 0x29, 0x06, 0x30, 0x78, 0xf1, 0xe4, 0x19, 0xe3,
	0xeb, 0xcf, 0xdf, 0x20, 0x1c, 0x08, 0xc9, 0xf2, 0xef, 0xef, 0x3f, 0x54,
	0xfe, 0xbf, 0xbf, 0x28, 0xfc, 0xbf, 0x7f, 0x51, 0xf9, 0x7f, 0xd0, 0xf8,
	0xff, 0xd0, 0xf8, 0x7f, 0xff, 0xe0, 0x57, 0xff, 0x07, 0xcd, 0xfc, 0x3f,
	0x68, 0xea, 0xff, 0xa1, 0xf1, 0xff, 0xfe, 0xfd, 0x83, 0xe2, 0x9e, 0x7f,
	0xe8, 0xfa, 0xd1, 0xed, 0xff, 0x87, 0xe6, 0x1f, 0x0c, 0xff, 0xa1, 0xca,
	0xcf, 0x9f, 0x37, 0x1f, 0xd9, 0x7c, 0x00, 0x5e, 0xf4, 0x44, 0x69, 0xf0,
	0x03, 0xee, 0x97, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
	0x42, 0x60, 0x82
};
unsigned int Silver_Base_png_len = 159;

unsigned char Silver_Base_Shrinked_png[] = {
	0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
	0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x14,
	0x08, 0x02, 0x00, 0x00, 0x00, 0xca, 0x87, 0x60, 0x8c, 0x00, 0x00, 0x00,
	0x19, 0x74, 0x45, 0x58, 0x74, 0x53, 0x6f, 0x66, 0x74, 0x77, 0x61, 0x72,
	0x65, 0x00, 0x41, 0x64, 0x6f, 0x62, 0x65, 0x20, 0x49, 0x6d, 0x61, 0x67,
	0x65, 0x52, 0x65, 0x61, 0x64, 0x79, 0x71, 0xc9, 0x65, 0x3c, 0x00, 0x00,
	0x03, 0x22, 0x69, 0x54, 0x58, 0x74, 0x58, 0x4d, 0x4c, 0x3a, 0x63, 0x6f,
	0x6d, 0x2e, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x2e, 0x78, 0x6d, 0x70, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x3c, 0x3f, 0x78, 0x70, 0x61, 0x63, 0x6b, 0x65,
	0x74, 0x20, 0x62, 0x65, 0x67, 0x69, 0x6e, 0x3d, 0x22, 0xef, 0xbb, 0xbf,
	0x22, 0x20, 0x69, 0x64, 0x3d, 0x22, 0x57, 0x35, 0x4d, 0x30, 0x4d, 0x70,
	0x43, 0x65, 0x68, 0x69, 0x48, 0x7a, 0x72, 0x65, 0x53, 0x7a, 0x4e, 0x54,
	0x63, 0x7a, 0x6b, 0x63, 0x39, 0x64, 0x22, 0x3f, 0x3e, 0x20, 0x3c, 0x78,
	0x3a, 0x78, 0x6d, 0x70, 0x6d, 0x65, 0x74, 0x61, 0x20, 0x78, 0x6d, 0x6c,
	0x6e, 0x73, 0x3a, 0x78, 0x3d, 0x22, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x3a,
	0x6e, 0x73, 0x3a, 0x6d, 0x65, 0x74, 0x61, 0x2f, 0x22, 0x20, 0x78, 0x3a,
	0x78, 0x6d, 0x70, 0x74, 0x6b, 0x3d, 0x22, 0x41, 0x64, 0x6f, 0x62, 0x65,
	0x20, 0x58, 0x4d, 0x50, 0x20, 0x43, 0x6f, 0x72, 0x65, 0x20, 0x35, 0x2e,
	0x30, 0x2d, 0x63, 0x30, 0x36, 0x30, 0x20, 0x36, 0x31, 0x2e, 0x31, 0x33,
	0x34, 0x37, 0x37, 0x37, 0x2c, 0x20, 0x32, 0x30, 0x31, 0x30, 0x2f, 0x30,
	0x32, 0x2f, 0x31, 0x32, 0x2d, 0x31, 0x37, 0x3a, 0x33, 0x32, 0x3a, 0x30,
	0x30, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x22, 0x3e, 0x20,
	0x3c, 0x72, 0x64, 0x66, 0x3a, 0x52, 0x44, 0x46, 0x20, 0x78, 0x6d, 0x6c,
	0x6e, 0x73, 0x3a, 0x72, 0x64, 0x66, 0x3d, 0x22, 0x68, 0x74, 0x74, 0x70,
	0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x77, 0x33, 0x2e, 0x6f, 0x72,
	0x67, 0x2f, 0x31, 0x39, 0x39, 0x39, 0x2f, 0x30, 0x32, 0x2f, 0x32, 0x32,
	0x2d, 0x72, 0x64, 0x66, 0x2d, 0x73, 0x79, 0x6e, 0x74, 0x61, 0x78, 0x2d,
	0x6e, 0x73, 0x23, 0x22, 0x3e, 0x20, 0x3c, 0x72, 0x64, 0x66, 0x3a, 0x44,
	0x65, 0x73, 0x63, 0x72, 0x69, 0x70, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x72,
	0x64, 0x66, 0x3a, 0x61, 0x62, 0x6f, 0x75, 0x74, 0x3d, 0x22, 0x22, 0x20,
	0x78, 0x6d, 0x6c, 0x6e, 0x73, 0x3a, 0x78, 0x6d, 0x70, 0x3d, 0x22, 0x68,
	0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x6e, 0x73, 0x2e, 0x61, 0x64, 0x6f,
	0x62, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x78, 0x61, 0x70, 0x2f, 0x31,
	0x2e, 0x30, 0x2f, 0x22, 0x20, 0x78, 0x6d, 0x6c, 0x6e, 0x73, 0x3a, 0x78,
	0x6d, 0x70, 0x4d, 0x4d, 0x3d, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f,
	0x2f, 0x6e, 0x73, 0x2e, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x2e, 0x63, 0x6f,
	0x6d, 0x2f, 0x78, 0x61, 0x70, 0x2f, 0x31, 0x2e, 0x30, 0x2f, 0x6d, 0x6d,
	0x2f, 0x22, 0x20, 0x78, 0x6d, 0x6c, 0x6e, 0x73, 0x3a, 0x73, 0x74, 0x52,
	0x65, 0x66, 0x3d, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x6e,
	0x73, 0x2e, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f,
	0x78, 0x61, 0x70, 0x2f, 0x31, 0x2e, 0x30, 0x2f, 0x73, 0x54, 0x79, 0x70,
	0x65, 0x2f, 0x52, 0x65, 0x73, 0x6f, 0x75, 0x72, 0x63, 0x65, 0x52, 0x65,
	0x66, 0x23, 0x22, 0x20, 0x78, 0x6d, 0x70, 0x3a, 0x43, 0x72, 0x65, 0x61,
	0x74, 0x6f, 0x72, 0x54, 0x6f, 0x6f, 0x6c, 0x3d, 0x22, 0x41, 0x64, 0x6f,
	0x62, 0x65, 0x20, 0x50, 0x68, 0x6f, 0x74, 0x6f, 0x73, 0x68, 0x6f, 0x70,
	0x20, 0x43, 0x53, 0x35, 0x20, 0x4d, 0x61, 0x63, 0x69, 0x6e, 0x74, 0x6f,
	0x73, 0x68, 0x22, 0x20, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a, 0x49, 0x6e,
	0x73, 0x74, 0x61, 0x6e, 0x63, 0x65, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d,
	0x70, 0x2e, 0x69, 0x69, 0x64, 0x3a, 0x31, 0x37, 0x37, 0x36, 0x31, 0x30,
	0x43, 0x42, 0x32, 0x33, 0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45,
	0x42, 0x44, 0x43, 0x42, 0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45,
	0x45, 0x35, 0x22, 0x20, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a, 0x44, 0x6f,
	0x63, 0x75, 0x6d, 0x65, 0x6e, 0x74, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d,
	0x70, 0x2e, 0x64, 0x69, 0x64, 0x3a, 0x31, 0x37, 0x37, 0x36, 0x31, 0x30,
	0x43, 0x43, 0x32, 0x33, 0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45,
	0x42, 0x44, 0x43, 0x42, 0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45,
	0x45, 0x35, 0x22, 0x3e, 0x20, 0x3c, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a,
	0x44, 0x65, 0x72, 0x69, 0x76, 0x65, 0x64, 0x46, 0x72, 0x6f, 0x6d, 0x20,
	0x73, 0x74, 0x52, 0x65, 0x66, 0x3a, 0x69, 0x6e, 0x73, 0x74, 0x61, 0x6e,
	0x63, 0x65, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d, 0x70, 0x2e, 0x69, 0x69,
	0x64, 0x3a, 0x31, 0x37, 0x37, 0x36, 0x31, 0x30, 0x43, 0x39, 0x32, 0x33,
	0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45, 0x42, 0x44, 0x43, 0x42,
	0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45, 0x45, 0x35, 0x22, 0x20,
	0x73, 0x74, 0x52, 0x65, 0x66, 0x3a, 0x64, 0x6f, 0x63, 0x75, 0x6d, 0x65,
	0x6e, 0x74, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d, 0x70, 0x2e, 0x64, 0x69,
	0x64, 0x3a, 0x31, 0x37, 0x37, 0x36, 0x31, 0x30, 0x43, 0x41, 0x32, 0x33,
	0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45, 0x42, 0x44, 0x43, 0x42,
	0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45, 0x45, 0x35, 0x22, 0x2f,
	0x3e, 0x20, 0x3c, 0x2f, 0x72, 0x64, 0x66, 0x3a, 0x44, 0x65, 0x73, 0x63,
	0x72, 0x69, 0x70, 0x74, 0x69, 0x6f, 0x6e, 0x3e, 0x20, 0x3c, 0x2f, 0x72,
	0x64, 0x66, 0x3a, 0x52, 0x44, 0x46, 0x3e, 0x20, 0x3c, 0x2f, 0x78, 0x3a,
	0x78, 0x6d, 0x70, 0x6d, 0x65, 0x74, 0x61, 0x3e, 0x20, 0x3c, 0x3f, 0x78,
	0x70, 0x61, 0x63, 0x6b, 0x65, 0x74, 0x20, 0x65, 0x6e, 0x64, 0x3d, 0x22,
	0x72, 0x22, 0x3f, 0x3e, 0x6a, 0xe1, 0x0d, 0xf2, 0x00, 0x00, 0x00, 0x65,
	0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0x62, 0x7c, 0xff, 0xed, 0x27, 0x03,
	0x18, 0x3c, 0x79, 0xf4, 0x68, 0xfa, 0x94, 0x49, 0x8c, 0x6f, 0xbf, 0x7e,
	0x67, 0x80, 0x81, 0x17, 0x4f, 0x9e, 0xb1, 0xfc, 0xfb, 0xf7, 0x1f, 0xce,
	0x17, 0x93, 0x92, 0x64, 0xf9, 0xf7, 0xf7, 0x1f, 0x03, 0x12, 0x00, 0xca,
	0xff, 0x45, 0xe1, 0xff, 0xfd, 0x8b, 0xca, 0xff, 0x83, 0xc6, 0xff, 0x87,
	0xc6, 0xff, 0xfb, 0x07, 0xbf, 0xfa, 0x3f, 0x68, 0xe6, 0xff, 0x41, 0x53,
	0xff, 0xef, 0x0f, 0xba, 0xfd, 0x7f, 0xf0, 0xba, 0x0f, 0xdd, 0xfc, 0xbf,
	0xff, 0xd0, 0xfc, 0x83, 0xe1, 0x3f, 0x54, 0xfe, 0xfc, 0x79, 0xf3, 0x91,
	0xf9, 0x00, 0x01, 0x06, 0x00, 0xfe, 0x10, 0x41, 0xb0, 0x8a, 0x17, 0x69,
	0xf0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60,
	0x82
};
unsigned int Silver_Base_Shrinked_png_len = 1009;

unsigned char Silver_Base_2x_png[] = {
	0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
	0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00, 0x28,
	0x08, 0x02, 0x00, 0x00, 0x00, 0x48, 0x34, 0xfc, 0xd7, 0x00, 0x00, 0x00,
	0x09, 0x70, 0x48, 0x59, 0x73, 0x00, 0x00, 0x16, 0x25, 0x00, 0x00, 0x16,
	0x25, 0x01, 0x49, 0x52, 0x24, 0xf0, 0x00, 0x00, 0x00, 0xb9, 0x49, 0x44,
	0x41, 0x54, 0x38, 0x11, 0x63, 0xcc, 0xca, 0xc9, 0x15, 0x11, 0x15, 0xf5,
	0xf6, 0xf3, 0x57, 0x54, 0x52, 0x66, 0x65, 0x65, 0x65, 0x60, 0x60, 0xf8,
	0xf5, 0xeb, 0xe7, 0x83, 0xfb, 0xf7, 0xb7, 0x6e, 0xda, 0xf8, 0xe6, 0xf5,
	0x6b, 0x66, 0x4f, 0x6f, 0x9f, 0xdc, 0xc2, 0x62, 0xa0, 0x0a, 0x26, 0x26,
	0x26, 0xa0, 0x1c, 0x10, 0x30, 0x33, 0x33, 0x0b, 0x0b, 0x8b, 0x18, 0x99,
	0x98, 0x5c, 0xb9, 0x74, 0x89, 0xf1, 0xd4, 0x85, 0x4b, 0x2a, 0xaa, 0x6a,
	0x10, 0x09, 0x34, 0xf2, 0xda, 0x95, 0x2b, 0x8c, 0xaf, 0x3e, 0x7e, 0x01,
	0x2a, 0x47, 0x93, 0x80, 0x70, 0x7f, 0xfd, 0xfa, 0xc5, 0x02, 0x34, 0xf3,
	0xff, 0xff, 0xff, 0x58, 0xa5, 0x81, 0x4e, 0x61, 0xc1, 0x25, 0x07, 0xd1,
	0x40, 0xa1, 0xf4, 0x3f, 0x1c, 0x16, 0xc3, 0x0c, 0xff, 0xf7, 0x0f, 0xab,
	0xbb, 0x60, 0xd2, 0xf8, 0x75, 0x13, 0x34, 0x1c, 0xbb, 0xa7, 0xe1, 0x86,
	0xe3, 0xb5, 0x9b, 0xa0, 0xe1, 0x83, 0x57, 0xf7, 0x3f, 0xbc, 0xfe, 0x1e,
	0xc2, 0x1e, 0xc3, 0x9f, 0x1c, 0xfe, 0xff, 0xc7, 0x1b, 0x25, 0xff, 0x29,
	0x0b, 0x16, 0x02, 0x76, 0xe3, 0x4f, 0xc8, 0x84, 0xc2, 0x9c, 0x80, 0xe1,
	0xb4, 0x94, 0x3e, 0x77, 0xf6, 0x1c, 0xbe, 0x2c, 0x78, 0xfe, 0xfc, 0x79,
	0x3c, 0xd2, 0x00, 0x60, 0xe2, 0x89, 0x27, 0x38, 0x98, 0xa8, 0xf6, 0x00,
	0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
};
unsigned int Silver_Base_2x_png_len = 263;

unsigned char Silver_Base_Shrinked_2x_png[] = {
	0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
	0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x0a, 0x00, 0x00, 0x00, 0x28,
	0x08, 0x02, 0x00, 0x00, 0x00, 0x48, 0x34, 0xfc, 0xd7, 0x00, 0x00, 0x00,
	0x19, 0x74, 0x45, 0x58, 0x74, 0x53, 0x6f, 0x66, 0x74, 0x77, 0x61, 0x72,
	0x65, 0x00, 0x41, 0x64, 0x6f, 0x62, 0x65, 0x20, 0x49, 0x6d, 0x61, 0x67,
	0x65, 0x52, 0x65, 0x61, 0x64, 0x79, 0x71, 0xc9, 0x65, 0x3c, 0x00, 0x00,
	0x03, 0x22, 0x69, 0x54, 0x58, 0x74, 0x58, 0x4d, 0x4c, 0x3a, 0x63, 0x6f,
	0x6d, 0x2e, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x2e, 0x78, 0x6d, 0x70, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x3c, 0x3f, 0x78, 0x70, 0x61, 0x63, 0x6b, 0x65,
	0x74, 0x20, 0x62, 0x65, 0x67, 0x69, 0x6e, 0x3d, 0x22, 0xef, 0xbb, 0xbf,
	0x22, 0x20, 0x69, 0x64, 0x3d, 0x22, 0x57, 0x35, 0x4d, 0x30, 0x4d, 0x70,
	0x43, 0x65, 0x68, 0x69, 0x48, 0x7a, 0x72, 0x65, 0x53, 0x7a, 0x4e, 0x54,
	0x63, 0x7a, 0x6b, 0x63, 0x39, 0x64, 0x22, 0x3f, 0x3e, 0x20, 0x3c, 0x78,
	0x3a, 0x78, 0x6d, 0x70, 0x6d, 0x65, 0x74, 0x61, 0x20, 0x78, 0x6d, 0x6c,
	0x6e, 0x73, 0x3a, 0x78, 0x3d, 0x22, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x3a,
	0x6e, 0x73, 0x3a, 0x6d, 0x65, 0x74, 0x61, 0x2f, 0x22, 0x20, 0x78, 0x3a,
	0x78, 0x6d, 0x70, 0x74, 0x6b, 0x3d, 0x22, 0x41, 0x64, 0x6f, 0x62, 0x65,
	0x20, 0x58, 0x4d, 0x50, 0x20, 0x43, 0x6f, 0x72, 0x65, 0x20, 0x35, 0x2e,
	0x30, 0x2d, 0x63, 0x30, 0x36, 0x30, 0x20, 0x36, 0x31, 0x2e, 0x31, 0x33,
	0x34, 0x37, 0x37, 0x37, 0x2c, 0x20, 0x32, 0x30, 0x31, 0x30, 0x2f, 0x30,
	0x32, 0x2f, 0x31, 0x32, 0x2d, 0x31, 0x37, 0x3a, 0x33, 0x32, 0x3a, 0x30,
	0x30, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x22, 0x3e, 0x20,
	0x3c, 0x72, 0x64, 0x66, 0x3a, 0x52, 0x44, 0x46, 0x20, 0x78, 0x6d, 0x6c,
	0x6e, 0x73, 0x3a, 0x72, 0x64, 0x66, 0x3d, 0x22, 0x68, 0x74, 0x74, 0x70,
	0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x77, 0x33, 0x2e, 0x6f, 0x72,
	0x67, 0x2f, 0x31, 0x39, 0x39, 0x39, 0x2f, 0x30, 0x32, 0x2f, 0x32, 0x32,
	0x2d, 0x72, 0x64, 0x66, 0x2d, 0x73, 0x79, 0x6e, 0x74, 0x61, 0x78, 0x2d,
	0x6e, 0x73, 0x23, 0x22, 0x3e, 0x20, 0x3c, 0x72, 0x64, 0x66, 0x3a, 0x44,
	0x65, 0x73, 0x63, 0x72, 0x69, 0x70, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x72,
	0x64, 0x66, 0x3a, 0x61, 0x62, 0x6f, 0x75, 0x74, 0x3d, 0x22, 0x22, 0x20,
	0x78, 0x6d, 0x6c, 0x6e, 0x73, 0x3a, 0x78, 0x6d, 0x70, 0x3d, 0x22, 0x68,
	0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x6e, 0x73, 0x2e, 0x61, 0x64, 0x6f,
	0x62, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x78, 0x61, 0x70, 0x2f, 0x31,
	0x2e, 0x30, 0x2f, 0x22, 0x20, 0x78, 0x6d, 0x6c, 0x6e, 0x73, 0x3a, 0x78,
	0x6d, 0x70, 0x4d, 0x4d, 0x3d, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f,
	0x2f, 0x6e, 0x73, 0x2e, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x2e, 0x63, 0x6f,
	0x6d, 0x2f, 0x78, 0x61, 0x70, 0x2f, 0x31, 0x2e, 0x30, 0x2f, 0x6d, 0x6d,
	0x2f, 0x22, 0x20, 0x78, 0x6d, 0x6c, 0x6e, 0x73, 0x3a, 0x73, 0x74, 0x52,
	0x65, 0x66, 0x3d, 0x22, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x6e,
	0x73, 0x2e, 0x61, 0x64, 0x6f, 0x62, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f,
	0x78, 0x61, 0x70, 0x2f, 0x31, 0x2e, 0x30, 0x2f, 0x73, 0x54, 0x79, 0x70,
	0x65, 0x2f, 0x52, 0x65, 0x73, 0x6f, 0x75, 0x72, 0x63, 0x65, 0x52, 0x65,
	0x66, 0x23, 0x22, 0x20, 0x78, 0x6d, 0x70, 0x3a, 0x43, 0x72, 0x65, 0x61,
	0x74, 0x6f, 0x72, 0x54, 0x6f, 0x6f, 0x6c, 0x3d, 0x22, 0x41, 0x64, 0x6f,
	0x62, 0x65, 0x20, 0x50, 0x68, 0x6f, 0x74, 0x6f, 0x73, 0x68, 0x6f, 0x70,
	0x20, 0x43, 0x53, 0x35, 0x20, 0x4d, 0x61, 0x63, 0x69, 0x6e, 0x74, 0x6f,
	0x73, 0x68, 0x22, 0x20, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a, 0x49, 0x6e,
	0x73, 0x74, 0x61, 0x6e, 0x63, 0x65, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d,
	0x70, 0x2e, 0x69, 0x69, 0x64, 0x3a, 0x42, 0x30, 0x37, 0x30, 0x30, 0x45,
	0x33, 0x38, 0x32, 0x33, 0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45,
	0x42, 0x44, 0x43, 0x42, 0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45,
	0x45, 0x35, 0x22, 0x20, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a, 0x44, 0x6f,
	0x63, 0x75, 0x6d, 0x65, 0x6e, 0x74, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d,
	0x70, 0x2e, 0x64, 0x69, 0x64, 0x3a, 0x42, 0x30, 0x37, 0x30, 0x30, 0x45,
	0x33, 0x39, 0x32, 0x33, 0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45,
	0x42, 0x44, 0x43, 0x42, 0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45,
	0x45, 0x35, 0x22, 0x3e, 0x20, 0x3c, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a,
	0x44, 0x65, 0x72, 0x69, 0x76, 0x65, 0x64, 0x46, 0x72, 0x6f, 0x6d, 0x20,
	0x73, 0x74, 0x52, 0x65, 0x66, 0x3a, 0x69, 0x6e, 0x73, 0x74, 0x61, 0x6e,
	0x63, 0x65, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d, 0x70, 0x2e, 0x69, 0x69,
	0x64, 0x3a, 0x31, 0x37, 0x37, 0x36, 0x31, 0x30, 0x43, 0x44, 0x32, 0x33,
	0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45, 0x42, 0x44, 0x43, 0x42,
	0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45, 0x45, 0x35, 0x22, 0x20,
	0x73, 0x74, 0x52, 0x65, 0x66, 0x3a, 0x64, 0x6f, 0x63, 0x75, 0x6d, 0x65,
	0x6e, 0x74, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d, 0x70, 0x2e, 0x64, 0x69,
	0x64, 0x3a, 0x31, 0x37, 0x37, 0x36, 0x31, 0x30, 0x43, 0x45, 0x32, 0x33,
	0x33, 0x34, 0x31, 0x31, 0x45, 0x30, 0x38, 0x45, 0x42, 0x44, 0x43, 0x42,
	0x33, 0x39, 0x37, 0x38, 0x33, 0x31, 0x39, 0x45, 0x45, 0x35, 0x22, 0x2f,
	0x3e, 0x20, 0x3c, 0x2f, 0x72, 0x64, 0x66, 0x3a, 0x44, 0x65, 0x73, 0x63,
	0x72, 0x69, 0x70, 0x74, 0x69, 0x6f, 0x6e, 0x3e, 0x20, 0x3c, 0x2f, 0x72,
	0x64, 0x66, 0x3a, 0x52, 0x44, 0x46, 0x3e, 0x20, 0x3c, 0x2f, 0x78, 0x3a,
	0x78, 0x6d, 0x70, 0x6d, 0x65, 0x74, 0x61, 0x3e, 0x20, 0x3c, 0x3f, 0x78,
	0x70, 0x61, 0x63, 0x6b, 0x65, 0x74, 0x20, 0x65, 0x6e, 0x64, 0x3d, 0x22,
	0x72, 0x22, 0x3f, 0x3e, 0xff, 0x12, 0x6f, 0xeb, 0x00, 0x00, 0x00, 0x7a,
	0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0x62, 0x7c, 0xff, 0xed, 0x27, 0x03,
	0x2a, 0xf8, 0xf5, 0xeb, 0xe7, 0x83, 0xfb, 0xf7, 0xb7, 0x6e, 0xda, 0xf8,
	0xe6, 0xf5, 0x6b, 0xc6, 0x77, 0x5f, 0x7f, 0x30, 0x60, 0x03, 0x40, 0x45,
	0x53, 0x27, 0x4c, 0xc0, 0x29, 0x0d, 0x04, 0xd7, 0xae, 0x5c, 0x61, 0x7c,
	0xfb, 0xe5, 0x3b, 0x2e, 0xe9, 0x5f, 0xbf, 0x7e, 0xb1, 0xfc, 0xff, 0xff,
	0x1f, 0x97, 0x34, 0x2b, 0x2b, 0x2b, 0x3e, 0x69, 0x20, 0xa0, 0x50, 0xfa,
	0x1f, 0x01, 0xdd, 0xff, 0xfe, 0xd1, 0xd2, 0x70, 0x02, 0x2e, 0xff, 0x47,
	0x3b, 0x97, 0x0f, 0xa8, 0xee, 0x7f, 0xff, 0x87, 0xa9, 0xc7, 0xfe, 0x53,
	0x12, 0xa1, 0xff, 0x29, 0x0b, 0x16, 0xda, 0xba, 0x7c, 0xe0, 0xa4, 0xcf,
	0x9d, 0x3d, 0x87, 0x4f, 0xfa, 0xfc, 0xf9, 0xf3, 0x78, 0xa4, 0x01, 0x02,
	0x0c, 0x00, 0x3d, 0x65, 0x8a, 0xd2, 0x20, 0x85, 0xdc, 0x18, 0x00, 0x00,
	0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
};
unsigned int Silver_Base_Shrinked_2x_png_len = 1030;



NSData* MTStatusBarBackgroundImageData(BOOL shrinked) {
	return [NSData dataWithBytesNoCopy:MTStatusBarBackgroundImageArray(shrinked) length:MTStatusBarBackgroundImageLength(shrinked) freeWhenDone:NO];
}

unsigned char* MTStatusBarBackgroundImageArray(BOOL shrinked) {
	if (shrinked) {
		if ([UIScreen mainScreen].scale == 1.0) {
			return Silver_Base_Shrinked_png;
		} else {
			return Silver_Base_Shrinked_2x_png;
		}
	} else {
		if ([UIScreen mainScreen].scale == 1.0) {
			return Silver_Base_png;
		} else {
			return Silver_Base_2x_png;
		}
	}
}

unsigned int MTStatusBarBackgroundImageLength(BOOL shrinked) {
	if (shrinked) {
		if ([UIScreen mainScreen].scale == 1.0) {
			return Silver_Base_Shrinked_png_len;
		} else {
			return Silver_Base_Shrinked_2x_png_len;
		}
	} else {
		if ([UIScreen mainScreen].scale == 1.0) {
			return Silver_Base_png_len;
		} else {
			return Silver_Base_2x_png_len;
		}
	}
}
