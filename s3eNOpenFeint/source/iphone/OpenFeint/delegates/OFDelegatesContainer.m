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

#import "OFDelegatesContainer.h"

@implementation OFDelegatesContainer

@synthesize openFeintDelegate, challengeDelegate, notificationDelegate, bragDelegate;

+ (OFDelegatesContainer*)containerWithOpenFeintDelegate:(id<OpenFeintDelegate>)openFeintDelegate
{
	OFDelegatesContainer* container = [[OFDelegatesContainer new] autorelease];
	container.openFeintDelegate = openFeintDelegate;
	return container;
}

+ (OFDelegatesContainer*)containerWithOpenFeintDelegate:(id<OpenFeintDelegate>)openFeintDelegate
								   andChallengeDelegate:(id<OFChallengeDelegate>)challengeDelegate
								andNotificationDelegate:(id<OFNotificationDelegate>)notificationDelegate
{
	OFDelegatesContainer* container = [[OFDelegatesContainer new] autorelease];
	container.openFeintDelegate = openFeintDelegate;
	container.challengeDelegate = challengeDelegate;
	container.notificationDelegate = notificationDelegate;
	return container;
}
@end

