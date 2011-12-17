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
#import "OFHighScore.h"
#import "OFHighScoreService.h"
#import "OFLeaderboard.h"
#import "OFUser.h"
#import "OFS3UploadParameters.h"
#import "OFPaginatedSeries.h"
#import "OFDependencies.h"
#import "OFUser.h"
#import "OFSqlQuery.h"

static id sharedDelegate = nil;

@interface OFHighScore (Private)
+ (void)_getHighScoresNearCurrentUserSuccess:(OFPaginatedSeries*)resources;
+ (void)_getHighScoresNearCurrentUserFailure;
- (void)_submitToSuccess;
- (void)_submitToFailure;
- (void)_downloadBlobSuccess:(OFHighScore*)score;
- (void)_downloadBlobFailure;
@end

@implementation OFHighScore

@synthesize latitude;
@synthesize longitude;
@synthesize distance;
@synthesize blob;
@synthesize blobUrl;
@synthesize user;
@synthesize rank;
@synthesize leaderboardId;
@synthesize gameCenterSeconds;
@synthesize gameCenterId;
@synthesize gameCenterName;

//Dev can set during submission of a high score.
@synthesize score;
@synthesize displayText;
@synthesize customData;

+ (void)setDelegate:(id<OFHighScoreDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFHighScore class]];
	}
}

+ (NSArray*)allHighScoresForCurrentUser
{
	NSArray* leaderboards = [OFLeaderboard leaderboards];
	NSMutableArray* highScores = [NSMutableArray arrayWithCapacity:[leaderboards count]];
	
	for (OFLeaderboard* leaderboard in leaderboards)
	{
		if (leaderboard.currentUserScore)
			[highScores addObject:leaderboard.currentUserScore];
	}
	
	return highScores;
}

+ (OFRequestHandle*)getHighScoresNearCurrentUserForLeaderboard:(OFLeaderboard*)leaderboard andBetterCount:(uint)betterCount andWorseCount:(uint)worseCount
{
	OFRequestHandle* handle = nil;
	handle = [OFHighScoreService getHighScoreNearCurrentUserForLeaderboard:leaderboard.resourceId
															andBetterCount:betterCount
															 andWorseCount:worseCount
                                                       onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getHighScoresNearCurrentUserSuccess:)]
                                                       onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getHighScoresNearCurrentUserFailure)]];
//																 onSuccess:OFDelegate(self, @selector(_getHighScoresNearCurrentUserSuccess:))
//																 onFailure:OFDelegate(self, @selector(_getHighScoresNearCurrentUserFailure))];
	[OFRequestHandlesForModule addHandle:handle forModule:[OFHighScore class]];
	return handle;
}

- (OFHighScore*)initForSubmissionWithScore:(int64_t)submitScore
{
	self = [super init];
	if(self)
	{
		self.score = submitScore;
	}
	return self;
}

- (void)submitTo:(OFLeaderboard*)leaderboard
{
	[OFHighScoreService setHighScore:self.score 
		withDisplayText:self.displayText 
		withCustomData:self.customData 
		withBlob:self.blob
		forLeaderboard:leaderboard.leaderboardId 
		silently:NO 
		deferred:NO
                 onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_submitToSuccess)]
                 onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_submitToFailure)]];
//		onSuccess:OFDelegate(self, @selector(_submitToSuccess)) 
//		onFailure:OFDelegate(self, @selector(_submitToFailure))];
}

- (OFRequestHandle*)downloadBlob
{
	OFRequestHandle* handle = nil;
	if(![self hasBlob])
	{
		[self _downloadBlobFailure];
	}
	else if(blob)
	{
		[self _downloadBlobSuccess:self];
	}
	else
	{
		handle = [OFHighScoreService downloadBlobForHighScore:self
                                          onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadBlobSuccess:)]
                                          onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadBlobFailure)]];
//													onSuccess:OFDelegate(self, @selector(_downloadBlobSuccess:))
//													onFailure:OFDelegate(self, @selector(_downlaodBlobFailure))];
		[OFRequestHandlesForModule addHandle:handle forModule:[OFHighScore class]];
	}
	return handle;
}

+ (void)_getHighScoresNearCurrentUserSuccess:(OFPaginatedSeries*)resources
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetHighScoresNearCurrentUser:)])
	{
		[sharedDelegate didGetHighScoresNearCurrentUser:resources.objects];
	}
}

+ (void)_getHighScoresNearCurrentUserFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetHighScoresNearCurrentUser)])
	{
		[sharedDelegate didFailGetHighScoresNearCurrentUser];
	}
}

- (void)_submitToSuccess
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didSubmit:)])
	{
		[sharedDelegate didSubmit:self];
	}
}

- (void)_submitToFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailSubmit:)])
	{
		[sharedDelegate didFailSubmit:self];
	}
}

- (void)_downloadBlobSuccess:(OFHighScore*)score
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didDownloadBlob:)])
	{
		[sharedDelegate didDownloadBlob:self];
	}
}

- (void)_downloadBlobFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailDownloadBlob:)])
	{
		[sharedDelegate didFailDownloadBlob:self];
	}
}

- (NSString*)displayText
{
	if (displayText)
	{
		return displayText;
	}
	else
	{
		return [NSString stringWithFormat:@"%qi", score];
	}
}

