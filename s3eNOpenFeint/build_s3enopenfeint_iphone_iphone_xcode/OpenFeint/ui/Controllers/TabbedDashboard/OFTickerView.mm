//  Copyright 2009-2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "OFTickerView.h"
#import "OpenFeint+Private.h"
#import "OFImageLoader.h"
#import "UIKit/UIStringDrawing.h"

static const float scrollSpeed = 75.0f; // pixels per second
static const int kTickerLeftCapWidth = 40;
static const int kTickerTopCapHeight = 0;
static const int kTickerLabelOffsetLeft = 25;
static const int kTickerLabelOffsetLeftIPad = 34;
static const int kTickerLabelOffsetRight = 29;

@implementation OFTickerView

@synthesize delegate;
@synthesize scrollInProgress;

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    scrollInProgress = NO;
	[label removeFromSuperview];
	label = nil;
	
	// If the dashboard is dismissed while a ticker message is scrolling, the
	// delegate will be nulled out, so be sure to check first.
	if (delegate && [delegate respondsToSelector:@selector(textFinishedScrolling)])
	{
		[delegate textFinishedScrolling];
	}
}

- (NSString*)text
{
	return label ? label.text : @"";
}

- (void)setText:(NSString *)inText
{
    if(scrollInProgress) return;
    scrollInProgress = YES;
	if (label)
	{
		[label removeFromSuperview];
	}
	
	UIFont* labelFont = [UIFont italicSystemFontOfSize:10.f];
	if (!labelFont)
	{
		labelFont = [UIFont systemFontOfSize:10.0];
	}

	label = [[UILabel alloc] init];
	label.font = labelFont;
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.shadowColor = [UIColor grayColor]; // 50%, no french
	label.shadowOffset = CGSizeMake(0, -1); // top shadow

	CGSize textSize = [inText sizeWithFont:label.font];
	label.frame = CGRectMake(0, 0, textSize.width, self.frame.size.height);

	[cropView addSubview:label];
	[label release];
	
	label.transform = CGAffineTransformTranslate(self.transform, self.frame.size.width, 0);
	
	[UIView beginAnimations:@"scrollText" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:((textSize.width + self.frame.size.width)/scrollSpeed)];
    
	label.transform = CGAffineTransformTranslate(self.transform, -textSize.width, 0);

	[UIView commitAnimations];
	
	label.text = inText;
}

- (void)_commonInit
{
    self.backgroundColor = [UIColor clearColor];
    
    UIImage* barImg = [OFImageLoader loadImage:[NSString stringWithFormat:@"OFTickerBar%@.png", [OpenFeint isLargeScreen] ? @"IPad" : @""]];
	UIImage* closeButtonImg = [OFImageLoader loadImage:[NSString stringWithFormat:@"OFTickerClose%@.png", [OpenFeint isLargeScreen] ? @"IPad" : @""]];
	
	CGRect bgFrame = self.bounds;
	CGRect closeButtonFrame = self.bounds;
	closeButtonFrame.size.width = closeButtonImg.size.width;
	bgFrame.size.width -= closeButtonFrame.size.width;
	closeButtonFrame.origin.x = bgFrame.size.width;
	
	UIImageView* bgView = [[UIImageView alloc] initWithFrame:bgFrame];
	bgView.image = [barImg stretchableImageWithLeftCapWidth:kTickerLeftCapWidth topCapHeight:kTickerTopCapHeight];
	[self addSubview:bgView];
	[bgView release];
    
	cropView = [[UIView alloc] initWithFrame:CGRectMake([OpenFeint isLargeScreen] ? kTickerLabelOffsetLeftIPad : kTickerLabelOffsetLeft,
														0,
														self.frame.size.width - (([OpenFeint isLargeScreen] ? kTickerLabelOffsetLeftIPad : kTickerLabelOffsetLeft) + kTickerLabelOffsetRight),
														self.frame.size.height)];
	cropView.clipsToBounds = YES;
	[self addSubview:cropView];
	[cropView release];
	
	xButton = [UIButton buttonWithType:UIButtonTypeCustom];
	xButton.frame = closeButtonFrame;
    xButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[xButton setImage:closeButtonImg forState:UIControlStateNormal];
	[self addSubview:xButton];    
}

- (id)initWithDelegate:(id<OFTickerViewDelegate>)aDelegate andFrame:(CGRect)frame
{
	[super initWithFrame:frame];
	self.delegate = aDelegate;
    [self _commonInit];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _commonInit];
    return self;
}

- (void)setDelegate:(id<OFTickerViewDelegate>)_delegate {
    delegate = _delegate;
    if ([delegate respondsToSelector:@selector(onXPressed)])
	{
		[xButton addTarget:delegate action:@selector(onXPressed) forControlEvents:UIControlEventTouchUpInside];
	}
}

@end
