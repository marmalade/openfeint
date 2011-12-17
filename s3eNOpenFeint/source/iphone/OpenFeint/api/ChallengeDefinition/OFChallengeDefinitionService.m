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

#import "OFChallengeDefinition.h"
#import "OFChallengeDefinitionStats.h"
#import "OFChallengeDefinitionService.h"
#import "OpenFeint+UserOptions.h"
#import "OFService+Private.h"
#import "OFQueryStringWriter.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFChallengeDefinitionService)

@implementation OFChallengeDefinitionService

OPENFEINT_DEFINE_SERVICE(OFChallengeDefinitionService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFChallengeDefinition class] forKey:[OFChallengeDefinition getResourceName]];
	[namedResourceMap setObject:[OFChallengeDefinitionStats class] forKey:[OFChallengeDefinitionStats getResourceName]];
}

+ (OFRequestHandle*) getIndexOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation
                                                :(OFInvocation*)_onFailure
{
    return [[self sharedInstance] 
			getAction:@"challenge_definitions.xml"
            withParameterArray:nil
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
			withRequestType:OFActionRequestSilent
			withNotice:nil];
}

+ (OFRequestHandle*)getChallengeDefinitionWithId:(NSString*)challengeDefinitionId 
                             onSuccessInvocation:(OFInvocation*)_onSuccess
                             onFailureInvocation:(OFInvocation*)_onFailure
{
	if(!challengeDefinitionId || [challengeDefinitionId isEqualToString:@""])
	{
		//TODO Change To Assert when asserts pop alert views
		[_onFailure invoke];
		return nil;
	}
	
	return [[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"challenge_definitions/%@.xml",challengeDefinitionId]
            withParameterArray:nil
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void)getChallengeDefinitionStatsForLocalUser:(NSUInteger)pageIndex
							clientApplicationId:(NSString*)clientApplicationId
                            onSuccessInvocation:(OFInvocation*)_onSuccess
                            onFailureInvocation:(OFInvocation*)_onFailure;
{
	[OFChallengeDefinitionService getChallengeDefinitionStatsForLocalUser:pageIndex
													  clientApplicationId:clientApplicationId
														 comparedToUserId:nil
																onSuccessInvocation:_onSuccess
																onFailureInvocation:_onFailure];
}

+ (void)getChallengeDefinitionStatsForLocalUser:(NSUInteger)pageIndex
							clientApplicationId:(NSString*)clientApplicationId
							   comparedToUserId:(NSString*)comparedToUserId                            
                            onSuccessInvocation:(OFInvocation*)_onSuccess
                            onFailureInvocation:(OFInvocation*)_onFailure
{
    
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL challenge_definition_stats = YES;
	[params ioBoolToKey:@"challenge_definition_stats" value:challenge_definition_stats];
	int per_page = 20;
	[params ioIntToKey:@"per_page" value:per_page];
	[params ioIntToKey:@"page" value:pageIndex];
	
	[params ioNSStringToKey:@"client_application_id" object: (clientApplicationId ? clientApplicationId : [OpenFeint clientApplicationId])];
	
	if (comparedToUserId && [comparedToUserId length] > 0)
	{
		[params ioNSStringToKey:@"compared_user_id" object:comparedToUserId];
	}
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"challenge_definitions.xml"]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloading Challenge Information")]];
}

@end
