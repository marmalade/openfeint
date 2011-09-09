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

#define OF_OPTIONALLY_INVOKE_DELEGATE(_delegate, _selector)	\
{ \
	id delegateAsId = (id)_delegate;								\
	if([delegateAsId respondsToSelector:@selector(_selector)])	\
	{														\
		[delegateAsId performSelector:@selector(_selector)];	\
	} \
}

#define OF_OPTIONALLY_INVOKE_DELEGATE_WITH_PARAMETER(_delegate, _selector, _parameter)	\
{ \
	id delegateAsId = (id)_delegate;								\
	if([delegateAsId respondsToSelector:@selector(_selector)])	\
	{														\
		[delegateAsId performSelector:@selector(_selector) withObject:(id)(_parameter)];	\
	} \
}

#define OF_OPTIONALLY_INVOKE_DELEGATE_WITH_TWO_PARAMETERS(_delegate, _selector, _parameterOne, _parameterTwo)	\
{ \
	id delegateAsId = (id)_delegate;								\
	if([delegateAsId respondsToSelector:@selector(_selector)])	\
	{														\
		[delegateAsId performSelector:@selector(_selector) withObject:(id)(_parameterOne) withObject:(id)(_parameterTwo)];	\
	} \
}


#import "OpenFeintDelegate.h"
#import "OFChallengeDelegate.h"
#import "OFNotificationDelegate.h"
#import "OFBragDelegate.h"

// NOTE: Delegates are not retained
@interface OFDelegatesContainer : NSObject
{
	id<OpenFeintDelegate>	openFeintDelegate;
	id<OFChallengeDelegate> challengeDelegate;
	id<OFNotificationDelegate> notificationDelegate;
	id<OFBragDelegate> bragDelegate;
}

// This will most likely be the same as your UIApplicationDelegate
@property (nonatomic, assign) id<OpenFeintDelegate> openFeintDelegate;
@property (nonatomic, assign) id<OFChallengeDelegate> challengeDelegate;
@property (nonatomic, assign) id<OFNotificationDelegate> notificationDelegate;
@property (nonatomic, assign) id<OFBragDelegate> bragDelegate;

+ (OFDelegatesContainer*)containerWithOpenFeintDelegate:(id<OpenFeintDelegate>)openFeintDelegate;

+ (OFDelegatesContainer*)containerWithOpenFeintDelegate:(id<OpenFeintDelegate>)openFeintDelegate
								   andChallengeDelegate:(id<OFChallengeDelegate>)challengeDelegate
								andNotificationDelegate:(id<OFNotificationDelegate>)notificationDelegate;

@end
