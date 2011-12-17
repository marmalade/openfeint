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
#import "OFGameDiscoveryImageHyperlink.h"
#import "OFGameDiscoveryService.h"
#import "OFDependencies.h"

@implementation OFGameDiscoveryImageHyperlink
	
@synthesize imageUrl, targetDiscoveryActionName, targetApplicationIPurchaseId, secondsToDisplay, targetDiscoveryPageTitle, appBannerPlacement;

- (void)setSecondsToDisplayFromString:(NSString*)value
{
	secondsToDisplay = [value floatValue];
}


+ (OFService*)getService
{
	return [OFGameDiscoveryService sharedInstance];
}

+ (NSString*)getResourceName
{
	return @"game_discovery_image_hyperlink";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (BOOL)isCategoryLink
{
	return self.targetDiscoveryActionName != nil && ![self.targetDiscoveryActionName isEqualToString:@""];
}

- (BOOL)isIPurchaseLink
{
	return self.targetApplicationIPurchaseId != nil && ![self.targetApplicationIPurchaseId isEqualToString:@""];
}

- (void) dealloc
{
	OFSafeRelease(appBannerPlacement);
	OFSafeRelease(imageUrl);
	OFSafeRelease(targetDiscoveryPageTitle)
	OFSafeRelease(targetDiscoveryActionName);
	OFSafeRelease(targetApplicationIPurchaseId);
	
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setSecondsToDisplayFromString:)], @"seconds_to_display",
[OFResourceField fieldSetter:@selector(setImageUrl:)], @"image_url",
[OFResourceField fieldSetter:@selector(setTargetApplicationIPurchaseId:)], @"target_application_ipurchase_id",
[OFResourceField fieldSetter:@selector(setTargetDiscoveryPageTitle:)], @"target_discovery_page_title",
[OFResourceField fieldSetter:@selector(setTargetDiscoveryActionName:)], @"target_discovery_action_name",
[OFResourceField fieldSetter:@selector(setAppBannerPlacement:)], @"app_banner_placement",
        nil] retain];
    }
    return sDataDictionary;
}
@end
