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

#import "OFBootstrapService.h"
#import "OFQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFBootstrap.h"
#import "OFPoller.h"
#import "OpenFeint+Private.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+UserStats.h"
#import "OFProvider.h"
#import "OFOfflineService.h"
#import "OFGameProfilePageInfo.h"
#import "OFPresenceService.h"
#import "IPhoneOSIntrospection.h"
#import "OFSettings.h"
#import "OFInviteService.h"
#import "OpenFeint+AddOns.h"
#import "OpenFeint+NSNotification.h"
#import "OpenFeint+NSNotification+Private.h"
#import "OFResource+ObjC.h"
#import "OpenFeint+EventLog.h"
#import "OFDependencies.h"

@interface OFOfflineService ()
+ (void) shareKnownResourceMap:(NSMutableDictionary*)namedResourceMap;
@end

@interface OFBootstrapService ()
@property (nonatomic, assign, readwrite) BOOL bootstrapInProgress;
@property (nonatomic, assign, readwrite) BOOL bootstrapIsForNewUser;
@property (nonatomic, retain) OFInvocation* success;
@property (nonatomic, retain) OFInvocation* failure;
@end

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFBootstrapService);

@implementation OFBootstrapService

@synthesize bootstrapInProgress;
@synthesize bootstrapIsForNewUser;
@synthesize success = mSuccess;
@synthesize failure = mFailure;

OPENFEINT_DEFINE_SERVICE(OFBootstrapService);

- (id) init
{
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

- (void)dealloc
{
    self.success = nil;
    self.failure = nil;
	[super dealloc];
}

- (void)registerPolledResources:(OFPoller*)poller
{
}

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFBootstrap class] forKey:[OFBootstrap getResourceName]];
	[OFOfflineService shareKnownResourceMap:namedResourceMap];
}

+ (BOOL) bootstrapInProgress
{
	return [[OFBootstrapService sharedInstance] bootstrapInProgress];
}

+ (void)doBootstrapWithNewAccount:(BOOL)createNewAccount userId:(NSString*)userId onSucceededLoggingIn:(OFInvocation*)onSuccess onFailedLoggingIn:(OFInvocation*)onFailure
{
    OFBootstrapService* instance = [OFBootstrapService sharedInstance];
    if ([instance bootstrapInProgress] || [OFProvider willSilentlyDiscardAction])
	{
        [onFailure invokeWith:nil];
		return;
	}
	
    [instance setBootstrapInProgress:YES];
    [instance setBootstrapIsForNewUser:createNewAccount];
    
    instance.success = onSuccess;
    instance.failure = onFailure;

	OFQueryStringWriter* params = [OFQueryStringWriter writer];    
	[params ioNSStringToKey:@"udid" object:[OpenFeint uniqueDeviceId]];
	
	// specificUserId is the same as userId (used in the bootstrap notification below),
	// with the exception being that if userId is @"0", specificUserId will be nil.  I don't
	// want to go through other consumers of userId and make sure their behavior is the
	// same whether they get @"0" or nil.
	NSString* specificUserId = nil;
	
	if (userId && ![userId isEqualToString:@"0"])
	{
		specificUserId = userId;
		
		[params ioNSStringToKey:@"user_id" object:userId];
	}

	if (createNewAccount)
	{
		[params ioBoolToKey:@"create_new_account" value:createNewAccount];
	}

	[params ioNSStringToKey:@"device_hardware_version" object:getHardwareVersion()];
	[params ioNSStringToKey:@"device_os_version" object:[[OFSettings instance] clientDeviceSystemVersion]];
	
	//Get any params needed for offline
	[OFOfflineService getBootstrapCallParams:params userId:userId];
	//Send up the latest user stats
	[OpenFeint getUserStatsParams:params];
		
	[OpenFeint postBootstrapBegan:specificUserId];
	
	[[self sharedInstance]
		_performAction:@"bootstrap.xml"
		withParameterArray:params.getQueryParametersAsMPURLRequestParameters
		withHttpMethod:@"POST"
		withSuccessInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(bootstrapSucceededOnBootstrapThread:) thread:[[OpenFeint provider] requestThread]]
		withFailureInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(bootstrapFailed:)]
		withRequestType:OFActionRequestSilent
		withNotice:nil 
		requiringAuthentication:NO];
}

