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
#import "OFMarkupLanguage.h"
#import "TTTAttributedLabel.h"
#import "NSString+OpenFeint.h"
#import "OFDependencies.h"

@interface OFMarkupTagInfo : NSObject
{
}

+ (OFMarkupTagInfo*)markupTagInfo;

@property (nonatomic, retain) NSString* attributeName;
@property (nonatomic, retain) NSString* paramValue;
@property (nonatomic, assign) int rangeOfOpeningTokenLocation;
@property (nonatomic, assign) int rangeOfOpeningTokenLength;
@property (nonatomic, assign) int rangeOfClosingTokenLocation;
@property (nonatomic, assign) int rangeOfClosingTokenLength;

@end


@implementation OFMarkupTagInfo

@synthesize attributeName, paramValue, rangeOfOpeningTokenLocation, rangeOfOpeningTokenLength, rangeOfClosingTokenLocation, rangeOfClosingTokenLength;

+ (OFMarkupTagInfo*)markupTagInfo
{
	return [[[OFMarkupTagInfo alloc] init] autorelease];
}

- (void)dealloc
{
	self.attributeName = nil;
	self.paramValue = nil;
	[super dealloc];
}

@end



@protocol OFMarkupAttribute
+ (void)applyAttribute:(NSString*)paramValue range:(NSRange)range toString:(NSMutableAttributedString*)string defaultFont:(UIFont*)defaultFont;
+ (NSString*)getAttributeName;
@end

@interface OFFontMarkupAttribute : NSObject <OFMarkupAttribute>
{
}
@end

@implementation OFFontMarkupAttribute

+ (void)applyAttribute:(NSString*)paramValue range:(NSRange)range toString:(NSMutableAttributedString*)string defaultFont:(UIFont*)defaultFont
{
	NSArray* params = [paramValue componentsSeparatedByString:@"@"];
	if ([params count] > 0)
	{
		float fontSize = defaultFont.pointSize;
		if ([params count] > 1)
		{
			int paramFontSize = [[params objectAtIndex:1] floatValue];
			if (paramFontSize > 0)
			{
				fontSize = paramFontSize;
			}
		}
		if (fontSize <= 0)
		{
			fontSize = 10;
		}
		NSString* fontName = [params objectAtIndex:0];
		CTFontRef font = CTFontCreateWithName((CFStringRef)fontName, fontSize, NULL);
		if (font)
		{
			[string addAttribute:(NSString*)kCTFontAttributeName value:(id)font range:range];
		}
	}
}

+ (NSString*)getAttributeName
{
	return @"font";
}

@end

@interface OFColorMarkupAttribute : NSObject <OFMarkupAttribute>
{
}
@end

@implementation OFColorMarkupAttribute

+ (void)applyAttribute:(NSString*)paramValue range:(NSRange)range toString:(NSMutableAttributedString*)string defaultFont:(UIFont*)defaultFont
{
	UIColor* color = [paramValue toColor];
	if (color)
	{
		[string addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[color CGColor] range:range];
	}
	else
	{
		OFLog(@"Color not correct format: %@", paramValue);
	}
}

+ (NSString*)getAttributeName
{
	return @"color";
}

@end

@interface OFUnderlineMarkupAttribute : NSObject <OFMarkupAttribute>
{
}
@end

@implementation OFUnderlineMarkupAttribute

+ (void)applyAttribute:(NSString*)paramValue range:(NSRange)range toString:(NSMutableAttributedString*)string defaultFont:(UIFont*)defaultFont
{
	[string addAttribute:(NSString*)kCTUnderlineStyleAttributeName value:[NSNumber numberWithInt:kCTUnderlineStyleSingle] range:range];
}

+ (NSString*)getAttributeName
{
	return @"underline";
}

@end




@implementation OFMarkupLanguage

