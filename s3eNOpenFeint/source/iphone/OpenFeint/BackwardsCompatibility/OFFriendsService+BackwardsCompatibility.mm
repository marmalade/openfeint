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
#import "OFFriendsService+BackwardsCompatibility.h"
@implementation OFFriendsService (BackwardsCompatibility)
+ (void)getUsersFollowedByUser:(NSString*)userId pageIndex:(NSInteger)pageIndex onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getUsersFollowedByUser:userId pageIndex:pageIndex 
             onSuccessInvocation:onSuccess.getInvocation() 
             onFailureInvocation:onFailure.getInvocation()];
}
+ (void)getUsersFollowedByLocalUser:(NSInteger)pageIndex onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getUsersFollowedByLocalUser:pageIndex 
                  onSuccessInvocation:onSuccess.getInvocation() 
                  onFailureInvocation:onFailure.getInvocation()];
}
+ (void)getInvitableFriends:(NSInteger)pageIndex onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getInvitableFriends:pageIndex 
          onSuccessInvocation:onSuccess.getInvocation() 
          onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*)getAllUsersFollowedByUserAlphabetical:(NSString*)userId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getAllUsersFollowedByUserAlphabetical:userId 
                                   onSuccessInvocation:onSuccess.getInvocation() 
                                   onFailureInvocation:onFailure.getInvocation()];
}
+ (void)getAllUsersFollowedByLocalUserAlphabetical:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getAllUsersFollowedByLocalUserAlphabeticalInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*)getAllUsersWithApp:(NSString*)applicationId followedByUser:(NSString*)userId alphabeticalOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getAllUsersWithApp:applicationId followedByUser:userId 
              alphabeticalOnSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}
+ (void)isLocalUserFollowingAnyone:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self isLocalUserFollowingAnyoneInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}
+ (void)getUsersWithAppFollowedByUser:(NSString*)applicationId followedByUser:(NSString*)userId pageIndex:(NSInteger)pageIndex onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getUsersWithAppFollowedByUser:applicationId followedByUser:userId pageIndex:pageIndex 
                    onSuccessInvocation:onSuccess.getInvocation() 
                    onFailureInvocation:onFailure.getInvocation()];
}
+ (void)getUsersWithAppFollowedByLocalUser:(NSString*)applicationId pageIndex:(NSInteger)pageIndex onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getUsersWithAppFollowedByLocalUser:applicationId pageIndex:pageIndex 
                         onSuccessInvocation:onSuccess.getInvocation() 
                         onFailureInvocation:onFailure.getInvocation()];
}
+ (void)getUsersFollowingUser:(NSString*)userId 
 excludeUsersFollowedByTarget:(BOOL)excludeUsersFollowedByTarget
					pageIndex:(NSInteger)pageIndex 
					onSuccess:(const OFDelegate&)onSuccess 
					onFailure:(const OFDelegate&)onFailure
{
    [self getUsersFollowingUser:userId excludeUsersFollowedByTarget:excludeUsersFollowedByTarget pageIndex:pageIndex 
            onSuccessInvocation:onSuccess.getInvocation() 
            onFailureInvocation:onFailure.getInvocation()];
}

+ (void)getUsersFollowingLocalUser:(NSInteger)pageIndex 
      excludeUsersFollowedByTarget:(BOOL)excludeUsersFollowedByTarget
						 onSuccess:(const OFDelegate&)onSuccess 
						 onFailure:(const OFDelegate&)onFailure
{
    [self getUsersFollowingLocalUser:pageIndex excludeUsersFollowedByTarget:excludeUsersFollowedByTarget 
                 onSuccessInvocation:onSuccess.getInvocation() 
                 onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*)makeLocalUserFollow:(NSString*)userId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self makeLocalUserFollow:userId onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];

}
+ (OFRequestHandle*)makeLocalUserStopFollowing:(NSString*)userId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self makeLocalUserStopFollowing:userId onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];

}
+ (void)removeLocalUsersFollower:(NSString*)userId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self removeLocalUsersFollower:userId onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];

}

@end