- (id)initWithLocalSQL:(OFSqlQuery*)queryRow forUser:(OFUser*)hsUser rank:(NSUInteger)scoreRank
{
	self = [super init];
	if (self != nil)
	{	
		OFSafeRelease(user);
		OFSafeRelease(blob);
		OFSafeRelease(customData);
		OFSafeRelease(displayText);
		OFSafeRelease(toHighRankText);
		OFSafeRelease(blobUploadParameters);
		user = [hsUser retain];
		leaderboardId = [[NSString stringWithFormat:@"%d", [queryRow intValue:@"leaderboard_id"]] retain];
		score = [queryRow int64Value:@"score"];
        displayText = [[queryRow stringValue:@"display_text"] retain];		
        blob = [[queryRow dataValue:@"blob"] retain];
        customData = [[queryRow stringValue:@"custom_data"] retain];
		rank = scoreRank;
		
		OFSafeRelease(resourceId);
		resourceId = @"1";	// arbitrary non-zero id
	}
	return self;
}

- (BOOL)hasBlob
{
	return blob || (blobUrl && [blobUrl length] > 0);
}

- (void)setUser:(OFUser*)value
{
	OFSafeRelease(user);
	user = [value retain];
}

- (void)_setScore:(NSString*)value
{
	score = [value longLongValue];
}

- (void)setRank:(NSString*)value
{
	rank = [value integerValue];
}

- (void)setLeaderboardId:(NSString*)value
{
	OFSafeRelease(leaderboardId);
	leaderboardId = [value retain];
}

- (void)_setDisplayText:(NSString*)value
{
	OFSafeRelease(displayText);
	if (value && ![value isEqualToString:@""])
	{
		displayText = [value retain];
	}
}

- (NSString*)toHighRankText
{
	return toHighRankText ? toHighRankText : @"99,999+";
}

- (void)setToHighRankText:(NSString*)value
{
	OFSafeRelease(toHighRankText);
	if (value && ![value isEqualToString:@""])
	{
		toHighRankText = [value retain];
	}
}

- (void)_setCustomData:(NSString*)value
{
	OFSafeRelease(customData);
	if (value && ![value isEqualToString:@""])
	{
		customData = [value retain];
	}
}

- (NSString*)customData
{
	return customData;
}

- (void)setBlobUrl:(NSString*)value
{
	if (value != blobUrl)
	{
		OFSafeRelease(blobUrl);
		if ([value length] > 0)
		{
			blobUrl = [value retain];
		}
	}
}

- (NSString*) blobUrl
{
	return blobUrl;
}

- (void)setBlobUploadParameters:(OFS3UploadParameters*)value
{
	if (value != blobUploadParameters)
	{
		OFSafeRelease(blobUploadParameters);
		blobUploadParameters = [value retain];
	}
}

- (OFS3UploadParameters*)blobUploadParameters
{
	return blobUploadParameters;
}

- (void)_setBlob:(NSData*)_blob
{
	if (blob != _blob)
	{
		OFSafeRelease(blob);
		blob = [_blob retain];
	}
}

- (void) setLatitude:(NSString*)value
{
	latitude = [value doubleValue];
}

- (void) setLongitude:(NSString*)value
{
	longitude = [value doubleValue];
}

- (void) setDistance:(NSString*)value
{
	distance = [value doubleValue];
}

- (void) setGameCenterSeconds:(NSString*) value
{
    gameCenterSeconds = [value intValue];
}

+ (OFService*)getService;
{
	return [OFHighScoreService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"high_score";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_high_score_discovered";
}

- (void) dealloc
{
	OFSafeRelease(user);
	OFSafeRelease(displayText);
	OFSafeRelease(toHighRankText);
	OFSafeRelease(customData);
	OFSafeRelease(blob);
	OFSafeRelease(blobUrl);
	OFSafeRelease(blobUploadParameters);
    OFSafeRelease(gameCenterId);
	OFSafeRelease(gameCenterName);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setUser:) getter:nil klass:[OFUser class]], @"user",
[OFResourceField nestedResourceSetter:@selector(setBlobUploadParameters:) getter:nil klass:[OFS3UploadParameters class]], @"blob_upload_parameters",
[OFResourceField fieldSetter:@selector(_setScore:)], @"score",
[OFResourceField fieldSetter:@selector(setRank:)], @"rank",
[OFResourceField fieldSetter:@selector(setLeaderboardId:)], @"leaderboard_id",
[OFResourceField fieldSetter:@selector(_setDisplayText:)], @"display_text",
[OFResourceField fieldSetter:@selector(setToHighRankText:)], @"to_high_rank_text",
[OFResourceField fieldSetter:@selector(_setCustomData:)], @"custom_data",
[OFResourceField fieldSetter:@selector(setBlobUrl:)], @"blob_url",
[OFResourceField fieldSetter:@selector(setLatitude:)], @"lat",
[OFResourceField fieldSetter:@selector(setLongitude:)], @"lng",
[OFResourceField fieldSetter:@selector(setDistance:)], @"distance",
[OFResourceField fieldSetter:@selector(setGameCenterSeconds:)], @"gamecenter_timestamp",
        nil] retain];
    }
    return sDataDictionary;
}
@end