+ (OFMarkupTagInfo*)findFirstMarkupTag:(NSString*)text range:(NSRange)range
{
	BOOL searchAgain = YES;
	while(searchAgain)
	{
		searchAgain = NO;
		NSRange rangeOfOpeningBrace = [text rangeOfString:@"<" options:0 range:range];
		if (rangeOfOpeningBrace.location != NSNotFound)
		{
			NSRange rangeToSearchClosingBrace = NSMakeRange(rangeOfOpeningBrace.location + 1,
															range.location + range.length - (rangeOfOpeningBrace.location + 1));
			NSRange rangeOfClosingBrace = [text rangeOfString:@">" options:0 range:rangeToSearchClosingBrace];
			if (rangeOfClosingBrace.location != NSNotFound)
			{
				NSRange rangeInsideBraces = NSMakeRange(rangeOfOpeningBrace.location + 1,
															  rangeOfClosingBrace.location - (rangeOfOpeningBrace.location + 1));
				NSRange rangeOfEqualsSign = [text rangeOfString:@"=" options:0 range:rangeInsideBraces];
				OFMarkupTagInfo* tagInfo = [OFMarkupTagInfo markupTagInfo];
				NSRange rangeOfAttributeName = NSMakeRange(rangeOfOpeningBrace.location + 1,
														   rangeOfClosingBrace.location - (rangeOfOpeningBrace.location + 1));
				if (rangeOfEqualsSign.location != NSNotFound)
				{
					tagInfo.paramValue = [text substringWithRange:NSMakeRange(rangeOfEqualsSign.location + 1,
																	  rangeOfClosingBrace.location - (rangeOfEqualsSign.location + 1))];
					rangeOfAttributeName.length = rangeOfEqualsSign.location - (rangeOfOpeningBrace.location + 1);
				}
				tagInfo.attributeName = [text substringWithRange:rangeOfAttributeName];
				
				NSString* closingToken = [NSString stringWithFormat:@"</%@>", tagInfo.attributeName];
				NSRange rangeToSearchClosingToken = NSMakeRange(rangeOfClosingBrace.location + 1,
																range.location + range.length - (rangeOfClosingBrace.location + 1));
				NSRange rangeOfClosingToken = [text rangeOfString:closingToken options:0 range:rangeToSearchClosingToken];
				if (rangeOfClosingToken.location != NSNotFound)
				{
					tagInfo.rangeOfClosingTokenLocation = rangeOfClosingToken.location;
					tagInfo.rangeOfClosingTokenLength = rangeOfClosingToken.length;
					tagInfo.rangeOfOpeningTokenLocation = rangeOfOpeningBrace.location;
					tagInfo.rangeOfOpeningTokenLength = rangeOfClosingBrace.location+1 - rangeOfOpeningBrace.location;
					return tagInfo;
				}
				else
				{
					OFLog(@"No closing token for %@", text);
					searchAgain = YES;
					range = NSMakeRange(rangeOfClosingBrace.location + 1,
												 range.location + range.length - (rangeOfClosingBrace.location + 1));
				}
			}
			else
			{
				searchAgain = YES;
				range = NSMakeRange(rangeOfOpeningBrace.location + 1,
											 range.length - (rangeOfOpeningBrace.location + 1));
			}
		}
	}
	
	return nil;
}

+ (Class)markupAttributeNamed:(NSString*)name
{
	NSArray* attributeArray = [NSArray arrayWithObjects:
							   [OFFontMarkupAttribute class],
							   [OFColorMarkupAttribute class],
							   [OFUnderlineMarkupAttribute class],
							   nil];
	
	for (Class attributeClass in attributeArray)
	{
		if ([name isEqualToString:[attributeClass getAttributeName]])
		{
			return attributeClass;
		}
	}
	return nil;
}

