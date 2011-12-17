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
#import "OFUnlockedAchievement.h"
#import "OFAchievementService.h"
#import "OFAchievement.h"
#import "OFDependencies.h"

@implementation OFUnlockedAchievement

@synthesize achievement, percentComplete, isInvalidResult;

- (void)setPercentComplete:(NSString*)value
{
	percentComplete = [value doubleValue];
}

- (void)setResult:(NSString*)value
{
	if ([value isEqualToString:@"invalid"])
		isInvalidResult = YES;
}

- (void)setAchievement:(OFResource*)value
{
	achievement = (OFAchievement*)[value retain];
}

+ (OFService*)getService;
{
	return [OFAchievementService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"unlocked_achievement";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (void) dealloc
{
	OFSafeRelease(achievement);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setAchievement:) getter:nil klass:[OFAchievement class]], @"achievement_definition",
[OFResourceField fieldSetter:@selector(setResult:)], @"result",
[OFResourceField fieldSetter:@selector(setPercentComplete:)], @"percent_complete",
        nil] retain];
    }
    return sDataDictionary;
}
@end
