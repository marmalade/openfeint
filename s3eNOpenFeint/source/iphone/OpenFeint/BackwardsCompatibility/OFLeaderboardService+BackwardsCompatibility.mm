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
#import "OFLeaderboardService+BackwardsCompatibility.h"
@implementation OFLeaderboardService (BackwardsCompatibility)
+ (OFRequestHandle*) getIndexOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getIndexOnSuccessInvocation:onSuccess.getInvocation() 
                         onFailureInvocation:onFailure.getInvocation()]; 
}    

+ (void) getLeaderboardsComparisonWithUser:(NSString*)comparedToUserId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getLeaderboardsComparisonWithUser:comparedToUserId 
                        onSuccessInvocation:onSuccess.getInvocation() 
                        onFailureInvocation:onFailure.getInvocation()];
}

+ (void)getLeaderboardsForApplication:(NSString*)applicationId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getLeaderboardsForApplication:applicationId
                    onSuccessInvocation:onSuccess.getInvocation() 
                    onFailureInvocation:onFailure.getInvocation()];
}

+ (void)getLeaderboardsForApplication:(NSString*)applicationId comparedToUserId:(NSString*)comparedToUserId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getLeaderboardsForApplication:applicationId
                       comparedToUserId:comparedToUserId
                    onSuccessInvocation:onSuccess.getInvocation() 
                    onFailureInvocation:onFailure.getInvocation()];
}
@end
