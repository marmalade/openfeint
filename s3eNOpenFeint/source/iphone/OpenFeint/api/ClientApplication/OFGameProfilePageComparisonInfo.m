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

#import "OFResourceField.h"
#import "OFGameProfilePageComparisonInfo.h"
#import "OFGameProfilePageInfo.h"
#import "OFDependencies.h"

@implementation OFGameProfilePageComparisonInfo

@synthesize gameProfilePageInfo, 
			localUsersAchievementsScore,
			comparedUsersAchievementsScore, 
			localUsersChallengesScore, 
			comparedUsersChallengesScore, 
			localUsersLeaderboardsScore, 
			comparedUsersLeaderboardsScore;

- (void)setGameProfilePageInfo:(OFGameProfilePageInfo*)value
{
	if (gameProfilePageInfo != value)
	{
		OFSafeRelease(gameProfilePageInfo);
		gameProfilePageInfo = [value retain];
	}
}

- (void)setLocalUsersAchievementsScore:(NSString*)value
{
	localUsersAchievementsScore = [value intValue];
}

- (void)setComparedUsersAchievementsScore:(NSString*)value
{
	comparedUsersAchievementsScore = [value intValue];
}

- (void)setLocalUsersChallengesScore:(NSString*)value
{
	localUsersChallengesScore = [value intValue];
}

- (void)setComparedUsersChallengesScore:(NSString*)value
{
	comparedUsersChallengesScore = [value intValue];
}

- (void)setLocalUsersLeaderboardsScore:(NSString*)value
{
	localUsersLeaderboardsScore = [value intValue];
}

- (void)setComparedUsersLeaderboardsScore:(NSString*)value
{
	comparedUsersLeaderboardsScore = [value intValue];
}


+ (NSString*)getResourceName
{
	return @"game_profile_page_comparison_info";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (void) dealloc
{
	OFSafeRelease(gameProfilePageInfo);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setGameProfilePageInfo:) getter:nil klass:[OFGameProfilePageInfo class]], @"game_profile_page_info",
[OFResourceField fieldSetter:@selector(setLocalUsersAchievementsScore:) getter:nil], @"local_user_achievements_score",
[OFResourceField fieldSetter:@selector(setComparedUsersAchievementsScore:) getter:nil], @"compared_users_achievements_score",
[OFResourceField fieldSetter:@selector(setLocalUsersChallengesScore:) getter:nil], @"local_users_challenges_score",
[OFResourceField fieldSetter:@selector(setComparedUsersChallengesScore:) getter:nil], @"compared_users_challenges_score",
[OFResourceField fieldSetter:@selector(setLocalUsersLeaderboardsScore:) getter:nil], @"local_users_leaderboards_score",
[OFResourceField fieldSetter:@selector(setComparedUsersLeaderboardsScore:) getter:nil], @"compared_users_leaderboards_score",
        nil] retain];
    }
    return sDataDictionary;
}
@end
