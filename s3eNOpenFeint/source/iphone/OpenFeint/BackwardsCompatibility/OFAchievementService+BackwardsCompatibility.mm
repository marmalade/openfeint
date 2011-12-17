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

#import "OFAchievementService+BackwardsCompatibility.h"


@implementation OFAchievementService (BackwardsCompatibility)
+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure
{
    [self getAchievementsForApplication:applicationId comparedToUser:comparedToUserId page:pageIndex 
                              onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							  silently:(BOOL)silently
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure
{
    [self getAchievementsForApplication:applicationId comparedToUser:comparedToUserId page:pageIndex silently:silently 
                              onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

+ (OFRequestHandle*) updateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification 
                             onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self updateAchievement:achievementId andPercentComplete:percentComplete andShowNotification:showUpdateNotification
               onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

+ (OFRequestHandle*) submitQueuedUpdateAchievements:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self submitQueuedUpdateAchievementsInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

@end
