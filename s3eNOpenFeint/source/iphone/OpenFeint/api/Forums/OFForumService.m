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

#import "OFForumService.h"
#import "OFQueryStringWriter.h"
#import "OFForumTopic.h"
#import "OFForumThread.h"
#import "OFForumPost.h"
#import "OFPaginatedSeries.h"
#import "OFTableSectionDescription.h"

#import "OFService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFDependencies.h"

@implementation OFForumService (Public)

+ (void)getTopicsForApplication:(NSString*)clientApplicationId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	if ([clientApplicationId length] == 0)
	{
		clientApplicationId = [OpenFeint clientApplicationId];
	}
		
	[[self sharedInstance] 
		getAction:[NSString stringWithFormat:@"client_applications/%@/forums.xml", clientApplicationId]
     withParameterArray:nil
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)getThreadsForTopic:(NSString*)topicId page:(NSInteger)pageNumber onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure

{
	OFAssert([topicId length] > 0, @"Must have a topic id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageNumber];
	
	[[self sharedInstance] 
		getAction:[NSString stringWithFormat:@"topics/%@/discussions.xml", topicId]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (OFRequestHandle*)getPostsForThread:(NSString*)threadId page:(NSInteger)pageNumber onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFAssert([threadId length] > 0, @"Must have a thread id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:pageNumber];

	return [[self sharedInstance] 
		getAction:[NSString stringWithFormat:@"discussions/%@/posts.xml", threadId]
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)postNewThreadInTopic:(NSString*)topicId subject:(NSString*)subject body:(NSString*)body onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure

{
	OFAssert([topicId length] > 0, @"Must have a topic id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"discussion[subject]" object:subject];
	[params ioNSStringToKey:@"discussion[body]" object:body];
	
	[[self sharedInstance] 
		postAction:[NSString stringWithFormat:@"topics/%@/discussions.xml", topicId]
		withParameterArray:params.getQueryParametersAsMPURLRequestParameters
        withSuccessInvocation:_onSuccess
		withFailureInvocation:_onFailure
		withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)replyToThread:(NSString*)threadId body:(NSString*)body onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure

{
    OFAssert([threadId length] > 0, @"Must have a thread id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"post[body]" object:body];

	[[self sharedInstance] 
		postAction:[NSString stringWithFormat:@"discussions/%@/posts.xml", threadId]
		withParameterArray:params.getQueryParametersAsMPURLRequestParameters
		withSuccessInvocation:_onSuccess
		withFailureInvocation:_onFailure
		withRequestType:OFActionRequestSilent
		withNotice:nil];
}

@end
