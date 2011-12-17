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
#import "OFGameFeedItem+DynamicLayout.h"
#import "OFGameFeedView.h"
#import "OpenFeint+Private.h"
#import "OFImageView.h"
#import "OFImageLoader.h"
#import "OFGameFeedView+Private.h"
#import "OFURLDispatcher.h"
#import "OFGameFeedDashboardAnalyticsListener.h"
#import "NSDictionary+OpenFeint.h"
#import "TTTAttributedLabel.h"
#import "OFMarkupLanguage.h"
#import "OFWebViewCacheLoader.h"
#import "IPhoneOSIntrospection.h"
#import "OFColoredTextLabel.h"
#import "OFWebViewManifestService.h"
#import "OFDependencies.h"

@implementation OFGameFeedItem (DynamicLayout)

- (BOOL)makeCGRectFromDictionary:(NSDictionary*)dictionary forKey:(id)aKey rect:(CGRect*)rect
{
	NSArray* rectArray = [dictionary objectForKey:aKey ifKindOfClass:[NSArray class]];
	float vals[4];
	if (rectArray && rectArray.count == 4)
	{
		for (int i = 0; i < 4; i++)
		{
			NSObject* obj = [rectArray objectAtIndex:i];
			if ([obj isKindOfClass:[NSString class]])
			{
				NSString* objString = (NSString*)obj;
				vals[i] = [objString floatValue];
			}
		}
		*rect = CGRectMake(vals[0],vals[1],vals[2],vals[3]);
		return YES;
	}
	return NO;
}

- (BOOL)makeCGSizeFromDictionary:(NSDictionary*)dictionary forKey:(id)aKey size:(CGSize*)size
{
	NSArray* sizeArray = [dictionary objectForKey:aKey ifKindOfClass:[NSArray class]];
	float vals[2];
	if (sizeArray && sizeArray.count == 2)
	{
		for (int i = 0; i < 2; i++)
		{
			NSObject* obj = [sizeArray objectAtIndex:i];
			if ([obj isKindOfClass:[NSString class]])
			{
				NSString* objString = (NSString*)obj;
				vals[i] = [objString floatValue];
			}
		}
		*size = CGSizeMake(vals[0],vals[1]);
		return YES;
	}
	return NO;
}

