////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2011 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma once

#import <UIKit/UIKit.h>

@class OFInvocation;

@interface OFGameFeedItem : UIView {
    UIView* mHitStateView;
    NSTimer* mFadeInTimer;
    OFInvocation* mDoneFadingInInvocation;
    BOOL dynamicLayoutLoaded;
}

@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, retain) NSDate* clickTimestamp;
@property (nonatomic, assign) int feedPosition;
@property (nonatomic, retain) NSTimer* fadeInTimer;
@property (nonatomic, retain) OFInvocation* doneFadingInInvocation;
@property (nonatomic, retain) NSArray* layoutInfoViews;
@property (nonatomic, retain) NSDictionary* layoutInfoConfig;
@property (nonatomic, retain) NSDictionary* layoutInfoLayouts;

+ (id)gameFeedItemWithCustom:(NSDictionary*)custom itemData:(id)itemData configurationData:(id)configData bundle:(NSString*)bundlePath layouts:(NSDictionary*)layouts;
- (NSDictionary*) analyticsParams;

- (NSString*)interpolate:(NSString*)text withData:(NSDictionary*)data ignoringSquareBraces:(BOOL)ignoringSquareBraces escapeSquareBraceContents:(BOOL)escapeSquareBraceContents;
- (NSString*)interpolate:(NSString*)text withData:(NSDictionary*)data ignoringSquareBraces:(BOOL)ignoringSquareBraces;
- (NSString*)interpolate:(NSString*)text withData:(NSDictionary*)data;
- (NSAttributedString*)interpolateAttributedString:(NSAttributedString*)attributedString withData:(NSDictionary*)data;
- (UIColor*)interpolateColor:(NSString*)text withData:(NSDictionary*)data defaultColor:(UIColor*)defaultColor;
- (UIImage*)interpolateImage:(NSString*)text withData:(NSDictionary*) data;
- (UIImage*)colorizeImage:(UIImage*)image color:(UIColor*)color;
- (void)wasShown;
- (void)wasPartlyShown;
- (void)fadeInAfterSeconds:(float)seconds doneInvocation:(OFInvocation*)doneInvocation;
- (void)fadeInAtDate:(NSDate*)date doneInvocation:(OFInvocation*)doneInvocation;

// This implementation takes itemToReplace, which is an OFGameFeedItem that will be removed from its superview once this one fades in.
- (void)fadeInAfterSeconds:(float)seconds doneInvocation:(OFInvocation*)doneInvocation replacingItem:(OFGameFeedItem*)itemToReplace;

@end
