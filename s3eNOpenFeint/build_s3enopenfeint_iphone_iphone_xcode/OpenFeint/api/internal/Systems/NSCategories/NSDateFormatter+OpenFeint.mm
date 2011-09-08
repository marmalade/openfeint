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

#import "NSDateFormatter+OpenFeint.h"

@implementation NSDateFormatter (OpenFeint)

+ (NSDateFormatter*)httpFormatter
{
	static NSString* sHttpDateFormatString = @"ccc',' dd LLL yyyy HH:mm:ss ZZ";

	NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:sHttpDateFormatString];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
	
	return formatter;
}

+ (NSDateFormatter*)railsFormatter
{
	static NSString* sRailsDateFormatString = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

	NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:sRailsDateFormatString];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
	
	return formatter;
}

+ (NSDateFormatter*)railsLocalDateFormatter
{
	static NSString* sRailsLocalDateFormatString = @"yyyy-MM-dd";
	
	NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:sRailsLocalDateFormatString];
	[formatter setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
	
	return formatter;
}

+ (NSDateFormatter*)normalFormatter
{
	static NSString* sDateFormatString = @"LLL dd',' yyyy hh:mma";
	
	NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:sDateFormatString];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"PST"]];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
	
	return formatter;
}

@end
