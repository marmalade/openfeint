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
#import "OFOffline.h"
#import "OFOfflineService.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

@implementation OFOffline

@synthesize achievements,leaderboards,leaderboardAggregations;

- (void)setLeaderboards:(NSMutableArray*)value
{
	OFSafeRelease(leaderboards);
	leaderboards = [value retain];
}

- (void)setAchievements:(NSMutableArray*)value
{
	OFSafeRelease(achievements);
	achievements = [value retain];
}

- (void)setLeaderboardAggregations:(NSMutableArray*)value
{
	OFSafeRelease(leaderboardAggregations);
	leaderboardAggregations = [value retain];
}

+ (OFService*)getService;
{
	return [OFOfflineService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"offline";
}

- (void) dealloc
{
	self.achievements = nil;
	self.leaderboards = nil;
	self.leaderboardAggregations = nil;
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceArraySetter:@selector(setAchievements:)], @"achievements",
[OFResourceField nestedResourceArraySetter:@selector(setLeaderboards:)], @"leaderboards",
[OFResourceField nestedResourceArraySetter:@selector(setLeaderboardAggregations:)], @"leaderboard_aggregations",
        nil] retain];
    }
    return sDataDictionary;
}
@end
