//  Copyright 2009-2011 Aurora Feint, Inc.
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
#import "OFColoredTextLabel.h"
#import "OFDependencies.h"

@implementation OFColoredTextLabel
@synthesize labelTemplate = mLabelTemplate;
@synthesize headerText = mHeaderText;
@synthesize bodyText = mBodyText;
@synthesize headerColor = mHeaderColor;
@synthesize bodyColor = mBodyColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    OFSafeRelease(mLabelTemplate);
    OFSafeRelease(mHeaderColor);
    OFSafeRelease(mHeaderText);
    OFSafeRelease(mBodyColor);
    OFSafeRelease(mBodyText);
    [super dealloc];
}

- (UILabel*)cloneLabel
{
    UILabel* newLabel = [[UILabel new] autorelease];
    newLabel.font = self.labelTemplate.font;
    newLabel.textColor = self.labelTemplate.textColor;
    newLabel.textAlignment = self.labelTemplate.textAlignment;
    newLabel.lineBreakMode = self.labelTemplate.lineBreakMode;
    newLabel.backgroundColor = self.labelTemplate.backgroundColor;
	newLabel.opaque = self.labelTemplate.opaque;
    
    
    newLabel.adjustsFontSizeToFitWidth = self.labelTemplate.adjustsFontSizeToFitWidth;
    newLabel.baselineAdjustment = self.labelTemplate.baselineAdjustment;
    newLabel.minimumFontSize = self.labelTemplate.minimumFontSize;
    newLabel.numberOfLines = self.labelTemplate.numberOfLines;
    
    newLabel.transform = self.labelTemplate.transform;
    newLabel.frame = self.labelTemplate.frame;
	
    return newLabel;
}


- (void)rebuild
{
    NSSet* oldViews = [NSSet setWithArray:self.subviews];
    for(UIView*view in oldViews)
    {
        [view removeFromSuperview];
    }
    
    UILabel* bodyLabel = [self cloneLabel];
	
    NSString* combinedText;
    if(self.headerText) 
    {
        //now, the combined text should be a set of spaces of equal length to the actual header text followed by the body
        CGSize headerFrame = [self.headerText sizeWithFont:bodyLabel.font
                                         constrainedToSize:bodyLabel.frame.size
                                             lineBreakMode:bodyLabel.lineBreakMode];
        CGSize spaces10 = [@"          " sizeWithFont:bodyLabel.font
                                    constrainedToSize:bodyLabel.frame.size
                                        lineBreakMode:bodyLabel.lineBreakMode];
        //now find closest number of spaces that match the header text
        int spaceCount = headerFrame.width / spaces10.width * 10 + 0.95;
        NSString* padding = [@"" stringByPaddingToLength:spaceCount withString:@" " startingAtIndex:0];
        combinedText = [padding stringByAppendingFormat:@" %@",self.bodyText];
    }
    else
        combinedText = self.bodyText;
    
    bodyLabel.textColor = self.bodyColor;
    bodyLabel.text = combinedText;
    [self addSubview:bodyLabel];
    
    //for a first pass, we'll just draw the header on top of the combined text.  If only color changes, this will work
    //but if other styles are required, it will need more
    //basically, we need to fake the header portion by prefixing a line of spaces of equal length.  Ugh.
    
	
	//need to find proper size for text only
	CGSize bodyFrame = [combinedText sizeWithFont:bodyLabel.font
								constrainedToSize:bodyLabel.frame.size
									lineBreakMode:bodyLabel.lineBreakMode];
	CGRect bodyRect = bodyLabel.frame;
	bodyRect.size.height = bodyFrame.height;
	bodyRect.origin = CGPointMake(0,0);
	bodyLabel.frame = bodyRect;
	
    if(self.headerText)
    {
        UILabel* headerLabel = [self cloneLabel];
        headerLabel.textColor = self.headerColor;
        headerLabel.text = self.headerText;
        headerLabel.backgroundColor = [UIColor clearColor];

        //need to find proper size for the color label
        CGSize headerFrame = [self.headerText sizeWithFont:headerLabel.font
                              constrainedToSize:bodyLabel.frame.size
                                             lineBreakMode:bodyLabel.lineBreakMode];
        CGRect headerRect = headerLabel.frame;
        headerRect.size.height = headerFrame.height;
		headerRect.origin = CGPointMake(0,0);
        headerLabel.frame = headerRect;
        
        
        
//        [headerLabel sizeToFit];
        //now shrink down to size
        [self addSubview:headerLabel];
    }
}

@end
