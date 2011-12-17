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
#import "OFApplicationDescription.h"
#import "OFResource+ObjC.h"
#import "OFApplicationDescriptionService.h"
#import "OFDependencies.h"

@implementation OFApplicationDescription

@synthesize name, iconUrl, itunesId, price, currentVersion, briefDescription, extendedDescription, applicationId;

- (void)setName:(NSString*)value
{
	OFSafeRelease(name);
	name = [value retain];
}

- (void)setIconUrl:(NSString*)value
{
	OFSafeRelease(iconUrl);
	if (![value isEqualToString:@""])
	{
		iconUrl = [value retain];
	}
}

- (void)setItunesId:(NSString*)value
{
	OFSafeRelease(itunesId);
	itunesId = [value retain];
}

- (void)setPrice:(NSString*)value
{
	OFSafeRelease(price);
	price = [value retain];
}

- (void)setCurrentVersion:(NSString*)value
{
	OFSafeRelease(currentVersion);
	currentVersion = [value retain];
}

- (void)setBriefDescription:(NSString*)value
{
	OFSafeRelease(briefDescription);
	briefDescription = [value retain];
}

- (void)setExtendedDescription:(NSString*)value
{
	OFSafeRelease(extendedDescription);
	extendedDescription = [value retain];
}

- (void)setApplicationId:(NSString*)value
{
	OFSafeRelease(applicationId);
	applicationId = [value retain];
}

+ (OFService*)getService;
{
	return [OFApplicationDescriptionService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"application_description";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (void) dealloc
{
	OFSafeRelease(name);
	OFSafeRelease(iconUrl);
	OFSafeRelease(itunesId);
	OFSafeRelease(price);
	OFSafeRelease(currentVersion);
	OFSafeRelease(briefDescription);
	OFSafeRelease(extendedDescription);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setName:)], @"name",
[OFResourceField fieldSetter:@selector(setIconUrl:)], @"icon_url",
[OFResourceField fieldSetter:@selector(setPrice:)], @"price",
[OFResourceField fieldSetter:@selector(setItunesId:)], @"itunes_id",
[OFResourceField fieldSetter:@selector(setCurrentVersion:)], @"current_version",
[OFResourceField fieldSetter:@selector(setBriefDescription:)], @"description_brief",
[OFResourceField fieldSetter:@selector(setExtendedDescription:)], @"description_extended",
[OFResourceField fieldSetter:@selector(setApplicationId:)], @"client_application_id",
        nil] retain];
    }
    return sDataDictionary;
}
@end
