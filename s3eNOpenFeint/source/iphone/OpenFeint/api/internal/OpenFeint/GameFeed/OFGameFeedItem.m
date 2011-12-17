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
#import "OFGameFeedItem.h"
#import "OpenFeint+Private.h"
#import "OFColoredTextLabel.h"
#import "OFImageView.h"
#import "OFImageLoader.h"
#import "OFGameFeedView+Private.h"
#import "OFURLDispatcher.h"
#import "OFGameFeedDashboardAnalyticsListener.h"
#import "NSDictionary+OpenFeint.h"
#import "OFGameFeedItem+DynamicLayout.h"
#import "NSString+OpenFeint.h"
#import "OFSettings.h"
#import "OFASIHTTPRequest.h"
#import "OFReachability.h"
#import "NSNotificationCenter+OpenFeint.h"
#import "IPhoneOSIntrospection.h"
#import "OpenFeint+EventLog.h"
#import "OFABTesting.h"
#import "OFDependencies.h"

static const float kfClickDebounceInterval = 2.0f;

@interface OFGameFeedItem()
@property (nonatomic, retain) NSString* action;
@property (nonatomic, retain) NSString* itemType;
@property (nonatomic, retain) NSString* analyticsName;
@property (nonatomic, retain) NSString* instanceKey;
@property (nonatomic, retain) NSString* impressionPath;
@property (nonatomic, assign) UIControlState controlState;
@property (nonatomic, retain) OFGameFeedItem* itemToReplace;
- (void)showHitStateDelay;
@end

@implementation OFGameFeedItem
@synthesize isVisible, clickTimestamp, feedPosition, action, itemType, analyticsName, instanceKey, impressionPath, controlState, fadeInTimer = mFadeInTimer;
@synthesize doneFadingInInvocation = mDoneFadingInInvocation;
@synthesize itemToReplace = mItemToReplace;
@synthesize layoutInfoViews = mLayoutInfoViews;
@synthesize layoutInfoConfig = mLayoutInfoConfig;
@synthesize layoutInfoLayouts = mLayoutInfoLayouts;

- (void)dealloc
{
    OFSafeRelease(action);
    [mFadeInTimer invalidate];
    OFSafeRelease(mFadeInTimer);
    OFSafeRelease(mDoneFadingInInvocation);
    [mItemToReplace removeFromSuperview];
    OFSafeRelease(mItemToReplace);
    OFSafeRelease(mLayoutInfoViews);
    OFSafeRelease(mLayoutInfoConfig);
    OFSafeRelease(mLayoutInfoLayouts);
    [super dealloc];
}

- (UIImage*)colorizeImage:(UIImage*)image color:(UIColor*)color
{
    if(!(color && image)) return image;
    
    if (is4PointOhSystemVersion())
    {
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    }
    else
    {
        UIGraphicsBeginImageContext(image.size);
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, image.CGImage);
    
    [color set];
    CGContextFillRect(ctx, area);
    
    CGContextRestoreGState(ctx);
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    CGContextDrawImage(ctx, area, image.CGImage);
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSString*)stringWithPercentEscapes:(NSString*)text
{
    return [(NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[[text mutableCopy] autorelease], NULL, CFSTR("&="),kCFStringEncodingUTF8) autorelease];
}

