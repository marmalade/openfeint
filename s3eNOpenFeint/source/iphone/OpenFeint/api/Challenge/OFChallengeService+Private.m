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


#import "OFChallengeService+Private.h"
#import "OFChallenge.h"
#import "OFChallengeToUser.h"
#import "OFService+Private.h"
#import "OFControllerLoaderObjC.h"
#import "OpenFeint+Private.h"
#import "OFQueryStringWriter.h"
#import "OFChallengeDetailController.h"
#import "OFNotification.h"
#import "OpenFeint+Dashboard.h"
#import "OpenFeint+UserOptions.h"
#import "OFInvocation.h"
#import "OFDependencies.h"

@implementation OFChallengeService (Private)

//download challenge to user - and launch OFNotification
+(void)getChallengeToUserAndShowNotification:(NSString*)challengeToUserId
{
//	OFDelegate success([self sharedInstance], @selector(_onChallengeReceivedNotification:));
//	OFDelegate failure([self sharedInstance], @selector(_onChallengeReceivedFailed));
	
	[self getChallengeToUserWithId:challengeToUserId 
               onSuccessInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(_onChallengeReceivedNotification:)] 
               onFailureInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(_onChallengeReceivedFailed)]];
}

- (void)_getChallengeToUserAndShowDetailView:(NSString*)challengeToUserId
{
	if ([OpenFeint isOnline])
	{
//		OFDelegate success(self, @selector(_onChallengeReceivedDetailView:));
//		OFDelegate failure(self, @selector(_onChallengeReceivedFailed));
		[OFChallengeService getChallengeToUserWithId:challengeToUserId 
                                 onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_onChallengeReceivedDetailView:)]  
                                 onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_onChallengeReceivedFailed)]];
	}
	else
	{
		// When the user hasn't logged in yet we gotta do some trickery so we wait for the bootstrap and then call ourselves again
		// The reason for _chainedGetChallengeToUserAndShowDetailView is that user params are always passed as the second argument
        [OpenFeint addBootstrapInvocations:[OFInvocation invocationForTarget:self selector:@selector(_chainedGetChallengeToUserAndShowDetailView:challengeId:) userParam:challengeToUserId]
                       onFailure:[OFInvocation invocationForTarget:self selector:@selector(_onChallengeReceivedFailed)]];
//		OFDelegate success(self, @selector(_chainedGetChallengeToUserAndShowDetailView:challengeId:), challengeToUserId);
//		OFDelegate failure(self, @selector(_onChallengeReceivedFailed));
//		[OpenFeint addBootstrapInvocations:success onFailure:failure];
	}
}

- (void)_chainedGetChallengeToUserAndShowDetailView:(OFInvocation*)next challengeId:(NSString*)challengeToUserId
{
	[self _getChallengeToUserAndShowDetailView:challengeToUserId];
    //NOTE: I believe this invocation will never get passed, the first param of a delegate is the return object, chains are a type of user param
	[next invoke];
}

//downloads challenge to user - and launch detail view
+(void)getChallengeToUserAndShowDetailView:(NSString*)challengeToUserId
{
	[[self sharedInstance] _getChallengeToUserAndShowDetailView:challengeToUserId];
}

//download sent challenges
+(void)getSentChallengesForLocalUserAndLocalApplication:(NSUInteger)pageIndex
											  onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"challenges.xml"]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:success
     withFailureInvocation:failure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Challenge Information")]];
}

//download completed challenges
+(void)getCompletedChallengesForLocalUserAndLocalApplication:(NSUInteger)pageIndex
												   onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL complete = YES;
	[params ioBoolToKey:@"complete" value:complete];
	[params ioIntToKey:@"page" value:pageIndex];
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"challenges_users.xml"]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:success
     withFailureInvocation:failure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Challenge Information")]];
}

+(void)getPendingChallengesForLocalUserAndApplication:(NSString*)clientApplicationId
											pageIndex:(NSUInteger)pageIndex
											onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFChallengeService getPendingChallengesForLocalUserAndApplication:clientApplicationId 
															 pageIndex:pageIndex 
													  comparedToUserId:nil
															 onSuccessInvocation:success 
                                                             onFailureInvocation:failure];
}

