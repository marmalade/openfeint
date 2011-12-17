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
#import "OFPresenceQueue.h"
#import "OFDependencies.h"

@implementation OFPresenceQueue

@synthesize name;

- (void)setName:(NSString*)value
{
	OFSafeRelease(name);
	name = [value retain];
}


+ (NSString*)getResourceName
{
	return @"presence_queue";
}

- (void)dealloc
{
	OFSafeRelease(name);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setName:)], @"name",
        nil] retain];
    }
    return sDataDictionary;
}
@end
