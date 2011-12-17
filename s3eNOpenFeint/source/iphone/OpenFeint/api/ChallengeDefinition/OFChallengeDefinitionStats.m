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
#import "OFChallengeDefinitionStats.h"
#import "OFChallengeDefinition.h"
#import "OFChallengeDefinitionService.h"
#import "OFDependencies.h"

@implementation OFChallengeDefinitionStats

@synthesize challengeDefinition, localUsersWins, localUsersLosses, localUsersTies, comparedUsersWins, comparedUsersLosses, comparison;

- (void)setChallengeDefinition:(OFChallengeDefinition*)value
{
	if (value != challengeDefinition)
	{
		OFSafeRelease(challengeDefinition);
		challengeDefinition = [value retain];
	}
}

- (void)setLocalUsersWins:(NSString*)value
{
	localUsersWins = [value intValue];
}

- (void)setLocalUsersLosses:(NSString*)value
{
	localUsersLosses = [value intValue];
}

- (void)setLocalUsersTies:(NSString*)value
{
	localUsersTies = [value intValue];
}

- (void)setComparedUsersWins:(NSString*)value
{
	if (value && [value length] > 0)
	{
		comparison = YES;
		comparedUsersWins = [value intValue];
	}
	else
	{
		comparedUsersWins = 0;
	}
}

- (void)setComparedUsersLosses:(NSString*)value
{
	if (value && [value length] > 0)
	{
		comparison = YES;
		comparedUsersLosses = [value intValue];
	}
	else
	{
		comparedUsersLosses = 0;
	}
}

+ (OFService*)getService;
{
	return [OFChallengeDefinitionService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"challenge_definition_stats";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_challenge_definition_stats_discovered";
}

- (void) dealloc
{
	OFSafeRelease(challengeDefinition);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setChallengeDefinition:) getter:nil klass:[OFChallengeDefinition class]], @"challenge_definition",
[OFResourceField fieldSetter:@selector(setLocalUsersWins:) getter:nil], @"local_users_wins",
[OFResourceField fieldSetter:@selector(setLocalUsersLosses:) getter:nil], @"local_users_losses",
[OFResourceField fieldSetter:@selector(setLocalUsersTies:) getter:nil], @"local_users_ties",
[OFResourceField fieldSetter:@selector(setComparedUsersWins:) getter:nil], @"compared_users_wins",
[OFResourceField fieldSetter:@selector(setComparedUsersLosses:) getter:nil], @"compared_users_losses",
        nil] retain];
    }
    return sDataDictionary;
}
@end
