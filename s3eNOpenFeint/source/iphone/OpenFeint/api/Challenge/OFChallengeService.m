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

#import "OFChallenge.h"
#import "OFChallengeToUser.h"
#import "OFChallengeDefinition.h"
#import "OFChallengeService.h"
#import "OFSendChallengeController.h"
#import "OFCompletedChallengeHeaderController.h"
#import "OFService+Private.h"
#import "OFQueryStringWriter.h"
#import "OFControllerLoaderObjC.h"
#import "OpenFeint+Private.h"
#import "OFNavigationController.h"
#import "OFProvider.h"
#import "OFChallengeDetailController.h"
#import "OFFramedNavigationController.h"
#import "OFUser.h"
#import "OFCompressableData.h"
#import "OFResource+ObjC.h"
#import "OFXmlElement.h"
#import "OFResource+ObjC.h"

#import "OFInvocationForwarder.h"
#import "OFInvocation.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFChallengeService)

#pragma mark OFChallengeService

@implementation OFChallengeService

OPENFEINT_DEFINE_SERVICE(OFChallengeService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFChallenge class] forKey:[OFChallenge getResourceName]];
	[namedResourceMap setObject:[OFChallengeToUser class] forKey:[OFChallengeToUser getResourceName]];
	[namedResourceMap setObject:[OFUser class] forKey:[OFUser getResourceName]];
}

//displays the send challenge modal
+ (void)displaySendChallengeModal:(NSString*)challengeDefinitionId
					challengeText:(NSString*)challengeText 
					challengeData:(NSData*)challengeData
{
	OFSendChallengeController* modal = (OFSendChallengeController*)[[OFControllerLoaderObjC loader] load:@"SendChallenge"]; // load(@"SendChallenge");
	modal.challengeDefinitionId = challengeDefinitionId;
	modal.challengeText = challengeText;
	modal.challengeData = challengeData;
	modal.title = OFLOCALSTRING(@"Challenge Friends");
	modal.isCompleted = NO;
	[OFNavigationController addCloseButtonToViewController:modal target:modal action:@selector(cancel)];
	OFNavigationController* navController = [[[OFFramedNavigationController alloc] initWithRootViewController:modal] autorelease];
	[OpenFeint presentRootControllerWithModal:navController];
}

+ (void)displayChallengeCompletedModal:(OFChallengeToUser*)userChallenge
							resultData:(NSData*)resultData
					 resultDescription:(NSString*)resultDescription
				reChallengeDescription:(NSString*)reChallengeDescription
{
	UIViewController* modal = nil;
	userChallenge.isCompleted = !userChallenge.challenge.challengeDefinition.multiAttempt || (userChallenge.result == kChallengeResultRecipientWon);
	userChallenge.resultDescription = resultDescription;
	if (userChallenge.challenge.challengeDefinition.multiAttempt && userChallenge.result == kChallengeResultRecipientWon)
	{
		OFSendChallengeController* sendChallengeModal = (OFSendChallengeController*)[[OFControllerLoaderObjC loader] load:@"SendChallenge"]; // load(@"SendChallenge");
		sendChallengeModal.challengeDefinitionId = userChallenge.challenge.challengeDefinition.resourceId;
		sendChallengeModal.challengeText = reChallengeDescription;
		sendChallengeModal.resultData = resultData;
		sendChallengeModal.userChallenge = userChallenge;
		sendChallengeModal.isCompleted = userChallenge.isCompleted;
		sendChallengeModal.title = OFLOCALSTRING(@"Challenge Result");
		modal = sendChallengeModal;
	}
	else
	{
		OFCompletedChallengeHeaderController* completedChallengeModal = (OFCompletedChallengeHeaderController*)[[OFControllerLoaderObjC loader] load:@"CompletedChallengeHeader"]; // load(@"CompletedChallengeHeader");
		completedChallengeModal.sendChallengeController = nil;
		[completedChallengeModal setChallenge:userChallenge];
		modal = completedChallengeModal;
	}
	
	[OFNavigationController addCloseButtonToViewController:modal target:modal action:@selector(cancel)];
	OFNavigationController* navController = [[[OFFramedNavigationController alloc] initWithRootViewController:modal] autorelease];
	[OpenFeint presentRootControllerWithModal:navController];
}