// Any occurrence of "{key}" inside text is replaced with the string value of "key" from the data dictionary
// "[key]" does the same, but also url-escapes the string
- (NSString*)interpolate:(NSString*)text withData:(NSDictionary*)data ignoringSquareBraces:(BOOL)ignoringSquareBraces escapeSquareBraceContents:(BOOL)escapeSquareBraceContents;
{
    if (nil == text) return nil;
    
    //search for a pair of {}, inside this might be something that we can grab using KVC
    BOOL inBracket = NO;
    BOOL inSquareBracket = NO;
    int rangeStart = 0; 
    NSMutableString* outString = [NSMutableString string];
    unichar* characterBuffer = (unichar*) malloc(text.length * sizeof(unichar));
    [text getCharacters:characterBuffer range:NSMakeRange(0, text.length)];
    unichar* c = characterBuffer;
    for(int loc=0; loc<text.length; ++loc, ++c)
    {
        if(inBracket)
        {
            if(*c == '}')
            {
                NSString* clip = [NSString stringWithCharacters:characterBuffer+rangeStart+1 length:loc-rangeStart-1];
                //convert clip based on the data here
                NSObject* fromData = [data valueForKeyPath:clip]; //for checking
                if([fromData isKindOfClass:[NSString class]])
                {
                    [outString appendString:(NSString*)fromData];
                }
                else
                {
                    OFLog(@"GameFeedItem: did not find data for configuration string %@ in %@", clip, data);
                }
                inBracket = NO;
                rangeStart = loc+1;  //skip past the closing bracket
            }
        }
        else if(inSquareBracket)
        {
            if(*c == ']')
            {
                NSString* clip = [NSString stringWithCharacters:characterBuffer+rangeStart+1 length:loc-rangeStart-1];
                //convert clip based on the data here
                NSString* variableContents = [data valueForKeyPath:clip]; //for checking
                if([variableContents isKindOfClass:[NSString class]])
                {
					if (escapeSquareBraceContents)
					{
						variableContents = [self stringWithPercentEscapes:variableContents];
					}
					[outString appendString:variableContents];
                }
                else
                {
                    OFLog(@"GameFeedItem: did not find data for configuration string %@ in %@", clip, data);
                }
                inSquareBracket = NO;
                rangeStart = loc+1;  //skip past the closing bracket
            }
        }
        else
        {
            if(*c == '{')
            {
                [outString appendString:[NSString stringWithCharacters:characterBuffer+rangeStart length:loc-rangeStart]];
                inBracket = YES;
                rangeStart = loc;
            }
            else if(!ignoringSquareBraces && *c == '[')
            {
                [outString appendString:[NSString stringWithCharacters:characterBuffer+rangeStart length:loc-rangeStart]];
                inSquareBracket = YES;
                rangeStart = loc;
            }
        }
    }
    [outString appendString:[NSString stringWithCharacters:characterBuffer+rangeStart length:text.length-rangeStart]];    
    free(characterBuffer);
    return outString;
}

- (NSString*)interpolate:(NSString*)text withData:(NSDictionary*)data ignoringSquareBraces:(BOOL)ignoringSquareBraces;
{
	return [self interpolate:text withData:data ignoringSquareBraces:ignoringSquareBraces escapeSquareBraceContents:YES];
}

- (NSString*)interpolate:(NSString*)text withData:(NSDictionary*)data
{
	return [self interpolate:text withData:data ignoringSquareBraces:NO];
}

- (NSAttributedString*)interpolateAttributedString:(NSAttributedString*)attributedString withData:(NSDictionary*)data
{
	NSMutableAttributedString* outString = [attributedString mutableCopy];
	
	int rangeRemainingLocation = 0;
	while(rangeRemainingLocation < [outString length])
	{
		NSString* currentString = [outString string];
		NSRange rangeRemaining = NSMakeRange(rangeRemainingLocation, [currentString length] - rangeRemainingLocation);
		NSRange rangeOfOpeningBrace = [currentString rangeOfString:@"[" options:0 range:rangeRemaining];
		if (rangeOfOpeningBrace.location != NSNotFound)
		{
			NSRange rangeToSearchRemainder = NSMakeRange((rangeOfOpeningBrace.location+rangeOfOpeningBrace.length), [currentString length] - (rangeOfOpeningBrace.location+rangeOfOpeningBrace.length));
			NSRange rangeOfClosingBrace = [currentString rangeOfString:@"]" options:0 range:rangeToSearchRemainder];
			if (rangeOfClosingBrace.location != NSNotFound)
			{
				NSRange rangeOfVariableName = NSMakeRange((rangeOfOpeningBrace.location+rangeOfOpeningBrace.length), rangeOfClosingBrace.location - (rangeOfOpeningBrace.location+rangeOfOpeningBrace.length));
				NSString* variableName = [currentString substringWithRange:rangeOfVariableName];
				NSString* fromData = [data valueForKeyPath:variableName];
				if([fromData isKindOfClass:[NSString class]])
				{
					NSRange rangeOfVariableNamePlusBraces = NSMakeRange(rangeOfVariableName.location - 1, rangeOfVariableName.length + 2);
					[outString replaceCharactersInRange:rangeOfVariableNamePlusBraces withString:fromData];
					
					rangeRemainingLocation = rangeOfClosingBrace.location + 1 - rangeOfVariableNamePlusBraces.length + fromData.length;
				}
				else
				{
					OFLog(@"GameFeedItem: did not find data for configuration string %@ in %@", variableName, data);
					rangeRemainingLocation = rangeOfClosingBrace.location + 1;
				}
			}
			else
			{
				OFLog(@"Couldn't match closing brace: %@", currentString);
				rangeRemainingLocation = rangeOfOpeningBrace.location + 1;
			}
		}
		else
		{
			// No more variables to parse
			break;
		}
	}
	return [outString autorelease];
}

