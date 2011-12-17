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

typedef enum 
{
    OFGameFeedAlignment_BOTTOM,
    OFGameFeedAlignment_TOP,
    OFGameFeedAlignment_CUSTOM,
    OFGameFeedAlignment_COUNT,
} OFGameFeedAlignment;

////////////////////////////////////////////////////////////
///
/// @type		NSNumber OFGameFeedAlignment
/// @default	OFGameFeedAlignment_BOTTOM
/// @behavior	
///				OFGameFeedAlignment_TOP:              The game feed bar is aligned to the top of the screen.
///				OFGameFeedAlignment_BOTTOM:           The bar is aligned to the top of the screen.
///				OFGameFeedAlignment_CUSTOM:           The position of the bar is not set.
///                                                     It is up to the developer to position it.
///
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingAlignment;

////////////////////////////////////////////////////////////
/// @type		NSNumber BOOL
/// @behavior	If YES, the view will animate in when it becomes visible.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingAnimateIn;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The color of usernames in the game feed.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingUsernameColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The color of a feed item's title
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingTitleColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The color of normal text.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingMessageTextColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The icon is colored this for "positive" events, such as a friend completing achievements
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingIconPositiveColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The icon is colored this for "negative" events like a stranger beating your high score
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingIconNegativeColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The icon color used if the event isn't positive or negative
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingIconNeutralColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The color for the disclosure arrow
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingDisclosureColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The color for the text telling the user what the disclosure does
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingCalloutTextColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The color of the portrait frame
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingFrameColor;

////////////////////////////////////////////////////////////
/// @type		OFColor
/// @behavior	The color of highlighted text
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingHighlightedTextColor;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The Feed background is an image that is tiled for the full background of the Game Feed.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingFeedBackgroundImageLandscape;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The feed background is an image that is tiled for the full background of the Game Feed.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingFeedBackgroundImagePortrait;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The image used for the entire game feed item cell.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingCellBackgroundImageLandscape;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The image used for the entire game feed item cell.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingCellBackgroundImagePortrait;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The image used for the entire game feed item cell, in hit state.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingCellHitImageLandscape;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The image used for the entire game feed item cell, in hit state.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingCellHitImagePortrait;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The cell divider is normally a thin line between the description and callout text.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingCellDividerImageLandscape;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The cell divider is normally a thin line between the description and callout text.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingCellDividerImagePortrait;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The profile frame is a 40x40 image displayed over the profile picture in certain feed items.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingProfileFrameImage;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	The profile frame is a 21x22 image displayed over the smaller profile picture in certain feed items.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingSmallProfileFrameImage;
