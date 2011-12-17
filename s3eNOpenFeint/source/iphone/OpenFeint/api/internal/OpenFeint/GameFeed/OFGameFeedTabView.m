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

#import "OFGameFeedTabView.h"
#import "OFImageLoader.h"
#import "OFGameFeedView.h"
#import "OpenFeint+Private.h"
#import "OFGameFeedSettings.h"
#import "OFGameFeedSettingsInternal.h"
#import "OFDependencies.h"

@interface OFGameFeedTabView(Private)

-(void)layoutTabView;
-(void)loadDefaultBrandingTab;

@end

@implementation OFGameFeedTabView

@synthesize alignment = mAlignment;
@synthesize icon = mIcon;
@synthesize text = mText;
@synthesize brandingTabImage = mBrandingTabImage;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        mIcon = [[OFImageLoader loadImage:@"OFGameBarLeafIcon.png"] retain];
        [self loadDefaultBrandingTab];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [mBrandingTabImage drawInRect:rect];
    if (mIcon) {
        [mIcon drawInRect:mIconRect];
    }

    if (mText) {
        UIColor* textColor = [UIColor colorWithRed:59/255.0f green:59/255.0f blue:59/255.0f alpha:1];
        UIFont* textFont= [UIFont fontWithName:@"Helvetica-Bold" size:11];
        [textColor set];
        [mText drawInRect:mTextRect withFont:textFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
    }
}

- (void)dealloc
{
    [mIcon release];
    [mText release];
    [mBrandingTabImage release];
    [super dealloc];
}

- (void)setAlignment:(int)alignment
{
    if (mAlignment == alignment) {
        return;
    }

    mAlignment = alignment;
     [self layoutTabView];
    [self setNeedsDisplay];
}

- (void)setIcon:(UIImage *)newIcon
{
    if (mIcon == newIcon) {
        return;
    }
    
    OFSafeRelease(mIcon);
    mIcon = [newIcon retain];
    if (!mIcon) {
        mIcon = [[OFImageLoader loadImage:@"OFGameBarLeafIcon.png"] retain];
    }
    [self layoutTabView];
    [self setNeedsDisplay];
}

- (void)setText:(NSString *)newText
{
    if (mText == newText) {
        return;
    }
    OFSafeRelease(mText);
    mText = [newText copy];
    [self layoutTabView];
    [self setNeedsDisplay];
}

- (void)setBrandingTabImage:(UIImage *)brandingTabImage
{
    if (mBrandingTabImage == brandingTabImage) {
        return;
    }
    OFSafeRelease(mBrandingTabImage);
    mBrandingTabImage = [brandingTabImage retain];
    if (!brandingTabImage) {
        // reset to default branding tab
        [self loadDefaultBrandingTab];
    }
    [self setNeedsDisplay];
}

-(void)layoutTabView
{
    UIFont* textFont= [UIFont fontWithName:@"Helvetica-Bold" size:11];
    int textWidth = 0;
    
    if (mText) {
        CGSize textSize = [mText sizeWithFont:textFont constrainedToSize:CGSizeMake(200, 12) lineBreakMode:UILineBreakModeTailTruncation];
        textWidth = textSize.width;
    }
    if (mAlignment == OFGameFeedTabAlignment_LEFT) {
        mIconRect = CGRectMake(2, 2, 12, 12);
        if (mIcon) {
            mTextRect = CGRectMake(16, 2, textWidth, 12);
        }
        else
        {
           mTextRect = CGRectMake(2, 2, textWidth, 12); 
        }
        int viewWidth = 18 + mTextRect.size.width + 10;
        self.frame = CGRectMake(0, -16, viewWidth, 16);
    } 
    else
    {
        mIconRect = CGRectMake(18, 2, 12, 12);
        if (mIcon) {
            mTextRect = CGRectMake(32, 2, textWidth+2, 12);
        }
        else
        {
            mTextRect = CGRectMake(20, 2, textWidth+2, 12); 
        }
        int viewWidth = 18 + mTextRect.size.width + 10;
        if ([OpenFeint isInLandscapeMode]) {
            self.frame = CGRectMake(480-viewWidth, -16, viewWidth, 16);
        }
        else
        {
             self.frame = CGRectMake(320-viewWidth, -16, viewWidth, 16);
        }
    }
}

-(void)loadDefaultBrandingTab
{
    UIImage* originBackImage;
    UIImage* backgroundImage;
    if (mAlignment == OFGameFeedTabAlignment_LEFT) {
        originBackImage = [OFImageLoader loadImage:@"OFGameBarCustomizeBackLeft.png"];
        backgroundImage = [originBackImage stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    }
    else
    {
        originBackImage = [OFImageLoader loadImage:@"OFGameBarCustomizeBackRight.png"];
        backgroundImage = [originBackImage stretchableImageWithLeftCapWidth:18 topCapHeight:0]; 
    }
    mBrandingTabImage = [backgroundImage retain];
}

@end
