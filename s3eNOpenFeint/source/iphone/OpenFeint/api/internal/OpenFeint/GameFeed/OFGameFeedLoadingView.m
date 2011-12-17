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

#import "OFGameFeedLoadingView.h"
#import "OFImageLoader.h"
#import "OpenFeint+Private.h"

#define ICON_TOTOAL_SIZE 205
#define ICON_MARGIN 5
#define ICON_TOP_MARGIN 30
#define ICON_TOP_MARGIN_LANDSCAPE 20

@interface OFGameFeedLoadingView() 
-(void)animateIn;
-(void)iconAnimationLoop;
-(void)textAnimationLoop;

@end

@implementation OFGameFeedLoadingView

@synthesize loadingTextArray = mLoadingTextArray;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        int x = (frame.size.width - ICON_TOTOAL_SIZE)/2 + 13;
        int y = ICON_TOP_MARGIN;
        
        if ([OpenFeint isInLandscapeMode]) {
            y = ICON_TOP_MARGIN_LANDSCAPE;
        }
        CALayer* chatLayer = [CALayer layer];
        UIImage* icon = [OFImageLoader loadImage:@"OFGameFeedChat.png"];
        chatLayer.contents = (id)icon.CGImage;
        chatLayer.position = CGPointMake(x+icon.size.width/2, y);
        chatLayer.bounds = CGRectMake(0, 0, icon.size.width, icon.size.height);
        [self.layer addSublayer:chatLayer];
        x += icon.size.width + ICON_MARGIN;
        
        CALayer* achieveLayer = [CALayer layer];
        icon = [OFImageLoader loadImage:@"OFGameFeedAchieve.png"];
        achieveLayer.contents = (id)icon.CGImage;
        achieveLayer.position = CGPointMake(x+icon.size.width/2, y);
        achieveLayer.bounds = CGRectMake(0, 0, icon.size.width, icon.size.height);
        [self.layer addSublayer:achieveLayer];
        x += icon.size.width + ICON_MARGIN;
        
        CALayer* peopleLayer = [CALayer layer];
        icon = [OFImageLoader loadImage:@"OFGameFeedPeople.png"];
        peopleLayer.contents = (id)icon.CGImage;
        peopleLayer.position = CGPointMake(x+icon.size.width/2, y);
        peopleLayer.bounds = CGRectMake(0, 0, icon.size.width, icon.size.height);
        [self.layer addSublayer:peopleLayer];
        x += icon.size.width + ICON_MARGIN;

        CALayer* vsLayer = [CALayer layer];
        icon = [OFImageLoader loadImage:@"OFGameFeedVs.png"];
        vsLayer.contents = (id)icon.CGImage;
        vsLayer.position = CGPointMake(x+icon.size.width/2, y);
        vsLayer.bounds = CGRectMake(0, 0, icon.size.width, icon.size.height);
        [self.layer addSublayer:vsLayer];
        x += icon.size.width + ICON_MARGIN;

        
        CALayer* inviteLayer = [CALayer layer];
        icon = [OFImageLoader loadImage:@"OFGameFeedInvite.png"];
        inviteLayer.contents = (id)icon.CGImage;
        inviteLayer.position = CGPointMake(x+icon.size.width/2, y);
        inviteLayer.bounds = CGRectMake(0, 0, icon.size.width, icon.size.height);
        [self.layer addSublayer:inviteLayer];
       
        
        mIconArray = [[NSArray arrayWithObjects:chatLayer, achieveLayer, peopleLayer, vsLayer, inviteLayer, nil] retain];
        
        mTextLayer = [[CATextLayer layer] retain];
        mTextLayer.fontSize = 12;
        mTextLayer.font = [UIFont boldSystemFontOfSize:12].fontName;
        mTextLayer.bounds = CGRectMake(0, 0, frame.size.width, 20);
        if ([OpenFeint isInLandscapeMode]) {
            mTextLayer.position = CGPointMake(self.frame.size.width/2, 55);
        }
        else
        {
            mTextLayer.position = CGPointMake(self.frame.size.width/2, 65);
        }
        mTextLayer.alignmentMode = @"center";
        mTextLayer.string = @"Loading... What's new?";
        [self.layer addSublayer:mTextLayer];
        
    }
    return self;
}

