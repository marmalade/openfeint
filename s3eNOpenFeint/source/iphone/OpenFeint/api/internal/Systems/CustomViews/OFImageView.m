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

#import "OFImageView.h"

#import "OFProvider.h"
#import "OFImageCache.h"
#import "OFImageLoader.h"
#import "OFUser.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

static float const kFadeTickInterval = 1.f / 30.f;

@interface OFImageView ()
- (void)_imageDownloaded:(UIImage*)image;
- (void)_imageDownloadFailed;
- (void)_addImageFrame;
- (void)_removeImageFrame;
- (void)_updateImageFrame;
- (void)_drawImage:(UIImage*)imageToDraw withAlpha:(float)alphaValue withRect:(CGRect)rect;
- (void)_fadeToNewImage:(UIImage*)image;
@property (nonatomic, retain) OFRequestHandle* inProgressRequest;
@end

@implementation OFImageView

@synthesize shouldScaleImageToFillRect = mShouldScaleImageToFillRect;
@synthesize imageUrl = mImageUrl;
@synthesize image = mImage;
@synthesize useFacebookOverlay = mUseFacebookOverlay;
@synthesize useSharpCorners = mUseSharpCorners;
@synthesize unframed = mUnframed;
@synthesize crossFadeDuration = mCrossFadeDuration;
@synthesize shouldShowLoadingIndicator = mShouldShowLoadingIndicator;
@synthesize imageDownloadInvocation = mImageDownloadInvocation;
@synthesize inProgressRequest = mInProgressRequest;
@synthesize cornerRadius = mCornerRadius;

- (void)_addImageFrame
{
	[self _removeImageFrame];

	if (mImage && !mUseSharpCorners && !mUnframed)
	{
		mImageFrame = [[UIImageView alloc] initWithFrame:CGRectMake(-7.f, -5.f, self.frame.size.width + 12.f, self.frame.size.height + 14.f)];
		mImageFrame.contentMode = UIViewContentModeScaleToFill;
		if(mImageFrameFileName == nil)
		{
			mImageFrameFileName = @"OFProfilePhotoFrame.png";
		}
		mImageFrame.image = [OFImageLoader loadImage:mImageFrameFileName];
		[self addSubview:mImageFrame];
		[self bringSubviewToFront:mImageFrame];
	}
}

- (void)_removeImageFrame
{
	[mImageFrame removeFromSuperview];
	OFSafeRelease(mImageFrame);
}

- (void)_updateImageFrame
{
	if (mImageFrame)
	{
		mImageFrame.frame = CGRectMake(-7.f, -5.f, self.frame.size.width + 12.f, self.frame.size.height + 14.f);
	}
}

- (void)removeFacebookOverlay
{
	if (mFacebookOverlay)
	{
		[mFacebookOverlay removeFromSuperview];
		OFSafeRelease(mFacebookOverlay);
	}
}

- (void)addFacebookOverlay
{
	[self removeFacebookOverlay];
	
	static float const kMinimumSizeForOverlay = 36.f;
	CGRect myFrame = self.frame;
	if (myFrame.size.width < kMinimumSizeForOverlay || myFrame.size.height < kMinimumSizeForOverlay)
		return;
	
	static float const kInset = 1.f;
	UIImage* fbIconImage = [OFImageLoader loadImage:@"OFProfilePictureFacebookIcon.png"];
	CGRect facebookRect = CGRectMake(myFrame.size.width - fbIconImage.size.width - kInset,
                                     myFrame.size.height - fbIconImage.size.height - kInset,
                                     fbIconImage.size.width,
                                     fbIconImage.size.height);
    
	facebookRect.origin.x = myFrame.size.width - facebookRect.size.width - kInset;
	facebookRect.origin.y = myFrame.size.height - facebookRect.size.height - kInset;
	mFacebookOverlay = [[UIImageView alloc] initWithFrame:facebookRect];
	mFacebookOverlay.image = fbIconImage;
	[self addSubview:mFacebookOverlay];
}

