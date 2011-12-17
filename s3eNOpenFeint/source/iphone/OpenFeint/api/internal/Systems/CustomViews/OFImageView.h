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

#pragma once

#import <UIKit/UIKit.h>

@class OFUser;
@class OFRequestHandle;
@class OFInvocation;

@interface OFImageView : UIControl
{
@private
	UIImage* mDefaultImage;
	
	NSString* mImageUrl;
	UIImage* mImage;
    OFRequestHandle* mInProgressRequest;

	BOOL mShouldScaleImageToFillRect;
	BOOL mShouldShowLoadingIndicator;
	
	float mCrossFadeDuration;	
	UIImage* mImageFadingIn;
	float mFadingImageAlpha;
	NSTimer* mFadingTimer;
	
	UIActivityIndicatorView* mLoadingView;
	
	CGPathRef mBorderPath;
	BOOL mUseSharpCorners;
	BOOL mUsingCustomBorderPath;
    float mCornerRadius;
	
    OFInvocation* mImageDownloadInvocation;
	BOOL mUseFacebookOverlay;
	UIImageView* mFacebookOverlay;
	
	NSString* mImageFrameFileName;
	BOOL mUnframed;
	UIImageView* mImageFrame;
}

@property (nonatomic, assign) BOOL shouldScaleImageToFillRect;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) NSString* imageUrl;
@property (nonatomic, assign) BOOL useFacebookOverlay;
@property (nonatomic, assign) BOOL useSharpCorners;
@property (nonatomic, assign) BOOL unframed;
@property (nonatomic, assign) float crossFadeDuration;
@property (nonatomic, assign) float cornerRadius;
@property (nonatomic, assign) BOOL shouldShowLoadingIndicator;
@property (nonatomic, retain) OFInvocation* imageDownloadInvocation;

- (void)setImageUrl:(NSString*)imageUrl crossFading:(BOOL)shouldCrossFade;

- (void)showLoadingIndicator;

- (void)setDefaultImage:(UIImage*)defaultImage;

- (void)useLocalPlayerProfilePictureDefault;
- (void)useOtherPlayerProfilePictureDefault;
- (void)useGameCenterProfilePicture;

- (void)useProfilePictureFromUser:(OFUser*)user;

- (void)setCustomClippingPath:(CGPathRef)path;

@end
