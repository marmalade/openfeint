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

#import "OFLeaderboardService.h"

#import "OFService+Private.h"
#import "OFLeaderboard.h"
#import "OFLeaderboardService+Private.h"
#import "OpenFeint.h"
#import "OpenFeint+Private.h"
#import "OFResource+ObjC.h"
#import "OFQueryStringWriter.h"
#import "OFDependencies.h"


OPENFEINT_DEFINE_SERVICE_INSTANCE(OFLeaderboardService);

@implementation OFLeaderboardService

OPENFEINT_DEFINE_SERVICE(OFLeaderboardService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFLeaderboard class] forKey:[OFLeaderboard getResourceName]];
}

+ (OFNotificationData*)getDownloadNotification
{
	return [OFNotificationData dataWithText:OFLOCALSTRING(@"Downloaded Leaderboards") andCategory:kNotificationCategoryLeaderboard andType:kNotificationTypeDownloading];
}

+ (OFRequestHandle*) getIndexOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFLeaderboardService getLeaderboardsForApplication:nil onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
    return nil;
}

+ (void) getLeaderboardsComparisonWithUser:(NSString*)comparedToUserId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFLeaderboardService getLeaderboardsComparisonWithUser:nil onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void)getLeaderboardsForApplication:(NSString*)applicationId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFLeaderboardService getLeaderboardsForApplication:applicationId comparedToUserId:nil onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void)getLeaderboardsForApplication:(NSString*)applicationId comparedToUserId:(NSString*)comparedToUserId onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure
{
	if ([OpenFeint isOnline]) 
	{
		OFQueryStringWriter* params = [OFQueryStringWriter writer];
		if (applicationId == nil || [applicationId length] == 0)
		{
			applicationId = @"@me";
		}
		
		if (comparedToUserId && [comparedToUserId length] != 0)
		{
			[params ioNSStringToKey:@"compared_user_id" object:comparedToUserId];
		}
		
		[[self sharedInstance] 
		 getAction:[NSString stringWithFormat:@"client_applications/%@/leaderboards.xml", applicationId]
         withParameterArray:params.getQueryParametersAsMPURLRequestParameters
         withSuccessInvocation:onSuccess
         withFailureInvocation:onFailure
		 withRequestType:OFActionRequestForeground
		 withNotice:[OFLeaderboardService getDownloadNotification]];
	} else {
		[OFLeaderboardService getLeaderboardsLocalInvocation:onSuccess onFailureInvocation:onFailure];
	}
}

@end
