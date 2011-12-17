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
#import "OFUser.h"
#import "OpenFeint+UserOptions.h"
#import "OFFriendsService.h"
#import "OFPaginatedSeries.h"
#import "OFUserService.h"
#import "OFTableSectionDescription.h"
#import "OFImageView.h"
#import "OFImageCache.h"
#import "OpenFeint+Private.h"
#import "OFSqlQuery.h"
#import "OFDependencies.h"

#define FORCE_ONLINE 0

static id sharedDelegate = nil;

@interface OFUser (Private)
+ (void)_getUserSuccess:(OFPaginatedSeries*)resources;
+ (void)_getUserFailure;
+ (void)_favoriteCurrentGameForCurrentUserSuccess;
+ (void)_favoriteCurrentGameForCurrentUserFailure;
- (void)_getFriendsSuccess:(OFPaginatedSeries*)followedUsers;
- (void)_getFriendsFailure;
- (void)_getFriendsWithThisApplicationSuccess:(OFPaginatedSeries*)followedUsers;
- (void)_getFriendsWithThisApplicationFailure;
+ (NSArray*)_extractUsersFromPaginatedSeries:(OFPaginatedSeries*)paginatedSeries;
@end

@implementation OFUser

@synthesize name;
@synthesize profilePictureUrl;
@synthesize profilePictureSource;
@synthesize usesFacebookProfilePicture;
@synthesize lastPlayedGameId;
@synthesize lastPlayedGameName;
@synthesize gamerScore;
@synthesize followsLocalUser;
@synthesize followedByLocalUser;
@synthesize online;
@synthesize latitude;
@synthesize longitude;

+ (void)setDelegate:(id<OFUserDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFUser class]];
	}
}

+ (OFRequestHandle*)getUser:(NSString*)userId
{
	OFRequestHandle* handle = nil;
	handle = [OFUserService getUser:userId
//						onSuccess:OFDelegate(self, @selector(_getUserSuccess:))
//						onFailure:OFDelegate(self, @selector(_getUserFailure))];
                onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getUserSuccess:)]
                onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getUserFailure)]];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFUser class]];
	return handle;
}

- (OFRequestHandle*)getFriends
{
	OFRequestHandle* handle = nil;
	handle = [OFFriendsService getAllUsersFollowedByUserAlphabetical:self.resourceId
                                                 onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getFriendsSuccess:)]
                                                 onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getFriendsFailure)]];
//														   onSuccess:OFDelegate(self, @selector(_getFriendsSuccess:))
//														   onFailure:OFDelegate(self, @selector(_getFriendsFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFUser class]];
	return handle;
}

- (OFRequestHandle*)getFriendsWithThisApplication
{
	OFRequestHandle* handle = nil;
	handle = [OFFriendsService getAllUsersWithApp:[OpenFeint clientApplicationId]
								   followedByUser:self.resourceId
                  alphabeticalOnSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getFriendsWithThisApplicationSuccess:)]
                              onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getFriendsWithThisApplicationFailure)]];
//							alphabeticalOnSuccess:OFDelegate(self, @selector(_getFriendsWithThisApplicationSuccess:))
//										onFailure:OFDelegate(self, @selector(_getFriendsWithThisApplicationFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFUser class]];
	return handle;
}

- (OFRequestHandle*)getProfilePicture
{
    OFInvocation* success = nil;
    OFInvocation* failure = nil;
    if(sharedDelegate)
    {
        if([sharedDelegate respondsToSelector:@selector(didGetProfilePicture:OFUser:)])
        {
            success = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didGetProfilePicture:OFUser:) userParam:self];
        }
        
        if([sharedDelegate respondsToSelector:@selector(didFailGetProfilePictureOFUser:)])
        {
            failure = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didFailGetProfilePictureOFUser:) userParam:self];
        }
    }
    OFRequestHandle* handle = [OpenFeint getImageFromUrl:profilePictureUrl forModule:[OFUser class] onSuccess:success onFailure:failure];
	return handle;
}

