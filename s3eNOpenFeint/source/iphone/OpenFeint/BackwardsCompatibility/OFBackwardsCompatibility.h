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

/* 
 A convenience header to add all the backwards compatibility in one file.  Since this is monolithic, it
 basically makes a file dependent on most of the OpenFeint API, so it's use is not recommended.
 */

#ifdef __OBJC__
#ifdef __cplusplus

#import "OpenFeint+BackwardsCompatibility.h"
#import "OFUserService+BackwardsCompatibility.h"
#import "OFAchievementService+BackwardsCompatibility.h"
#import "OFAnnouncementService+BackwardsCompatibility.h"
#import "OFApplicationDescriptionService+BackwardsCompatibility.h"
#import "OFChallengeDefinitionService+BackwardsCompatibility.h"
#import "OFChallengeService+BackwardsCompatibility.h"
#import "OFChatRoomDefinitionService+BackwardsCompatibility.h"
#import "OFChatRoomInstanceService+BackwardsCompatibility.h"
#import "OFClientApplicationService+BackwardsCompatibility.h"
#import "OFForumService+BackwardsCompatibility.h"
#import "OFFriendsService+BackwardsCompatibility.h"
#import "OFHighScoreService+BackwardsCompatibility.h"
#import "OFInviteService+BackwardsCompatibility.h"
#import "OFLeaderboardService+BackwardsCompatibility.h"
#import "OFProfileService+BackwardsCompatibility.h"
#import "OFPushNotificationService+BackwardsCompatibility.h"
#import "OFSocialNotificationService+BackwardsCompatibility.h"
#import "OFTickerService+BackwardsCompatibility.h"
#import "OFTimeStampService+BackwardsCompatibility.h"
#import "OFUsersCredentialService+BackwardsCompatibility.h"
#import "OFUserSettingService+BackwardsCompatibility.h"
#import "OFCloudStorageService+BackwardsCompatibility.h"

#endif
#endif
