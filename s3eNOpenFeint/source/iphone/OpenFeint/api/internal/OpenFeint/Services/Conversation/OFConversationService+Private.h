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

#import "OFService.h"

@interface OFConversationService : OFService

OPENFEINT_DECLARE_AS_SERVICE(OFConversationService);

+ (void)startConversationWithUser:(NSString*)userId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (void)postMessage:(NSString*)message toConversation:(NSString*)conversationId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (void)getConversationHistory:(NSString*)conversationId page:(NSUInteger)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (void)deleteConversation:(NSString*)conversationId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;

@end