- (void)createLabel:(NSDictionary*)objectData withItemData:(NSDictionary*)itemData
{
	NSString* text = [objectData objectForKey:@"text" ifKindOfClass:[NSString class]];
	if (text)
	{
		UILabel *label;
		
		if (is3Point2SystemVersion())
		{
			label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0,0,300,80)];
		}
		else
		{
			label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,300,80)];
		}
		
		[label autorelease];
		label.textColor = [self interpolateColor:[objectData objectForKey:@"color"] withData:itemData defaultColor:[UIColor grayColor]];
		
		[label setOpaque:NO];
		[label setBackgroundColor:nil];
		[label setTextAlignment:UITextAlignmentLeft];
		label.numberOfLines = 0;
		label.lineBreakMode = UILineBreakModeWordWrap;
		
		NSString* fontName = [objectData objectForKey:@"font" ifKindOfClass:[NSString class]];
		
		float fontSize = 10.5f;
		NSString* fontSizeString = [objectData objectForKey:@"font_size" ifKindOfClass:[NSString class]];
		if (fontSizeString)
		{
			float fontSizeFromData = [fontSizeString floatValue];
			if (fontSizeFromData > 0.0f)
			{
				fontSize = fontSizeFromData;
			}
		}
		UIFont* font = nil;
		if (fontName)
		{
			font = [UIFont fontWithName:fontName size:fontSize];
		}
		if (!font)
		{
			font = [UIFont systemFontOfSize:fontSize];
		}
		
		[label setFont:font];
		
		CGRect labelFrame;
		if ([self makeCGRectFromDictionary:objectData forKey:@"frame" rect:&labelFrame])
		{
			label.frame = labelFrame;
		}
        
        label.shadowColor = [self interpolateColor:[objectData objectForKey:@"shadow_color"] withData:itemData defaultColor:[UIColor clearColor]];

        CGSize labelShadowOffset;
        if ([self makeCGSizeFromDictionary:objectData forKey:@"shadow_offset" size:&labelShadowOffset])
        {
            label.shadowOffset = labelShadowOffset;
        }
		
		NSString* alignmentString = [objectData objectForKey:@"alignment" ifKindOfClass:[NSString class]];
		if (alignmentString)
		{
			if ([alignmentString isEqualToString:@"left"])
			{
				[label setTextAlignment:UITextAlignmentLeft];
			}
			else if ([alignmentString isEqualToString:@"right"])
			{
				[label setTextAlignment:UITextAlignmentRight];
			}
			else if ([alignmentString isEqualToString:@"center"])
			{
				[label setTextAlignment:UITextAlignmentCenter];
			}
		}
		
		if (is3Point2SystemVersion())
		{
			// Square braces in the text field of a label means "don't try to parse formatting tags".
			// We will leave the unparsed variables in the string for now, then we will apply the
			// formatting.  Then, we will expand variables in the square braces.		
			text = [self interpolate:text withData:itemData ignoringSquareBraces:YES];
			
			// Expand variables in square braces.
			// If the variable name text has formatting, that will be preserved for the expanded variable string.
			NSAttributedString* attributedString = [OFMarkupLanguage attributedStringByParsingMarkup:text withAttributesFromLabel:label];
			attributedString = [self interpolateAttributedString:attributedString withData:itemData];
			
			TTTAttributedLabel* attributedLabel = (TTTAttributedLabel*)label;
			[attributedLabel setText:attributedString];

			[self addSubview:label];
		}
		else
		{
			// If we are on an os less than 3.2, TTTAttributedLabel won't be supported.
			// In that case, just use OFColoredTextLabel which will support two colored UILabels,
			// but will not support fonts or sizes.
			
			text = [self interpolate:text withData:itemData ignoringSquareBraces:NO escapeSquareBraceContents:NO];
			
			UIColor* altColor;
			int altColorStringStartIndex;
			int altColorStringLength;
			text = [OFMarkupLanguage removeMarkupFromText:text
											  outAltColor:&altColor
							  outAltColorStringStartIndex:&altColorStringStartIndex
								  outAltColorStringLength:&altColorStringLength];
			
			OFColoredTextLabel *coloredLabel = [[OFColoredTextLabel alloc] initWithFrame:label.frame];
			coloredLabel.labelTemplate = label;
			[self addSubview:coloredLabel];
			[coloredLabel release];
			
			if (!altColor)
			{
				coloredLabel.bodyText = text;
				coloredLabel.bodyColor = label.textColor;
			}
			else if (altColorStringStartIndex == 0)
			{
				coloredLabel.headerText = [text substringWithRange:NSMakeRange(0,altColorStringLength)];
				coloredLabel.headerColor = altColor;
				coloredLabel.bodyText = [text substringWithRange:NSMakeRange(altColorStringLength, [text length] - altColorStringLength)];
				coloredLabel.bodyColor = label.textColor;
			}
			else
			{
				coloredLabel.headerText = [text substringWithRange:NSMakeRange(0,altColorStringStartIndex)];
				coloredLabel.headerColor = label.textColor;
				coloredLabel.bodyText = [text substringWithRange:NSMakeRange(altColorStringStartIndex, [text length] - altColorStringStartIndex)];
				coloredLabel.bodyColor = altColor;
			}
			
			[coloredLabel rebuild];
		}
	}
	else
	{
		NSLog(@"No \"text\" element for label");
	}
}

- (void)createImage:(NSDictionary*)objectData withItemData:(NSDictionary*)itemData
{
	OFImageView* image = [[OFImageView alloc] initWithFrame:CGRectMake(0,0,100,100)];
	[self addSubview:image];
	[image release];
	image.userInteractionEnabled = NO;
	[image setOpaque:NO];
	[image setBackgroundColor:nil];
	
	NSNumber* framed = [objectData objectForKey:@"framed" ifKindOfClass:[NSNumber class]];
	if (framed && [framed boolValue])
	{
		image.unframed = NO;
	}
	else
	{
		image.unframed = YES;
	}

	NSNumber* sharpCorners = [objectData objectForKey:@"sharp_corners" ifKindOfClass:[NSNumber class]];
	if (sharpCorners && ![sharpCorners boolValue])
	{
		image.useSharpCorners = NO;
	}
	else
	{
		image.useSharpCorners = YES;
	}
    
	NSNumber* cornerRadius = [objectData objectForKey:@"corner_radius"];
	if (cornerRadius)
	{
		image.useSharpCorners = NO;
		image.cornerRadius = [cornerRadius floatValue];
	}

	NSNumber* scaleToFill = [objectData objectForKey:@"scale_to_fill" ifKindOfClass:[NSNumber class]];
	if (scaleToFill && [scaleToFill boolValue])
	{
		image.shouldScaleImageToFillRect = YES;
	}
	else
	{
		image.shouldScaleImageToFillRect = NO;
	}
	
	CGRect imageFrame;
	if ([self makeCGRectFromDictionary:objectData forKey:@"frame" rect:&imageFrame])
	{
		image.frame = imageFrame;
	}
    
    NSNumber* hidden = [objectData objectForKey:@"hit_state" ifKindOfClass:[NSNumber class]];
    if (hidden && [hidden boolValue]) {
        image.hidden = YES;
        mHitStateView = image;
    }

    [self configureImageView:image withItemData:itemData andObjectData:objectData];
}