- (void)setUseFacebookOverlay:(BOOL)useOverlay
{
	[self removeFacebookOverlay];
	mUseFacebookOverlay = useOverlay;
	if (mUseFacebookOverlay && mImage && (mImage != mDefaultImage || mImageFadingIn))
	{
		[self addFacebookOverlay];
	}
}

- (id)awakeAfterUsingCoder:(NSCoder*)aDecoder
{
	mShouldShowLoadingIndicator = YES;
	mCrossFadeDuration = 0.25f;
	mShouldScaleImageToFillRect = YES;
	return self;
}

- (void)_resetView:(UIImage*)image
{
	[self removeFacebookOverlay];
	[self _removeImageFrame];
	
	[mLoadingView stopAnimating];
	[mLoadingView removeFromSuperview];
	OFSafeRelease(mLoadingView);

	OFSafeRelease(mImage);
	mImage = [image retain];
	
	if (mUseFacebookOverlay && mImage && mImage != mDefaultImage)
	{
		[self addFacebookOverlay];
	}

	[self _addImageFrame];

	OFSafeRelease(mImageFadingIn);
	mFadingImageAlpha = 0.f;
	[mFadingTimer invalidate];
	mFadingTimer = nil;
}

- (void)setImageUrl:(NSString*)imageUrl
{
	[self setImageUrl:imageUrl crossFading:NO];
}

- (void)setImageUrl:(NSString*)imageUrl crossFading:(BOOL)shouldCrossFade
{
	OFSafeRelease(mImageUrl);
	mImageUrl = [imageUrl retain];
    [self.inProgressRequest cancel];

	UIImage* image = [[OFImageCache sharedInstance] fetch:mImageUrl];
	if(shouldCrossFade)
	{
		[self _fadeToNewImage:image];
	}
	else
	{
		[self _resetView:image];
	}
	[self setNeedsDisplay];

	if (mImageUrl != nil && ![mImageUrl isEqualToString:@""])
	{
		if (image == nil)
		{
			if (mDefaultImage != nil)
			{
				if(shouldCrossFade)
				{
					[self _fadeToNewImage:mDefaultImage];
				}
				else
				{
					[self _resetView:mDefaultImage];
				}
			}
			else
			{
				[self showLoadingIndicator];
			}

            self.inProgressRequest = [OpenFeint getImageFromUrl:imageUrl 
                                                      forModule:[OFImageView class]
                                                      onSuccess:[OFInvocation invocationForTarget:self selector:@selector(_imageDownloaded:)]  
                                                      onFailure:[OFInvocation invocationForTarget:self selector:@selector(_imageDownloadFailed)]];
		}
		else
		{
            [mImageDownloadInvocation invoke];
		}
	}
	else if (mDefaultImage)
	{
		if(shouldCrossFade)
		{
			[self _fadeToNewImage:mDefaultImage];
		}
		else
		{
			[self _resetView:mDefaultImage];
		}
	}
}

- (void)setImage:(UIImage*)image
{
	OFSafeRelease(mImageUrl);
	
	if (mDefaultImage != nil && image == nil)
		image = mDefaultImage;
	
	[self _resetView:image];
	[self setNeedsDisplay];
}

- (void)dealloc
{
    self.inProgressRequest = nil;
	CGPathRelease(mBorderPath);
	OFSafeRelease(mImageUrl);
	[self _resetView:nil];
	OFSafeRelease(mImageFrameFileName);
	OFSafeRelease(mImage);
	OFSafeRelease(mDefaultImage);
    self.imageDownloadInvocation = nil;
	[super dealloc];
}

