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
#import "OpenFeint/OFChallengeDefinitionService.h"
#import "OFDelegate.h"

@interface OFChallengeDefinitionService (BackwardsCompatibility)
+ (OFRequestHandle*) getIndexOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*)getChallengeDefinitionWithId:(NSString*)challengeDefinitionId 
                                       onSuccess:(const OFDelegate&)onSuccess
                                       onFailure:(const OFDelegate&)onFailure;
+ (void)getChallengeDefinitionStatsForLocalUser:(NSUInteger)pageIndex
							clientApplicationId:(NSString*)clientApplicationId
									  onSuccess:(OFDelegate const&)onSuccess 
									  onFailure:(OFDelegate const&)onFailure;
+ (void)getChallengeDefinitionStatsForLocalUser:(NSUInteger)pageIndex
							clientApplicationId:(NSString*)clientApplicationId
							   comparedToUserId:(NSString*)comparedToUserId
									  onSuccess:(OFDelegate const&)onSuccess 
									  onFailure:(OFDelegate const&)onFailure;

@end
