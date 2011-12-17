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

#import "IPhoneOSIntrospection.h"

#include <sys/types.h>
#include <sys/sysctl.h>

BOOL is2PointOhSystemVersion()
{
	static BOOL is2PointOh = NO;
	static BOOL hasDoneTheWork = NO;
	
	if (!hasDoneTheWork)
	{
		hasDoneTheWork = YES;
		NSArray* versionComponents = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
		NSString* majorVersionNumber = (NSString*)[versionComponents objectAtIndex:0];
		is2PointOh = [majorVersionNumber isEqualToString:@"2"];
	}
	
	return is2PointOh;
}

BOOL is3PointOhSystemVersion()
{
	static BOOL is3PointOh = NO;
	static BOOL hasDoneTheWork = NO;
	
	if (!hasDoneTheWork)
	{
		hasDoneTheWork = YES;
		NSArray* versionComponents = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
		NSInteger majorVersionNumber = [(NSString*)[versionComponents objectAtIndex:0] intValue];
		is3PointOh = majorVersionNumber >= 3;
	}
	
	return is3PointOh;
}

BOOL is3Point2SystemVersion()
{
	static BOOL is3Point2 = NO;
	static BOOL hasDoneTheWork = NO;
	
	if (!hasDoneTheWork)
	{
		hasDoneTheWork = YES;
		NSArray* versionComponents = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
		NSInteger majorVersionNumber = [(NSString*)[versionComponents objectAtIndex:0] intValue];
		NSInteger minorVersionNumber = [(NSString*)[versionComponents objectAtIndex:1] intValue];
        is3Point2 = (majorVersionNumber == 3 && minorVersionNumber >= 2) || majorVersionNumber > 3;
	}
	
	return is3Point2;
}

BOOL is4PointOhSystemVersion()
{
	static BOOL is4PointOh = NO;
	static BOOL hasDoneTheWork = NO;
	
	if (!hasDoneTheWork)
	{
		hasDoneTheWork = YES;
		NSArray* versionComponents = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
		NSInteger majorVersionNumber = [(NSString*)[versionComponents objectAtIndex:0] intValue];
		is4PointOh = majorVersionNumber >= 4;
	}
	
	return is4PointOh;
}

BOOL is4Point1SystemVersion()
{
	static BOOL is4Point1 = NO;
	static BOOL hasDoneTheWork = NO;
	
	if (!hasDoneTheWork)
	{
		hasDoneTheWork = YES;
		NSArray* versionComponents = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
		NSInteger majorVersionNumber = [(NSString*)[versionComponents objectAtIndex:0] intValue];
		NSInteger minorVersionNumber = [(NSString*)[versionComponents objectAtIndex:1] intValue];
        is4Point1 = (majorVersionNumber == 4 && minorVersionNumber >= 1) || majorVersionNumber > 4;
	}
	
	return is4Point1;
}

NSString* getHardwareVersion()
{
	size_t size = 0;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	
	char* tempString = (char*)malloc(size);
	sysctlbyname("hw.machine", tempString, &size, NULL, 0);
	
	NSString* hardwareType = [NSString stringWithUTF8String:tempString];
	free(tempString);
	
	return hardwareType;
}
