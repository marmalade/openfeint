//  Copyright 2011 Aurora Feint, Inc.
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
#import "OFXmlElement.h"
#import "OFXmlElement+Parsing.h"

@interface OFXmlElement ()
@property (nonatomic, retain, readwrite) NSMutableArray* children;
@property (nonatomic, retain) NSMutableArray* loadingElements;
@end


@implementation OFXmlElement
@synthesize value = mValue;
@synthesize name = mName;
@synthesize attributes = mAttributes;
@synthesize children = mChildren;
@synthesize loadingElements = mLoadingElements;

+(id)elementWithString:(NSString*)str
{
    return [self parseElementsFromData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

+(id)elementWithData:(NSData*)data
{
    return [self parseElementsFromData:data];
}

+(id)elementWithName:(NSString*)name
{
    return [[[self alloc] initWithName:name] autorelease];
}

-(id)initWithName:(NSString*)name
{
    if((self = [super init]))
    {
        self.name = name;
        self.children = [NSMutableArray array];
    }
    return self;
}

-(void)dealloc
{
    self.value = nil;
    self.name = nil;
    self.attributes = nil;
    self.children = nil;
    self.loadingElements = nil;
    [super dealloc];
}

-(OFXmlElement*)getChildWithName:(NSString*)name
{
    for(OFXmlElement* child in self.children)
    {
        if([child.name isEqualToString:name]) return child;
    }
    return nil;
}

-(void)addChild:(OFXmlElement*)childNode
{
    [self.children addObject:childNode];
}

-(OFXmlElement*)getChildAt:(NSUInteger) index
{
    return [self.children objectAtIndex:index];
}

-(BOOL)hasChildren
{
    return self.children.count > 0;
}

-(NSString*)description
{
    NSMutableString* value = [NSMutableString stringWithCapacity:100];
    [value appendFormat:@"name: %@\nvalue: %@\n", mName, mValue];
    if (mAttributes)
    {
        [value appendFormat:@"params:\n%@\n", mAttributes];
    }
    for(OFXmlElement* child in self.children)
    {
        NSString* childString = [child description];
        [value appendFormat:@"{\n%@\n}", childString];
    }
    return value;
}

@end
