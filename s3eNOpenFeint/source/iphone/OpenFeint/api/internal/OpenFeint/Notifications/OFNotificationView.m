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

#import "OFNotificationView.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OpenFeint+Private.h"
#import "OFControllerLoaderObjC.h"
#import "OFImageLoader.h"
#import "OFImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+OpenFeint.h"
#import "OFDependencies.h"

static const float gNotificationWaitSeconds = 2.f; 

@interface OFNotificationView()

- (void)_calcFrameAndTransform;
- (CGPoint)_calcOffScreenPosition:(CGPoint)onScreenPosition;
- (NSString*)_getBackgroundImageName;

@end

@implementation OFNotificationView

@synthesize notice;
@synthesize statusIndicator;
@synthesize backgroundImage;
@synthesize notificationImage;
@synthesize viewToMove;

- (void)animationDidStop:(CABasicAnimation *)theAnimation finished:(BOOL)flag
{
	if (mPresenting)
	{
		mPresenting = NO;
		[self performSelector:@selector(_dismiss) withObject:nil afterDelay:mNotificationDuration];
	}
	else
	{
		[[self layer] removeAnimationForKey:[theAnimation keyPath]];
		[self removeFromSuperview];
	}
}

- (void)_animateKeypath:(NSString*)keyPath 
			  fromValue:(float)startValue 
				toValue:(float)endValue 
			   overTime:(float)duration
	  animationDelegate:(UIView*)animDelegate
	 removeOnCompletion:(BOOL)removeOnCompletion
			   fillMode:(NSString*)fillMode
{
	CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:keyPath];
	animation.fromValue = [NSNumber numberWithFloat:startValue];
	animation.toValue = [NSNumber numberWithFloat:endValue];
	animation.duration = duration;
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	animation.delegate = animDelegate;
	animation.removedOnCompletion = removeOnCompletion;
	animation.fillMode = fillMode;
	[[self layer] addAnimation:animation forKey:keyPath];
}

- (void)_animateFromPosition:(CGPoint)startPos 
				  toPosition:(CGPoint)endPos 
					overTime:(float)duration
		   animationDelegate:(UIView*)animDelegate
		  removeOnCompletion:(BOOL)removeOnCompletion
					fillMode:(NSString*)fillMode

{
	if (startPos.x != endPos.x)
	{
		[self _animateKeypath:@"position.x" 
					fromValue:startPos.x 
					  toValue:endPos.x
					 overTime:duration 
			animationDelegate:animDelegate 
		   removeOnCompletion:removeOnCompletion 
					 fillMode:fillMode];
	}
	if (startPos.y != endPos.y)
	{
		[self _animateKeypath:@"position.y" 
					fromValue:startPos.y
					  toValue:endPos.y 
					 overTime:duration 
			animationDelegate:animDelegate 
		   removeOnCompletion:removeOnCompletion 
					 fillMode:fillMode];
	}
}

- (void)_dismiss
{
	CGPoint onScreenPosition = self.layer.position;
	[self _animateFromPosition:onScreenPosition
					toPosition:[self _calcOffScreenPosition:onScreenPosition]
					  overTime:0.5f
			 animationDelegate:self
			removeOnCompletion:NO
					  fillMode:kCAFillModeForwards];
}

- (void)_presentForDuration:(float)duration
{
	mPresenting = YES;
	mNotificationDuration = duration;
	
	CGPoint onScreenPosition = self.layer.position;
	[self _animateFromPosition:[self _calcOffScreenPosition:onScreenPosition]
					toPosition:onScreenPosition
					  overTime:0.25f
			 animationDelegate:self
			removeOnCompletion:YES
					  fillMode:kCAFillModeRemoved];

	[presentationView addSubview:self];
	
	OFSafeRelease(presentationView);
}

- (void)_makeStatusIconActiveAndDismiss:(OFNotificationStatus*)status
{
	[self _presentForDuration:gNotificationWaitSeconds];

	if (status == nil)
	{
		statusIndicator.hidden = YES;

		if(notificationImage.image == nil)
		{
			//The notification image is also around this same area, don't change the position and size if we have one.
			CGRect noticeFrame = notice.frame;
			noticeFrame.origin.x -= notificationImage.frame.size.width;
			noticeFrame.size.width += notificationImage.frame.size.width;
			notice.frame = noticeFrame;
		}
	}
	else
	{	
		statusIndicator.image = [OFImageLoader loadImage:status];
		statusIndicator.hidden = NO;
	}
}

