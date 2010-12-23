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

#import "MTStatusBarOverlay.h"
#import <QuartzCore/QuartzCore.h>

//===========================================================
#pragma mark -
#pragma mark Customize Section
//===========================================================

// Text color for UIStatusBarStyleDefault
#define kStatusBarStyleDefaultTextColor [UIColor blackColor]
// Activity Indicator Style for UIStatusBarStyleDefault
#define kStatusBarStyleDefaultActivityIndicatorViewStyle UIActivityIndicatorViewStyleGray
// Text color for UIStatusBarStyleBlackOpaque
#define kStatusBarStyleBlackTextColor [UIColor colorWithRed:0.749 green:0.749 blue:0.749 alpha:1.0]
// Activity Indicator Style for UIStatusBarStyleBlackOpaque
#define kStatusBarStyleBlackActivityIndicatorViewStyle UIActivityIndicatorViewStyleWhite

// duration of the animation to show next status message in seconds
#define kNextStatusAnimationDuration			0.8
// duration the statusBarOverlay takes to appear when it was hidden
#define kAppearAnimationDuration				0.5

// animation duration of animation mode shrink
#define kAnimationDurationShrink				0.3
// animation duration of animation mode fallDown
#define kAnimationDurationFallDown				0.5

// value that is added to [UIApplication sharedApplication].statusBarOrientationAnimationDuration to
// make delay appearance of StatusBarOverlay after rotation
#define kStatusBarOrientationAppearTimeDelta	0.2

// x-offset of the child-views of the background when status bar is in small mode
#define kSmallXOffset					50
// default-width of the small-mode
#define kWidthSmall						80

// default frame of detail view when it is hidden
#define kDefaultDetailViewFrame CGRectMake(20, -150, 280, 150)

//===========================================================
#pragma mark -
#pragma mark Defines
//===========================================================

// macro for checking if we are on the iPad
#define IsIPad UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
// the height of the status bar
#define kStatusBarHeight 20
// width of the screen in portrait-orientation
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
// height of the screen in portrait-orientation
#define kScreenHeight [UIScreen mainScreen].bounds.size.height



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