+ (void)_getUserSuccess:(OFPaginatedSeries*)resources
{
	if ([resources count] > 0)
	{
		OFUser* user = [resources.objects objectAtIndex:0];
		if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetUser:)])
		{
			[sharedDelegate didGetUser:user];
		}
	}
	else
	{
		[self _getUserFailure];
	}

}

+ (void)_getUserFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetUser)])
	{
		[sharedDelegate didFailGetUser];
	}
}

- (void)_getFriendsSuccess:(OFPaginatedSeries*)loadedUsers
{	
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetFriends:OFUser:)])
	{
		[sharedDelegate didGetFriends:[OFUser _extractUsersFromPaginatedSeries:loadedUsers] OFUser:self];
	}
}

- (void)_getFriendsFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetFriendsOFUser:)])
	{
		[sharedDelegate didFailGetFriendsOFUser:self];
	}
}

- (void)_getFriendsWithThisApplicationSuccess:(OFPaginatedSeries*)loadedUsers
{	
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetFriendsWithThisApplication:OFUser:)])
	{
		[sharedDelegate didGetFriendsWithThisApplication:[OFUser _extractUsersFromPaginatedSeries:loadedUsers] OFUser:self];
	}
}

- (void)_getFriendsWithThisApplicationFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetFriendsWithThisApplicationOFUser:)])
	{
		[sharedDelegate didFailGetFriendsWithThisApplicationOFUser:self];
	}
}


+ (NSArray*)_extractUsersFromPaginatedSeries:(OFPaginatedSeries*)paginatedSeries
{
	NSArray* tableDescOfUsers = [[[NSArray alloc] initWithArray:paginatedSeries.objects] autorelease];
	
	NSMutableArray* users = [[[NSMutableArray alloc] initWithCapacity:32] autorelease];
	for(uint i = 0; i < [tableDescOfUsers count]; i++)
	{
		OFTableSectionDescription* tableSec = [tableDescOfUsers objectAtIndex:i];
		if([tableSec.title isEqualToString:@"Online Now"])
		{
			continue;
		}
		
		[users addObjectsFromArray:tableSec.page.objects];
	}
	
	return users;
}

