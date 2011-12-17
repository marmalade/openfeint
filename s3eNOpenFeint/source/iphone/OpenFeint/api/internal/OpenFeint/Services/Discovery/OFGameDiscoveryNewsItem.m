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
#import "OFGameDiscoveryNewsItem.h"
#import "OFGameDiscoveryService.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

@implementation OFGameDiscoveryNewsItem
		
@synthesize iconUrl, title, subtitle;
		
- (void)setIconUrl:(NSString*)value
{
	OFSafeRelease(iconUrl);
	iconUrl = [value retain];
}

- (void)setTitle:(NSString*)value
{
	OFSafeRelease(title);
	title = [value retain];
}

- (void)setSubtitle:(NSString*)value
{
	OFSafeRelease(subtitle);
	subtitle = [value retain];
}


+ (OFService*)getService
{
	return [OFGameDiscoveryService sharedInstance];
}

+ (NSString*)getResourceName
{
	return @"game_discovery_news_item";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (void) dealloc
{
	OFSafeRelease(iconUrl);
	OFSafeRelease(title);
	OFSafeRelease(subtitle);
	
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setIconUrl:)], @"icon_url",
[OFResourceField fieldSetter:@selector(setTitle:)], @"title",
[OFResourceField fieldSetter:@selector(setSubtitle:)], @"subtitle",
        nil] retain];
    }
    return sDataDictionary;
}
@end
