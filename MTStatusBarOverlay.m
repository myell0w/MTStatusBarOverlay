//
//  MTStatusBar.m
//  MTHelper
//
//  Created by Matthias Tretter on 27.09.10.
//  Copyright 2010 YellowSoft. All rights reserved.
//

#import "MTStatusBarOverlay.h"

// duration of the animation to show next status message in seconds
#define kNextStatusAnimationDuration	0.8
// x-offset of the child-views of the background when status bar is in small mode
#define kSmallXOffset					50
// default-width of the small-mode
#define kWidthSmall						80


//=========================================================== 
#pragma mark -
#pragma mark Helper Functions
//=========================================================== 

BOOL IsIPad() {
    static BOOL hasCheckediPadStatus = NO;
	static BOOL isRunningOniPad = NO;
	
	if (!hasCheckediPadStatus) {
		if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)]) {
			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
				isRunningOniPad = YES;
			}
		}
        
		hasCheckediPadStatus = YES;
	}
	
	return isRunningOniPad;
}



//=========================================================== 
#pragma mark -
#pragma mark Encoded Images
//=========================================================== 

unsigned char statusBarBackgroundGrey_png[] = {
	0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
	0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x14,
	0x08, 0x02, 0x00, 0x00, 0x00, 0xe4, 0xc2, 0x41, 0x1e, 0x00, 0x00, 0x00,
	0x19, 0x74, 0x45, 0x58, 0x74, 0x53, 0x6f, 0x66, 0x74, 0x77, 0x61, 0x72,
	0x65, 0x00, 0x41, 0x64, 0x6f, 0x62, 0x65, 0x20, 0x49, 0x6d, 0x61, 0x67,
	0x65, 0x52, 0x65, 0x61, 0x64, 0x79, 0x71, 0xc9, 0x65, 0x3c, 0x00, 0x00,
	0x00, 0x7e, 0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0xbc, 0xd2, 0xcd, 0x0a,
	0x40, 0x40, 0x14, 0x05, 0xe0, 0x99, 0xf2, 0x10, 0x92, 0xbc, 0x1f, 0xe1,
	0x61, 0xa4, 0xec, 0xcc, 0x53, 0x59, 0x58, 0x28, 0x69, 0xf2, 0xd3, 0x94,
	0x88, 0xac, 0xe6, 0xde, 0xbc, 0x82, 0x73, 0x17, 0xce, 0xfe, 0xeb, 0x9c,
	0x6e, 0x57, 0x67, 0x79, 0x91, 0xe6, 0x65, 0x9c, 0x24, 0xea, 0x43, 0xec,
	0x34, 0x35, 0x75, 0xa5, 0xbb, 0x7e, 0x08, 0xe3, 0x48, 0x7d, 0xce, 0x6a,
	0x67, 0xed, 0xae, 0x47, 0x81, 0xd1, 0xdb, 0x71, 0xc3, 0x66, 0xd9, 0x4f,
	0xd8, 0x58, 0xb7, 0xc3, 0x66, 0x5c, 0x1d, 0x6a, 0x02, 0x26, 0x82, 0x0d,
	0x79, 0xdc, 0x78, 0x41, 0x8f, 0x67, 0x81, 0x11, 0x6c, 0x63, 0x81, 0x21,
	0xf2, 0x78, 0x0f, 0xff, 0x73, 0x37, 0x62, 0x16, 0xfc, 0x81, 0xc0, 0x08,
	0x7a, 0x4c, 0x6b, 0x50, 0xf3, 0x0a, 0x30, 0x00, 0x1d, 0xed, 0x40, 0x55,
	0xe5, 0xd4, 0x12, 0xf2, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44,
	0xae, 0x42, 0x60, 0x82
};
unsigned int statusBarBackgroundGrey_png_len = 220;



//=========================================================== 
#pragma mark -
#pragma mark Private Class Extension
//=========================================================== 

@interface MTStatusBarOverlay ()

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UIImageView *statusBarBackgroundImageView;
@property (nonatomic, retain) UIImage *grayStatusBarImage;
@property (nonatomic, retain) UILabel *statusLabel1;
@property (nonatomic, retain) UILabel *statusLabel2;
@property (nonatomic, assign) UILabel *hiddenStatusLabel;

- (IBAction)contentViewClicked:(id)sender;

@end



@implementation MTStatusBarOverlay