- (void)_recreateBorderPath
{
	if (mUsingCustomBorderPath)
	{
		return;
	}
	
	if (mBorderPath)
	{
		CGPathRelease(mBorderPath);
		mBorderPath = nil;
	}

	if (mUseSharpCorners)
	{
		return;
	}

	CGRect rect = self.frame;
	
	float const radius = (mCornerRadius == 0.0f) ? 5.0f : mCornerRadius;

	float maxx = CGRectGetWidth(rect);
	float midx = maxx * 0.5f;
	float maxy = CGRectGetHeight(rect);
	float midy = maxy * 0.5f;

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0.0f, midy);
	CGPathAddArcToPoint(path, NULL, 0.0f, 0.0f, midx, 0.0f, radius);
	CGPathAddArcToPoint(path, NULL, maxx, 0.0f, maxx, midy, radius);
	CGPathAddArcToPoint(path, NULL, maxx, maxy, midx, maxy, radius);
	CGPathAddArcToPoint(path, NULL, 0.0f, maxy, 0.0f, midy, radius);
	CGPathCloseSubpath(path);

	mBorderPath = path;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[self _recreateBorderPath];
	[self _updateImageFrame];
	[self setUseFacebookOverlay:mUseFacebookOverlay];
}

- (void)_tickFading:(NSTimer*)_timer
{
	BOOL invalidateTimer = NO;
	
	if (_timer == mFadingTimer)
	{
		mFadingImageAlpha += kFadeTickInterval / mCrossFadeDuration;
		if (mFadingImageAlpha >= 1.f)
		{
			mFadingImageAlpha = 0.f;
			mFadingTimer = nil;
			
			[self _resetView:mImageFadingIn];
			OFSafeRelease(mImageFadingIn);
			
			invalidateTimer = YES;
		}

		[self setNeedsDisplay];
	}
	else
	{
		invalidateTimer = YES;
	}

	if (invalidateTimer)
	{
		[_timer invalidate];
	}
}

- (void)_fadeToNewImage:(UIImage*)image
{
	OFSafeRelease(mImageFadingIn);
	mImageFadingIn = [image retain];
	mFadingImageAlpha = 0.f;
	mFadingTimer = [NSTimer scheduledTimerWithTimeInterval:kFadeTickInterval target:self selector:@selector(_tickFading:) userInfo:nil repeats:YES];
    
    if (mUseFacebookOverlay) {
        [self addFacebookOverlay];
    }
}

- (void)_imageDownloaded:(UIImage*)image
{
    if (!image)
    {
        [self _imageDownloadFailed];
        return;
    }

    self.inProgressRequest = nil;
    [self _fadeToNewImage:image];
    [self setNeedsDisplay];
    [mImageDownloadInvocation invoke];
}

- (void)_imageDownloadFailed
{
    self.inProgressRequest = nil;
	UIImage* imageToUse = mDefaultImage;
	if (imageToUse == nil)
    {
        OFLog(@"OFImageView download failed but doesn't have a default image!");
    }

	[self _fadeToNewImage:imageToUse];
	[self setNeedsDisplay];

    [mImageDownloadInvocation invoke];
}

- (void)_drawImage:(UIImage*)imageToDraw withAlpha:(float)alphaValue withRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (mBorderPath)
	{
		CGContextBeginPath(ctx);
		CGContextAddPath(ctx, mBorderPath);
		CGContextClosePath(ctx);
		CGContextClip(ctx);
	}

	if(mShouldScaleImageToFillRect)
	{
		[imageToDraw drawInRect:rect blendMode:kCGBlendModeNormal alpha:alphaValue];
	}
	else
	{
		CGPoint topLeftToCenterImage = CGPointMake(
			-((imageToDraw.size.width - rect.size.width) * 0.5f),
			-((imageToDraw.size.height - rect.size.height) * 0.5f)
		);
			
		[imageToDraw drawAtPoint:topLeftToCenterImage blendMode:kCGBlendModeNormal alpha:alphaValue];
	}
}

