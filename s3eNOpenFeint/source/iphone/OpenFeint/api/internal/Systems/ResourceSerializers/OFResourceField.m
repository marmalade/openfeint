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
#import "OFResourceField.h"
#import "objc/runtime.h"
@interface OFResourceField()
@property (nonatomic, readwrite) SEL setter;
@property (nonatomic, readwrite) SEL getter;
@property (nonatomic, retain, readwrite) Class resourceClass;
@property (nonatomic, readwrite) BOOL isArray;


@end


@implementation OFResourceField
@synthesize setter = mSetter;
@synthesize getter = mGetter;
@synthesize resourceClass = mResourceClass;
@synthesize isArray = mIsArray;

-(id) initWithSetter:(SEL) setter getter:(SEL) getter klass:(Class) resourceClass isArray:(BOOL) isArray
{
    if((self = [super init]))
    {
        self.setter = setter;
        self.getter = getter;
        self.resourceClass = resourceClass;
        self.isArray = isArray;
    }
    return self;
}

-(void) dealloc
{
    self.resourceClass = nil;
    [super dealloc];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"Resource field setter:%s getter:%s klass:%@ array?%@",
            sel_getName(self.setter), sel_getName(self.getter), self.resourceClass, self.isArray ? @"YES" : @"NO"];
}

+(id) fieldSetter:(SEL)setter
{
    return [[[OFResourceField alloc] initWithSetter:setter getter:nil klass:nil isArray:NO] autorelease];
}
+(id) fieldSetter:(SEL)setter getter:(SEL)getter
{
    return [[[OFResourceField alloc] initWithSetter:setter getter:getter klass:nil isArray:NO] autorelease];
}
+(id) nestedResourceSetter:(SEL)setter getter:(SEL)getter klass:(Class) resourceClass
{
    return [[[OFResourceField alloc] initWithSetter:setter getter:getter klass:resourceClass isArray:NO] autorelease];
}
+(id) nestedResourceArraySetter:(SEL) setter
{
    return [[[OFResourceField alloc] initWithSetter:setter getter:nil klass:nil isArray:YES] autorelease];
}
+(id) nestedResourceArraySetter:(SEL) setter getter:(SEL)getter
{
    return [[[OFResourceField alloc] initWithSetter:setter getter:getter klass:nil isArray:YES] autorelease];
}
@end
