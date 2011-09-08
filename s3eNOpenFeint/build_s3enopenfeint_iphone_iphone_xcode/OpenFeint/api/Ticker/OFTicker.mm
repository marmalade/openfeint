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

#import "OFDependencies.h"
#import "OFTicker.h"
#import "OFTickerService.h"
#import "OFResourceDataMap.h"

@implementation OFTicker

@synthesize message;
@synthesize date;

- (void)setMessage:(NSString*)value
{
	OFSafeRelease(message);
	message = [value retain];
}

- (void)setDate:(NSString*)value
{
	OFSafeRelease(date);
	date = [value retain];
}

+ (OFService*)getService;
{
	return [OFTickerService sharedInstance];
}

+ (OFResourceDataMap*)getDataMap
{
	static OFPointer<OFResourceDataMap> dataMap;
	
	if(dataMap.get() == NULL)
	{
		dataMap = new OFResourceDataMap;
		dataMap->addField(@"message",								@selector(setMessage:));
		dataMap->addField(@"date",									@selector(setDate:));				
	}
	
	return dataMap.get();
}

+ (NSString*)getResourceName
{
	return @"ticker";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_ticker_discovered";
}

- (void) dealloc
{
	OFSafeRelease(message);
	OFSafeRelease(date);
	[super dealloc];
}

@end
