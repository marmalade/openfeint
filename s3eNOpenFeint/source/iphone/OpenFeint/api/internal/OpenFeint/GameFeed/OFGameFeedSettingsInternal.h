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

// The following have been removed from the api intentionally,
// as we have decided not to provide this feature.
// These used to exist in OFGameFeedSettings.h

////////////////////////////////////////////////////////////
/// @type		NSNumber BOOL
/// @behavior	If YES, a tab will be shown on the game feed.
///             The layout of the tab may be customized.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingShowTabView;

typedef enum 
{
    OFGameFeedTabAlignment_LEFT,
    OFGameFeedTabAlignment_RIGHT,
} OFGameFeedTabAlignment;

////////////////////////////////////////////////////////////
/// @type		NSNumber OFGameFeedTabAlignment
/// @default	OFGameFeedTabAlignment_LEFT
/// @behavior	Specifies the alignment of the tab view, if enabled.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingTabAlignment;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	A small icon that shows on the tab view.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingTabIcon;

////////////////////////////////////////////////////////////
/// @type		NSString
/// @behavior	Shown on the tab view.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingTabText;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	Shown on the tab view.
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingTabBrandingImage;
////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingTabLeftImage;

////////////////////////////////////////////////////////////
/// @type		UIImage
/// @behavior	
////////////////////////////////////////////////////////////
extern NSString* OFGameFeedSettingTabRightImage;



extern NSString* OFGameFeedSettingTestConfigFilename;
extern NSString* OFGameFeedSettingTestFeedFilename;
