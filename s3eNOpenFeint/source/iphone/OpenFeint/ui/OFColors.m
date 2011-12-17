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

#include "OFColors.h"
static UIColor* sDarkGreen;
static UIColor* sMiddleGreen;
static UIColor* sBrightGreen;
static UIColor* sYellow;
static UIColor* sSemiTransparentBlack;
static UIColor* sLightBlue;
static UIColor* sNavBarColor;
static UIColor* sDefaultGreyColor;
static BOOL loaded = NO;

@implementation OFColors

+(void)load
{
    if(!loaded)
    {
        loaded = YES;
        sDarkGreen = [[[UIColor alloc] initWithRed:24.f/255.f green:81.f/255.f blue:80.f/255.f alpha:1.f] retain];
        sMiddleGreen = [[[UIColor alloc] initWithRed:60.f/255.f green:110.f/255.f blue:81.f/255.f alpha:1.f] retain];
        sBrightGreen = [[[UIColor alloc] initWithRed:174.f/255.f green:242.f/255.f blue:184.f/255.f alpha:1.f] retain];
        sYellow = [[[UIColor alloc] initWithRed:254.f/255.f green:241.f/255.f blue:97.f/255.f alpha:1.f] retain];
        sSemiTransparentBlack = [[[UIColor alloc] initWithRed:0.f green:0.f blue:0.f alpha:0.5f] retain];
        sLightBlue = [[[UIColor alloc] initWithRed:10.f/255.f green:116.f/255.f blue:180.f/255.f alpha:1.f] retain];
        sNavBarColor = [[[UIColor alloc] initWithRed:128.f/255.f green:128.f/255.f blue:128.f/255.f alpha:1.f] retain];
        sDefaultGreyColor = [[[UIColor alloc] initWithWhite:186.f/255.f alpha:1.f] retain];    
    }
}

+(UIColor*)darkGreen { [self load]; return sDarkGreen; }
+(UIColor*)middleGreen { [self load]; return sMiddleGreen; }
+(UIColor*)brightGreen { [self load]; return sBrightGreen; }
+(UIColor*)yellow { [self load]; return sYellow; }
+(UIColor*)semiTransparentBlack { [self load]; return sSemiTransparentBlack; }
+(UIColor*)lightBlue { [self load]; return sLightBlue; }
+(UIColor*)navBarColor { [self load]; return sNavBarColor; }
+(UIColor*)defaultGreyColor { [self load]; return sDefaultGreyColor; }


@end
