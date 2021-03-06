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
#import "OFLeaderboard.h"
#import "OFDependencies.h"
#import "OFPaginatedSeries.h"
#import "OFTableSectionDescription.h"
#import "OFRequestHandle.h"
#import "OFLeaderboardService+Private.h"
#import "OFHighScoreService+Private.h"
#import "OpenFeint+UserOptions.h"

static id sharedDelegate = nil;

//////////////////////////////////////////////////////////////////////////////////////////
/// @internal
//////////////////////////////////////////////////////////////////////////////////////////
@interface OFLeaderboard (Private)
- (void)_downloadedHighScores:(OFPaginatedSeries*)page;
- (void)_failedDownloadingHighScores;
- (NSString*)leaderboardId;

@end

@implementation OFLeaderboard

@synthesize filter, name, currentUserScore, descendingScoreOrder;

#pragma mark Public Methods

+ (void)setDelegate:(id<OFLeaderboardDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFLeaderboard class]];
	}
}

+ (NSArray*)leaderboards
{
	return [OFLeaderboardService getLeaderboardsLocal];
}

+ (OFLeaderboard*)leaderboard:(NSString*)leaderboardID
{
	return [OFLeaderboardService getLeaderboard:leaderboardID];
}

- (void)submitScore:(OFHighScore*)score
{
	[OFHighScoreService 
		setHighScore:score.score 
		withDisplayText:score.displayText 
		withCustomData:score.customData 
		forLeaderboard:self.leaderboardId 
		silently:NO 
		onSuccessInvocation:nil 
		onFailureInvocation:nil];
}

- (OFHighScore*)highScoreForCurrentUser
{
	return [OFHighScoreService getHighScoreForUser:[OpenFeint localUser] leaderboardId:[self leaderboardId] descendingSortOrder:self.descendingScoreOrder];
}

- (NSArray*)locallySubmittedScores
{
	return [OFHighScoreService getHighScoresLocal:self.leaderboardId];
}

- (OFRequestHandle*)downloadHighScoresWithFilter:(OFScoreFilter)downloadFilter
{
	OFAssert(downloadFilter != OFScoreFilter_None, @"When Downloading High Scores you must specify a filter other than NONE");
	
	
	filter = downloadFilter;
	
	OFRequestHandle* handle =  [OFHighScoreService 
								getPage:1 
								pageSize:25 
								forLeaderboard:self.leaderboardId 
								comparedToUserId:nil
								friendsOnly:(filter == OFScoreFilter_FriendsOnly) 
								silently:YES
                                timeScope:0
                                onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadedHighScores:)]
                                onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_failedDownloadingHighScores)]];
//								onSuccess:OFDelegate(self, @selector(_downloadedHighScores:)) 
//								onFailure:OFDelegate(self, @selector(_failedDownloadingHighScores))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFLeaderboard class]];
	return handle;
}

#pragma mark Internal Methods

- (id)initWithLocalSQL:(OFSqlQuery*)queryRow localUserScore:(OFHighScore*) locUserScore comparedUserScore:(OFHighScore*) compUserScore
{
	self = [super init];
	if (self != nil)
	{	
		name = [[queryRow stringValue:@"name"] retain];
		resourceId = [[queryRow stringValue:@"id"] retain];
		descendingScoreOrder = [queryRow intValue:@"descending_sort_order"] != 0;
		OFSafeRelease(currentUserScore);
		currentUserScore = [locUserScore retain];
		OFSafeRelease(comparedUserScore);
		comparedUserScore = [compUserScore retain];
	}
	return self;
}

- (BOOL)isComparison
{
	return comparedUserScore != nil;
}

- (OFUser*)comparedToUser
{
	return [comparedUserScore user];
}

- (void)_downloadedHighScores:(OFPaginatedSeries*)page
{
	if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didDownloadHighScores:OFLeaderboard:)])
	{
		NSArray* objects = [page objects];
		if ([objects count] > 0 && [[objects objectAtIndex:0] isKindOfClass:[OFTableSectionDescription class]])
		{
			objects = [[[objects lastObject] page] objects];
		}
		
		[sharedDelegate didDownloadHighScores:objects OFLeaderboard:self];
	}
}

- (void)_failedDownloadingHighScores
{
	if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailDownloadHighScoresOFLeaderboard:)])
	{
		[sharedDelegate didFailDownloadHighScoresOFLeaderboard:self];
	}
}

- (NSString*) leaderboardId
{
	return resourceId;
}

#pragma mark -
#pragma mark OFResource
#pragma mark -

- (void)setName:(NSString*)value
{
	OFSafeRelease(name);
	name = [value retain];
}

- (void)setDescendingScoreOrder:(NSString*)value
{
	descendingScoreOrder = [value boolValue];
}

- (void)setCurrentUsersScore:(OFHighScore*)value
{
	OFSafeRelease(currentUserScore);
	currentUserScore = [value retain];
}

- (void)setComparedToUsersScore:(OFHighScore*)value
{
	OFSafeRelease(comparedUserScore);
	comparedUserScore = [value retain];
}

+ (OFService*)getService;
{
	return [OFLeaderboardService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"leaderboard";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_leaderboard_discovered";
}

- (void) dealloc
{
	OFSafeRelease(name);
	OFSafeRelease(currentUserScore);
	OFSafeRelease(comparedUserScore);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setCurrentUsersScore:) getter:nil klass:[OFHighScore class]], @"current_user_high_score",
[OFResourceField nestedResourceSetter:@selector(setComparedToUsersScore:) getter:nil klass:[OFHighScore class]], @"compared_user_high_score",
[OFResourceField fieldSetter:@selector(setName:)], @"name",
[OFResourceField fieldSetter:@selector(setDescendingScoreOrder:)], @"descending_sort_order",
        nil] retain];
    }
    return sDataDictionary;
}
@end