- (UIColor*)interpolateColor:(NSString*)text withData:(NSDictionary*)data defaultColor:(UIColor*)defaultColor
{
    id colorString = [data valueForKeyPath:text];
	if ([colorString isKindOfClass:[NSString class]])
	{
		UIColor* color = [colorString toColor];
		if (color)
		{
			return color;
		}
	}
    return defaultColor;
}

- (UIImage*)interpolateImage:(NSString*)text withData:(NSDictionary*) data
{
    id check = [data valueForKeyPath:text];
    if([check isKindOfClass:[UIImage class]]) return check;
    return nil;
}


- (void)loadedImage:(UIImage*)image forView:(UIImageView*)view
{
    [view setImage:image];
}

- (void)failedToLoadImageForView:(UIImageView*)view
{
    OFLog(@"GameFeed failed to load image");
}

- (void)fillFieldsUsingData:(NSDictionary*)itemData config:(NSDictionary*)configData bundle:(NSString*)bundlePath
{
    NSArray* fieldMappings = [configData objectForKey:@"mappings"];
    for(NSDictionary*mapping in fieldMappings)
    {
        int tagValue = [[mapping objectForKey:@"tag"] intValue];
        UIView* fieldView = [self viewWithTag:tagValue];
                
        if(fieldView)
        {
            if([fieldView isKindOfClass:[UILabel class]])
            {
                NSString*titleText = [self interpolate:[mapping objectForKey:@"title"] withData:itemData];
                //if title exists, swap with multilabel
                if(titleText.length)
                {
                    OFColoredTextLabel* multiLabel = [OFColoredTextLabel new];
                    multiLabel.labelTemplate = (UILabel*)fieldView;
                    multiLabel.headerText = [self interpolate:[mapping objectForKey:@"title"] withData:itemData];
                    multiLabel.bodyText = [self interpolate:[mapping objectForKey:@"text"] withData:itemData];
                    multiLabel.headerColor = [self interpolateColor:[mapping objectForKey:@"title_color"] withData:itemData defaultColor:[UIColor greenColor]];
                    multiLabel.bodyColor = [self interpolateColor:[mapping objectForKey:@"color"] withData:itemData defaultColor:[UIColor grayColor]];
                    [multiLabel rebuild];
                    [fieldView removeFromSuperview];
                    [self addSubview:multiLabel];
                    [multiLabel release];
                }
                else
                {
                    UILabel* labelCast = (UILabel*)fieldView;
                    [labelCast setText:[self interpolate:[mapping objectForKey:@"text"] withData:itemData]];
                    [labelCast setTextColor:[self interpolateColor:[mapping objectForKey:@"color"] withData:itemData defaultColor:[UIColor grayColor]]];
                }
            }
            else if([fieldView isKindOfClass:[OFImageView class]])
            {
                OFImageView* imageCast = (OFImageView*)fieldView;
                imageCast.unframed = YES;

                [self configureImageView:imageCast withItemData:itemData andObjectData:mapping];
            }
            else if([fieldView isKindOfClass:[UIImageView class]])
            {
                UIImageView* imageCast = (UIImageView*)fieldView;
                
                NSString* url = [self interpolate:[mapping objectForKey:@"image_url"] withData:itemData];
                if(url.length)
                {
                    if([url hasPrefix:@"http"])
                    {
                        //make a request
                        OFInvocation* success = [OFInvocation invocationForTarget:self selector:@selector(loadedImage:forView:) userParam:fieldView];
                        OFInvocation* failure = [OFInvocation invocationForTarget:self selector:@selector(failedToLoadImageForView:) userParam:fieldView];
                        [OpenFeint getImageFromUrl:url forModule:self onSuccess:success onFailure:failure];
                    }
                    else
                    {   //relative loads assumed from bundle
                        NSString* imagePath = [bundlePath stringByAppendingPathComponent:url];
                        [imageCast setImage:[UIImage imageWithContentsOfFile:imagePath]];
                    }
                    
                }
                else
                {
                    UIColor* tintColor = [self interpolateColor:[mapping objectForKey:@"color"] withData:itemData defaultColor:nil];
                    UIImage* image = [self interpolateImage:[mapping objectForKey:@"image"] withData:itemData];
                    if(image) 
                    {
                        [imageCast setImage:[self colorizeImage:image color:tintColor]];
                    }
                    else
                    {
                        //use the image that exists in the nib
                        if(tintColor)
                        {
                            [imageCast setImage:[self colorizeImage:imageCast.image color:tintColor]];
                        }                             
                    }
                }
            }
        }
        else
        {
            OFLog(@"GameFeed: tag %d was not found in the nib file %@", tagValue, [configData objectForKey:@"nib"]);
        }
    }
}