- (id)initWithLocalSQL:(OFSqlQuery*)queryRow
{
	self = [super init];
	if (self != nil)
	{	
		resourceId = [[queryRow stringValue:@"id"] retain];
		name = [[queryRow stringValue:@"name"] retain];
		profilePictureUrl = [[queryRow stringValue:@"profile_picture_url"] retain];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self != nil)
	{
		resourceId = [[aDecoder decodeObjectForKey:@"resourceId"] retain];
		name = [[aDecoder decodeObjectForKey:@"name"] retain];
		profilePictureUrl = [[aDecoder decodeObjectForKey:@"profilePictureUrl"] retain];
		profilePictureSource = [[aDecoder decodeObjectForKey:@"profilePictureSource"] retain];
		usesFacebookProfilePicture = [(NSNumber*)[aDecoder decodeObjectForKey:@"usesFacebookProfilePicture"] boolValue];
		lastPlayedGameId = [[aDecoder decodeObjectForKey:@"lastPlayedGameId"] retain];
		lastPlayedGameName = [[aDecoder decodeObjectForKey:@"lastPlayedGameName"] retain];
		followsLocalUser = [(NSNumber*)[aDecoder decodeObjectForKey:@"followsLocalUser"] boolValue];
		followedByLocalUser = [(NSNumber*)[aDecoder decodeObjectForKey:@"followedByLocalUser"] boolValue];
		gamerScore = [(NSNumber*)[aDecoder decodeObjectForKey:@"gamerScore"] intValue];
		online = [(NSNumber*)[aDecoder decodeObjectForKey:@"online"] boolValue];
		latitude = [(NSNumber*)[aDecoder decodeObjectForKey:@"latitude"] doubleValue];
		longitude = [(NSNumber*)[aDecoder decodeObjectForKey:@"longitude"] doubleValue];
		
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:resourceId forKey:@"resourceId"];
	[aCoder encodeObject:name forKey:@"name"];
	[aCoder encodeObject:profilePictureUrl forKey:@"profilePictureUrl"];
	[aCoder encodeObject:profilePictureSource forKey:@"profilePictureSource"];
	[aCoder encodeObject:[NSNumber numberWithBool:usesFacebookProfilePicture] forKey:@"usesFacebookProfilePicture"];
	[aCoder encodeObject:lastPlayedGameId forKey:@"lastPlayedGameId"];
	[aCoder encodeObject:lastPlayedGameName forKey:@"lastPlayedGameName"];
	[aCoder encodeObject:[NSNumber numberWithBool:followsLocalUser] forKey:@"followsLocalUser"];
	[aCoder encodeObject:[NSNumber numberWithBool:followedByLocalUser] forKey:@"followedByLocalUser"];
	[aCoder encodeObject:[NSNumber numberWithInt:gamerScore] forKey:@"gamerScore"];
	[aCoder encodeObject:[NSNumber numberWithBool:online] forKey:@"online"];
	[aCoder encodeObject:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
	[aCoder encodeObject:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
	
}

- (void)setName:(NSString*)value
{
	OFSafeRelease(name);
	name = [value retain];
}

- (void)setProfilePictureUrl:(NSString*)value
{
	OFSafeRelease(profilePictureUrl);
	if (![value isEqualToString:@""])
	{
		profilePictureUrl = [value retain];
	}
}

- (void)setProfilePictureSource:(NSString*)value
{
	OFSafeRelease(profilePictureSource);
	if (![value isEqualToString:@""])
	{
		profilePictureSource = [value retain];
	}
}

- (void)setUsesFacebookProfilePicture:(NSString*)value
{
	usesFacebookProfilePicture = [value boolValue];
}

- (NSString*)getUsesFacebookProfilePictureAsString
{
	return [NSString stringWithFormat:@"%u", (uint)usesFacebookProfilePicture];
}

- (NSString*)getFollowsLocalUserAsString
{
	return [NSString stringWithFormat:@"%u", (uint)followsLocalUser];
}

- (NSString*)getFollowedByLocalUserAsString
{
	return [NSString stringWithFormat:@"%u", (uint)followedByLocalUser];
}

- (NSString*)getOnlineAsString
{
	return [NSString stringWithFormat:@"%u", (uint)online];
}

- (NSString*)getGamerScoreAsString
{
	return [NSString stringWithFormat:@"%u", (uint)gamerScore];
}

- (void)setLastPlayedGameId:(NSString*)value
{
	OFSafeRelease(lastPlayedGameId);
	lastPlayedGameId = [value retain];
}

- (void)setLastPlayedGameName:(NSString*)value
{
	OFSafeRelease(lastPlayedGameName);
	lastPlayedGameName = [value retain];
}

- (void)setGamerScore:(NSString*)value
{
	gamerScore = [value intValue];
}

- (void)setFollowsLocalUserAsString:(NSString*)value
{
	followsLocalUser = [value boolValue];
}

- (void)setFollowedByLocalUserAsString:(NSString*)value
{
	followedByLocalUser = [value boolValue];
}

- (void)setOnlineAsString:(NSString*)value
{
	online = [value boolValue];
}

- (void) setLatitude:(NSString*)value
{
	latitude = [value doubleValue];
}

- (NSString*)getLatitudeAsString
{
	return [NSString stringWithFormat:@"%f", latitude];
}

- (void) setLongitude:(NSString*)value
{
	longitude = [value doubleValue];
}

- (NSString*)getLongitudeAsString
{
	return [NSString stringWithFormat:@"%f", longitude];
}

- (BOOL)online
{
	//The current playes online var doesn't stay in sync, but Open Feint keeps track if the current user is online.
	if([self isLocalUser])
	{
		return [OpenFeint isOnline];
	}
	else
	{
		return online;
	}

}

+ (id)invalidUser
{
	OFUser* user = [[[OFUser alloc] init] autorelease];
	user->resourceId = @"0";
	user->name = OFLOCALSTRING(@"Not Logged In");
	user->lastPlayedGameName = OFLOCALSTRING(@"OpenFeint Game");
	
	return user;
}


+ (NSString*)getResourceName
{
	return @"user";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"user_discovered";
}

- (BOOL)isLocalUser
{
	return [self.resourceId isEqualToString:[OpenFeint lastLoggedInUserId]] || [self.resourceId isEqualToString:@"0"];
}

#if FORCE_ONLINE
- (BOOL)online
{
    return YES;
}
#endif

- (NSString*)userId
{
	return resourceId;
}

- (void)adjustGamerscore:(int)gamerscoreAdjustment
{
	gamerScore += gamerscoreAdjustment;
}

- (void)changeProfilePictureUrl:(NSString*)url facebook:(BOOL)isFacebook twitter:(BOOL)isTwitter uploaded:(BOOL)isUploaded
{
	[self setProfilePictureUrl:url];
	usesFacebookProfilePicture = isFacebook;
	
	if (isFacebook)
	{
		[self setProfilePictureSource:@"FbconnectCredential"];
	}
	else if (isTwitter)
	{
		[self setProfilePictureSource:@"TwitterCredential"];
	}
    else if (isUploaded)
    {
        [self setProfilePictureSource:@"Upload"];
    }
	else
	{
		[self setProfilePictureSource:nil];
	}
}

- (void)setFollowedByLocalUser:(BOOL)value
{
	followedByLocalUser = value;
}

- (void) dealloc
{
	OFSafeRelease(name);
	OFSafeRelease(profilePictureUrl);
	OFSafeRelease(profilePictureSource);
	OFSafeRelease(lastPlayedGameName);
	OFSafeRelease(lastPlayedGameId);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setName:) getter:@selector(name)], @"name",
[OFResourceField fieldSetter:@selector(setProfilePictureUrl:) getter:@selector(profilePictureUrl)], @"profile_picture_url",
[OFResourceField fieldSetter:@selector(setProfilePictureSource:) getter:@selector(profilePictureSource)], @"profile_picture_source",
[OFResourceField fieldSetter:@selector(setUsesFacebookProfilePicture:) getter:@selector(getUsesFacebookProfilePictureAsString)], @"uses_facebook_profile_picture",
[OFResourceField fieldSetter:@selector(setLastPlayedGameId:) getter:@selector(lastPlayedGameId)], @"last_played_game_id",
[OFResourceField fieldSetter:@selector(setLastPlayedGameName:) getter:@selector(lastPlayedGameName)], @"last_played_game_name",
[OFResourceField fieldSetter:@selector(setGamerScore:) getter:@selector(getGamerScoreAsString)], @"gamer_score",
[OFResourceField fieldSetter:@selector(setFollowsLocalUserAsString:) getter:@selector(getFollowsLocalUserAsString)], @"following_local_user",
[OFResourceField fieldSetter:@selector(setFollowedByLocalUserAsString:) getter:@selector(getFollowedByLocalUserAsString)], @"followed_by_local_user",
[OFResourceField fieldSetter:@selector(setOnlineAsString:) getter:@selector(getOnlineAsString)], @"online",
[OFResourceField fieldSetter:@selector(setLatitude:) getter:@selector(getLatitudeAsString)], @"lat",
[OFResourceField fieldSetter:@selector(setLongitude:) getter:@selector(getLongitudeAsString)], @"lng",
        nil] retain];
    }
    return sDataDictionary;
}
@end