//sends challenges to users
+ (OFRequestHandle*)sendChallenge:(NSString*)challengeDefinitionId
					challengeText:(NSString*)challengeText 
					challengeData:(NSData*)challengeData
					  userMessage:(NSString*)userMessage
					   hiddenText:(NSString*)hiddenText
						  toUsers:(NSArray*)userIds 
			inResponseToChallenge:(NSString*)instigatingChallengeId
              onSuccessInvocation:(OFInvocation*)_onSuccess 
              onFailureInvocation:(OFInvocation*)_onFailure
{	
	if(!challengeDefinitionId || [challengeDefinitionId isEqualToString:@""])
	{
		//TODO Change To Assert when asserts pop alert views
		//Invalid challenge def
		[_onFailure invoke];
		return nil;
	}
	
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"challenge_hidden_text" object:hiddenText];
	[params ioNSStringToKey:@"challenger_id" object:@"me"];
	[params ioNSStringToKey:@"challenge_description" object:challengeText];
	[params ioNSStringToKey:@"challenge_definition_id" object:challengeDefinitionId];
	if (instigatingChallengeId)
	{
		[params ioNSStringToKey:@"challenge_response_to_challenge_id" object:challengeDefinitionId];
	}
	
	if (userMessage)
	{
		[params ioNSStringToKey:@"challenge_user_message" object:userMessage];
	}
    
	[params ioNSDataToKey:@"challenge_user_data" object:[OFCompressableData serializedDataFromData:challengeData]];
	

    [params serializeArrayToKey:@"challenge_user_ids" elementName:@"user_ids" container:userIds];
	
	return [[self sharedInstance] 
	 postAction:@"challenges.xml"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestBackground
	 withNotice:[OFNotificationData dataWithText:OFLOCALSTRING(@"Challenge Sent")
									 andCategory:kNotificationCategoryChallenge
										 andType:kNotificationTypeSubmitting]];	
}

+ (OFRequestHandle*)submitChallengeResult:(NSString*)challengeToUserId
                                   result:(OFChallengeResult)challengeResult
                        resultDescription:(NSString*)resultDescription
                      onSuccessInvocation:(OFInvocation*)_onSuccess 
                      onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	if(!challengeToUserId || [challengeToUserId isEqualToString:@""])
	{
		//TODO Change To Assert when asserts pop alert views
		[_onFailure invoke];
		return nil;
	}
	
	{
        [params pushScope:@"challenges_user" isArray:NO];
		[params ioNSStringToKey:@"result_text" object:resultDescription];
		if (challengeResult == kChallengeResultRecipientWon)
		{
			[params ioNSStringToKey:@"result" object:@"win"];
		}
		else if (challengeResult == kChallengeResultRecipientLost)
		{
			[params ioNSStringToKey:@"result" object:@"lose"];
		}
		else if (challengeResult == kChallengeResultTie)
		{
			[params ioNSStringToKey:@"result" object:@"tie"];
		}
        [params popScope];
	}
	
	return [[self sharedInstance] 
	 postAction:[NSString stringWithFormat:@"challenges_users/%@/update.xml", challengeToUserId]
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Submitted Challenge")]];
}

