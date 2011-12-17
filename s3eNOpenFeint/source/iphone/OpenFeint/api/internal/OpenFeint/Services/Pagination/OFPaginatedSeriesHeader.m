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

#import "OFPaginatedSeriesHeader.h"
#import "OFXmlElement.h"


static NSUInteger readIntValueFromXml(NSString*name, OFXmlElement* element)
{
    OFXmlElement*child = [element getChildWithName:name];
    return [child.value integerValue];
}

@implementation OFPaginatedSeriesHeader

@synthesize currentOffset;
@synthesize currentPage;
@synthesize totalPages;
@synthesize perPage;
@synthesize totalObjects;

+ (NSString*)getElementName
{
	return @"pagination_header";
}

+ (OFPaginatedSeriesHeader*)paginationHeaderWithXml:(OFXmlElement*)element;
{
	return [[[OFPaginatedSeriesHeader alloc] initWithXml:element] autorelease];
}


- (OFPaginatedSeriesHeader*)initWithXml:(OFXmlElement*)element;
{
	self = [super init];
	if (self != nil)
	{
		currentOffset	= readIntValueFromXml(@"current_offset", element);
		currentPage		= readIntValueFromXml(@"current_page", element);
		totalPages		= readIntValueFromXml(@"total_pages", element);
		perPage			= readIntValueFromXml(@"per_page", element);
		totalObjects	= readIntValueFromXml(@"total_entries", element);					
	}
	return self;
}

- (OFPaginatedSeriesHeader*)initWithPaginationSeriesHeader:(OFPaginatedSeriesHeader*)otherHeader
{
	self = [super init];
	if (self != nil)
	{
		currentOffset = otherHeader.currentOffset;
		currentPage = otherHeader.currentPage;
		totalPages = otherHeader.totalPages;
		perPage = otherHeader.perPage;
		totalObjects = otherHeader.totalObjects;		
	}
	return self;
	
}


+ (OFPaginatedSeriesHeader*)paginationHeaderClonedFrom:(OFPaginatedSeriesHeader*)otherHeader
{
	if(otherHeader == nil)
	{
		return nil;
	}
	
	return [[[OFPaginatedSeriesHeader alloc] initWithPaginationSeriesHeader:otherHeader] autorelease];
}

- (BOOL)isLastPageLoaded
{
	return currentPage >= totalPages;
}

@end
