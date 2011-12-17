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
#import "OFUserGameStat.h"
#import "OFProfileService.h"
#import "OFDependencies.h"

@implementation OFUserGameStat

@synthesize userHasGame, userId, userGamerScore, userFavoritedGame;

- (void)setUserHasGame:(NSString*)value
{
	userHasGame = [value boolValue];
}

- (void)setUserId:(NSString*)value
{
	OFSafeRelease(userId);
	userId = [value retain];
}

- (void)setUserGamerscore:(NSString*)value
{
	userGamerScore = [value intValue];
}

- (void)setUserFavoritedGame:(NSString*)value
{
	userFavoritedGame = [value boolValue];
}

+ (OFService*)getService;
{
	return nil;
}


+ (NSString*)getResourceName
{
	return @"user_game_stat";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_user_game_stat_discovered";
}

- (void) dealloc
{
	self.userId = nil;
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setUserHasGame:)], @"user_has_game",
[OFResourceField fieldSetter:@selector(setUserId:)], @"user_id",
[OFResourceField fieldSetter:@selector(setUserGamerscore:)], @"user_gamerscore",
[OFResourceField fieldSetter:@selector(setUserFavoritedGame:)], @"user_favorited_game",
        nil] retain];
    }
    return sDataDictionary;
}
@end