+ (NSAttributedString*)attributedStringByParsingMarkup:(NSString*)text withAttributesFromLabel:(UILabel*)label
{	
	NSMutableAttributedString* mutableAttributedString = [[[NSMutableAttributedString alloc] initWithString:text] autorelease];
    [mutableAttributedString addAttributes:[TTTAttributedLabel NSAttributedStringAttributesFromLabel:label] range:NSMakeRange(0, [mutableAttributedString length])];
	
	int rangeRemainingStart = 0;
	while (rangeRemainingStart < [mutableAttributedString length])
	{
		NSString* currentText = [mutableAttributedString string];
		NSRange rangeRemaining = NSMakeRange(rangeRemainingStart, [currentText length] - rangeRemainingStart);
		OFMarkupTagInfo* tagInfo = [self findFirstMarkupTag:currentText range:rangeRemaining];
		if (tagInfo)
		{
			Class attributeClass = [self markupAttributeNamed:tagInfo.attributeName];
			
			if (attributeClass)
			{
				NSRange markupRange = NSMakeRange(tagInfo.rangeOfOpeningTokenLocation + tagInfo.rangeOfOpeningTokenLength,
												  tagInfo.rangeOfClosingTokenLocation - (tagInfo.rangeOfOpeningTokenLocation + tagInfo.rangeOfOpeningTokenLength));
				[attributeClass applyAttribute:tagInfo.paramValue range:markupRange toString:mutableAttributedString defaultFont:label.font];
				
				[mutableAttributedString deleteCharactersInRange:NSMakeRange(tagInfo.rangeOfClosingTokenLocation, tagInfo.rangeOfClosingTokenLength)];
				[mutableAttributedString deleteCharactersInRange:NSMakeRange(tagInfo.rangeOfOpeningTokenLocation, tagInfo.rangeOfOpeningTokenLength)];
			}
			else
			{
				OFLog(@"Unknown attribute: %@", tagInfo.attributeName);
				rangeRemainingStart = tagInfo.rangeOfOpeningTokenLocation + tagInfo.rangeOfOpeningTokenLength;
			}
		}
		else
		{
			break;
		}
	}
	
	return mutableAttributedString;
}

+ (NSString*)removeMarkupFromText:(NSString*)text
					  outAltColor:(UIColor**)outAltColor
			outAltColorStringStartIndex:(int*)outAltColorStringStartIndex
			  outAltColorStringLength:(int*)outAltColorStringLength
{
	NSMutableString* mutableString = [[text mutableCopy] autorelease];
	
	if (outAltColor)
	{
		*outAltColor = nil;
	}
	
	int rangeRemainingStart = 0;
	while (rangeRemainingStart < [mutableString length])
	{
		NSRange rangeRemaining = NSMakeRange(rangeRemainingStart, [mutableString length] - rangeRemainingStart);
		OFMarkupTagInfo* tagInfo = [self findFirstMarkupTag:mutableString range:rangeRemaining];
		if (tagInfo)
		{
			Class attributeClass = [self markupAttributeNamed:tagInfo.attributeName];
			
			if (attributeClass)
			{				
				[mutableString deleteCharactersInRange:NSMakeRange(tagInfo.rangeOfClosingTokenLocation, tagInfo.rangeOfClosingTokenLength)];
				[mutableString deleteCharactersInRange:NSMakeRange(tagInfo.rangeOfOpeningTokenLocation, tagInfo.rangeOfOpeningTokenLength)];
				
				if (outAltColor &&
					(*outAltColor == nil) &&
					[tagInfo.attributeName isEqualToString:@"color"])
				{
					if (outAltColor)
					{
						*outAltColor = [tagInfo.paramValue toColor];
					}
					if (outAltColorStringStartIndex)
					{
						*outAltColorStringStartIndex = tagInfo.rangeOfOpeningTokenLocation;
					}
					if (outAltColorStringLength)
					{
						*outAltColorStringLength = tagInfo.rangeOfClosingTokenLocation - (tagInfo.rangeOfOpeningTokenLocation + tagInfo.rangeOfOpeningTokenLength);
					}
				}
			}
			else
			{
				OFLog(@"Unknown attribute: %@", tagInfo.attributeName);
				rangeRemainingStart = tagInfo.rangeOfOpeningTokenLocation + tagInfo.rangeOfOpeningTokenLength;
			}
		}
		else
		{
			break;
		}
	}
	
	return mutableString;
}



@end