+(void)getPendingChallengesForLocalUserAndLocalApplication:(NSUInteger)pageIndex
												 onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFChallengeService getPendingChallengesForLocalUserAndApplication:nil
															 pageIndex:pageIndex
															 onSuccessInvocation:success
															 onFailureInvocation:failure];
	
}

+(void)getPendingChallengesForLocalUserAndApplication:(NSString*)clientApplicationId
											pageIndex:(NSUInteger)pageIndex
									 comparedToUserId:(NSString*)comparedToUserId
											onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL incomplete = YES;
	BOOL viewed = YES;
	[params ioBoolToKey:@"incomplete" value:incomplete];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioBoolToKey:@"mark_as_viewed" value:viewed];
	if (clientApplicationId && [clientApplicationId length] != 0)
	{
		[params ioNSStringToKey:@"client_application_id" object:clientApplicationId];
	}
	if (comparedToUserId && [comparedToUserId length] != 0)
	{
		[params ioNSStringToKey:@"compared_user_id" object:comparedToUserId];
	}
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"challenges_users.xml"]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:success
     withFailureInvocation:failure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Challenge Information")]];
}

//downloads a list of challenge to users with challenge id
+(void)getUsersWhoReceivedChallengeWithId:(NSString*)challengeId
					  clientApplicationId:(NSString*)clientApplicationId
								pageIndex:(NSUInteger)pageIndex
								onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"challenge_id" object:challengeId];
	[params ioNSStringToKey:@"client_application_id" object:( clientApplicationId ? clientApplicationId : [OpenFeint clientApplicationId])];
	[params ioIntToKey:@"page" value:pageIndex];
	
	[[self sharedInstance] 
	 getAction:@"challenges_users.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:success
     withFailureInvocation:failure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void)getUsersToChallenge:(NSString*)instigatingChallengerId 
				  pageIndex:(NSUInteger)pageIndex
				  onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioNSStringToKey:@"user_id" object:@"me"];
	[params ioNSStringToKey:@"scope" object:@"people-of-interest"];
	[params ioNSStringToKey:@"with_client_application" object:( [OpenFeint clientApplicationId])];
	[params ioNSStringToKey:@"not_sectioned" object:@"yes"];
	if (instigatingChallengerId)
	{
		[params ioNSStringToKey:@"challenger_user_id" object:instigatingChallengerId];
	}

	[[self sharedInstance] 
	 getAction:@"users.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:success
     withFailureInvocation:failure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Friends")]];

}

#pragma mark Callbacks
//onsuccess for downloadChallengeWithId-launches challengeNotification in game
- (void)_onChallengeReceivedNotification:(OFPaginatedSeries*)resources
{
	OFChallengeToUser* newChallenge = [resources.objects objectAtIndex:0];
	
	//launch OFChallengeNotification

//    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
//                            newChallenge.challenge.resourceId, @"challenge_id",
//                            nil];
    
    // Why do we need to load this?  We don't do anything with it.
//	OFChallengeDetailController *detailController = (OFChallengeDetailController*)[[OFControllerLoaderObjC loader] load:@"ChallengeDetail" withParams:params];
    
	[[OFNotification sharedInstance] showChallengeNotice:newChallenge];
}

- (void)_onChallengeReceivedDetailView:(OFPaginatedSeries*)resources
{
	if ([resources count] == 0)
	{
		return;
	}
	OFChallengeToUser* newChallenge = [resources.objects objectAtIndex:0];
	UIViewController* listController = [[OFControllerLoaderObjC loader] load:@"ChallengeList"];

    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            newChallenge.challenge.resourceId, @"challenge_id",
                            nil];
	OFChallengeDetailController *detailController = (OFChallengeDetailController*)[[OFControllerLoaderObjC loader] load:@"ChallengeDetail" withParams:params];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andControllers:[NSArray arrayWithObjects:listController, detailController, nil]];
}

//onfailure for downloadChallengeWithId
- (void)_onChallengeReceivedFailed
{
	[[OFNotification sharedInstance] showBackgroundNotice:[OFNotificationData dataWithText:OFLOCALSTRING(@"Error downloading challenge.") 
																			   andCategory:kNotificationCategoryChallenge
																				   andType:kNotificationTypeError] 
												andStatus:OFNotificationStatusFailure];
	OFLog(@"OFChallengeService challenge data download failed!");
}

@end
