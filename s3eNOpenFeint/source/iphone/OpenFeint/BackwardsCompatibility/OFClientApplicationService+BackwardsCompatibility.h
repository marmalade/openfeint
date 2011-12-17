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
#import "OpenFeint/OFClientApplicationService.h"
#import "OFDelegate.h"
@interface OFClientApplicationService (BackwardsCompatibility)
+ (void) getPlayedGamesForUser:(NSString*)userId withPage:(NSInteger)pageIndex andCountPerPage:(NSInteger)perPage onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure;
+ (void) getFavoriteGamesForUser:(NSString*)userId withPage:(NSInteger)pageIndex andCountPerPage:(NSInteger)perPage onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure;
+ (void) getPlayedGamesForLocalUsersFriends:(NSInteger)pageIndex onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure;
+ (void) getGameProfilePageComparisonInfo:(NSString*)clientApplicationId 
						 comparedToUserId:(NSString*)comparedToUserId 
								onSuccess:(OFDelegate const&)onSuccess 
								onFailure:(OFDelegate const&)onFailure;
+ (void) getGameProfilePageInfo:(NSString*)clientApplicationId onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure;
+ (void) getPlayerReviewForGame:(NSString*)clientApplicationId byUser:(NSString*)userId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

@end
