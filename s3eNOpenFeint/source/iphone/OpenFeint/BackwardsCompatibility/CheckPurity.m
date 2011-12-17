//  Copyright 2011 Aurora Feint, Inc.
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

//The only purpose of this file is to verify that the headers can compile cleanly

#import "OpenFeint/OpenFeint.h"

#import "OpenFeint/OFUserService.h"
#import "OpenFeint/OFAbridgedHighScore.h"			
#import "OpenFeint/OFHttpBasicCredential.h"
#import "OpenFeint/OFAchievement.h"				
#import "OpenFeint/OFImageUrl.h"
#import "OpenFeint/OFAnnouncement.h"			
#import "OpenFeint/OFInvite.h"
#import "OpenFeint/OFApplicationDescription.h"		
#import "OpenFeint/OFInviteDefinition.h"
#import "OpenFeint/OFBragDelegate.h"		 //this one uses a LOT of references
#import "OpenFeint/OFLeaderboard.h"
#import "OpenFeint/OFChallenge.h"			
#import "OpenFeint/OFNewsletterSubscription.h"
#import "OpenFeint/OFChallengeDefinition.h"			
#import "OpenFeint/OFNotificationDelegate.h"
#import "OpenFeint/OFChallengeDefinitionStats.h"		
#import "OpenFeint/OFOnlineStatus.h"
#import "OpenFeint/OFChallengeDelegate.h"			
#import "OpenFeint/OFPlayedGame.h"
#import "OpenFeint/OFChallengeToUser.h"			
#import "OpenFeint/OFPlayerReview.h"
#import "OpenFeint/OFChatMessage.h"				
#import "OpenFeint/OFReceivedChallengeNotificationData.h"
#import "OpenFeint/OFChatMessageService.h"			
#import "OpenFeint/OFRequestHandle.h"
#import "OpenFeint/OFChatRoomDefinition.h"		
#import "OpenFeint/OFChatRoomInstance.h"			
#import "OpenFeint/OFS3Response.h"
#import "OpenFeint/OFCloudStorage.h"			
#import "OpenFeint/OFS3UploadParameters.h"
#import "OpenFeint/OFCloudStorageBlob.h"			
#import "OpenFeint/OFScoreEnumerator.h"
#import "OpenFeint/OFCloudStorageStatus.h"			
#import "OpenFeint/OFSocialNotification.h"
#import "OpenFeint/OFCompressableData.h"			
#import "OpenFeint/OFSocialNotificationApi.h"
#import "OpenFeint/OFCurrentUser.h"				
#import "OpenFeint/OFTicker.h"
#import "OpenFeint/OFDelegatesContainer.h"		
#import "OpenFeint/OFTimeStamp.h"
#import "OpenFeint/OFDeviceContact.h"			
#import "OpenFeint/OFUnlockedAchievementNotificationData.h"
#import "OpenFeint/OFDistributedScoreEnumerator.h"	
#import "OpenFeint/OFUser.h"
#import "OpenFeint/OFForumPost.h"				
#import "OpenFeint/OFUserGameStat.h"
#import "OpenFeint/OFForumThread.h"			
#import "OpenFeint/OFUserSetting.h"
#import "OpenFeint/OFForumTopic.h"				
#import "OpenFeint/OFUserSettingPushController.h"
#import "OpenFeint/OFGamePlayer.h"				
#import "OpenFeint/OFUsersCredential.h"
#import "OpenFeint/OFGameProfilePageComparisonInfo.h"	
#import "OpenFeint/OFXPRequest.h"
#import "OpenFeint/OFGameProfilePageInfo.h"			
#import "OpenFeint/OFSession.h"
#import "OpenFeint/OFGamerscore.h"				

#import "OpenFeint/OpenFeintDelegate.h"
#import "OpenFeint/OFHighScore.h"				
#import "OpenFeint/OpenFeintSettings.h"

#import "OpenFeint/OFUserService.h"
#import "OpenFeint/OFAchievementService.h"
#import "OpenFeint/OFAnnouncementService.h"
#import "OpenFeint/OFApplicationDescriptionService.h"
#import "OpenFeint/OFChallengeDefinitionService.h"
#import "OpenFeint/OFChallengeService.h"
#import "OpenFeint/OFChatRoomDefinitionService.h"
#import "OpenFeint/OFChatRoomInstanceService.h"
#import "OpenFeint/OFClientApplicationService.h"
#import "OpenFeint/OFForumService.h"
#import "OpenFeint/OFFriendsService.h"
#import "OpenFeint/OFHighScoreService.h"
#import "OpenFeint/OFInviteService.h"
#import "OpenFeint/OFLeaderboardService.h"
#import "OpenFeint/OFProfileService.h"
#import "OpenFeint/OFPushNotificationService.h"
#import "OpenFeint/OFSocialNotificationService.h"
#import "OpenFeint/OFTickerService.h"
#import "OpenFeint/OFTimeStampService.h"
#import "OpenFeint/OFUsersCredentialService.h"
#import "OpenFeint/OFUserSettingService.h"
#import "OpenFeint/OFCloudStorageService.h"