+ (id)gameFeedItemWithCustom:(NSDictionary*)custom itemData:(id)itemData configurationData:(id)configData bundle:(NSString*)bundlePath layouts:(NSDictionary*)layouts
{
    //from config, find the proper xib file to load
    //then apply the mappings and any customization
    NSString* feedItemName = [itemData objectForKey:@"type"];
    NSArray* itemConfigArray = [configData objectForKey:feedItemName];
    
    NSMutableArray* itemsForGeneralPopulation = [NSMutableArray arrayWithCapacity:10];

    NSDictionary* itemConfig = nil;
    
    // Go through all the variants.
    // Each one that contains variant_testing_start_ratio and variant_testing_end_ratio will be used only on matching devices.
    // All others are chosed randomly from for the general population.
    for (NSDictionary* thisItem in itemConfigArray)
    {
        NSString* ratioStartString = [thisItem objectForKey:@"variant_testing_start_ratio"];
        NSString* ratioEndString = [thisItem objectForKey:@"variant_testing_end_ratio"];
        if (ratioStartString && ratioEndString)
        {
            float ratioStart = [ratioStartString floatValue];
            float ratioEnd = [ratioEndString floatValue];
            if ([OFABTesting isWithinRangeFrom:ratioStart to:ratioEnd])
            {
                itemConfig = thisItem;
                break;
            }
        }
        else
        {
            [itemsForGeneralPopulation addObject:thisItem];
        }
    }
    
    if (!itemConfig && [itemsForGeneralPopulation count] > 0)
    {
        //If there is an array of items ot pick from, pick one randomly.
        int itemIndex = arc4random() % itemsForGeneralPopulation.count;
        itemConfig = [itemsForGeneralPopulation objectAtIndex:itemIndex];
    }
    
    if(itemConfig)
    {
        NSArray* nibConfigArray = [itemConfig objectForKey:@"nib"];
        NSString* nibName = nil;
        //check for landscape version
        if([OpenFeint isInLandscapeMode])
        {
            NSString* matchString = [[nibConfigArray objectAtIndex:0] stringByAppendingString:@"Landscape"];
            for(int i=1; i<nibConfigArray.count; ++i)
            {
                if([[nibConfigArray objectAtIndex:i] isEqualToString:matchString])
                {
                    nibName = matchString;
                    break;
                }
            }
            
        }
        if(!nibName)
        {
            nibName = [nibConfigArray objectAtIndex:0];
        }
        NSArray* objects = [[OpenFeint getResourceBundle] loadNibNamed:nibName owner:nil options:nil];
        OFGameFeedItem* item = [[objects objectAtIndex:0] retain];

        NSMutableDictionary* combined = [NSMutableDictionary new];
        [combined addEntriesFromDictionary:itemData];
        [combined setObject:custom forKey:@"custom"];
        [item fillFieldsUsingData:combined config:itemConfig bundle:bundlePath];

        NSDictionary* configs = [itemConfig objectForKey:@"configs" ifKindOfClass:[NSDictionary class]];
        if (configs)
        {
            [combined setObject:configs forKey:@"configs"];
        }

        item.action = [item interpolate:[itemConfig objectForKey:@"action"] withData:combined];
        item.itemType = feedItemName;
        item.analyticsName = [item interpolate:[itemConfig objectForKey:@"analytics_name"] withData:combined];
        item.instanceKey = [item interpolate:[itemConfig objectForKey:@"instance_key"] withData:combined];
        item.impressionPath = [item interpolate:[itemConfig objectForKey:@"impression_path"] withData:combined];
		
        NSArray* views = nil;
        if([OpenFeint isInLandscapeMode])
		{
			views = [itemConfig objectForKey:@"views_landscape" ifKindOfClass:[NSArray class]];
		}
		if (!views)
		{
			views = [itemConfig objectForKey:@"views" ifKindOfClass:[NSArray class]];
		}
		if (views)
		{
            item.layoutInfoViews = views;
            item.layoutInfoConfig = combined;
            item.layoutInfoLayouts = layouts;
		}
        
        return [item autorelease];
    }
    else
    {
        OFLog(@"No configuration found for game item type %@", feedItemName);
        return nil;
    }    
}

