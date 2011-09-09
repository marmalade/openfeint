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

#import "OFDependencies.h"
#import "OFBootstrap.h"
#import "OFBootstrapService.h"
#import "OFResourceDataMap.h"
#import "OFBootstrapService.h"
#import "OFGameProfilePageInfo.h"
#import "OFUser.h"

@implementation OFBootstrap

@synthesize minimumOpenFeintVersionSupported;
@synthesize pollingFrequencyInChat;
@synthesize pollingFrequencyDefault;
@synthesize loggedInUserHasSetName;
@synthesize loggedInUserIsNewUser;
@synthesize gameProfilePageInfo;
@synthesize user;
@synthesize accessToken;
@synthesize accessTokenSecret;
@synthesize loggedInUserHasNonDeviceCredential;

@synthesize loggedInUserHasHttpBasicCredential;
@synthesize loggedInUserHasFbconnectCredential;
@synthesize loggedInUserHasTwitterCredential;

@synthesize clientApplicationId;
@synthesize clientApplicationIconUrl;
@synthesize loggedInUserHadFriendsOnBootup;
@synthesize unviewedChallengesCount;
@synthesize pendingFriendsCount;

@synthesize imsUnreadCount;
@synthesize subscribedThreadsUnreadCount;
@synthesize invitesUnreadCount;
@synthesize unfulfilledInvitesCount;

@synthesize suggestionsForumId;

@synthesize initialDashboardScreen;
@synthesize initialDashboardModalContentURL;

@synthesize initializePresenceService;
@synthesize pipeHttpOverPresenceService;
@synthesize presenceQueue;
@synthesize loggedInUserHasShareLocationEnabled;

//#define TEST_NAG_SCREEN

#ifdef TEST_NAG_SCREEN
// To test the nag screen  and make it appear on launch of dashboard, define TEST_NAG_SCREEN and set one of these strings to the static below.
//  @"/web_views/dashboard_modals/complete_account"		
//  @"/web_views/dashboard_modals/set_name"
//  @"/web_views/dashboard_modals/import_friends"
static NSString* TEST_NAG_SCREEN_URL = @"/web_views/dashboard_modals/complete_account";
#endif

- (id)init
{
	self = [super init];
	if(self)
	{
#ifdef TEST_NAG_SCREEN
		initialDashboardModalContentURL = TEST_NAG_SCREEN_URL;
#endif
	}
	return self;
}

- (void)setMinimumOpenFeintVersionSupported:(NSString*)value
{
	minimumOpenFeintVersionSupported = [value integerValue];
}

- (void)setPollingFrequencyInChat:(NSString*)value
{
	pollingFrequencyInChat = [value integerValue];
}

- (void)setPollingFrequencyDefault:(NSString*)value
{
	pollingFrequencyDefault = [value integerValue];
}

- (void)setGameProfilePageInfo:(OFGameProfilePageInfo*)value
{
	OFSafeRelease(gameProfilePageInfo);
	gameProfilePageInfo = [value retain];
}

- (void)setUser:(OFUser*)value
{
	OFSafeRelease(user);
	user = [value retain];
}

- (void)setLoggedInUserHadFriendsOnBootup:(NSString*)value
{
	loggedInUserHadFriendsOnBootup = [value boolValue];
}

- (void)setLoggedInUserHasSetName:(NSString*)value
{
	loggedInUserHasSetName = [value boolValue];
}

- (void)setLoggedInUserHasNonDeviceCredential:(NSString*)value
{
	loggedInUserHasNonDeviceCredential = [value boolValue];
}

- (void)setLoggedInUserHasHttpBasicCredential:(NSString*)value
{
	loggedInUserHasHttpBasicCredential = [value boolValue];
}

- (void)setLoggedInUserHasFbconnectCredential:(NSString*)value
{
	loggedInUserHasFbconnectCredential = [value boolValue];
}

- (void)setLoggedInUserHasTwitterCredential:(NSString*)value
{
	loggedInUserHasTwitterCredential = [value boolValue];
}

- (void)setLoggedInUserIsNewUser:(NSString*)value
{
	loggedInUserIsNewUser = [value boolValue];
}

- (void)setAccessTokenSecret:(NSString*)value
{
	OFSafeRelease(accessTokenSecret);
	accessTokenSecret = [value retain];
}

- (void)setAccessToken:(NSString*)value
{
	OFSafeRelease(accessToken);
	accessToken = [value retain];
}

- (void)setPresenceQueue:(NSString*)value
{
	OFSafeRelease(presenceQueue);
	presenceQueue = [value retain];
}

- (void)setInitializePresenceService:(NSString*)value
{
	initializePresenceService = [value boolValue];
}

- (void)setPipeHttpOverPresenceService:(NSString*)value
{
	pipeHttpOverPresenceService = [value boolValue];
}

- (void)setClientApplicationId:(NSString*)value
{
	OFSafeRelease(clientApplicationId);
	clientApplicationId = [value retain];
}

- (void)setClientApplicationIconUrl:(NSString*)value
{
	OFSafeRelease(clientApplicationIconUrl);
	clientApplicationIconUrl = [value retain];
}

- (void)setInitialDashboardScreen:(NSString*)value
{
	OFSafeRelease(initialDashboardScreen);
	initialDashboardScreen = [value retain];
}