- (void)drawRect:(CGRect)rect
{
	if (mImage != nil)
	{
		[self _drawImage:mImage withAlpha:1.f withRect:rect];			
	}
	else
	{	
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		CGContextClearRect(ctx, rect);
	}
	
	if (mImageFadingIn != nil)
	{
		[self _drawImage:mImageFadingIn withAlpha:mFadingImageAlpha withRect:rect];		
	}
}

- (void)showLoadingIndicator
{
	if(!mShouldShowLoadingIndicator)
	{
		return;
	}
	
	mLoadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	mLoadingView.hidesWhenStopped = YES;

	CGRect loadingFrame = mLoadingView.frame;
	loadingFrame.origin.x = (self.frame.size.width - mLoadingView.frame.size.width) * 0.5f;
	loadingFrame.origin.y = (self.frame.size.height - mLoadingView.frame.size.height) * 0.5f;
	[mLoadingView setFrame:loadingFrame];

	[mLoadingView startAnimating];
	[self addSubview:mLoadingView];	
}

- (void)setDefaultImage:(UIImage*)defaultImage
{
	OFSafeRelease(mDefaultImage);
	mDefaultImage = [defaultImage retain];
	[self _resetView:mDefaultImage];
	[self setNeedsDisplay];
}


- (void)setCustomClippingPath:(CGPathRef)path
{
	CGPathRelease(mBorderPath);
	mBorderPath = path;
	CGPathRetain(mBorderPath);
	mUsingCustomBorderPath = (mBorderPath != nil);
	
	if (!mUsingCustomBorderPath)
	{
		[self _recreateBorderPath];
	}
}

- (void)useLocalPlayerProfilePictureDefault
{
	[self setDefaultImage:[OFImageLoader loadImage:@"OFProfileIconDefaultSelf.png"]];
}

- (void)useOtherPlayerProfilePictureDefault
{
	[self setDefaultImage:[OFImageLoader loadImage:@"OFProfileIconDefault.png"]];
}

-(void)useGameCenterProfilePicture
{
//    mImageFrame.image = [OFImageLoader loadImage:mImageFrameFileName];
    mImageFrameFileName = @"OFGameCenterProfileFrame.png";
    [self _addImageFrame];
    [self setDefaultImage:[OFImageLoader loadImage:@"OFProfileIconDefault.png"]];
}


- (void)useProfilePictureFromUser:(OFUser*)user
{
    mImageFrameFileName = nil;
	if (user)
	{
		if ([user isLocalUser])
		{
			[self useLocalPlayerProfilePictureDefault];
		}
		else
		{
			[self useOtherPlayerProfilePictureDefault];
		}
		
		if (![OpenFeint allowUserGeneratedContent])
		{
			self.useFacebookOverlay = NO;
			self.imageUrl = nil;
		}
		else
		{
		self.useFacebookOverlay = user.usesFacebookProfilePicture;
		self.imageUrl = user.profilePictureUrl;
	}
	}
	else
	{
		[self useOtherPlayerProfilePictureDefault];
		self.imageUrl = nil;
	}
	
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch* touch = [touches anyObject];
	
	if ([touch tapCount] == 1)
	{
		[self sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
}

- (void)setUseSharpCorners:(BOOL)useSharpCorners
{
	mUseSharpCorners = useSharpCorners;
	[self _recreateBorderPath];
	[self _removeImageFrame];
	[self _addImageFrame];
}

- (void)setCornerRadius:(float)cornerRadius
{
    mCornerRadius = cornerRadius;
	[self _recreateBorderPath];
	[self _removeImageFrame];
	[self _addImageFrame];
}

- (void)setUnframed:(BOOL)unframed
{
	if (mUnframed != unframed)
	{
		mUnframed = unframed;
		[self _removeImageFrame];
		[self _addImageFrame];
	}
}

- (void)setHidden:(BOOL)hidden
{
	BOOL wasHidden = self.hidden;
	[super setHidden:hidden];
	if (wasHidden && !hidden)
	{
		[self setNeedsDisplay];
	}
}

@end
