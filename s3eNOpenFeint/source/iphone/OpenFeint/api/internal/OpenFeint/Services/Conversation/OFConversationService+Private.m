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

#import "OFConversationService+Private.h"
#import "OFService+Private.h"
#import "OFQueryStringWriter.h"

#import "OFForumPost.h"
#import "OFConversation.h"
#import "OpenFeint+UserOptions.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFConversationService);

@implementation OFConversationService

OPENFEINT_DEFINE_SERVICE(OFConversationService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFConversation class] forKey:[OFConversation getResourceName]];
	[namedResourceMap setObject:[OFForumPost class] forKey:[OFForumPost getResourceName]];
}

+ (void)startConversationWithUser:(NSString*)userId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFAssert([userId length] > 0, @"Must have a user id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"discussion[other_user_id]" object:userId];

	[[self sharedInstance] 
		postAction:@"discussions.xml"
		withParameterArray:params.getQueryParametersAsMPURLRequestParameters
		withSuccessInvocation:success
		withFailureInvocation:failure
		withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)postMessage:(NSString*)message toConversation:(NSString*)conversationId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFAssert([conversationId length] > 0, @"Must have a conversation id");
	OFAssert([message length] > 0, @"Must have a message");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"post[body]" object:message];

	[[self sharedInstance] 
		postAction:[NSString stringWithFormat:@"discussions/%@/posts.xml", conversationId]
		withParameterArray:params.getQueryParametersAsMPURLRequestParameters
		withSuccessInvocation:success
		withFailureInvocation:failure
		withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)getConversationHistory:(NSString*)conversationId page:(NSUInteger)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFAssert([conversationId length] > 0, @"Must have a conversation id");

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:oneBasedPageNumber];

	[[self sharedInstance] 
		getAction:[NSString stringWithFormat:@"discussions/%@/posts.xml", conversationId]
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:success
	 withFailureInvocation:failure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)deleteConversation:(NSString*)conversationId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure 
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
    [params ioNSStringToKey:@"client_application_id" object:( [OpenFeint clientApplicationId])];
    
	[[self sharedInstance] 
     postAction:[NSString stringWithFormat:@"discussions/%@/delete.xml", conversationId]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:success
     withFailureInvocation:failure
     withRequestType:OFActionRequestSilent
     withNotice:nil];
}
@end