unsigned char statusBarBackgroundGreySmall_png[] = {
	0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
	0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x14,
	0x08, 0x02, 0x00, 0x00, 0x00, 0xe4, 0xc2, 0x41, 0x1e, 0x00, 0x00, 0x00,
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
	0x70, 0x2e, 0x69, 0x69, 0x64, 0x3a, 0x32, 0x31, 0x44, 0x36, 0x33, 0x46,
	0x43, 0x37, 0x46, 0x43, 0x44, 0x46, 0x31, 0x31, 0x44, 0x46, 0x38, 0x42,
	0x31, 0x34, 0x44, 0x35, 0x30, 0x33, 0x33, 0x33, 0x38, 0x39, 0x45, 0x43,
	0x42, 0x45, 0x22, 0x20, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a, 0x44, 0x6f,
	0x63, 0x75, 0x6d, 0x65, 0x6e, 0x74, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d,
	0x70, 0x2e, 0x64, 0x69, 0x64, 0x3a, 0x32, 0x31, 0x44, 0x36, 0x33, 0x46,
	0x43, 0x38, 0x46, 0x43, 0x44, 0x46, 0x31, 0x31, 0x44, 0x46, 0x38, 0x42,
	0x31, 0x34, 0x44, 0x35, 0x30, 0x33, 0x33, 0x33, 0x38, 0x39, 0x45, 0x43,
	0x42, 0x45, 0x22, 0x3e, 0x20, 0x3c, 0x78, 0x6d, 0x70, 0x4d, 0x4d, 0x3a,
	0x44, 0x65, 0x72, 0x69, 0x76, 0x65, 0x64, 0x46, 0x72, 0x6f, 0x6d, 0x20,
	0x73, 0x74, 0x52, 0x65, 0x66, 0x3a, 0x69, 0x6e, 0x73, 0x74, 0x61, 0x6e,
	0x63, 0x65, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d, 0x70, 0x2e, 0x69, 0x69,
	0x64, 0x3a, 0x32, 0x31, 0x44, 0x36, 0x33, 0x46, 0x43, 0x35, 0x46, 0x43,
	0x44, 0x46, 0x31, 0x31, 0x44, 0x46, 0x38, 0x42, 0x31, 0x34, 0x44, 0x35,
	0x30, 0x33, 0x33, 0x33, 0x38, 0x39, 0x45, 0x43, 0x42, 0x45, 0x22, 0x20,
	0x73, 0x74, 0x52, 0x65, 0x66, 0x3a, 0x64, 0x6f, 0x63, 0x75, 0x6d, 0x65,
	0x6e, 0x74, 0x49, 0x44, 0x3d, 0x22, 0x78, 0x6d, 0x70, 0x2e, 0x64, 0x69,
	0x64, 0x3a, 0x32, 0x31, 0x44, 0x36, 0x33, 0x46, 0x43, 0x36, 0x46, 0x43,
	0x44, 0x46, 0x31, 0x31, 0x44, 0x46, 0x38, 0x42, 0x31, 0x34, 0x44, 0x35,
	0x30, 0x33, 0x33, 0x33, 0x38, 0x39, 0x45, 0x43, 0x42, 0x45, 0x22, 0x2f,
	0x3e, 0x20, 0x3c, 0x2f, 0x72, 0x64, 0x66, 0x3a, 0x44, 0x65, 0x73, 0x63,
	0x72, 0x69, 0x70, 0x74, 0x69, 0x6f, 0x6e, 0x3e, 0x20, 0x3c, 0x2f, 0x72,
	0x64, 0x66, 0x3a, 0x52, 0x44, 0x46, 0x3e, 0x20, 0x3c, 0x2f, 0x78, 0x3a,
	0x78, 0x6d, 0x70, 0x6d, 0x65, 0x74, 0x61, 0x3e, 0x20, 0x3c, 0x3f, 0x78,
	0x70, 0x61, 0x63, 0x6b, 0x65, 0x74, 0x20, 0x65, 0x6e, 0x64, 0x3d, 0x22,
	0x72, 0x22, 0x3f, 0x3e, 0x3a, 0x34, 0xd4, 0x3b, 0x00, 0x00, 0x00, 0x6b,
	0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0xbc, 0xd2, 0x4b, 0x0a, 0x80, 0x30,
	0x0c, 0x04, 0xd0, 0x06, 0xbc, 0xff, 0x42, 0x04, 0x77, 0xf6, 0x6e, 0xa5,
	0xf8, 0xa1, 0x58, 0x15, 0xb5, 0x22, 0x24, 0xc1, 0x2b, 0x38, 0x59, 0x74,
	0xf6, 0x8f, 0x19, 0x42, 0x68, 0x2b, 0xaf, 0xfb, 0x9d, 0x18, 0x42, 0xdf,
	0xb5, 0xb4, 0xde, 0x8f, 0x43, 0x32, 0xc7, 0x91, 0xd2, 0x59, 0x1c, 0x18,
	0x5a, 0xf6, 0x0b, 0x36, 0x53, 0x3e, 0x60, 0x13, 0x53, 0x46, 0x4d, 0xc3,
	0x22, 0xb0, 0x51, 0x83, 0x11, 0x96, 0x2a, 0xdb, 0x58, 0x0d, 0xc6, 0xb0,
	0x4d, 0x0d, 0x46, 0x84, 0xf1, 0x1e, 0xad, 0x73, 0x37, 0x51, 0x35, 0xfc,
	0x81, 0xc1, 0x18, 0x7a, 0xfc, 0xe0, 0x51, 0xf3, 0x09, 0x30, 0x00, 0xeb,
	0x44, 0x40, 0x9b, 0xbe, 0x24, 0xcf, 0x3b, 0x00, 0x00, 0x00, 0x00, 0x49,
	0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
};
unsigned int statusBarBackgroundGreySmall_png_len = 1015;



//===========================================================
#pragma mark -
#pragma mark Private Class Extension
//===========================================================

@interface MTStatusBarOverlay ()

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UIImageView *statusBarBackgroundImageView;
@property (nonatomic, retain) UIImage *grayStatusBarImage;
@property (nonatomic, retain) UIImage *grayStatusBarImageSmall;
@property (nonatomic, retain) UILabel *statusLabel1;
@property (nonatomic, retain) UILabel *statusLabel2;
@property (nonatomic, assign) UILabel *hiddenStatusLabel;
@property (nonatomic, retain) UILabel *finishedLabel;
@property (nonatomic, assign) CGRect oldBackgroundViewFrame;
@property (nonatomic, assign, getter=isHideInProgress) BOOL hideInProgress;
// read out hidden-state using alpha-value and hidden-property
@property (nonatomic, readonly, getter=isReallyHidden) BOOL reallyHidden;


