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
#import "OFLeaderboard+Sync.h"
#import "OFLeaderboardService.h"
#import "OFDependencies.h"

@implementation OFLeaderboard_Sync

@synthesize name, active, allowPostingLowerScores, descendingSortOrder, isAggregate, reachedAt, score, endVersion, startVersion, visible, displayText, customData;

- (id)initWithLocalSQL:(OFSqlQuery*)queryRow
{
	self = [super init];
	if (self != nil)
	{	
		resourceId = [[queryRow stringValue:@"id"] retain];
		name = [[queryRow stringValue:@"name"] retain];
		active = [queryRow boolValue:@"active"];
		allowPostingLowerScores = [queryRow boolValue:@"allow_posting_lower_scores"];
		descendingSortOrder = [queryRow boolValue:@"descending_sort_order"];
		isAggregate = [queryRow boolValue:@"is_aggregate"];
		endVersion = [[queryRow stringValue:@"end_version"] retain];
		startVersion = [[queryRow stringValue:@"start_version"] retain];
		visible = [queryRow boolValue:@"visible"];
	}
	return self;
}


- (void)setName:(NSString*)value
{
	OFSafeRelease(name);
	name = [value retain];
}

- (void)setActive:(NSString*)value
{
	active = [value boolValue];
}

- (void)setAllowPostingLowerScores:(NSString*)value
{
	allowPostingLowerScores = [value boolValue];
}

- (void)setDescendingSortOrder:(NSString*)value
{
	descendingSortOrder = [value boolValue];
}

- (void)setIsAggregate:(NSString*)value
{
	isAggregate = [value boolValue];
}

- (void)setReachedAt:(NSString*)value
{
	OFSafeRelease(reachedAt);
	
	if (value != nil)
	{
		NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
		
		[dateFormatter setDateFormat:@"yyy-MM-dd HH:mm:ss zzz"];
		NSMutableString* tmpDate = [[[NSMutableString alloc] initWithString:value] autorelease]; 
		if( [value length] == 19 )
		{
			[tmpDate appendString: @" GMT"];
		}
		reachedAt = [[dateFormatter dateFromString:tmpDate] retain];
	}
}

- (void)setScore:(NSString*)value
{
	score = [value longLongValue];
}

- (void)setEndVersion:(NSString*)value
{
	OFSafeRelease(endVersion);
	endVersion = [value retain];
}

- (void)setStartVersion:(NSString*)value
{
	OFSafeRelease(startVersion);
	startVersion = [value retain];
}

- (void)setDisplayText:(NSString*)value
{
	OFSafeRelease(displayText);
	displayText = [value retain];
}

- (void)setCustomData:(NSString*)value
{
	OFSafeRelease(customData);
	customData = [value retain];
}

- (void)setVisible:(NSString*)value
{
	visible = [value boolValue];
}

+ (OFService*)getService;
{
	return [OFLeaderboardService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"leaderboard";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_leaderboard_discovered";
}

- (void) dealloc
{
	self.name = nil;
	self.startVersion = nil;
	self.endVersion = nil;
	self.reachedAt = nil;
	self.displayText = nil;
	self.customData = nil;
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setName:)], @"name",
[OFResourceField fieldSetter:@selector(setActive:)], @"active",
[OFResourceField fieldSetter:@selector(setAllowPostingLowerScores:)], @"allow_posting_lower_scores",
[OFResourceField fieldSetter:@selector(setDescendingSortOrder:)], @"descending_sort_order",
[OFResourceField fieldSetter:@selector(setIsAggregate:)], @"is_aggregate",
[OFResourceField fieldSetter:@selector(setReachedAt:)], @"reached_at",
[OFResourceField fieldSetter:@selector(setScore:)], @"score",
[OFResourceField fieldSetter:@selector(setEndVersion:)], @"end_version",
[OFResourceField fieldSetter:@selector(setStartVersion:)], @"start_version",
[OFResourceField fieldSetter:@selector(setVisible:)], @"visible",
[OFResourceField fieldSetter:@selector(setDisplayText:)], @"display_text",
[OFResourceField fieldSetter:@selector(setCustomData:)], @"custom_data",
        nil] retain];
    }
    return sDataDictionary;
}
@end
