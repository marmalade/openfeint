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

#import "OFProfileService.h"
#import "OFService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFPlayedGame.h"
#import "OFGamerscore.h"
#import "OFUserGameStat.h"
#import "OFUser.h"
#import "OFUsersCredential.h"
#import "OFResource+ObjC.h"
#import "OFQueryStringWriter.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFProfileService)

@implementation OFProfileService

OPENFEINT_DEFINE_SERVICE(OFProfileService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFPlayedGame class] forKey:[OFPlayedGame getResourceName]];
	[namedResourceMap setObject:[OFGamerscore class] forKey:[OFGamerscore getResourceName]];
	[namedResourceMap setObject:[OFUserGameStat class] forKey:[OFUserGameStat getResourceName]];
	[namedResourceMap setObject:[OFUser class] forKey:[OFUser getResourceName]];
	[namedResourceMap setObject:[OFUsersCredential class] forKey:[OFUsersCredential getResourceName]];
}

+ (void) getLocalPlayerProfileOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFProfileService getProfileForUser:nil onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) getProfileForUser:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	if (userId == nil || [userId isEqualToString:[OpenFeint lastLoggedInUserId]])
	{
		userId = @"me";
	}
	else
	{
		[params ioNSStringToKey:@"compared_to_user_id" object:@"me"];
	}
	
	[[self sharedInstance] 
		getAction:[NSString stringWithFormat:@"profiles/%@/", userId]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void) getGamerscoreForUser:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{    
	if (userId == nil)
		userId = @"me";

	[[self sharedInstance] 
		getAction:[NSString stringWithFormat:@"profiles/%@/gamerscore", userId]
     withParameterArray:nil
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void) viewedOwnProfilePage
{
	[[self sharedInstance] 
	 getAction:@"profiles/viewed_own"
	 withParameterArray:nil
	 withSuccessInvocation:nil
	 withFailureInvocation:nil
	 withRequestType:OFActionRequestSilentIgnoreErrors
	 withNotice:nil];
}

@end
