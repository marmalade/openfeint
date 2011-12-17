//  Copyright 2011 Aurora Feint, Inc.
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
#import "OFChallengeService+BackwardsCompatibility.h"


@implementation OFChallengeService (BackwardsCompatibility)
+ (OFRequestHandle*)sendChallenge:(NSString*)challengeDefinitionId
					challengeText:(NSString*)challengeText 
					challengeData:(NSData*)challengeData
					  userMessage:(NSString*)userMessage
					   hiddenText:(NSString*)hiddenText
						  toUsers:(NSArray*)userIds 
			inResponseToChallenge:(NSString*)instigatingChallengeId
						onSuccess:(OFDelegate const&)onSuccess 
						onFailure:(OFDelegate const&)onFailure
{
    return [self sendChallenge:challengeDefinitionId challengeText:challengeText challengeData:challengeData 
                   userMessage:userMessage hiddenText:hiddenText toUsers:userIds inResponseToChallenge:instigatingChallengeId
           onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

+ (OFRequestHandle*)submitChallengeResult:(NSString*)challengeToUserId
                                   result:(OFChallengeResult)challengeResult
                        resultDescription:(NSString*)resultDescription
                                onSuccess:(OFDelegate const&)onSuccess 
                                onFailure:(OFDelegate const&)onFailure
{
    return [self submitChallengeResult:challengeToUserId result:challengeResult resultDescription:resultDescription 
                   onSuccessInvocation:onSuccess.getInvocation() 
                   onFailureInvocation:onFailure.getInvocation()];
}

+(OFRequestHandle*)downloadChallengeData:(NSString*)challengeDataUrl
                               onSuccess:(OFDelegate const&)onSuccess
                               onFailure:(OFDelegate const&)onFailure
{
    return [self downloadChallengeData:challengeDataUrl 
                   onSuccessInvocation:onSuccess.getInvocation() 
                   onFailureInvocation:onFailure.getInvocation()];
}

+(void)getChallengeToUserWithId:(NSString*)challengeToUserId
					  onSuccess:(OFDelegate const&)onSuccess
					  onFailure:(OFDelegate const&)onFailure
{
    [self getChallengeToUserWithId:challengeToUserId                   
               onSuccessInvocation:onSuccess.getInvocation() 
               onFailureInvocation:onFailure.getInvocation()];
}

+ (OFRequestHandle*)rejectChallenge:(NSString*)challengeToUserId
                          onSuccess:(OFDelegate const&)onSuccess
                          onFailure:(OFDelegate const&)onFailure
{
    return [self rejectChallenge:challengeToUserId 
             onSuccessInvocation:onSuccess.getInvocation() 
             onFailureInvocation:onFailure.getInvocation()];
}

+ (void)getChallengeHistoryAcrossAllTypes:(NSUInteger)pageIndex
								onSuccess:(OFDelegate const&)onSuccess 
								onFailure:(OFDelegate const&)onFailure
{
    [self getChallengeHistoryAcrossAllTypes:pageIndex 
                        onSuccessInvocation:onSuccess.getInvocation() 
                        onFailureInvocation:onFailure.getInvocation()];
}

+ (void)getChallengeHistoryForType:(NSString*)challengeDefinitionId
			   clientApplicationId:(NSString*)clientApplicationId			   
						 pageIndex:(NSInteger)pageIndex
						 onSuccess:(OFDelegate const&)onSuccess 
						 onFailure:(OFDelegate const&)onFailure
{	
    [OFChallengeService getChallengeHistoryForType:challengeDefinitionId
                             clientApplicationId:clientApplicationId
                                       pageIndex:pageIndex
                                comparedToUserId:nil
                                       onSuccess:onSuccess
                                       onFailure:onFailure];
}

+ (void)getChallengeHistoryForType:(NSString*)challengeDefinitionId
			   clientApplicationId:(NSString*)clientApplicationId
						 pageIndex:(NSInteger)pageIndex
				  comparedToUserId:(NSString*)comparedToUserId
						 onSuccess:(OFDelegate const&)onSuccess 
						 onFailure:(OFDelegate const&)onFailure
{
    [self getChallengeHistoryForType:challengeDefinitionId clientApplicationId:clientApplicationId 
                           pageIndex:pageIndex comparedToUserId:comparedToUserId
                 onSuccessInvocation:onSuccess.getInvocation() 
                 onFailureInvocation:onFailure.getInvocation()];
}

@end
