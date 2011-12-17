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
#import "OFProfileService+BackwardsCompatibility.h"
@implementation OFProfileService (BackwardsCompatibility)
+ (void) getLocalPlayerProfileOnSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure
{
    [self getLocalPlayerProfileOnSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}
+ (void) getProfileForUser:(NSString*)userId onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure
{
    [self getProfileForUser:userId onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}
+ (void) getGamerscoreForUser:(NSString*)userId onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure
{
    [self getGamerscoreForUser:userId onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

@end
