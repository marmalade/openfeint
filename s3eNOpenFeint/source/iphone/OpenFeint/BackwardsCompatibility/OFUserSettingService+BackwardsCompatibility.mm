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
#import "OFUserSettingService+BackwardsCompatibility.h"
@implementation OFUserSettingService (BackwardsCompatibility)
+ (OFRequestHandle*) getIndexOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getIndexOnSuccessInvocation:onSuccess.getInvocation() 
                         onFailureInvocation:onFailure.getInvocation()];
}
+ (void) getUserSettingWithKey:(NSString*)settingKey onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getUserSettingWithKey:settingKey 
            onSuccessInvocation:onSuccess.getInvocation() 
            onFailureInvocation:onFailure.getInvocation()];

}
+ (void) setUserSettingWithId:(NSString*)settingId toBoolValue:(BOOL)value onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setUserSettingWithId:settingId toBoolValue:value
           onSuccessInvocation:onSuccess.getInvocation() 
           onFailureInvocation:onFailure.getInvocation()];

}
+ (void) setUserSettingWithKey:(NSString*)settingKey toBoolValue:(BOOL)value onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setUserSettingWithKey:settingKey toBoolValue:value
            onSuccessInvocation:onSuccess.getInvocation() 
            onFailureInvocation:onFailure.getInvocation()];

}

+ (void) setSubscribeToDeveloperNewsLetter:(BOOL)subscribe clientApplicationId:(NSString*)clientApplicationId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setSubscribeToDeveloperNewsLetter:subscribe clientApplicationId:clientApplicationId 
                        onSuccessInvocation:onSuccess.getInvocation() 
                        onFailureInvocation:onFailure.getInvocation()];
}
+ (void) getSubscribingToDeveloperNewsLetter:(NSString*)clientApplicationId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getSubscribingToDeveloperNewsLetter:clientApplicationId 
                          onSuccessInvocation:onSuccess.getInvocation() 
                          onFailureInvocation:onFailure.getInvocation()];
}

@end
