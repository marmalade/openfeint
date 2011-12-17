//  Copyright 2009-2010 Aurora Feint, Inc.
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

#import "OFForumService+Private.h"
#import "OFInvocation.h"

@interface OFForumService (Public)

+ (void)getTopicsForApplication:(NSString*)clientApplicationId onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;

+ (void)getThreadsForTopic:(NSString*)topicId page:(NSInteger)pageNumber onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;
+ (OFRequestHandle*)getPostsForThread:(NSString*)threadId page:(NSInteger)pageNumber onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;

+ (void)postNewThreadInTopic:(NSString*)topicId subject:(NSString*)subject body:(NSString*)body onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;
+ (void)replyToThread:(NSString*)threadId body:(NSString*)body onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;
@end
