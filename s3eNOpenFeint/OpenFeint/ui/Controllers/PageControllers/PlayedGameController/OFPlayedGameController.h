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

#import "OFTableSequenceControllerHelper.h"
#import "OFBannerProvider.h"

static const int kNumSamples = 10;

@class OFService;

enum OFPlayedGameScope { kPlayedGameScopeMyGames = 0, kPlayedGameScopeFriendsGames, kPlayedGameScopeTargetServiceIndex };
@interface OFPlayedGameController : OFTableSequenceControllerHelper<OFBannerProvider, UIAccelerometerDelegate>
{
	OFPlayedGameScope scope;
	NSString* targetDiscoveryPageName;
	OFResource* headerBannerResource;
	bool inFavoriteTab;
	bool reloadWhenShownNext;
	NSTimeInterval defaultUpdateInterval;
	NSObject<UIAccelerometerDelegate>* defaultDelegate;
	bool enableShake;
    CGFloat previousX[kNumSamples];
    CGFloat previousY[kNumSamples];
    CGFloat previousZ[kNumSamples];
}

@property (nonatomic, retain) NSObject<UIAccelerometerDelegate>* defaultDelegate;
@property (nonatomic, assign) OFPlayedGameScope scope;
@property (nonatomic, retain) NSString* targetDiscoveryPageName;

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath;
- (NSString*)bannerCellControllerName;

- (void)enableShakeAgain;

@end