- (void)_requestSucceeded:(MPOAuthAPIRequestLoader*)request nextCall:(OFInvocation*)nextCall
{
	[self _makeStatusIconActiveAndDismiss:OFNotificationStatusSuccess];					
	[nextCall invokeWith:request];
}

- (void)_requestFailed:(MPOAuthAPIRequestLoader*)request nextCall:(OFInvocation*)nextCall
{
	[self _makeStatusIconActiveAndDismiss:OFNotificationStatusFailure];
	[nextCall invokeWith:request];
}

+ (NSString*)notificationViewName
{
	return @"NotificationView";
}

+ (void)showNotificationWithText:(NSString*)noticeText andImageNamed:(NSString*)imageName andStatus:(OFNotificationStatus*)status inView:(UIView*)containerView
{
	OFNotificationView* view = (OFNotificationView*)[[OFControllerLoaderObjC loader] loadView:self.notificationViewName]; // loadView([self notificationViewName]);

	// ensuring thread-safety by firing the notice on the main thread
	SEL selector = @selector(configureWithText:andImageNamed:andStatus:inView:);
	NSMethodSignature* methodSig = [view methodSignatureForSelector:selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSig];
	[invocation setTarget:view];
	[invocation setSelector:selector];
	[invocation setArgument:&noticeText atIndex:2];
	[invocation setArgument:&imageName atIndex:3];
	[invocation setArgument:&status atIndex:4];
	[invocation setArgument:&containerView atIndex:5];
	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:0.f invocation:invocation repeats:NO] forMode:NSDefaultRunLoopMode];
}

+ (void)showNotificationWithRequest:(MPOAuthAPIRequestLoader*)request andNotice:(NSString*)noticeText inView:(UIView*)containerView
{
	OFNotificationView* view = (OFNotificationView*)[[OFControllerLoaderObjC loader] loadView:self.notificationViewName]; // loadView([self notificationViewName]);

	// ensuring thread-safety by firing the notice on the main thread
	SEL selector = @selector(configureWithRequest:andNotice:inView:);
	NSMethodSignature* methodSig = [view methodSignatureForSelector:selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSig];
	[invocation setTarget:view];
	[invocation setSelector:selector];
	[invocation setArgument:&request atIndex:2];
	[invocation setArgument:&noticeText atIndex:3];
	[invocation setArgument:&containerView atIndex:4];
	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:0.f invocation:invocation repeats:NO] forMode:NSDefaultRunLoopMode];
}

- (void)_calcFrameAndTransform
{
    OFAssert(presentationView != nil, @"You must have called [self _setPresentationView:] before this!");
    OFUIViewLocation location = [presentationView findSubviewLocation:self position:[OpenFeint notificationPosition] deltaRange:2];    
    self.frame = location.frame;
    self.transform = location.transform;
    viewToMove.frame = CGRectMake(viewToMove.frame.origin.x + location.deltaX, viewToMove.frame.origin.y + location.deltaY, viewToMove.frame.size.width, viewToMove.frame.size.height);
}

- (CGPoint)_calcOffScreenPosition:(CGPoint)onScreenPosition
{
	CGSize notificationSize = self.bounds.size;
	if (mParentViewIsRotatedInternally)
	{
		UIInterfaceOrientation dashboardOrientation = [OpenFeint getDashboardOrientation];
		float offScreenOffsetX = 0.f;
		float offScreenOffsetY = 0.f;
		
		switch (dashboardOrientation)
		{
			case UIInterfaceOrientationLandscapeRight:		offScreenOffsetX = -notificationSize.height;	break;
			case UIInterfaceOrientationLandscapeLeft:		offScreenOffsetX = notificationSize.height;		break;
			case UIInterfaceOrientationPortraitUpsideDown:	offScreenOffsetY = -notificationSize.height;	break;
			case UIInterfaceOrientationPortrait:			offScreenOffsetY = notificationSize.height;		break;
		}
		
		if ([OpenFeint invertNotifications])
		{
			// We're off the other side, basically.
			offScreenOffsetX *= -1.0f;
			offScreenOffsetY *= -1.0f;
		}
		
		return CGPointMake(onScreenPosition.x + offScreenOffsetX, onScreenPosition.y + offScreenOffsetY);
	}
	else
	{
		if ([OpenFeint invertNotifications] ^ ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown))
		{
			return CGPointMake(onScreenPosition.x, onScreenPosition.y - notificationSize.height);
		}
		else
		{
			return CGPointMake(onScreenPosition.x, onScreenPosition.y + notificationSize.height);
		}

	}
}

