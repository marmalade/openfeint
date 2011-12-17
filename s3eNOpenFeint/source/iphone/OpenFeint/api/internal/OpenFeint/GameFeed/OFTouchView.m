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

#import "OFTouchView.h"


@implementation OFTouchView

@synthesize receiver, forwardSubviewTouches;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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


// This class is used as a proxy for touch events for another UIView.
// If the frame of a UIView is smaller than the area that you want to allow
// the user to interact with, this is useful.
// For example, a UIScrollView's frame needs to be set to control where page
// boundaries are, but we want to allow the user to see a portion of the next page, beyond the frame.
// To achieve this, we can set clipsToBounds=NO on that scroll view, and also add this view
// as its sibling, to pick up the events.
- (UIView *) hitTest: (CGPoint)point withEvent: (UIEvent *)event
{
    if (self.forwardSubviewTouches)
    {
        if(CGRectContainsPoint(self.bounds, point)) 
        {
            for(UIView *view in self.receiver.subviews)
            {
                CGPoint subViewpoint = [view convertPoint:point fromView:self];
                UIView* hitView = [view hitTest:subViewpoint withEvent:event];
                if (hitView)
                {
                    return hitView;
                }
            }
            return self.receiver;
        } 
        else
        {
            return [super hitTest:point withEvent:event];
        }
    }
    else
    {
        if ([self pointInside:point withEvent:event])
        {
            return self.receiver;
        }
        return nil;
    }
}


- (void)dealloc
{
    self.receiver = nil;
    [super dealloc];
}

@end
