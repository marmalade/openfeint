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

#import "OFInputResponsePerformSelector.h"

@implementation OFInputResponsePerformSelector

- (id)initWithSelector:(SEL)selector andTarget:target;
{
	self = [super init];
	if (self)
	{
		mSelector = selector;
		mTarget = target;
	}
	return self;
}

+ (OFNotificationInputResponse*)responseWithSelector:(SEL)selector andTarget:target
{
	return [[[OFInputResponsePerformSelector alloc] initWithSelector:selector andTarget:target] autorelease];
}

- (void)respondToInput
{
	[mTarget performSelector:mSelector];
}

@end
