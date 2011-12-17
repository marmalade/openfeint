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
#import "OpenFeint+BackwardsCompatibility.h"
@implementation OpenFeint (BackwardsCompatibility)
+ (void)userDidApproveFeint:(BOOL)approved accountSetupCompleteDelegate:(OFDelegate&)accountSetupCompleteDelegate
{
    [self userDidApproveFeint:approved accountSetupCompleteInvocation:accountSetupCompleteDelegate.getInvocation()];
}
+ (void)presentUserFeintApprovalModal:(OFDelegate&)approvedDelegate deniedDelegate:(OFDelegate&)deniedDelegate
{
    [self presentUserFeintApprovalModalInvocation:approvedDelegate.getInvocation() 
                                 deniedInvocation:deniedDelegate.getInvocation()];
}
+ (void)loginWithUserId:(NSString*)openFeintUserId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self loginWithUserId:openFeintUserId
      onSuccessInvocation:onSuccess.getInvocation()
      onFailureInvocation:onFailure.getInvocation()];
}
@end
