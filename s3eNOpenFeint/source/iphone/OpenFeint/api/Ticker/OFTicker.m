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
#import "OFTicker.h"
#import "OFTickerService.h"
#import "OFDependencies.h"

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

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setMessage:)], @"message",
[OFResourceField fieldSetter:@selector(setDate:)], @"date",
        nil] retain];
    }
    return sDataDictionary;
}
@end
