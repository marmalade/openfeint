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
#import "OFPlayedGame.h"
#import "OFProfileService.h"
#import "OFUserGameStat.h"
#import "OpenFeint+UserOptions.h"
#import "OFGameDiscoveryService.h"
#import "OFPaginatedSeries.h"
#import "OFImageCache.h"
#import "OFImageView.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

static id sharedDelegate = nil;

@interface OFPlayedGame (Private)
+ (void)_getFeaturedGamesSuccess:(OFPaginatedSeries*)resources;
+ (void)_getFeaturedGamesFailure;
@end

@implementation OFPlayedGame

@synthesize name, iconUrl, clientApplicationId, totalGamerscore, friendsWithApp, userGameStats, iTunesAppStoreUrl, favorite, review;

+ (void)setDelegate:(id<OFPlayedGameDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFPlayedGame class]];
	}
}

+ (OFRequestHandle*)getFeaturedGames
{
	OFRequestHandle* handle = nil;
	handle = [OFGameDiscoveryService getDiscoveryPageNamed:@"developers_picks" 
												  withPage:1 
                                       onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getFeaturedGamesSuccess:)]
                                       onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getFeaturedGamesFailure)]];
//												 onSuccess:OFDelegate(self, @selector(_getFeaturedGamesSuccess:)) 
//												 onFailure:OFDelegate(self, @selector(_getFeaturedGamesFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFPlayedGame class]];
	return handle;
}

- (BOOL)isOwnedByCurrentUser
{
	OFUserGameStat* localUserGameStat = [self getLocalUsersGameStat];
	return localUserGameStat ? localUserGameStat.userHasGame : NO;
}

- (OFRequestHandle*)getGameIcon
{
    OFInvocation* success = nil;
    OFInvocation* failure = nil;
    if(sharedDelegate)
    {
        if([sharedDelegate respondsToSelector:@selector(didGetGameIcon:OFPlayedGame:)])
        {
            success = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didGetGameIcon:OFPlayedGame:) userParam:self];
        }
        
        if([sharedDelegate respondsToSelector:@selector(didFailGetGameIconOFPlayedGame:)])
        {
            failure = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didFailGetGameIconOFPlayedGame:) userParam:self];
        }
    }
    OFRequestHandle* handle = [OpenFeint getImageFromUrl:iconUrl forModule:[OFPlayedGame class] onSuccess:success onFailure:failure];
	return handle;
}

+ (void)_getFeaturedGamesSuccess:(OFPaginatedSeries*)resources
{	
	NSArray* featuredGames = [[[NSArray alloc] initWithArray:resources.objects] autorelease];
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetFeaturedGames:)])
	{
		[sharedDelegate didGetFeaturedGames:featuredGames];
	}
}

+ (void)_getFeaturedGamesFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetFeaturedGames)])
	{
		[sharedDelegate didFailGetFeaturedGames];
	}
}


- (void)setName:(NSString*)value
{
	OFSafeRelease(name);
	name = [value retain];
}

- (void)setIconUrl:(NSString*)value
{
	OFSafeRelease(iconUrl);
	iconUrl = [value retain];
}

- (void)setClientApplicationId:(NSString*)value
{
	OFSafeRelease(clientApplicationId);
	clientApplicationId = [value retain];
}

- (void)setUserGameStats:(NSMutableArray*)value
{
	OFSafeRelease(userGameStats);
	userGameStats = [value retain];
}

- (void)setTotalGamerscore:(NSString*)value
{
	totalGamerscore = [value intValue];
}

- (void)setFriendsWithApp:(NSString*)value
{
	friendsWithApp = [value intValue];
}

- (void)setITunesAppStoreUrl:(NSString*)value
{
	OFSafeRelease(iTunesAppStoreUrl);
	iTunesAppStoreUrl = [value retain];
}

- (void)setFavorite:(NSString*)value
{
	favorite = [value boolValue];
}

- (void)setReview:(NSString*)value
{
	if (review != value)
	{
		OFSafeRelease(review);
		review = [value retain];
	}
}

+ (OFService*)getService;
{
	return [OFProfileService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"played_game";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_played_game_discovered";
}

- (OFUserGameStat*)getLocalUsersGameStat
{
	for (OFUserGameStat* stat in userGameStats)
	{
		if ([stat.userId isEqualToString:[OpenFeint lastLoggedInUserId]])
		{
			return stat;
		}
	}
	return nil;
}

- (void) dealloc
{
	OFSafeRelease(iconUrl);
	OFSafeRelease(name);
	OFSafeRelease(userGameStats);
	OFSafeRelease(clientApplicationId);
	OFSafeRelease(iTunesAppStoreUrl);
	OFSafeRelease(review);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceArraySetter:@selector(setUserGameStats:)], @"user_game_stats",
[OFResourceField fieldSetter:@selector(setName:)], @"name",
[OFResourceField fieldSetter:@selector(setIconUrl:)], @"icon_url",
[OFResourceField fieldSetter:@selector(setClientApplicationId:)], @"client_application_id",
[OFResourceField fieldSetter:@selector(setTotalGamerscore:)], @"total_gamerscore",
[OFResourceField fieldSetter:@selector(setFriendsWithApp:)], @"friends_with_app",
[OFResourceField fieldSetter:@selector(setITunesAppStoreUrl:)], @"i_tunes_app_store_url",
[OFResourceField fieldSetter:@selector(setFavorite:)], @"favorite",
[OFResourceField fieldSetter:@selector(setReview:)], @"review",
        nil] retain];
    }
    return sDataDictionary;
}
@end