//=========================================================== 
#pragma mark -
#pragma mark Properties
//=========================================================== 
@synthesize backgroundView = backgroundView_;
@synthesize statusBarBackgroundImageView = statusBarBackgroundImageView_;
@synthesize statusLabel1 = statusLabel1_;
@synthesize statusLabel2 = statusLabel2_;
@synthesize hiddenStatusLabel = hiddenStatusLabel_;
@synthesize activityIndicator = activityIndicator_;
@synthesize smallRect = smallRect_;
@synthesize grayStatusBarImage = grayStatusBarImage_;


//=========================================================== 
#pragma mark -
#pragma mark Lifecycle
//===========================================================

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Place the window on the correct level and position
        self.windowLevel = UIWindowLevelStatusBar+1.0f;
        self.frame = [UIApplication sharedApplication].statusBarFrame;
		
		smallRect_ = CGRectMake(self.frame.size.width - kWidthSmall, 0.0f, kWidthSmall, self.frame.size.height);
		
        // Create view that stores all the content
        backgroundView_ = [[UIControl alloc] initWithFrame:self.frame];
		[backgroundView_ addTarget:self action:@selector(contentViewClicked:) forControlEvents:UIControlEventTouchUpInside];
		backgroundView_.clipsToBounds = YES;
		
		// Image of gray status bar
		NSData *pngData = [NSData dataWithBytesNoCopy:statusBarBackgroundGrey_png length:statusBarBackgroundGrey_png_len freeWhenDone:NO];
		grayStatusBarImage_ = [[UIImage imageWithData:pngData] retain];
		
		// Background-Image of the Content View
		statusBarBackgroundImageView_ = [[UIImageView alloc] initWithFrame:self.frame];
		statusBarBackgroundImageView_.backgroundColor = [UIColor blackColor];
		[self addSubviewToBackgroundView:statusBarBackgroundImageView_];
		
		// Activity Indicator
		activityIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityIndicator_.frame = CGRectMake(8.0f, 3.0f, self.frame.size.height - 6, self.frame.size.height - 6);
		activityIndicator_.hidesWhenStopped = YES;
		[self addSubviewToBackgroundView:activityIndicator_];
		
		// Status Label 1 is first visible
		statusLabel1_ = [[UILabel alloc] initWithFrame:CGRectMake(35.0f, 0.0f, 200.0f, self.frame.size.height-1)];
		statusLabel1_.backgroundColor = [UIColor clearColor];
		statusLabel1_.font = [UIFont boldSystemFontOfSize:12.0f];
		[self addSubviewToBackgroundView:statusLabel1_];
		
		// Status Label 2 is hidden
		statusLabel2_ = [[UILabel alloc] initWithFrame:CGRectMake(35.0f, self.frame.size.height, 200.0f, self.frame.size.height-1)];
		statusLabel2_.backgroundColor = [UIColor clearColor];
		statusLabel2_.font = [UIFont boldSystemFontOfSize:12.0f];
		statusLabel2_.text = @"hidden";
		[self addSubviewToBackgroundView:statusLabel2_];
		
		// the hidden status label at the beggining
		hiddenStatusLabel_ = statusLabel2_;
		
        [self addSubview:backgroundView_];
    }
	
	return self;
}


- (void)dealloc {
	[backgroundView_ release], backgroundView_ = nil;
	[statusBarBackgroundImageView_ release], statusBarBackgroundImageView_ = nil;
	[statusLabel1_ release], statusLabel1_ = nil;
	[statusLabel2_ release], statusLabel2_ = nil;
	[activityIndicator_ release], activityIndicator_ = nil;
	[grayStatusBarImage_ release], grayStatusBarImage_ = nil;
	
	[super dealloc];
}

//=========================================================== 
#pragma mark -
#pragma mark Change Status Bar Appearance and 
//===========================================================

- (void)addSubviewToBackgroundView:(UIView *)view {
	view.userInteractionEnabled = NO;
	[self.backgroundView addSubview:view];
}

