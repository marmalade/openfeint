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

#import "NSString+OpenFeint.h"
#import "sha1.h"
#import "OFDependencies.h"

@implementation NSString (OpenFeint)

- (NSString*) sha1 
{
    const char *cString = [self UTF8String];
    unsigned char output[20];
    
    SHA1_CTX ctx;
    OFSHA1Init(&ctx);
    OFSHA1Update(&ctx, (unsigned char*)cString, strlen(cString));
    OFSHA1Final(output, &ctx);
    
    unsigned char printableOutput[41];
    const char hexString[] = "0123456789abcdef";
    for(int i=0; i<20; ++i) {
        printableOutput[2*i] = hexString[(output[i]>>4)&15];
        printableOutput[2*i+1] = hexString[(output[i])&15];
    }
    printableOutput[40] = 0;
    
    NSString *result = [NSString stringWithCString:(const char*)printableOutput encoding:NSUTF8StringEncoding];
    return result;
}

- (UIFont*)getFontToFitSize:(CGSize) size font:(UIFont*) font max:(uint) maxFontSize min:(uint) minFontSize
{
	if(minFontSize > maxFontSize || minFontSize == 0 || maxFontSize == 0)
	{
		//Invalid cases
		return nil;
	}
	
	//Go from max font size to min, along the way - see if any fits in side the size passed in.  If we find one that fits inside,
	//return that font immediately.
	UIFont* fontToFitInRect = nil;
	for(uint i = maxFontSize; i > minFontSize; i--)
	{
		fontToFitInRect = [font fontWithSize:i];
		CGSize constraintSize = CGSizeMake(size.width, MAXFLOAT);
		CGSize sizeWithFont = [self sizeWithFont:fontToFitInRect constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
		if(sizeWithFont.height <= size.height)
		{
			return fontToFitInRect;
		}
	}
	
	return [font fontWithSize:minFontSize];
}


- (NSComparisonResult)compareVersionStringComponent:(NSString*)versionStringComponent
{
	int number1, number2;
	NSScanner* scan1 = [NSScanner scannerWithString:self];
	NSScanner* scan2 = [NSScanner scannerWithString:versionStringComponent];
	if (![scan1 scanInt:&number1])
	{
		OFLog(@"Bad version component: %@", self);
		return NSOrderedAscending;
	}
	if (![scan2 scanInt:&number2])
	{
		OFLog(@"Bad version component: %@", versionStringComponent);
		return NSOrderedDescending;
	}
	if (number1 > number2)
	{
		return NSOrderedDescending;
	}
	if (number1 < number2)
	{
		return NSOrderedAscending;
	}
	if (![scan1 isAtEnd] && ![scan2 isAtEnd])
	{
		// Comparing, for example, "2b" to "2c"
		NSString* remainder1 = [[scan1 string] substringFromIndex:[scan1 scanLocation]];
		NSString* remainder2 = [[scan2 string] substringFromIndex:[scan2 scanLocation]];
		return [remainder1 compare:remainder2];
	}
	if ([scan1 isAtEnd] && [scan2 isAtEnd])
	{
		return NSOrderedSame;
	}
	if ([scan1 isAtEnd])
	{
		// versionStringComponent has a number and a letter.  self just has a number.
		return NSOrderedAscending;
	}
	if ([scan2 isAtEnd])
	{
		// self has a number and a letter.  versionStringComponent just has a number.
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

- (NSComparisonResult)compareVersionString:(NSString*)versionString
{
	NSArray* components1 = [self componentsSeparatedByString:@"."];
	NSArray* components2 = [versionString componentsSeparatedByString:@"."];
	for (int i = 0; i < components1.count && i < components2.count; i++)
	{
		NSString* component1 = [components1 objectAtIndex:i];
		NSString* component2 = [components2 objectAtIndex:i];
		
		NSComparisonResult componentResult = [component1 compareVersionStringComponent:component2];
		if (componentResult != NSOrderedSame)
		{
			return componentResult;
		}
	}
	if (components1.count != components2.count)
	{
		return (components1.count > components2.count) ? NSOrderedDescending : NSOrderedAscending;
	}
	return NSOrderedSame;
}

- (int)hexStringToIntegerValue
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	unsigned int retval;
	if (![scanner scanHexInt:&retval])
	{
		return 0;
	}
	return retval;
}

- (UIColor*)toColor
{
	if (([self length] == 7 || [self length] == 9) && ([self characterAtIndex:0] == '#'))
	{
		int iRed = [[self substringWithRange:NSMakeRange(1,2)] hexStringToIntegerValue];
		float fRed = iRed/255.0f;
		int iGreen = [[self substringWithRange:NSMakeRange(3,2)] hexStringToIntegerValue];
		float fGreen = iGreen/255.0f;
		int iBlue = [[self substringWithRange:NSMakeRange(5,2)] hexStringToIntegerValue];
		float fBlue = iBlue/255.0f;
		float fAlpha = 1.0f;
		if ([self length] == 9)
		{
			int iAlpha = [[self substringWithRange:NSMakeRange(7,2)] hexStringToIntegerValue];
			fAlpha = iAlpha/255.0f;
		}
		UIColor* color = [UIColor colorWithRed:fRed green:fGreen blue:fBlue alpha:fAlpha];
		return color;
	}
	return nil;
}

@end