+(void)getChallengeToUserWithId:(NSString*)challengeToUserId
            onSuccessInvocation:(OFInvocation*)_onSuccess
            onFailureInvocation:(OFInvocation*)_onFailure
{
    
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"challenges_users/%@.xml",challengeToUserId]
     withParameterArray:nil
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (OFRequestHandle*)rejectChallenge:(NSString*)challengeToUserId
                onSuccessInvocation:(OFInvocation*)_onSuccess
                onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	{
        [params pushScope:@"challenges_user" isArray:NO];
		BOOL ignored = YES;
		[params ioBoolToKey:@"ignored" value:ignored];
        [params popScope];
	}
	
	return [[self sharedInstance] 
	 postAction:[NSString stringWithFormat:@"challenges_users/%@/update.xml", challengeToUserId]
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Rejected Challenge")]];
}

//download challenge blob
+(OFRequestHandle*)downloadChallengeData:(NSString*)challengeDataUrl
                     onSuccessInvocation:(OFInvocation*)_onSuccess
                     onFailureInvocation:(OFInvocation*)_onFailure
{
    OFBlobInvocationForwarder *forwarder =[OFBlobInvocationForwarder blobForwarderWithString:challengeDataUrl success:_onSuccess failure:_onFailure 
                                                                                    userData:nil returnAsS3:NO];
    [forwarder start];
    return [OFRequestHandle requestHandle:forwarder.requestID];
}

+ (void)writeChallengeToUserToFile:(NSString*)fileName challengeToUser:(OFChallengeToUser*)challengeToUser
{
	NSString* xmlString = [challengeToUser toResourceArrayXml];
	NSData* data = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
	[data writeToFile:fileName atomically:YES];	
}

+ (OFChallengeToUser*)readChallengeToUserFromFile:(NSString*)fileName
{
	if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
	{
		return nil;
	}
	NSData* documentData = [NSData dataWithContentsOfFile:fileName];
	OFXmlElement* document = [OFXmlElement elementWithData:documentData];
	OFPaginatedSeries* page = [OFResource resourcesFromXml:document withMap:[OFChallengeService sharedInstance].knownResources];
	if ([page.objects count] > 0)
	{
		return [page.objects objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}

+ (void)getChallengeHistoryAcrossAllTypes:(NSUInteger)pageIndex
                      onSuccessInvocation:(OFInvocation*)_onSuccess
                      onFailureInvocation:(OFInvocation*)_onFailure;
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL history = YES;
	[params ioBoolToKey:@"history" value:history];
	[params ioIntToKey:@"page" value:pageIndex];
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"challenges_users.xml"]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloading Challenge Information")]];
}

+ (void)getChallengeHistoryForType:(NSString*)challengeDefinitionId
			   clientApplicationId:(NSString*)clientApplicationId
						 pageIndex:(NSInteger)pageIndex
               onSuccessInvocation:(OFInvocation*)_onSuccess
               onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFChallengeService getChallengeHistoryForType:challengeDefinitionId
							   clientApplicationId:clientApplicationId
										 pageIndex:pageIndex
								  comparedToUserId:nil
                               onSuccessInvocation:_onSuccess
                               onFailureInvocation:_onFailure];
}

+ (void)getChallengeHistoryForType:(NSString*)challengeDefinitionId
			   clientApplicationId:(NSString*)clientApplicationId
						 pageIndex:(NSInteger)pageIndex
				  comparedToUserId:(NSString*)comparedToUserId
               onSuccessInvocation:(OFInvocation*)_onSuccess
               onFailureInvocation:(OFInvocation*)_onFailure
{

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL history = YES;
	[params ioBoolToKey:@"history" value:history];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioNSStringToKey:@"challenge_definition_id" object:challengeDefinitionId];
	if (clientApplicationId)
	{
		[params ioNSStringToKey:@"client_application_id" object:clientApplicationId];
	}
	if (comparedToUserId && [comparedToUserId length] > 0)
	{
		[params ioNSStringToKey:@"compared_user_id" object:comparedToUserId];
	}
	
	[[self sharedInstance] 
		  getAction:[NSString stringWithFormat:@"challenges_users.xml"]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestForeground
		 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloading Challenge Information")]];
}

@end