// is called when the user touches the statusbar
- (IBAction)contentViewClicked:(id)sender;
// updates the current status bar background image for the given size and style
- (void)setStatusBarBackgroundForSize:(CGRect)size statusBarStyle:(UIStatusBarStyle)style;
// updates the text-colors of the labels for the given style
- (void)setLabelUIForStatusBarStyle:(UIStatusBarStyle)style;
// tries to retrieve the current visible view controller of the app and returns it, used for rotation
- (UIViewController *)currentVisibleViewController;

// set hidden-state using alpha-value instead of hidden-property
- (void)setHidden:(BOOL)hidden useAlpha:(BOOL)animated;

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
@synthesize grayStatusBarImage = grayStatusBarImage_;
@synthesize grayStatusBarImageSmall = grayStatusBarImageSmall_;
@synthesize smallFrame = smallFrame_;
@synthesize oldBackgroundViewFrame = oldBackgroundViewFrame_;
@synthesize animation = animation_;
@synthesize hideInProgress = hideInProgress_;

//===========================================================
#pragma mark -
#pragma mark Lifecycle
//===========================================================

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Place the window on the correct level and position
        self.windowLevel = UIWindowLevelStatusBar+1.0f;
        self.frame = [UIApplication sharedApplication].statusBarFrame;
		self.alpha = 0.0f;
		self.hidden = NO;

		// Default Small size: just show Activity Indicator
		smallFrame_ = CGRectMake(self.frame.size.width - kWidthSmall, 0.0f, kWidthSmall, self.frame.size.height);

		// Default Animation-Mode
		animation_ = MTStatusBarOverlayAnimationNone;

		// the detail view that is shown when the user touches the status bar in animation mode "FallDown"
		detailView_ = [[UIControl alloc] initWithFrame:kDefaultDetailViewFrame];
		detailView_.backgroundColor = [UIColor blackColor];
		detailView_.alpha = 0.7;
		detailView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

		// add rounded corners to detail-view
		CALayer *l = [detailView_ layer];
		l.masksToBounds = YES;
		l.cornerRadius = 10.0;
		l.borderWidth = 1.0;
		l.borderColor = [[UIColor darkGrayColor] CGColor];

		[self addSubview:detailView_];

        // Create view that stores all the content
        backgroundView_ = [[UIControl alloc] initWithFrame:self.frame];
		[backgroundView_ addTarget:self action:@selector(contentViewClicked:) forControlEvents:UIControlEventTouchUpInside];
		backgroundView_.clipsToBounds = YES;
		backgroundView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		// Image of gray status bar
		NSData *pngData = [NSData dataWithBytesNoCopy:statusBarBackgroundGrey_png length:statusBarBackgroundGrey_png_len freeWhenDone:NO];
		grayStatusBarImage_ = [[UIImage imageWithData:pngData] retain];

		NSData *pngDataSmall = [NSData dataWithBytesNoCopy:statusBarBackgroundGreySmall_png length:statusBarBackgroundGreySmall_png_len freeWhenDone:NO];
		grayStatusBarImageSmall_ = [[UIImage imageWithData:pngDataSmall] retain];

		// Background-Image of the Content View
		statusBarBackgroundImageView_ = [[UIImageView alloc] initWithFrame:self.frame];
		statusBarBackgroundImageView_.backgroundColor = [UIColor blackColor];
		statusBarBackgroundImageView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubviewToBackgroundView:statusBarBackgroundImageView_];

		// Activity Indicator
		activityIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		activityIndicator_.frame = CGRectMake(8.0f, 3.0f, self.frame.size.height - 6, self.frame.size.height - 6);
		activityIndicator_.hidesWhenStopped = YES;
		[self addSubviewToBackgroundView:activityIndicator_];

		// Finished-Label
		finishedLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(8,0,self.frame.size.height, self.frame.size.height)];
		finishedLabel_.backgroundColor = [UIColor clearColor];
		finishedLabel_.hidden = YES;
		finishedLabel_.text = @"✔";
		finishedLabel_.font = [UIFont boldSystemFontOfSize:14.f];
		[self addSubviewToBackgroundView:finishedLabel_];

		// Status Label 1 is first visible
		statusLabel1_ = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, 0.0f, self.frame.size.width - 60.0f, self.frame.size.height-1)];
		statusLabel1_.backgroundColor = [UIColor clearColor];
		statusLabel1_.font = [UIFont boldSystemFontOfSize:12.0f];
		statusLabel1_.textAlignment = UITextAlignmentCenter;
		statusLabel1_.lineBreakMode = UILineBreakModeTailTruncation;
		statusLabel1_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubviewToBackgroundView:statusLabel1_];

		// Status Label 2 is hidden
		statusLabel2_ = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, self.frame.size.height,self.frame.size.width - 60.0f , self.frame.size.height-1)];
		statusLabel2_.backgroundColor = [UIColor clearColor];
		statusLabel2_.font = [UIFont boldSystemFontOfSize:12.0f];
		statusLabel2_.textAlignment = UITextAlignmentCenter;
		statusLabel2_.lineBreakMode = UILineBreakModeTailTruncation;
		statusLabel2_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubviewToBackgroundView:statusLabel2_];

		// the hidden status label at the beggining
		hiddenStatusLabel_ = statusLabel2_;

        [self addSubview:backgroundView_];


		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didRotate:)
													 name:UIDeviceOrientationDidChangeNotification object:nil];
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
	[grayStatusBarImage_ release], grayStatusBarImage_ = nil;
	[grayStatusBarImageSmall_ release], grayStatusBarImageSmall_ = nil;

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

