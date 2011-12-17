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
#import "OFBootstrap.h"
#import "OFBootstrapService.h"
#import "OFBootstrapService.h"
#import "OFGameProfilePageInfo.h"
#import "OFUser.h"
#import "OFDependencies.h"

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

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
			[OFResourceField nestedResourceSetter:@selector(setGameProfilePageInfo:) getter:nil klass:[OFGameProfilePageInfo class]], @"game_profile_page_info",
			[OFResourceField nestedResourceSetter:@selector(setUser:) getter:nil klass:[OFUser class]], @"user",
			[OFResourceField fieldSetter:@selector(setMinimumOpenFeintVersionSupported:)], @"minimum_openfeint_version_supported",
			[OFResourceField fieldSetter:@selector(setPollingFrequencyInChat:)], @"polling_frequency_in_chat",
			[OFResourceField fieldSetter:@selector(setPollingFrequencyDefault:)], @"polling_frequency_default",
			[OFResourceField fieldSetter:@selector(setLoggedInUserHasSetName:)], @"logged_in_user_has_set_name",
			[OFResourceField fieldSetter:@selector(setLoggedInUserHadFriendsOnBootup:)], @"logged_in_user_has_friends",
			[OFResourceField fieldSetter:@selector(setLoggedInUserIsNewUser:)], @"logged_in_user_is_new_user",
			[OFResourceField fieldSetter:@selector(setAccessToken:)], @"access_token",
			[OFResourceField fieldSetter:@selector(setAccessTokenSecret:)], @"access_token_secret",
			[OFResourceField fieldSetter:@selector(setLoggedInUserHasHttpBasicCredential:)], @"logged_in_user_has_http_basic_credential",
			[OFResourceField fieldSetter:@selector(setLoggedInUserHasFbconnectCredential:)], @"logged_in_user_has_fbconnect_credential",
			[OFResourceField fieldSetter:@selector(setLoggedInUserHasTwitterCredential:)], @"logged_in_user_has_twitter_credential",
			[OFResourceField fieldSetter:@selector(setClientApplicationId:)], @"client_application_id",
			[OFResourceField fieldSetter:@selector(setClientApplicationIconUrl:)], @"client_application_icon_url",
			[OFResourceField fieldSetter:@selector(setUnviewedChallengesCount:)], @"unviewed_challenges_count",
			[OFResourceField fieldSetter:@selector(setPendingFriendsCount:)], @"pending_friends_count",
			[OFResourceField fieldSetter:@selector(setImsUnreadCount:)], @"ims_unread_count",
			[OFResourceField fieldSetter:@selector(setSubscribedThreadsUnreadCount:)], @"subscribed_threads_unread_count",
			[OFResourceField fieldSetter:@selector(setInvitesUnreadCount:)], @"invites_unread_count",
			[OFResourceField fieldSetter:@selector(setUnfulfilledInvitesCount:)], @"unfulfilled_invites_count",
			[OFResourceField fieldSetter:@selector(setSuggestionsForumId:)], @"topic_app_suggestions_id",
			[OFResourceField fieldSetter:@selector(setInitialDashboardScreen:)], @"initial_dashboard_screen",
			[OFResourceField fieldSetter:@selector(setInitialDashboardModalContentURL:)], @"initial_dashboard_modal_content_url",
			[OFResourceField fieldSetter:@selector(setInitializePresenceService:)], @"initialize_presence_service",
			[OFResourceField fieldSetter:@selector(setPipeHttpOverPresenceService:)], @"pipe_http_over_presence_service",
			[OFResourceField fieldSetter:@selector(setPresenceQueue:)], @"presence_queue",
			[OFResourceField fieldSetter:@selector(setLoggedInUserHasShareLocationEnabled:)], @"logged_in_user_has_share_location_enabled",
			nil] retain];
    }
    return sDataDictionary;
}
@end
