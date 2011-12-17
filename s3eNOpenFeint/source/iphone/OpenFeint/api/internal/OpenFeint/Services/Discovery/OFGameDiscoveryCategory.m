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
#import "OFGameDiscoveryCategory.h"
#import "OFGameDiscoveryService.h"

@implementation OFGameDiscoveryCategory
		
@synthesize iconUrl, name, subtext, secondaryText, targetDiscoveryActionName, targetDiscoveryPageTitle;


+ (OFService*)getService
{
	return [OFGameDiscoveryService sharedInstance];
}

+ (NSString*)getResourceName
{
	return @"game_discovery_category";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (void) dealloc
{
	self.iconUrl = nil; 
	self.name = nil;
	self.subtext = nil;
	self.secondaryText = nil;
	self.targetDiscoveryActionName = nil;
	self.targetDiscoveryPageTitle = nil;
	
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setIconUrl:)], @"icon_url",
[OFResourceField fieldSetter:@selector(setName:)], @"name",
[OFResourceField fieldSetter:@selector(setSubtext:)], @"subtext",
[OFResourceField fieldSetter:@selector(setSecondaryText:)], @"secondary_text",
[OFResourceField fieldSetter:@selector(setTargetDiscoveryActionName:)], @"target_discovery_action_name",
[OFResourceField fieldSetter:@selector(setTargetDiscoveryPageTitle:)], @"target_discovery_page_title",
        nil] retain];
    }
    return sDataDictionary;
}
@end
