////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2011 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#import "OFColor.h"

@implementation OFColor
@synthesize red, green, blue, alpha;

#define clampInt(i, min, max) {(i < min ? min : (i > max ? max : i))}

+ (OFColor*)colorWithRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
    return [[[OFColor alloc] initWithRed:r green:g blue:b alpha:a] autorelease];
}

+ (OFColor*)colorWithRed:(float)r green:(float)g blue:(float)b
{
    return [self colorWithRed:r green:g blue:b alpha:1.0f];
}

- (id)initWithRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
    if((self = [super init]))
    {
        red = r;
        green = g;
        blue = b;
        alpha = a;
    }
    return self;
}

- (id)initWithRed:(float)r green:(float)g blue:(float)b
{
    return [self initWithRed:r green:g blue:b alpha:1.0f];
}

- (NSString*)toString
{
	int iRed = clampInt((int)(red*255.0f), 0, 255);
	int iGreen = clampInt((int)(green*255.0f), 0, 255);
	int iBlue = clampInt((int)(blue*255.0f), 0, 255);
	int iAlpha = clampInt((int)(alpha*255.0f), 0, 255);
	NSString* string = [NSString stringWithFormat:@"#%.2X%.2X%.2X%.2X", iRed, iGreen, iBlue, iAlpha];
	return string;
}

- (NSString *)description
{
    return [self toString];
}

@end
