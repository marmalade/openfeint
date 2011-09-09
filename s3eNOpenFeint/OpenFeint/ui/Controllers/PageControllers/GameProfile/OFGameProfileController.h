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

#import "OFViewController.h"
#import "OFProfileFrame.h"
#import "OFBannerProvider.h"

@class OFButtonPanel;
@class OFBadgeButton;
@class OFGameProfilePageInfo;
@class OFUser;

@interface OFGameProfileController : OFViewController<OFBannerProvider, OFCallbackable>
{
	IBOutlet UIButton* leaderboardsButton;
	IBOutlet UIButton* achievementsButton;
	IBOutlet OFBadgeButton* challengesButton;
	IBOutlet UIButton* discussionsButton;
	IBOutlet UIButton* discussionsLongButton;
	IBOutlet OFBadgeButton* fanClubButton;
	IBOutlet OFBadgeButton* fanClubLongButton;
	IBOutlet UIButton* whosPlayingButton;
	IBOutlet UIButton* whosPlayingLongButton;
	
	IBOutlet UIView* backgroundView;
	IBOutlet OFButtonPanel* buttonPanel;
	
	NSString* clientApplicationId;
	OFGameProfilePageInfo* gameProfileInfo;
	
	BOOL wasOfflineLastRefresh;
	BOOL usingLongButtons;
}

+ (void)showGameProfileWithClientApplicationId:(NSString*)clientApplicationId compareToUser:(OFUser*)comparisonUser;
+ (void)showGameProfileWithClientApplicationId:(NSString*)clientApplicationId;
+ (void)showGameProfileWithLocalApplication;

- (IBAction)pressedLeaderboards;
- (IBAction)pressedAchievements;
- (IBAction)pressedChallenges;
- (IBAction)pressedDiscussions;
- (IBAction)pressedFanClub;
- (IBAction)pressedWhosPlaying;

+ (void)setPushControllerData:(UIViewController*)controllerToPush withGameProfileInfo:(OFGameProfilePageInfo*)gameProfileInfo;
- (void)pushController:(UIViewController*)controller;
- (UIViewController*)pushControllerByName:(NSString*)controllerName;

- (void)refreshView;
- (void)registerForBadgeNotifications;
- (void)setOnlineStatus:(BOOL)onlineStatus;

@end