- (void)show {
	// don't show if status bar is hidden
	if ([UIApplication sharedApplication].statusBarHidden) {
		return;
	}

	// start activity indicator
	[self.activityIndicator startAnimating];
	// show status bar overlay with animation
	[UIView animateWithDuration:kAppearAnimationDuration animations:^{
		[self setHidden:NO useAlpha:YES];
	}];
}

- (void)hide {
	[self.activityIndicator stopAnimating];

	// hide status bar overlay with animation
	[UIView animateWithDuration:kAppearAnimationDuration animations:^{
		[self setHidden:YES useAlpha:YES];
	} completion:^(BOOL finished) {
		self.hideInProgress = NO;
	}];
}

- (void)setMessage:(NSString *)message animated:(BOOL)animated {
	// don't show if status bar is hidden
	if ([UIApplication sharedApplication].statusBarHidden) {
		return;
	}

	self.hideInProgress = NO;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
	self.finishedLabel.hidden = YES;
	self.activityIndicator.hidden = NO;

	// status bar not visible in the moment, just show it
	if (self.reallyHidden) {
		[self showWithMessage:message];
		return;
	}

	if (animated) {
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
							options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
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

	// w/o animation
	else {
		if (self.hiddenStatusLabel == self.statusLabel1) {
			self.statusLabel2.text = message;
		} else {
			self.statusLabel1.text = message;
		}
	}
}

- (void)showWithMessage:(NSString *)message {
	// don't duplicate animation if already displaying with text
	if (message == nil || (!self.reallyHidden && [self.statusLabel1.text isEqualToString:message])) {
		return;
	}

	self.finishedLabel.hidden = YES;

	// update status bar background
	UIStatusBarStyle statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
	[self setStatusBarBackgroundForSize:self.backgroundView.frame statusBarStyle:statusBarStyle];
	// update label-UI depending on status bar style
	[self setLabelUIForStatusBarStyle:statusBarStyle];

	// if status bar is currently hidden, show it
	if (self.reallyHidden) {
		// set text of visible status label
		if (self.statusLabel2 == self.hiddenStatusLabel) {
			self.statusLabel1.text = message;
		} else {
			self.statusLabel2.text = message;
		}

		[self show];
	}

	// already visible, animate to new text
	else {
		[self setMessage:message animated:YES];
	}
}

- (void)finishWithMessage:(NSString *)message duration:(NSTimeInterval)duration {
	[self showWithMessage:message];

	self.activityIndicator.hidden = YES;
	self.finishedLabel.hidden = NO;

	self.hideInProgress = YES;
	[self performSelector:@selector(hide) withObject:nil afterDelay:duration];
}

//===========================================================
#pragma mark -
#pragma mark Rotation Notification
//===========================================================

- (void) didRotate:(NSNotification *)notification {
	// current device orientation
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	// current visible view controller
	UIViewController *visibleViewController = [self currentVisibleViewController];

	// check if we should rotate
	if (visibleViewController == nil ||
		![visibleViewController respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)] ||
		![visibleViewController shouldAutorotateToInterfaceOrientation:orientation]) {
		return;
	}

	// hide and then unhide after rotation
	[self setHidden:YES useAlpha:YES];

	// store a flag, if the StatusBar is currently shrinked
	BOOL currentlyShrinked = self.shrinked;

	if (orientation == UIDeviceOrientationPortrait) {
		self.transform = CGAffineTransformIdentity;
		self.frame = CGRectMake(0,0,kScreenWidth,kStatusBarHeight);
		self.smallFrame = CGRectMake(self.frame.size.width - kWidthSmall, 0.0f, kWidthSmall, self.frame.size.height);
	}else if (orientation == UIDeviceOrientationLandscapeLeft) {
		self.transform = CGAffineTransformMakeRotation(M_PI * (90) / 180.0);
		self.frame = CGRectMake(kScreenWidth - kStatusBarHeight,0, kStatusBarHeight, 480);
		self.smallFrame = CGRectMake(kScreenHeight-kWidthSmall,0,kWidthSmall,kStatusBarHeight);
	} else if (orientation == UIDeviceOrientationLandscapeRight) {
		self.transform = CGAffineTransformMakeRotation(M_PI * (-90) / 180.0);
		self.frame = CGRectMake(0,0, kStatusBarHeight, kScreenHeight);
		self.smallFrame = CGRectMake(kScreenHeight-kWidthSmall,0, kWidthSmall, kStatusBarHeight);
	} else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
		self.transform = CGAffineTransformMakeRotation(M_PI);
		self.frame = CGRectMake(0,kScreenHeight - kStatusBarHeight,kScreenWidth,kStatusBarHeight);
		self.smallFrame = CGRectMake(self.frame.size.width - kWidthSmall, 0.0f, kWidthSmall, self.frame.size.height);
	}

	// if the statusBar is currently shrinked, update the frames for the new rotation state
	if (currentlyShrinked) {
		// the oldBackgroundViewFrame is the frame of the whole StatusBar
		self.oldBackgroundViewFrame = CGRectMake(0,0,UIInterfaceOrientationIsPortrait(orientation) ? kScreenWidth : kScreenHeight,kStatusBarHeight);
		// the backgroundView gets the newly computed smallFrame
		self.backgroundView.frame = self.smallFrame;
	}

	// make visible after given time
	[UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration+kStatusBarOrientationAppearTimeDelta
					 animations:^{
		[self setHidden:NO useAlpha:YES];
	}];
}

