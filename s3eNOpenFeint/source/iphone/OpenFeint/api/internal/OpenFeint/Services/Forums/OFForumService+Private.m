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
#import "OFService+Private.h"
#import "OFQueryStringWriter.h"

#import "OFForumTopic.h"
#import "OFForumThread.h"
#import "OFForumPost.h"

#import "OpenFeint+UserOptions.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFForumService);

@implementation OFForumService

OPENFEINT_DEFINE_SERVICE(OFForumService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFForumTopic class] forKey:[OFForumTopic getResourceName]];
	[namedResourceMap setObject:[OFForumThread class] forKey:[OFForumThread getResourceName]];
	[namedResourceMap setObject:[OFForumPost class] forKey:[OFForumPost getResourceName]];
}

+ (void)subscribeToThread:(NSString*)threadId topic:(NSString*)topicId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFAssert([topicId length] > 0, @"Must have a topic id");
	OFAssert([threadId length] > 0, @"Must have a thread id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"topic_id" object:topicId];

	[[self sharedInstance] 
		postAction:[NSString stringWithFormat:@"discussions/%@/subscribe.xml", threadId]
		withParameterArray:params.getQueryParametersAsMPURLRequestParameters
		withSuccessInvocation:success
		withFailureInvocation:failure
		withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)unsubscribeFromThread:(NSString*)threadId topic:(NSString*)topicId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFAssert([topicId length] > 0, @"Must have a topic id");
	OFAssert([threadId length] > 0, @"Must have a thread id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"topic_id" object:topicId];

	[[self sharedInstance] 
		postAction:[NSString stringWithFormat:@"discussions/%@/unsubscribe.xml", threadId]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:success
     withFailureInvocation:failure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

@end
