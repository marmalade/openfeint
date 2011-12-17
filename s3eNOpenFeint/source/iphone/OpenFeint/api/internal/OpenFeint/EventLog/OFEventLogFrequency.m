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

#import "OFEventLogFrequency.h"

@implementation OFEventLogFrequency

@synthesize numEventsToUploadAfter;

#pragma mark Life-cycle

- (id)initWithName:(NSString*)logName
{
	self = [super initWithName:logName];
	if (self != nil)
	{
        self.numEventsToUploadAfter = 10;
	}
	
	return self;
}

- (void)frequencyUploadCheck
{
    if([pendingEvents count] >= self.numEventsToUploadAfter)
    {
        [self upload];
    }
}

#pragma mark Public Interface

- (void)setNumEventsToUploadAfter:(int)_numEventsToUploadAfter
{
    numEventsToUploadAfter = _numEventsToUploadAfter;
    [self frequencyUploadCheck];
}

- (void)logEventWithActionKey:(NSString*)actionKey logName:(NSString*)logName parameters:(NSDictionary*)parameters
{
    [super logEventWithActionKey:actionKey logName:logName parameters:parameters];
    [self frequencyUploadCheck];
}

- (void)logEventNamed:(NSString*)eventName logName:(NSString*)logName parameters:(NSDictionary*)parameters
{
    [super logEventNamed:eventName logName:logName parameters:parameters];
    [self frequencyUploadCheck];
}

@end