- (void)configureImageView:(OFImageView*)image withItemData:(NSDictionary*)itemData andObjectData:(NSDictionary*)objectData
{
    UIColor* tintColor = [self interpolateColor:[objectData objectForKey:@"color"] withData:itemData defaultColor:nil];
    UIImage* uiImage = nil;
    
    NSDictionary* imageConfig = [objectData objectForKey:@"image" ifKindOfClass:[NSDictionary class]];
    if (!imageConfig)
    {
        NSString* imageString = [objectData objectForKey:@"image" ifKindOfClass:[NSString class]];
        if (imageString)
        {
            imageConfig = [itemData valueForKeyPath:imageString];
            if ([imageConfig isKindOfClass:[UIImage class]])
            {
                // Great, this is the dev's custom image.
                uiImage = (UIImage*)imageConfig;
            }
            
            if (![imageConfig isKindOfClass:[NSDictionary class]])
            {
                // Well, this isn't an imageConfig, so don't do the
                // config parsing below.
                imageConfig = nil;
            }
        }
    }
    
    if (imageConfig)
    {
        NSString* url = [imageConfig objectForKey:@"url"];
        url = [self interpolate:url withData:itemData];
        if(url && url.length)
        {
            [image setImageUrl:url crossFading:YES];

            // We totally don't support tinting on image URLs yet, so bail early.
            return;
        }
        else
        {
            NSString* imageName = [imageConfig objectForKey:@"bundle" ifKindOfClass:[NSString class]];
            
            if (imageName)
            {
                imageName = [self interpolate:imageName withData:itemData];
                uiImage = [OFImageLoader loadImage:imageName];
            }
            else
            {
                imageName = [objectData objectForKey:@"manifest" ifKindOfClass:[NSString class]];
                imageName = [self interpolate:imageName withData:itemData];

                uiImage = [UIImage imageWithContentsOfFile:[[OFWebViewManifestService rootPath] stringByAppendingPathComponent:imageName]];
            }
        }
    }
    
    if(uiImage)
    {
        [image setImage:[self colorizeImage:uiImage color:tintColor]];
    }
    else if(tintColor)
    {
        //use the image that exists in the nib
        [image setImage:[self colorizeImage:image.image color:tintColor]];
    }
}

- (void)layoutDynamicView:(NSArray*)views withItemData:(NSDictionary*)itemData andLayouts:(NSDictionary*)layouts
{
    static int recursionGuard = 0;
    recursionGuard++;
    if (recursionGuard > 10)
    {
        // So we don't crash if the config has a cycle.
        OFAssert(0, @"Layout recursing more than ten times.  Is there a cycle?");
    }
	else for (NSObject* objectDataObj in views)
	{
		if ([objectDataObj isKindOfClass:[NSDictionary class]])
		{
			NSDictionary* objectLayoutData = (NSDictionary*)objectDataObj;
			NSString* type = [objectLayoutData objectForKey:@"type" ifKindOfClass:[NSString class]];
			if (type)
			{
				if ([type isEqualToString:@"label"])
				{
					[self createLabel:objectLayoutData withItemData:itemData];
				}
				else if ([type isEqualToString:@"image"])
				{
					[self createImage:objectLayoutData withItemData:itemData];
				}
				else
				{
                    OFLog(@"Unknown layout object type: %@", type);
				}
			}
		}
		else if ([objectDataObj isKindOfClass:[NSString class]])
		{
            NSString* layoutName = (NSString*)objectDataObj;
            NSArray* layout = [layouts objectForKey:layoutName ifKindOfClass:[NSArray class]];
            if (layout)
            {
                [self layoutDynamicView:layout withItemData:itemData andLayouts:layouts];
            }
            else
            {
                OFLog(@"Failed lookup of layout: %@", layoutName);
            }
        }
	}
    recursionGuard--;
}

@end
