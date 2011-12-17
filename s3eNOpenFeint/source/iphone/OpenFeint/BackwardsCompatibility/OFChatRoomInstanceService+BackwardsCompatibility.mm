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
#import "OFChatRoomInstanceService+BackwardsCompatibility.h"


@implementation OFChatRoomInstanceService (BackwardsCompatibility)
+ (void) getPage:(NSInteger)pageIndex forChatRoomDefinition:(OFChatRoomDefinition*)roomDefinition onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getPage:pageIndex forChatRoomDefinition:roomDefinition 
        onSuccessInvocation:onSuccess.getInvocation() 
        onFailureInvocation:onFailure.getInvocation()];
}

+ (void) attemptToJoinRoom:(OFChatRoomInstance*)roomToJoin 
				 rejoining:(BOOL)rejoining 
				 onSuccess:(const OFDelegate&)onSuccess 
				 onFailure:(const OFDelegate&)onFailure
{
    [self attemptToJoinRoom:roomToJoin rejoining:rejoining
        onSuccessInvocation:onSuccess.getInvocation() 
        onFailureInvocation:onFailure.getInvocation()];
    
}
+ (void) loadLastRoomJoined:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self loadLastRoomJoinedInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

@end