- (void)setInitialDashboardModalContentURL:(NSString*)value
{
#ifndef TEST_NAG_SCREEN
	OFSafeRelease(initialDashboardModalContentURL);
	initialDashboardModalContentURL = [value retain];
#endif
}

// Uncomment this to force a nag screen to show up
//- (NSString*)initialDashboardModalContentURL
//{
//    return @"/web_views/dashboard_modals/import_friends";
//}

- (void)setUnviewedChallengesCount:(NSString*)value
{
	unviewedChallengesCount = [value integerValue];
}

- (void)setPendingFriendsCount:(NSString*)value
{
	pendingFriendsCount = [value integerValue];
}

- (void)setImsUnreadCount:(NSString*)value
{
	imsUnreadCount = [value integerValue];
}

- (void)setSubscribedThreadsUnreadCount:(NSString*)value
{
	subscribedThreadsUnreadCount = [value integerValue];
}

- (void)setInvitesUnreadCount:(NSString*)value
{
	invitesUnreadCount = [value integerValue];
}

- (void)setUnfulfilledInvitesCount:(NSString*)value
{
	unfulfilledInvitesCount = [value integerValue];
}

- (void)setSuggestionsForumId:(NSString*)value
{
	OFSafeRelease(suggestionsForumId);
	suggestionsForumId = [value retain];
}

- (void)setLoggedInUserHasShareLocationEnabled:(NSString*)value
{
	loggedInUserHasShareLocationEnabled = [value boolValue];
}

+ (OFResourceDataMap*)getDataMap
{
	static OFPointer<OFResourceDataMap> dataMap;
	
	if(dataMap.get() == NULL)
	{
		dataMap = new OFResourceDataMap;
		dataMap->addField(@"minimum_openfeint_version_supported",			@selector(setMinimumOpenFeintVersionSupported:));	
		dataMap->addField(@"polling_frequency_in_chat",						@selector(setPollingFrequencyInChat:));
		dataMap->addField(@"polling_frequency_default",						@selector(setPollingFrequencyDefault:));
		dataMap->addNestedResourceField(@"game_profile_page_info",			@selector(setGameProfilePageInfo:), nil, [OFGameProfilePageInfo class]);
		dataMap->addNestedResourceField(@"user",							@selector(setUser:), nil, [OFUser class]);
		dataMap->addField(@"logged_in_user_has_set_name",					@selector(setLoggedInUserHasSetName:));
		dataMap->addField(@"logged_in_user_has_friends",					@selector(setLoggedInUserHadFriendsOnBootup:));
		dataMap->addField(@"logged_in_user_is_new_user",					@selector(setLoggedInUserIsNewUser:));
		dataMap->addField(@"access_token",									@selector(setAccessToken:));
		dataMap->addField(@"access_token_secret",							@selector(setAccessTokenSecret:));		

		dataMap->addField(@"logged_in_user_has_http_basic_credential",		@selector(setLoggedInUserHasHttpBasicCredential:));	
		dataMap->addField(@"logged_in_user_has_fbconnect_credential",		@selector(setLoggedInUserHasFbconnectCredential:));	
		dataMap->addField(@"logged_in_user_has_twitter_credential",         @selector(setLoggedInUserHasTwitterCredential:));	

		dataMap->addField(@"client_application_id",							@selector(setClientApplicationId:));
		dataMap->addField(@"client_application_icon_url",					@selector(setClientApplicationIconUrl:));
		dataMap->addField(@"unviewed_challenges_count",						@selector(setUnviewedChallengesCount:));
		dataMap->addField(@"pending_friends_count",						    @selector(setPendingFriendsCount:));

		dataMap->addField(@"ims_unread_count",								@selector(setImsUnreadCount:));
		dataMap->addField(@"subscribed_threads_unread_count",				@selector(setSubscribedThreadsUnreadCount:));
		dataMap->addField(@"invites_unread_count",							@selector(setInvitesUnreadCount:));
		dataMap->addField(@"unfulfilled_invites_count",						@selector(setUnfulfilledInvitesCount:));
		
		dataMap->addField(@"topic_app_suggestions_id",						@selector(setSuggestionsForumId:));
		dataMap->addField(@"initial_dashboard_screen",						@selector(setInitialDashboardScreen:));
        dataMap->addField(@"initial_dashboard_modal_content_url",			@selector(setInitialDashboardModalContentURL:));
		
		dataMap->addField(@"initialize_presence_service",					@selector(setInitializePresenceService:));
		dataMap->addField(@"pipe_http_over_presence_service",				@selector(setPipeHttpOverPresenceService:));
		dataMap->addField(@"presence_queue",								@selector(setPresenceQueue:));
		dataMap->addField(@"logged_in_user_has_share_location_enabled",		@selector(setLoggedInUserHasShareLocationEnabled:));
	}
	
	return dataMap.get();
}

+ (NSString*)getResourceName
{
	return @"bootstrap";
}

- (void)dealloc
{
	OFSafeRelease(accessToken);
	OFSafeRelease(accessTokenSecret);
	OFSafeRelease(clientApplicationId);
	OFSafeRelease(clientApplicationIconUrl);
	OFSafeRelease(gameProfilePageInfo);
	OFSafeRelease(user);
	OFSafeRelease(suggestionsForumId);
	OFSafeRelease(initialDashboardScreen);
    OFSafeRelease(initialDashboardModalContentURL);
	OFSafeRelease(presenceQueue);
	[super dealloc];
}

@end
