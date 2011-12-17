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

#import "OFClientApplicationService+Private.h"
#import "OFQueryStringWriter.h"
#import "OFService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFDependencies.h"

@implementation OFClientApplicationService (Private)

+ (OFRequestHandle*)setGameIsFavorite:(NSString*)clientApplicationId favorite:(BOOL)favorite review:(NSString*)review onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	{
        [params pushScope:@"client_application_user" isArray:NO];
		if (review)
		{
			OFAssert(favorite, @"Can't submit reviews for game's that aren't favorite");
			[params ioNSStringToKey:@"review" object:review];
		}
		[params ioBoolToKey:@"favorite" value:favorite];
        [params popScope];
	}
	
	
	return [[self sharedInstance] 
	 postAction:[NSString stringWithFormat:@"client_applications/%@/users/review.xml", clientApplicationId ? clientApplicationId : [OpenFeint clientApplicationId]]
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:success
            withFailureInvocation:failure
            withRequestType:OFActionRequestForeground
	 withNotice:nil];
}

+ (OFRequestHandle*) makeGameFavorite:(NSString*)clientApplicationId reviewText:(NSString*)review onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	return [OFClientApplicationService setGameIsFavorite:clientApplicationId favorite:YES review:review onSuccessInvocation:success onFailureInvocation:failure];
}

+ (void) unfavoriteGame:(NSString*)clientApplicationId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFClientApplicationService setGameIsFavorite:clientApplicationId favorite:NO review:nil onSuccessInvocation:success onFailureInvocation:failure];
}

+ (void) viewedFanClub:(NSString*)clientApplicationId
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	if (clientApplicationId == nil)
	{
		clientApplicationId = [OpenFeint clientApplicationId];
	}
	[params ioNSStringToKey:@"client_application_id" object:clientApplicationId];
	
	[[self sharedInstance] 
	 getAction:@"client_application_users/fan_club"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:nil
     withFailureInvocation:nil
	 withRequestType:OFActionRequestSilentIgnoreErrors
	 withNotice:nil];
}

+ (void) removeGameFromLocalUsersList:(NSString*)clientApplicationId onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;
{
	[[self sharedInstance] 
	 deleteAction:[NSString stringWithFormat:@"profile/games/%@", clientApplicationId]
	 withParameterArray:nil
	 withSuccessInvocation:onSuccess
	 withFailureInvocation:onFailure
	 withRequestType:OFActionRequestSilentIgnoreErrors
	 withNotice:nil];
}

@end
