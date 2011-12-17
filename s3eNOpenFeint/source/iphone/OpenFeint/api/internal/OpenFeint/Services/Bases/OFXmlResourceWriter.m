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

#import "OFXmlResourceWriter.h"
#import "OFResource.h"
#import "OFResource+ObjC.h"
#import "OFResourceField.h"
#import "OFDependencies.h"

#pragma mark OFXmlResourceNode

@implementation OFXmlResourceNode

@synthesize children, key, value;

+ (id)nodeWithKey:(NSString*)key andValue:(NSString*)value
{
	return [[[OFXmlResourceNode alloc] initWithKey:key andValue:value] autorelease];
}

+ (id)nodeWithKey:(NSString*)key andChildren:(NSMutableArray*)children
{
	return [[[OFXmlResourceNode alloc] initWithKey:key andChildren:children] autorelease];
}

- (id)initWithKey:(NSString*)_key andValue:(NSString*)_value
{
	self = [super init];
	if (self)
	{
		self.key = _key;
		self.value = _value;
	}
	return self;
}

- (id)initWithKey:(NSString*)_key andChildren:(NSMutableArray*)_children
{
	self = [super init];
	if (self)
	{
		self.key = _key;
		self.children = _children;
	}
	return self;
}

- (void)openScope:(NSMutableString*)document
{
	[document appendFormat:@"<%@>", self.key];
}

- (void)closeScope:(NSMutableString*)document
{
	[document appendFormat:@"</%@>", self.key];
}

- (void)writeContent:(NSMutableString*)document
{
	if (self.value)
	{
		[document appendString:self.value];
	}
	else
	{
		for (OFXmlResourceNode* child in self.children)
		{
			[child appendXmlToString:document];
		}
	}
}

- (void)appendXmlToString:(NSMutableString*)document
{
	[self openScope:document];
	[self writeContent:document];
	[self closeScope:document];
}

- (NSString*)toXmlString
{
	NSMutableString* document = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
	[self appendXmlToString:document];
	return document;
}


- (void)dealloc
{
	self.children = nil;
	self.key = nil;
	self.value = nil;
	[super dealloc];
}

@end

#pragma mark OFXmlResourceWriter Implementation

@implementation OFXmlResourceWriter

+ (NSString*)xmlStringFromResources:(NSArray*)resources
{
	OFXmlResourceWriter* writer = [OFXmlResourceWriter xmlWriterWithResources:resources];
	return [writer createXmlAsString];
}

+ (OFXmlResourceWriter*)xmlWriterWithResources:(NSArray*)resources
{
	return [[[OFXmlResourceWriter alloc] initWithResources:resources] autorelease];
}

- (id)initWithResources:(NSArray*)resources
{
	self = [super init];
	if (self)
	{
		mRootNode = [[OFXmlResourceNode nodeWithKey:@"resources" andChildren:[self buildNodesFromResources:resources]] retain];
	}
	return self;
}

- (OFXmlResourceNode*)buildNodeFromResource:(OFResource*)resource withKey:(NSString *)theKey
{
	NSMutableArray* children = [[NSMutableArray new] autorelease];
	[children addObject:[OFXmlResourceNode nodeWithKey:@"id" andValue:resource.resourceId]];
	
    for(NSString* fieldName in [[resource class] dataDictionary])
	{
        OFResourceField* field = [[[resource class] dataDictionary] objectForKey:fieldName];
		if (field.getter)
		{
			id value = [resource performSelector:field.getter];
			if (field.isArray)
			{
				[children addObject:[self buildNodesFromResources:value]];
				[children addObject:[OFXmlResourceNode nodeWithKey:fieldName andChildren:[self buildNodesFromResources:value]]];

			}
			else if (field.resourceClass)
			{
				//[[resource class] getResourceName]
				[children addObject:[self buildNodeFromResource:value withKey:fieldName]];
			}
			else
			{
				[children addObject:[OFXmlResourceNode nodeWithKey:fieldName andValue:value]];
			}
		}
		else
		{
			OFLog(@"Trying to serialize out resource without a getter (%@)", fieldName);
		}
	}
	//return [OFXmlResourceNode nodeWithKey:@"wtf" andChildren:children];

	return [OFXmlResourceNode nodeWithKey:theKey andChildren:children];
}

- (NSMutableArray*)buildNodesFromResources:(NSArray*)resources
{
	NSMutableArray *nodes = [[NSMutableArray new] autorelease];
	for (OFResource* curResource in resources)
	{
		[nodes addObject:[self buildNodeFromResource:curResource withKey:[[curResource class] getResourceName]]];
	}
	return nodes;
}

- (NSString*)createXmlAsString
{
	return [mRootNode toXmlString];
}



@end
