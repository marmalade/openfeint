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
#import "OFHighScoreService.h"
#import "OFAbridgedHighScore.h"
#import "OFLeaderboard.h"
#import "OFImageView.h"
#import "OFImageCache.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

static id sharedDelegate = nil;


@implementation OFAbridgedHighScore

@synthesize score;
@synthesize displayText;
@synthesize userId;
@synthesize userName;
@synthesize userProfilePictureUrl;
@synthesize userGamerScore;

+ (void)setDelegate:(id<OFAbridgedHighScoreDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFAbridgedHighScore class]];
	}
}

- (OFRequestHandle*)getProfilePicture
{
    OFInvocation* success = nil;
    OFInvocation* failure = nil;
    if(sharedDelegate)
    {
        if([sharedDelegate respondsToSelector:@selector(didGetProfilePicture:OFAbridgedHighScore:)])
        {
            success = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didGetProfilePicture:OFAbridgedHighScore:) userParam:self];
        }
        
        if([sharedDelegate respondsToSelector:@selector(didFailGetProfilePictureOFAbridgedHighScore:)])
        {
            failure = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didFailGetProfilePictureOFAbridgedHighScore:) userParam:self];
        }
    }
    OFRequestHandle* handle = [OpenFeint getImageFromUrl:userProfilePictureUrl forModule:[OFAbridgedHighScore class] onSuccess:success onFailure:failure];
	return handle;
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

- (void)setScore:(NSString*)value
{
	score = [value longLongValue];
}

- (void)setUserGamerScore:(NSString*)value
{
	userGamerScore = [value integerValue];
}

- (void)setLeaderboardId:(NSString*)value
{
	OFSafeRelease(leaderboardId);
	leaderboardId = [value retain];
}

- (void)setDisplayText:(NSString*)value
{
	OFSafeRelease(displayText);
	if (value && ![value isEqualToString:@""])
	{
		displayText = [value retain];
	}
}

- (void)setUserName:(NSString*)value
{
	OFSafeRelease(userName);
	if (value && ![value isEqualToString:@""])
	{
		userName = [value retain];
	}
}

- (void)setUserId:(NSString*)value
{
	OFSafeRelease(userId);
	if (value && ![value isEqualToString:@""])
	{
		userId = [value retain];
	}
}

- (void)setUserProfilePictureUrl:(NSString*)value
{
	OFSafeRelease(userProfilePictureUrl);
	if (value && ![value isEqualToString:@""])
	{
		userProfilePictureUrl = [value retain];
	}
}

+ (OFService*)getService;
{
	return [OFHighScoreService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"abridged_score";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_abridged_high_score_discovered";
}

- (void) dealloc
{
	OFSafeRelease(displayText);
	OFSafeRelease(leaderboardId);
	OFSafeRelease(userId);
	OFSafeRelease(userName);
	OFSafeRelease(userProfilePictureUrl);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setScore:)], @"score",
[OFResourceField fieldSetter:@selector(setLeaderboardId:)], @"leaderboard_id",
[OFResourceField fieldSetter:@selector(setDisplayText:)], @"display_text",
[OFResourceField fieldSetter:@selector(setUserId:)], @"user_id",
[OFResourceField fieldSetter:@selector(setUserName:)], @"user_name",
[OFResourceField fieldSetter:@selector(setUserProfilePictureUrl:)], @"user_profile_picture_url",
[OFResourceField fieldSetter:@selector(setUserGamerScore:)], @"user_gamer_score",
        nil] retain];
    }
    return sDataDictionary;
}
@end