- (void)showHitStateDelay
{
    if (self.controlState == UIControlStateHighlighted) {
        mHitStateView.hidden = NO;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mHitStateView) {
        self.controlState = UIControlStateHighlighted;
        [self performSelector:@selector(showHitStateDelay) withObject:nil afterDelay:0.14];
    }
}

- (NSDictionary*) analyticsParams
{
    if (self.itemType)
    {
        NSMutableDictionary* dict = [[NSMutableDictionary new] autorelease];

        [dict setObject:self.itemType forKey:@"item_type"];
        [dict setObject:[NSNumber numberWithInt:self.feedPosition] forKey:@"feed_position"];
        
        if (self.analyticsName != nil)
        {
            [dict setObject:self.analyticsName forKey:@"analytics_name"];
        }
        
        if (self.instanceKey != nil)
        {
            [dict setObject:self.instanceKey forKey:@"instance_key"];
        }
        
        return dict;
    }
    
    return nil;
}

- (void)onClicked
{
    NSDictionary* params = [self analyticsParams];
    if (params)
    {
        [OFGameFeedView logEventWithActionKey:@"click" parameters:params];
    }

	NSURL* url = nil;
    if(self.action)
    {
        url = [NSURL URLWithString:self.action];
    }
    
	if (!url)
	{
		OFLog(@"Can't make URL from string: %@", self.action);
	}
	else
	{
        if (params)
        {
            if ([OFReachability isConnectedToInternet])
            {
                [[OFURLDispatcher defaultDispatcher] dispatchAction:url withObserver:[OFGameFeedDashboardAnalyticsListener listenWithParams:params]];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:gameFeedShouldDisplayOfflineItem object:nil];
            }
        }
	}    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mHitStateView) {
        self.controlState = UIControlStateNormal;
        mHitStateView.hidden = YES;
    }
    
    // debounce
    NSDate* now = [NSDate date];
    if (self.clickTimestamp && [now timeIntervalSinceDate:self.clickTimestamp] < kfClickDebounceInterval) {
        return;
    } else {
        self.clickTimestamp = now;
    }    
	
    [self onClicked];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mHitStateView) {
        self.controlState = UIControlStateNormal;
        mHitStateView.hidden = YES;
    }
}

- (void)wasShown
{
    if (self.impressionPath)
    {
        NSString* adServerURL = [[[NSURL URLWithString:[[OFSettings instance] getSetting:@"ad-server-url"]] standardizedURL] absoluteString];
        NSString* reqURL = [NSString stringWithFormat:@"%@%@", adServerURL, self.impressionPath];
        OFASIHTTPRequest* impressionRequest = [OFASIHTTPRequest requestWithURL:[NSURL URLWithString:reqURL]];

        [impressionRequest startAsynchronous];
    }
}

- (void)wasPartlyShown
{
    if (!dynamicLayoutLoaded)
    {
        dynamicLayoutLoaded = YES;
        [self layoutDynamicView:self.layoutInfoViews withItemData:self.layoutInfoConfig andLayouts:self.layoutInfoLayouts];
    }
}

- (void)doneFadingIn
{
    [mDoneFadingInInvocation invoke];
    if (mItemToReplace)
    {
        [mItemToReplace removeFromSuperview];
        self.itemToReplace = nil;
    }
}

- (void)fadeIn
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(doneFadingIn)];
    self.alpha = 1;
    [UIView commitAnimations];
}

- (void)fadeInAfterSeconds:(float)seconds doneInvocation:(OFInvocation*)doneInvocation;
{
    self.alpha = 0;
    self.doneFadingInInvocation = doneInvocation;

    if (seconds <= 0.f)
    {
        [self fadeIn];
    }
    else
    {
        self.fadeInTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self
          selector:@selector(fadeIn) userInfo:nil repeats:NO];
    }
}

- (void)fadeInAfterSeconds:(float)seconds doneInvocation:(OFInvocation*)doneInvocation replacingItem:(OFGameFeedItem*)itemToReplace
{
    [self fadeInAfterSeconds:seconds doneInvocation:doneInvocation];
    self.itemToReplace = itemToReplace;
}

- (void)fadeInAtDate:(NSDate*)date doneInvocation:(OFInvocation*)doneInvocation;
{
    self.alpha = 0;
    self.doneFadingInInvocation = doneInvocation;
    self.fadeInTimer = [[[NSTimer alloc] initWithFireDate:date interval:0.0f target:self selector:@selector(fadeIn) userInfo:nil repeats:NO] autorelease];
    [[NSRunLoop currentRunLoop] addTimer:self.fadeInTimer forMode:NSRunLoopCommonModes];
}

@end
