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


#import "OFResource.h"

@class OFGameProfilePageInfo;

@interface OFGameProfilePageComparisonInfo : OFResource
{
	@package
	OFGameProfilePageInfo* gameProfilePageInfo;
	NSInteger localUsersAchievementsScore;
	NSInteger comparedUsersAchievementsScore;
	NSInteger localUsersChallengesScore;
	NSInteger comparedUsersChallengesScore;
	NSInteger localUsersLeaderboardsScore;
	NSInteger comparedUsersLeaderboardsScore;
	
}

+ (OFResourceDataMap*)getDataMap;
+ (NSString*)getResourceName;
+ (NSString*)getResourceDiscoveredNotification;

@property (nonatomic, readonly) OFGameProfilePageInfo* gameProfilePageInfo;
@property (nonatomic, readonly) NSInteger localUsersAchievementsScore;
@property (nonatomic, readonly) NSInteger comparedUsersAchievementsScore;
@property (nonatomic, readonly) NSInteger localUsersChallengesScore;
@property (nonatomic, readonly) NSInteger comparedUsersChallengesScore;
@property (nonatomic, readonly) NSInteger localUsersLeaderboardsScore;
@property (nonatomic, readonly) NSInteger comparedUsersLeaderboardsScore;

@end
