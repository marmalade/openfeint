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
#pragma once
#import "OpenFeint/OFAchievementService.h"
#import "OFDelegate.h"

@interface OFAchievementService (BackwardsCompatibility)
+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure;
+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							  silently:(BOOL)silently
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure;
+ (OFRequestHandle*) updateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification 
                             onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

+ (OFRequestHandle*) submitQueuedUpdateAchievements:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

@end