-(void)dealloc
{
    [mTextLayer release];
    [mIconArray release];
    self.loadingTextArray = nil;

    [super dealloc];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    UIImage* background = [OFImageLoader loadImage:@"OFGameFeedLoadingBackground.png"];
    if (background) {
        [background drawInRect:rect];
    }
}


- (void)didMoveToWindow
{
    if (self.superview && self.window)
    {
        [self animateIn];
    }
    else
    {
        // stop all animation
        for(CALayer* layer in mIconArray)
        {
            [layer removeAllAnimations];
        }
    }
}

-(void)animateIn
{
    int index = 0;
    for(CALayer* layer in mIconArray)
    {
        [layer removeAllAnimations];
        layer.opacity = 0;
        CFTimeInterval now = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
        CABasicAnimation* fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeIn.fillMode = kCAFillModeForwards;
        fadeIn.removedOnCompletion = NO;
        fadeIn.fromValue = [NSNumber numberWithFloat:0];
        fadeIn.toValue = [NSNumber numberWithFloat:1];
        fadeIn.duration = 0.3;
        fadeIn.beginTime = now + 0.3*index;
        if (index == [mIconArray count]-1) 
        {
            [fadeIn setDelegate:self];
        }
        [layer addAnimation:fadeIn forKey:@"opacity"];
        index ++;
    }
    
    [self textAnimationLoop];
}

-(void)iconAnimationLoop
{
    static BOOL isFadingOut = YES;
    int index = 0;
    for(CALayer* layer in mIconArray)
    {
        if (isFadingOut) {
            layer.opacity = 1;
        }
        else
        {
            layer.opacity = 0.5;
        }
        [layer removeAllAnimations];
        CFTimeInterval now = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
        CABasicAnimation* fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeIn.fillMode = kCAFillModeForwards;
        fadeIn.removedOnCompletion = NO;
        if (isFadingOut) {
            fadeIn.fromValue = [NSNumber numberWithFloat:1];
            fadeIn.toValue = [NSNumber numberWithFloat:0.5];
        }
        else
        {
            fadeIn.fromValue = [NSNumber numberWithFloat:0.5];
            fadeIn.toValue = [NSNumber numberWithFloat:1];
        }
        fadeIn.duration = 0.2;
        fadeIn.beginTime = now + 0.2*index;
        if (index == [mIconArray count]-1) {
            fadeIn.delegate = self;
        }
        [layer addAnimation:fadeIn forKey:@"opacityLoop"];
        index ++;
        
    }
    isFadingOut = !isFadingOut;
    
}

-(void)textAnimationLoop
{
    mTextLayer.opacity = 0;
    if (mLoadingTextArray && [mLoadingTextArray count] > 0) {
        mTextLayer.string = [mLoadingTextArray objectAtIndex:arc4random()%[mLoadingTextArray count]];
    }
    [mTextLayer removeAllAnimations];
    CAAnimationGroup* animationGroup = [[[CAAnimationGroup alloc] init] autorelease];
    
    CABasicAnimation* fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = [NSNumber numberWithFloat:0];
    fadeIn.toValue = [NSNumber numberWithFloat:1];
    fadeIn.duration = 1;
    fadeIn.removedOnCompletion = NO;
    fadeIn.fillMode = kCAFillModeForwards;
    
    CABasicAnimation* fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.fromValue = [NSNumber numberWithFloat:1];
    fadeOut.toValue = [NSNumber numberWithFloat:0];
    fadeOut.duration = 0.5;
    CFTimeInterval now = [mTextLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    fadeOut.beginTime = now + 2.5;
    fadeOut.removedOnCompletion = NO;
    fadeOut.fillMode = kCAFillModeForwards;
    
    animationGroup.animations = [NSArray arrayWithObjects:fadeIn,fadeOut, nil];
    animationGroup.delegate = self;
    animationGroup.removedOnCompletion = NO;
    animationGroup.duration = 3;
    [mTextLayer addAnimation:animationGroup forKey:@"text_animation"];
}

- (void)animationDidStart:(CAAnimation *)anim
{
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (anim == [mTextLayer animationForKey:@"text_animation"]) {
        [self textAnimationLoop];
    }
    else
    {
        if (flag) {
            [self iconAnimationLoop];
        }

    }
    
}

@end
