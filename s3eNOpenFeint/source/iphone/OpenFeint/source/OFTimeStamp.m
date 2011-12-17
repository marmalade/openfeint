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

#import "OFResourceField.h"
#import "OFTimeStamp.h"
#import "OFTimeStampService.h"
#import "OFPaginatedSeries.h"
#import "NSDateFormatter+OpenFeint.h"
#import "OFDependencies.h"

static id sharedDelegate = nil;

@interface OFTimeStamp (Private)
+ (void)_getServerTimeSuccess:(OFPaginatedSeries*)resources;
+ (void)_getServerTimeFailure;
@end

@implementation OFTimeStamp

@synthesize time, secondsSinceEpoch;

+ (void)setDelegate:(id<OFTimeStampDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFTimeStamp class]];
	}
}

+ (OFRequestHandle*)getServerTime;
{
	OFRequestHandle* handle = nil;
	
//	handle = [OFTimeStampService getServerTimeOnSuccess:OFDelegate(self, @selector(_getServerTimeSuccess:))
//											  onFailure:OFDelegate(self, @selector(_getServerTimeFailure))];
	handle = [OFTimeStampService getServerTimeOnSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getServerTimeSuccess:)] 
                                              onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getServerTimeFailure)]];			  
	[OFRequestHandlesForModule addHandle:handle forModule:[OFTimeStamp class]];
	return handle;
}

+ (void)_getServerTimeSuccess:(OFPaginatedSeries*)resources
{
	if ([resources count] > 0)
	{
		OFTimeStamp* timeStamp = [resources.objects objectAtIndex:0];
	
		if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetServerTime:)])
		{
			[sharedDelegate didGetServerTime:timeStamp];
		}
	}
	else
	{
		[self _getServerTimeFailure];
	}

}

+ (void)_getServerTimeFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetServerTime)])
	{
		[sharedDelegate didFailGetServerTime];
	}
}

- (void)setTime:(NSString*)value
{
	OFSafeRelease(time);
	time = [[[NSDateFormatter railsFormatter] dateFromString:value] retain];
}

- (void)setSecondsSinceEpoch:(NSString*)value
{
	secondsSinceEpoch = [value intValue];
}

+ (OFService*)getService;
{
	return [OFTimeStampService sharedInstance];
}

+ (NSString*)getResourceName
{
	return @"server_timestamp";
}

- (void) dealloc
{
	OFSafeRelease(time);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setTime:)], @"timestamp",
[OFResourceField fieldSetter:@selector(setSecondsSinceEpoch:)], @"seconds_since_epoch",
        nil] retain];
    }
    return sDataDictionary;
}
@end