- (void)showWithMessage:(NSString *)message {
	if (message == nil) {
		return;
	}
	
	// if status bar is currently hidden, show it
	if (self.hidden) {
		// set background image, if we have a gray status bar
		if ([UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleDefault && !IsIPad()) {
			self.statusBarBackgroundImageView.image = [self.grayStatusBarImage stretchableImageWithLeftCapWidth:2.0f topCapHeight:0.0f];
			self.statusLabel1.textColor = [UIColor blackColor];
			self.statusLabel2.textColor = [UIColor blackColor];
			self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		} else {
			self.statusBarBackgroundImageView.image = nil;
			self.statusLabel1.textColor = [UIColor colorWithRed:0.749 green:0.749 blue:0.749 alpha:1.0];
			self.statusLabel2.textColor = [UIColor colorWithRed:0.749 green:0.749 blue:0.749 alpha:1.0];
			self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
		}
		
		// set text of visible status label
		self.statusLabel1.text = message;
		// start activity indicator
		[self.activityIndicator startAnimating];
		// show status bar overlay
		self.hidden = NO;
	}
	
	// already visible, animate to new text
	else {
		// set text of currently not visible label to new text
		if (self.hiddenStatusLabel == self.statusLabel1) {
			self.statusLabel1.text = message;
			
			// position under visible status label
			self.statusLabel1.frame = CGRectMake(self.statusLabel1.frame.origin.x, 
												 self.frame.size.height,
												 self.statusLabel1.frame.size.width, 
												 self.statusLabel1.frame.size.height);
		} else {
			self.statusLabel2.text = message;
			
			// position under visible status label
			self.statusLabel2.frame = CGRectMake(self.statusLabel2.frame.origin.x, 
												 self.frame.size.height,
												 self.statusLabel2.frame.size.width, 
												 self.statusLabel2.frame.size.height);
		}
		
		// animate not visible label into user view
		[UIView animateWithDuration:kNextStatusAnimationDuration 
							  delay:0 
							options:UIViewAnimationOptionCurveEaseInOut 
						 animations:^{
							 // move both status labels up
							 self.statusLabel1.frame = CGRectMake(self.statusLabel1.frame.origin.x, 
																  self.statusLabel1.frame.origin.y - self.frame.size.height,
																  self.statusLabel1.frame.size.width, 
																  self.statusLabel1.frame.size.height);
							 self.statusLabel2.frame = CGRectMake(self.statusLabel2.frame.origin.x, 
																  self.statusLabel2.frame.origin.y - self.frame.size.height,
																  self.statusLabel2.frame.size.width, 
																  self.statusLabel2.frame.size.height);
						 } 
						 completion:^(BOOL finished) {
							 // after animation, set new hidden status label indicator
							 if (self.hiddenStatusLabel == self.statusLabel1) {
								 self.hiddenStatusLabel = self.statusLabel2;
							 } else {
								 self.hiddenStatusLabel = self.statusLabel1;
							 }
						 }];
	}
}

- (void)hide {
	[self.activityIndicator stopAnimating];
	self.hidden = YES;
}


//=========================================================== 
#pragma mark -
#pragma mark Action Methods
//===========================================================

- (IBAction)contentViewClicked:(id)sender {	
	[UIView animateWithDuration:0.3 animations:^{
		// if size is small size, make it bigger
		if (CGRectEqualToRect(self.backgroundView.frame, self.smallRect)) {
			self.backgroundView.frame = self.frame;
			
			// move activity indicator and statusLabel to the left
			self.activityIndicator.frame = CGRectMake(self.activityIndicator.frame.origin.x - kSmallXOffset, self.activityIndicator.frame.origin.y,
													  self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
			self.statusLabel1.frame = CGRectMake(self.statusLabel1.frame.origin.x - kSmallXOffset, self.statusLabel1.frame.origin.y,
												 self.statusLabel1.frame.size.width, self.statusLabel1.frame.size.height);
			self.statusLabel2.frame = CGRectMake(self.statusLabel2.frame.origin.x - kSmallXOffset, self.statusLabel2.frame.origin.y,
												 self.statusLabel2.frame.size.width, self.statusLabel2.frame.size.height);
		} 
		// else make it smaller
		else {
			self.backgroundView.frame = self.smallRect;
			
			// move activity indicator and statusLabel to the right
			self.activityIndicator.frame = CGRectMake(self.activityIndicator.frame.origin.x + kSmallXOffset, self.activityIndicator.frame.origin.y,
													  self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
			self.statusLabel1.frame = CGRectMake(self.statusLabel1.frame.origin.x + kSmallXOffset, self.statusLabel1.frame.origin.y,
												 self.statusLabel1.frame.size.width, self.statusLabel1.frame.size.height);
			self.statusLabel2.frame = CGRectMake(self.statusLabel2.frame.origin.x + kSmallXOffset, self.statusLabel2.frame.origin.y,
												 self.statusLabel2.frame.size.width, self.statusLabel2.frame.size.height);
		}
	}];
}

@end
