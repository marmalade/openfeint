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

#import "OFClientApplicationService.h"
#import "OFService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFQueryStringWriter.h"

#import "OFPlayedGame.h"
#import "OFUserGameStat.h"
#import "OFUser.h"
#import "OFGameProfilePageInfo.h"
#import "OFGameProfilePageComparisonInfo.h"
#import "OFPaginatedSeries.h"
#import "OFPlayerReview.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFClientApplicationService)

@implementation OFClientApplicationService

OPENFEINT_DEFINE_SERVICE(OFClientApplicationService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFPlayedGame class] forKey:[OFPlayedGame getResourceName]];
	[namedResourceMap setObject:[OFUserGameStat class] forKey:[OFUserGameStat getResourceName]];
	[namedResourceMap setObject:[OFUser class] forKey:[OFUser getResourceName]];
	[namedResourceMap setObject:[OFGameProfilePageInfo class] forKey:[OFGameProfilePageInfo getResourceName]];
	[namedResourceMap setObject:[OFGameProfilePageComparisonInfo class] forKey:[OFGameProfilePageComparisonInfo getResourceName]];
	[namedResourceMap setObject:[OFPlayerReview class] forKey:[OFPlayerReview getResourceName]];
}

+ (void) getPlayedGamesForUser:(NSString*)userId 
			 favoriteGamesOnly:(BOOL)favoriteGamesOnly
					  withPage:(NSInteger)pageIndex 
			   andCountPerPage:(NSInteger)perPage 
           onSuccessInvocation:(OFInvocation*)onSuccess 
           onFailureInvocation:(OFInvocation*)onFailure;
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioIntToKey:@"per_page" value:perPage];
	
	if (userId == nil || [userId isEqualToString:[OpenFeint lastLoggedInUserId]])
	{
		userId = @"me";
	}
	else
	{
		[params ioNSStringToKey:@"compared_to_user_id" object:@"me"];
	}
	
	if (favoriteGamesOnly)
	{
		[params ioBoolToKey:@"only_favorites" value:favoriteGamesOnly];
	}
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"profiles/%@/list_games", userId]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:onSuccess
     withFailureInvocation:onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Game Information")]];
}

+ (void) getPlayedGamesForUser:(NSString*)userId withPage:(NSInteger)pageIndex andCountPerPage:(NSInteger)perPage 
           onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFClientApplicationService getPlayedGamesForUser:userId favoriteGamesOnly:NO withPage:pageIndex andCountPerPage:perPage onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) getFavoriteGamesForUser:(NSString*)userId withPage:(NSInteger)pageIndex andCountPerPage:(NSInteger)perPage 
             onSuccessInvocation:(OFInvocation*)_onSuccess 
             onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFClientApplicationService getPlayedGamesForUser:userId favoriteGamesOnly:YES withPage:pageIndex andCountPerPage:perPage onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void)getPlayedGamesInScope:(NSString*)scope page:(NSInteger)pageIndex 
          onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioNSStringToKey:@"scope" object:scope];
	
	
	[[self sharedInstance] 
	 getAction:@"apps.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Game Information")]];
}

+ (void) getPlayedGamesForLocalUsersFriends:(NSInteger)pageIndex 
                        onSuccessInvocation:(OFInvocation*)onSuccess 
                        onFailureInvocation:(OFInvocation*)onFailure
{
	[OFClientApplicationService getPlayedGamesInScope:@"people-of-interest" page:pageIndex onSuccessInvocation:onSuccess onFailureInvocation:onFailure];
}

+ (void) getGameProfilePageInfo:(NSString*)clientApplicationId onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;
{
	[OFClientApplicationService getGameProfilePageComparisonInfo:clientApplicationId comparedToUserId:nil onSuccessInvocation:onSuccess onFailureInvocation:onFailure];
}

+ (void) getGameProfilePageComparisonInfo:(NSString*)clientApplicationId 
						 comparedToUserId:(NSString*)comparedToUserId 
                      onSuccessInvocation:(OFInvocation*)_onSuccess 
                      onFailureInvocation:(OFInvocation*)_onFailure
{
	BOOL comparison = comparedToUserId && [comparedToUserId length] > 0;
	
	// if it's the local client application just immediately invoke success with a local profile page info
	OFGameProfilePageInfo* localProfile = [OpenFeint localGameProfileInfo];
	if (!comparison && ([clientApplicationId length] == 0 || [clientApplicationId isEqualToString:localProfile.resourceId]))
	{
		[_onSuccess invokeWith:[OFPaginatedSeries paginatedSeriesWithObject:localProfile]];
		return;
	}
	
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL game_profile_page_info = YES;
	[params ioBoolToKey:@"game_profile_page_info" value:game_profile_page_info];
	
	if (comparison)
	{
		[params ioNSStringToKey:@"compared_user_id" object:comparedToUserId];
	}
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"apps/%@.xml", clientApplicationId ? clientApplicationId : [OpenFeint clientApplicationId]]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloading Game Information")]];
}

+ (void) getPlayerReviewForGame:(NSString*)clientApplicationId byUser:(NSString*)userId 
                       onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	clientApplicationId = clientApplicationId ? clientApplicationId : [OpenFeint clientApplicationId];
	userId = userId ? userId : [OpenFeint lastLoggedInUserId];
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"client_applications/%@/users/%@.xml", clientApplicationId, userId]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloading")]];
}

@end