- (NSString*)_getBackgroundImageName
{
	ENotificationPosition notificationPos = [OpenFeint notificationPosition];
	if([OpenFeint isLargeScreen])
	{
		switch (notificationPos)
		{
			case ENotificationPosition_BOTTOM_LEFT:		return @"OFNotificationBackgroundIPadBottomLeft.png";
			case ENotificationPosition_TOP_LEFT:		return @"OFNotificationBackgroundIPadTopLeft.png";
			case ENotificationPosition_BOTTOM_RIGHT:	return @"OFNotificationBackgroundIPadBottomRight.png";
			case ENotificationPosition_TOP_RIGHT:		return @"OFNotificationBackgroundIPadTopRight.png";
			default:									return @"OFNotificationBackgroundIPadBottomLeft.png"; //This should never happen unless the dev put in something invalid.
		}
	}
	else
	{
		switch (notificationPos)
		{
			case ENotificationPosition_BOTTOM_LEFT:
			case ENotificationPosition_BOTTOM_RIGHT:	return @"OFNotificationBackgroundIPhoneBottom.png";
			case ENotificationPosition_TOP_LEFT:
			case ENotificationPosition_TOP_RIGHT:		return @"OFNotificationBackgroundIPhoneTop.png";
			default:									return @"OFNotificationBackgroundIPhoneBottom.png"; //This should never happen unless the dev put in something invalid
		}
	}
}

- (void)_setPresentationView:(UIView*)_presentationView
{
	OFSafeRelease(presentationView);
	presentationView = [_presentationView retain];
    if (_presentationView)
    {
        mParentViewIsRotatedInternally = [presentationView isRotatedInternally];       
    }
	[self _calcFrameAndTransform];
}

- (void)_buildViewWithText:(NSString*)noticeText
{
	statusIndicator.hidden = YES;
	notice.text = noticeText;
	[backgroundImage setContentMode:UIViewContentModeScaleToFill];
    
    CGFloat capFromRight = 50.f;
	[backgroundImage setImage:[backgroundImage.image stretchableImageWithLeftCapWidth:(backgroundImage.image.size.width - capFromRight) topCapHeight:0]];
}

- (void)setupDefaultImages
{
	NSString* backgroundImageName = [self _getBackgroundImageName];
	UIImage* backgroundDefaultImage = [OFImageLoader loadImage:backgroundImageName];
	[backgroundImage setDefaultImage:backgroundDefaultImage];
	
	backgroundImage.unframed = YES;
	backgroundImage.useSharpCorners = YES;
	statusIndicator.unframed = YES;
	
}

- (void)configureWithText:(NSString*)noticeText andImageNamed:(NSString*)imageName andStatus:(OFNotificationStatus*)status inView:(UIView*)containerView
{
	[self setupDefaultImages];
	
	
	if(imageName && ![imageName isEqualToString:@""])
	{
		[notificationImage setDefaultImage:[OFImageLoader loadImage:imageName]];
		notificationImage.unframed = YES;
		notificationImage.useSharpCorners = YES;
		notificationImage.shouldScaleImageToFillRect = NO;
	}
	
	[self _setPresentationView:containerView];
	[self _buildViewWithText:noticeText];
	[self _makeStatusIconActiveAndDismiss:status];
}

- (void)configureWithRequest:(MPOAuthAPIRequestLoader*)request andNotice:(NSString*)noticeText inView:(UIView*)containerView
{
	[self setupDefaultImages];
	
	[self _setPresentationView:containerView];
	[self _buildViewWithText:noticeText];
	
    request.successInvocation = [OFInvocation invocationForTarget:self selector:@selector(_requestSucceeded:nextCall:) chained:request.successInvocation];
    request.failureInvocation = [OFInvocation invocationForTarget:self selector:@selector(_requestFailed:nextCall:) chained:request.failureInvocation];
//	[request setOnSuccess:OFDelegate(self, @selector(_requestSucceeded:nextCall:), [request getOnSuccess].getInvocation())]; 
//	[request setOnFailure:OFDelegate(self, @selector(_requestFailed:nextCall:), [request getOnFailure].getInvocation())]; 		
	[request loadSynchronously:NO];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView* hitView = [super hitTest:point withEvent:event];
	return hitView;
}

- (void)dealloc 
{
	self.statusIndicator = nil;
	self.backgroundImage = nil;
	self.notice = nil;
	OFSafeRelease(presentationView);
    [super dealloc];
}

@end