//===========================================================
#pragma mark -
#pragma mark Getter
//===========================================================

- (BOOL)isShrinked {
	return CGRectEqualToRect(self.backgroundView.frame, self.smallFrame);
}

- (BOOL)isDetailViewVisible {
	return self.detailView.hidden == NO && self.detailView.alpha > 0.0 &&
		   self.detailView.frame.origin.y + self.detailView.frame.size.height >= kStatusBarHeight;
}

//===========================================================
#pragma mark -
#pragma mark Private Methods
//===========================================================

- (IBAction)contentViewClicked:(id)sender {
	switch (self.animation) {
		case MTStatusBarOverlayAnimationShrink:
			[UIView animateWithDuration:kAnimationDurationShrink animations:^{
				// update status bar background
				[self setStatusBarBackgroundForSize:self.backgroundView.frame statusBarStyle:[UIApplication sharedApplication].statusBarStyle];

				// if size is small size, make it bigger
				if (self.shrinked) {
					self.backgroundView.frame = self.oldBackgroundViewFrame;

					// move activity indicator and statusLabel to the left
					self.activityIndicator.frame = CGRectMake(self.activityIndicator.frame.origin.x - kSmallXOffset, self.activityIndicator.frame.origin.y,
															  self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
					self.finishedLabel.frame = CGRectMake(self.finishedLabel.frame.origin.x - kSmallXOffset, self.finishedLabel.frame.origin.y,
														  self.finishedLabel.frame.size.width, self.finishedLabel.frame.size.height);
					self.statusLabel1.frame = CGRectMake(self.statusLabel1.frame.origin.x - kSmallXOffset, self.statusLabel1.frame.origin.y,
														 self.statusLabel1.frame.size.width, self.statusLabel1.frame.size.height);
					self.statusLabel2.frame = CGRectMake(self.statusLabel2.frame.origin.x - kSmallXOffset, self.statusLabel2.frame.origin.y,
														 self.statusLabel2.frame.size.width, self.statusLabel2.frame.size.height);
				}
				// else make it smaller
				else {
					self.oldBackgroundViewFrame = self.backgroundView.frame;
					self.backgroundView.frame = self.smallFrame;

					// move activity indicator and statusLabel to the right
					self.activityIndicator.frame = CGRectMake(self.activityIndicator.frame.origin.x + kSmallXOffset, self.activityIndicator.frame.origin.y,
															  self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
					self.finishedLabel.frame = CGRectMake(self.finishedLabel.frame.origin.x + kSmallXOffset, self.finishedLabel.frame.origin.y,
														  self.finishedLabel.frame.size.width, self.finishedLabel.frame.size.height);
					self.statusLabel1.frame = CGRectMake(self.statusLabel1.frame.origin.x + kSmallXOffset, self.statusLabel1.frame.origin.y,
														 self.statusLabel1.frame.size.width, self.statusLabel1.frame.size.height);
					self.statusLabel2.frame = CGRectMake(self.statusLabel2.frame.origin.x + kSmallXOffset, self.statusLabel2.frame.origin.y,
														 self.statusLabel2.frame.size.width, self.statusLabel2.frame.size.height);
				}
			}];
			break;

		case MTStatusBarOverlayAnimationFallDown:
			if (self.detailViewVisible) {
				[UIView animateWithDuration:kAnimationDurationFallDown animations:^{
					self.detailView.frame = CGRectMake(self.detailView.frame.origin.x, - self.detailView.frame.size.height,
													   self.detailView.frame.size.width, self.detailView.frame.size.height);
				}];
			} else {
				[UIView animateWithDuration:kAnimationDurationFallDown
									  delay:0
									options:UIViewAnimationOptionCurveEaseInOut
								 animations:^{
									 self.detailView.frame = CGRectMake(self.detailView.frame.origin.x, 0,
																		self.detailView.frame.size.width, self.detailView.frame.size.height);								 }
								 completion:NULL];
			}

			break;
		case MTStatusBarOverlayAnimationNone:
			// ignore
			break;
	}
}

- (void)setStatusBarBackgroundForSize:(CGRect)size statusBarStyle:(UIStatusBarStyle)style {
	// gray status bar?
	// on iPad the Default Status Bar Style is black too
	if (style == UIStatusBarStyleDefault && !IsIPad) {
		// choose image depending on size
		if (self.shrinked) {
			self.statusBarBackgroundImageView.image = [self.grayStatusBarImage stretchableImageWithLeftCapWidth:2.0f topCapHeight:0.0f];
		} else {
			self.statusBarBackgroundImageView.image = [self.grayStatusBarImageSmall stretchableImageWithLeftCapWidth:2.0f topCapHeight:0.0f];
		}
	}

	// black status bar? -> no image
	else {
		self.statusBarBackgroundImageView.image = nil;
	}
}

- (void)setLabelUIForStatusBarStyle:(UIStatusBarStyle)style {
	// gray status bar?
	// on iPad the Default Status Bar Style is black too
	if (style == UIStatusBarStyleDefault && !IsIPad) {
		self.statusLabel1.textColor = kStatusBarStyleDefaultTextColor;
		self.statusLabel2.textColor = kStatusBarStyleDefaultTextColor;
		self.finishedLabel.textColor = kStatusBarStyleDefaultTextColor;
		self.activityIndicator.activityIndicatorViewStyle = kStatusBarStyleDefaultActivityIndicatorViewStyle;
	} else {
		self.statusLabel1.textColor = kStatusBarStyleBlackTextColor;
		self.statusLabel2.textColor = kStatusBarStyleBlackTextColor;
		self.finishedLabel.textColor = kStatusBarStyleBlackTextColor;
		self.activityIndicator.activityIndicatorViewStyle = kStatusBarStyleBlackActivityIndicatorViewStyle;
	}
}

- (UIViewController *)currentVisibleViewController {
	// Credits go to ShareKit: https://github.com/ideashower/ShareKit

	// Try to find the root view controller programmically
	// Find the top window (that is not an alert view or other window)
	UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];

	if (topWindow.windowLevel != UIWindowLevelNormal) {
		NSArray *windows = [[UIApplication sharedApplication] windows];

		for(topWindow in windows) {
			if (topWindow.windowLevel == UIWindowLevelNormal)
				break;
		}
	}

	UIView *rootView = [[topWindow subviews] objectAtIndex:0];
	id nextResponder = [rootView nextResponder];

	if ([nextResponder isKindOfClass:[UIViewController class]]) {
		return nextResponder;
	} else {
		NSLog(@"MTStatusBarOverlay: Could not find a root view controller, will not rotate!");
		return nil;
	}
}

//===========================================================
#pragma mark -
#pragma mark Custom Hide-Methods using alpha instead of hidden-property (for animation)
//===========================================================

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
