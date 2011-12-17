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


#import "OFFriendsService.h"
#import "OFQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFUser.h"
#import "OFGamePlayer.h"
#import "OFUsersCredential.h"
#import "OFPaginatedSeries.h"
#import "OpenFeint+UserOptions.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFFriendsService)

@implementation OFFriendsService

OPENFEINT_DEFINE_SERVICE(OFFriendsService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFUser class] forKey:[OFUser getResourceName]];
	[namedResourceMap setObject:[OFGamePlayer class] forKey:[OFGamePlayer getResourceName]];
	[namedResourceMap setObject:[OFUsersCredential class] forKey:[OFUsersCredential getResourceName]];
	
}

+ (OFRequestHandle*)getUsersFollowedByUser:(NSString*)userId 
                                    params:(OFQueryStringWriter*)params 
                       onSuccessInvocation:(OFInvocation*)onSuccess 
                       onFailureInvocation:(OFInvocation*)onFailure
{
	
	[params ioNSStringToKey:@"user_id" object:( userId ? userId : @"me")];
	[params ioNSStringToKey:@"scope" object:@"people-of-interest"];
	
	return [[self sharedInstance] 
	 getAction:@"users.xml"
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:onSuccess
	 withFailureInvocation:onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Friends")]];
}


+ (void)getUsersFollowedByLocalUser:(NSInteger)pageIndex onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFFriendsService getUsersFollowedByUser:nil pageIndex:pageIndex onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

// Gets the list of friends that are invitable to this app.  Currently: friends who don't have this device credential and who don't have the app already.
+ (void)getInvitableFriends:(NSInteger)pageIndex onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];

	[[self sharedInstance]
	 getAction:@"invites/new/invitable_friends"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (OFRequestHandle*)getAllUsersFollowedByUserAlphabetical:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL alphabetical = YES;
	[params ioBoolToKey:@"full_alphabetical_list" value:alphabetical];
	return [OFFriendsService getUsersFollowedByUser:userId params:params onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void)getAllUsersFollowedByLocalUserAlphabeticalInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

{
	[OFFriendsService getAllUsersFollowedByUserAlphabetical:nil onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*)getAllUsersWithApp:(NSString*)applicationId followedByUser:(NSString*)userId alphabeticalOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL alphabetical = YES;
	[params ioBoolToKey:@"full_alphabetical_list" value:alphabetical];
	[params ioNSStringToKey:@"with_client_application" object:( ([applicationId length] > 0) ? applicationId : [OpenFeint clientApplicationId])];
	[params ioNSStringToKey:@"not_sectioned" object:@"yes"];
	return [OFFriendsService getUsersFollowedByUser:userId params:params onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void)getUsersFollowedByUser:(NSString*)userId pageIndex:(NSInteger)pageIndex onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	[OFFriendsService getUsersFollowedByUser:userId params:params onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void)getUsersWithAppFollowedByLocalUser:(NSString*)applicationId pageIndex:(NSInteger)pageIndex onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

{
	[OFFriendsService getUsersWithAppFollowedByUser:applicationId followedByUser:nil pageIndex:pageIndex onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void)getUsersWithAppFollowedByUser:(NSString*)applicationId followedByUser:(NSString*)userId pageIndex:(NSInteger)pageIndex onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioNSStringToKey:@"user_id" object:( userId ? userId : @"me")];
	[params ioNSStringToKey:@"scope" object:@"people-of-interest"];

	[params ioNSStringToKey:@"with_client_application" object:( applicationId ? applicationId : [OpenFeint clientApplicationId])];
	
	
	[[self sharedInstance] 
	 getAction:@"users.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Friends")]];
}

+ (void)getUsersFollowingLocalUser:(NSInteger)pageIndex 
						 excludeUsersFollowedByTarget:(BOOL)excludeUsersFollowedByTarget
               onSuccessInvocation:(OFInvocation*)_onSuccess 
               onFailureInvocation:(OFInvocation*)_onFailure;

{
	[OFFriendsService getUsersFollowingUser:nil 
			   excludeUsersFollowedByTarget:excludeUsersFollowedByTarget 
								  pageIndex:pageIndex 
                        onSuccessInvocation:_onSuccess 
                        onFailureInvocation:_onFailure];
}

+ (void)getUsersFollowingUser:(NSString*)userId 
 excludeUsersFollowedByTarget:(BOOL)excludeUsersFollowedByTarget
					pageIndex:(NSInteger)pageIndex 
          onSuccessInvocation:(OFInvocation*)_onSuccess 
          onFailureInvocation:(OFInvocation*)_onFailure;

{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	if (userId)
	{
		[params ioNSStringToKey:@"user_id" object:userId];
	}
	[params ioNSStringToKey:@"scope" object:@"followers"];
	if (excludeUsersFollowedByTarget)
	{
		BOOL exclude = YES;
		[params ioBoolToKey:@"im-not-following" value:exclude];
	}
	
	[[self sharedInstance] 
	 getAction:@"users.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Followers")]];
}
	
+ (OFRequestHandle*)makeLocalUserFollow:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
{	
	return [[self sharedInstance] 
	 postAction:[NSString stringWithFormat:@"users/%@/following.xml", userId]
	 withParameterArray:nil
	 withSuccessInvocation:_onSuccess
	 withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Followed")]];
}

+ (OFRequestHandle*)makeLocalUserStopFollowing:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
{	
	return [[self sharedInstance] 
	 deleteAction:[NSString stringWithFormat:@"users/%@/following.xml", userId]
	 withParameterArray:nil
	 withSuccessInvocation:_onSuccess
	 withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Stopped Following")]];
}

+ (void)removeLocalUsersFollower:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"follower" object:@"yes"];
	
	[[self sharedInstance] 
	 deleteAction:[NSString stringWithFormat:@"users/%@/following.xml", userId]
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:_onSuccess
	 withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Removed Follower")]];
}

+ (void)isLocalUserFollowingAnyoneInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
{
	int pageIndex = 1;
	int perPage = 1;
//	OFDelegate onSuccessChained([self sharedInstance], @selector(onIsLocalUserFollowingAnyoneSuccess:nextCall:), _onSuccess);
	
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioIntToKey:@"per_page" value:perPage];
	[params ioNSStringToKey:@"user_id" object:@"me"];
	[params ioNSStringToKey:@"scope" object:@"people-of-interest"];
	
	[[self sharedInstance] 
	 getAction:@"users.xml"
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(onIsLocalUserFollowingAnyoneSuccess:nextCall:) chained:_onSuccess]
	 withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

- (void)onIsLocalUserFollowingAnyoneSuccess:(OFPaginatedSeries*)page nextCall:(OFInvocation*)nextCall
{
	BOOL isFollowingAnyone = [page.objects count] > 0;
	[nextCall invokeWith:[NSNumber numberWithBool:isFollowingAnyone]];
}

@end
