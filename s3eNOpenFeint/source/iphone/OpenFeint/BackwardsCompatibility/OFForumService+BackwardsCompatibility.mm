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
#import "OFForumService+BackwardsCompatibility.h"


@implementation OFForumService (BackwardsCompatibility)
+ (void)getTopicsForApplication:(NSString*)clientApplicationId onSuccess:(OFDelegate const&)success onFailure:(OFDelegate const&)failure
{
    [self getTopicsForApplication:clientApplicationId 
              onSuccessInvocation:success.getInvocation() 
              onFailureInvocation:failure.getInvocation()];
}
+ (void)getThreadsForTopic:(NSString*)topicId page:(NSInteger)pageNumber onSuccess:(OFDelegate const&)success onFailure:(OFDelegate const&)failure
{
    [self getThreadsForTopic:topicId page:pageNumber 
         onSuccessInvocation:success.getInvocation() 
         onFailureInvocation:failure.getInvocation()];
}
+ (OFRequestHandle*)getPostsForThread:(NSString*)threadId page:(NSInteger)pageNumber onSuccess:(OFDelegate const&)success onFailure:(OFDelegate const&)failure
{
    return [self getPostsForThread:threadId page:pageNumber 
               onSuccessInvocation:success.getInvocation() 
               onFailureInvocation:failure.getInvocation()];
}

+ (void)postNewThreadInTopic:(NSString*)topicId subject:(NSString*)subject body:(NSString*)body onSuccess:(OFDelegate const&)success onFailure:(OFDelegate const&)failure
{
    [self postNewThreadInTopic:topicId subject:subject body:body 
           onSuccessInvocation:success.getInvocation() 
           onFailureInvocation:failure.getInvocation()];
}

+ (void)replyToThread:(NSString*)threadId body:(NSString*)body onSuccess:(OFDelegate const&)success onFailure:(OFDelegate const&)failure
{
    [self replyToThread:threadId body:body 
    onSuccessInvocation:success.getInvocation() 
    onFailureInvocation:failure.getInvocation()];
}



@end