- (void)bootstrapSucceededOnBootstrapThread:(OFPaginatedSeries*)resources
{
	if([resources count] == 0)
	{
		[self performSelectorOnMainThread:@selector(bootstrapFailed:) withObject:nil waitUntilDone:NO];
		return;
	}
	
	OFBootstrap* bootstrap = (OFBootstrap*)[resources objectAtIndex:0];

    if([OpenFeint sharedInstance].mForceUserCheckOnBootstrap) {
        [OpenFeint sharedInstance].mForceUserCheckOnBootstrap = NO;
        id delegate = [OpenFeint getDelegate];
        if([delegate respondsToSelector:@selector(userAttemptingToLogin:)]) {
            if(![delegate userAttemptingToLogin:bootstrap.user]) {
				[[OpenFeint class] performSelectorOnMainThread:@selector(abortBootstrap) withObject:nil waitUntilDone:NO];
				[self performSelectorOnMainThread:@selector(bootstrapFailed:) withObject:nil waitUntilDone:NO];
				return;
			}
        }
    }
	
	[OpenFeint storePollingFrequencyDefault:bootstrap.pollingFrequencyDefault];
	[OpenFeint storePollingFrequencyInChat:bootstrap.pollingFrequencyInChat];
	[[OpenFeint provider] setAccessToken:bootstrap.accessToken andSecret:bootstrap.accessTokenSecret];
	[OpenFeint setLoggedInUserHasSetName:bootstrap.loggedInUserHasSetName];
	[OpenFeint setLoggedInUserHadFriendsOnBootup:bootstrap.loggedInUserHadFriendsOnBootup];
	
	[OpenFeint setLoggedInUserHasHttpBasicCredential:bootstrap.loggedInUserHasHttpBasicCredential];
	[OpenFeint setLoggedInUserHasFbconnectCredential:bootstrap.loggedInUserHasFbconnectCredential];
	[OpenFeint setLoggedInUserHasTwitterCredential:bootstrap.loggedInUserHasTwitterCredential];
	
	[OpenFeint setLoggedInUserHasNonDeviceCredential: bootstrap.loggedInUserHasHttpBasicCredential 
													  || bootstrap.loggedInUserHasFbconnectCredential 
													  || bootstrap.loggedInUserHasTwitterCredential];
	
	[OpenFeint setLoggedInUserIsNewUser:bootstrap.loggedInUserIsNewUser];
    
	[OpenFeint setClientApplicationId:bootstrap.clientApplicationId];
	[OpenFeint setClientApplicationIconUrl:bootstrap.clientApplicationIconUrl];
	[OpenFeint setUnviewedChallengesCount:bootstrap.unviewedChallengesCount];
	[OpenFeint setPendingFriendsCount:bootstrap.pendingFriendsCount];
	[OpenFeint setLocalGameProfileInfo:bootstrap.gameProfilePageInfo];
	[OpenFeint setLocalUser:bootstrap.user];
	[OpenFeint setSuggestionsForumId:bootstrap.suggestionsForumId];
	[OpenFeint setInitialDashboardScreen:bootstrap.initialDashboardScreen];
    [OpenFeint setInitialDashboardModalContentURL:bootstrap.initialDashboardModalContentURL];
	[OpenFeint setLoggedInUserSharesOnlineStatus:bootstrap.initializePresenceService];

	[OpenFeint setUnreadIMCount:bootstrap.imsUnreadCount andUnreadPostCount:bootstrap.subscribedThreadsUnreadCount andUnreadInviteCount:bootstrap.invitesUnreadCount];
		
	[OpenFeint setUserDistanceUnit: (bootstrap.loggedInUserHasShareLocationEnabled ? kDistanceUnitMiles : kDistanceUnitNotAllowed)];
	
	[[OFPresenceService sharedInstance] setPresenceQueue:bootstrap.presenceQueue];
	[[OFPresenceService sharedInstance] setPipeHttpOverPresence:bootstrap.pipeHttpOverPresenceService];

	if (bootstrap.initializePresenceService)
	{
		[[OFPresenceService sharedInstance] connect];
	}

	[OpenFeint resetUserStats];
	[OpenFeint incrementNumberOfOnlineGameSessions]; //Will get updated on the server the next bootstrap.

	if([resources count] > 1)
	{
		//sync data from host
		OFBootstrap* bootstrap = (OFBootstrap*)[resources objectAtIndex:0];
		OFOffline* offline = (OFOffline*)[resources objectAtIndex:1];
		[OFOfflineService syncOfflineData:offline bootStrap:bootstrap];
	}

    // notifications
    if ([self bootstrapIsForNewUser]) {
        [[OpenFeint eventLog] logEventWithActionKey:@"new_user" logName:@"client_sdk" parameters:nil];
        [OpenFeint postUserCreated];
    } else {
        [OpenFeint postExistingUserLoggedIn];
    }

	[self performSelectorOnMainThread:@selector(bootstrapSucceeded:) withObject:resources waitUntilDone:NO];
}

- (void)bootstrapSucceeded:(OFPaginatedSeries *)resources
{
	[OpenFeint notifyAddOnsUserLoggedIn];
    bootstrapInProgress = NO;
	[OpenFeint postBootstrapSucceeded];	
    [self.success invokeWith:(NSObject*) resources];
    self.success = nil;
    self.failure = nil;
}

- (void)bootstrapFailed:(MPOAuthAPIRequestLoader*)loader
{
	bootstrapInProgress = NO;
	[OpenFeint postBootstrapFailed];
    [self.failure invokeWith:loader];
    self.success = nil;
    self.failure = nil;
}

@end
