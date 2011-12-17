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
#import "UIView+OpenFeint.h"
#import "OpenFeint+Private.h"
#import "QuartzCore/CALayer.h"
#import "OFDependencies.h"

@implementation UIView (OpenFeint)
-(UIView*)findViewByTag:(int) targetTag
{
    if(self.tag == targetTag)
	{
		return self;
	}
    
	for(UIView* view in self.subviews)
	{
		UIView* targetView = [view findViewByTag:targetTag];
		if(targetView != nil)
		{
			return targetView;
		}
	}
	
	return NULL;
    
}

-(UIView*)findViewByClass:(Class) viewClass
{
	if ([self isKindOfClass:viewClass])
	{
		return self;
	}
	
	for (UIView* view in self.subviews)
	{
		UIView* viewOfType = [self findViewByClass:viewClass];
		if(viewOfType != nil)
		{
			return viewOfType;
		}
	}
	
	return nil;
}

-(UIView*)findSuperviewByClass:(Class) viewClass
{
	UIView* returnView = nil;
	UIView* view = self;
    
	while (view && !returnView)
	{
		if ([view isKindOfClass:viewClass])
			returnView = view;
		
		view = [view superview];
	}
    
	return returnView;
}

-(void)setDelegateForAllTextFields:(id<UITextFieldDelegate, UITextViewDelegate>)delegate
{
	for(UIView* view in self.subviews)
	{
		if([view isKindOfClass:[UITextField class]])
		{
			UITextField* textField = (UITextField*)view;
            
			if(textField.delegate == nil)
			{
				textField.delegate = delegate;
			}
		}
		else if ([view isKindOfClass:[UITextView class]])
		{
			UITextView* textView = (UITextView*)view;
			
			if (textView.delegate == nil)
			{
				textView.delegate = delegate;
			}
		}
		
		[view setDelegateForAllTextFields:delegate];
	}
}

-(void)setReturnKeyForAllTextFields:(UIReturnKeyType)lastKey
{
	unsigned int i = 1;
	UITextField* textField = nil;
    
	while(YES)
	{
		UIView* view = [self viewWithTag:i];
		++i;
        
		if(!view)
		{
			break;
		}
		
		if(![view isKindOfClass:[UITextField class]])
		{			
			textField = nil;
			continue;
		}
		
		textField = (UITextField*)view;
		textField.returnKeyType = UIReturnKeyNext;
	}
	
	if(textField)
	{
		textField.returnKeyType = lastKey;
	}
}

-(UIScrollView*)findFirstScrollView
{
	if([self isKindOfClass:[UIScrollView class]])
	{
		return (UIScrollView*)self;
	}
	
	for(UIView* view in self.subviews)
	{
		UIScrollView* targetView = [view findFirstScrollView];
		if(targetView != nil)
		{
			return targetView;
		}
	}
    
	return nil;
}

-(BOOL)resignFirstResponderRecursive
{
	if([self isKindOfClass:[UIResponder class]])
	{
		UIResponder* responder = (UIResponder*)self;
		if([responder isFirstResponder])
		{
			[responder resignFirstResponder];
			return YES;
		}
	}
	
	for(UIView* view in self.subviews)
	{
		if([view resignFirstResponderRecursive])
		{
			return YES;
		}
	}
	
	return NO;
}

-(void)setEnabledForAllControls:(BOOL)isEnabled
{
	if([self isKindOfClass:[UIControl class]])
	{
		UIControl* control = (UIControl*)self;
		control.enabled = isEnabled;
	}
	
	for(UIView* view in self.subviews)
	{
        [view setEnabledForAllControls:isEnabled];
	}
}

-(CGSize)sizeThatFitsTight
{	
    CGSize sizeThatFits = CGSizeZero;    
	for(UIView* view in self.subviews)
	{
		float right = view.frame.origin.x + view.frame.size.width;
		float bottom = view.frame.origin.y + view.frame.size.height;
		if(right > sizeThatFits.width)
		{
			sizeThatFits.width = right;
		}
		
		if(bottom > sizeThatFits.height)
		{
			sizeThatFits.height = bottom;
		}		
	}

	return sizeThatFits;
}

-(void)debugShowParentsOfRecursive
{
    UIView* parent = self.superview;
	if(parent)
	{	
		OFLog(@"%@\n", parent);
		[parent debugShowParentsOfRecursive];
	}    
}

-(void)debugShowParents
{	
	OFLog(@"Looking at parents of %@\n", self);
	OFLog(@"-----------------------------------------------\n");
	
	[self debugShowParentsOfRecursive];
	OFLog(@"-----------------------------------------------\n\n");
}

-(void)debugShowAllChildren
{
    OFLog(@"Looking at children of %@\n", self);
    OFLog(@"-----------------------------------------------\n");
    
    for(UIView* subview in [self subviews])
    {
        OFLog(@"%@\n", subview);
    }
    OFLog(@"-----------------------------------------------\n\n");
}
     
- (BOOL)isRotatedInternally
{
	//There are some assumptions here that go against the way notificatoin is written.  This *tries* to figure out if the orientation OpenFeint is initialized with
	//Does not match the actual orientation of the device.  This is true for games that have a internal "portrait" view for the iPhone, but tip the camera in the gl
	//world to make the world look landscape.  In this case OpenFeint is initialized with a landscape view.
    BOOL isPortrait = self.bounds.size.width <= ([UIScreen mainScreen].bounds.size.height + [UIScreen mainScreen].bounds.size.width) * 0.5f;
    return UIInterfaceOrientationIsLandscape(([OpenFeint getDashboardOrientation])) && isPortrait;
}

- (NSString*) detailedDescription
{
    return [NSString stringWithFormat:@"View Info for:%@\ntransform rot:%f %f %f %f trans:%f %f\ncenter %f %f\nbounds origin:%f %f size:%f %f\nanchor %f %f",
            self,
            self.transform.a, self.transform.b, self.transform.c, self.transform.d, self.transform.tx, self.transform.ty, 
            self.center.x, self.center.y,
            self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height,
            self.layer.anchorPoint.x, self.layer.anchorPoint.y
            ];
}

-(OFUIViewLocation) findSubviewLocation:(UIView*) subView position:(ENotificationPosition)position deltaRange:(float)deltaRange
{
    OFUIViewLocation location;	
    location.transform = CGAffineTransformIdentity;
    location.frame = CGRectZero;
    location.deltaX = 0.0f;
    location.deltaY = 0.0f;    

	const float kNotificationHeight = subView.frame.size.height;
	
	// If we are doing inverted notifications, we may need to come in past the UIStatusBar.
	CGSize statusBarOffsetSize = CGSizeZero;
	if (![UIApplication sharedApplication].statusBarHidden) {
		statusBarOffsetSize = [UIApplication sharedApplication].statusBarFrame.size;
	}
	
	static float const kfMaxNotificationWidth = 480.f;
	
	UIInterfaceOrientation dashboardOrientation = [OpenFeint getDashboardOrientation];
	if ([self isRotatedInternally]) 
	{	
        //The parent in most cases will be the application window which is never autorotated.  With autorotation or OpenGL camera flipping, the coordinates will be different
        //The transform should be set in those cases.

 		//If here, the orientation passed into openfeint, and the orientation of the iphone don't match.  This implies that the dev is using some openGL world which
		//the phone still "thinks" is in portrait, but the dev has tipped, or flipped the camera to make the world appear in a different orientation.  In this case
		//we have to move notifications apporiately to the orientation they want openfeint to appear in (because the default cooridinat system will give us incorrect positions).
		
		CGSize notificationSize = CGSizeMake(self.frame.size.height, kNotificationHeight);
		notificationSize.width = MIN(kfMaxNotificationWidth, notificationSize.width);
        
		location.frame = CGRectMake(-notificationSize.width * 0.5f,
									  -notificationSize.height * 0.5f, 
									  notificationSize.width, 
									  notificationSize.height
									  );
		
		
		//Here (unlike the "normal" case) we deal with rotations and center points of the object to position the frame.
		if(![OpenFeint isLargeScreen])
		{	
			//iPhone
			if (position == ENotificationPosition_TOP)
			{
				switch (dashboardOrientation)
				{
						//Rotate 90 (clockwise?)
					case UIInterfaceOrientationLandscapeRight:
						location.transform = CGAffineTransformMake(0, 1, -1, 0, 
															 self.bounds.size.width - notificationSize.height * 0.5f - statusBarOffsetSize.width,
															 self.bounds.size.height * 0.5f);
						location.deltaX = -deltaRange;
						break;
						//Rotate 270
					case UIInterfaceOrientationLandscapeLeft:
						location.transform = CGAffineTransformMake(0, -1, 1, 0, 
															 notificationSize.height * 0.5f + statusBarOffsetSize.width,
															 self.bounds.size.height * 0.5f);
						location.deltaX = deltaRange;
						break;
					default:
						break;
				}
			}
			else if(position == ENotificationPosition_BOTTOM)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
						// Rotate 90
						location.transform = CGAffineTransformMake(0, 1, -1, 0, 
															 notificationSize.height * 0.5f, 
															 self.bounds.size.height * 0.5f);
						location.deltaX = deltaRange;
						break;
						//Rotate 270
					case UIInterfaceOrientationLandscapeLeft:
						location.transform = CGAffineTransformMake(0, -1, 1, 0, 
															 self.bounds.size.width - notificationSize.height * 0.5f, 
															 self.bounds.size.height * 0.5f);
						location.deltaX = -deltaRange;
						break;
					default:
						break;
				}			
			}
		}
		else
		{
			if(position == ENotificationPosition_TOP_LEFT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						location.transform = CGAffineTransformMake(0, 1, -1, 0, 
															 self.bounds.size.width - (notificationSize.height * 0.5f) - statusBarOffsetSize.width,
															 notificationSize.width * 0.5f);
						location.deltaX = -deltaRange;
						
					}
                        break;
                        
					case UIInterfaceOrientationLandscapeLeft:
					{
						location.transform = CGAffineTransformMake(0, -1, 1, 0, 
                                                             (notificationSize.height * 0.5f) + statusBarOffsetSize.width,
                                                             self.bounds.size.height - (notificationSize.width * 0.5f));
						location.deltaX = deltaRange;
					}
                        break;
					default:
						break;
				}
			}
			else if(position == ENotificationPosition_BOTTOM_LEFT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						location.transform = CGAffineTransformMake(0, 1, -1, 0, 
															 notificationSize.height * 0.5f,
															 notificationSize.width * 0.5f);
						location.deltaX = deltaRange;
					}
                        break;
						
					case UIInterfaceOrientationLandscapeLeft:
					{
						location.transform = CGAffineTransformMake(0, -1, 1, 0, 
															 self.bounds.size.width - (notificationSize.height * 0.5f),
															 self.bounds.size.height - (notificationSize.width * 0.5f));
						location.deltaX = -deltaRange;
					}
                        break;
                        
					default:
						break;
				}
			}
			else if(position == ENotificationPosition_TOP_RIGHT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						location.transform = CGAffineTransformMake(0, 1, -1, 0, 
															 self.bounds.size.width - (notificationSize.height * 0.5f) - statusBarOffsetSize.width,
															 self.bounds.size.height - (notificationSize.width * 0.5f));
						location.deltaX = -deltaRange;
					}
                        break;
						
					case UIInterfaceOrientationLandscapeLeft:
					{
						location.transform = CGAffineTransformMake(0, -1, 1, 0, 
															 notificationSize.height * 0.5f + statusBarOffsetSize.width,
															 notificationSize.width * 0.5f);
						location.deltaX = deltaRange;
					}
                        break;
						
					default:
                        break;
				}
			}
			else if(position == ENotificationPosition_BOTTOM_RIGHT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						location.transform = CGAffineTransformMake(0, 1, -1, 0, 
															 notificationSize.height * 0.5f,
															 self.bounds.size.height - (notificationSize.width * 0.5f));
						location.deltaX = deltaRange;
					}
                        break;
						
					case UIInterfaceOrientationLandscapeLeft:
					{
						location.transform = CGAffineTransformMake(0, -1, 1, 0, 
															 self.bounds.size.width - (notificationSize.height * 0.5f),
															 notificationSize.width * 0.5f);
						location.deltaX = -deltaRange;
					}
                        break;
                        
					default:
                        break;
				}
			}
		}        
	}
	else
	{
		//Here we deal with building the frame in the upper left corner of the frame.  Since we only have a case that rotates the object 180 degrees (when upsidedown)
		//this is the easiest method for "normal" cases.
		CGSize notificationSize = CGSizeMake(self.bounds.size.width, kNotificationHeight);
		notificationSize.width = MIN(kfMaxNotificationWidth, notificationSize.width);
		
		CGFloat frameX, frameY;
		frameX = frameY = 0.0f;
		
		if(![OpenFeint isLargeScreen])
		{
			//iPhone
			//If we're Portrait upside down, we have to switch which side you think it would pop up on rotate it around 180 (after this if else).
			BOOL topNotUpsideDown = ((ENotificationPosition_TOP == position) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomNotUpsideDown = ((ENotificationPosition_BOTTOM == position) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topUpsideDown = ((ENotificationPosition_TOP == position) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomUpsideDown = ((ENotificationPosition_BOTTOM == position) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			
			if (topNotUpsideDown || bottomUpsideDown)
			{
				//Come in from the top and center the notification
				frameX = (self.bounds.size.width - notificationSize.width) * 0.5f;
				frameY = 0.0f;
				
				if(topNotUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY += statusBarOffsetSize.height;
				}
				
				location.deltaY = -deltaRange;
			}
			else if(bottomNotUpsideDown || topUpsideDown) //This must be the case if we hit the else, unless the dev put in something invalid for orientation on the iphone.
			{
				//Come in from the bottom and center the notification.
				frameX = (self.bounds.size.width - notificationSize.width) * 0.5f;
				frameY = self.bounds.size.height - notificationSize.height;
				
				if(topUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY -= statusBarOffsetSize.height;
				}
				
				location.deltaY = deltaRange;
			}
		}
		else
		{
			//iPad
			//Come in on the corner specified by the dev.  Note taht if our dashboard orientation is interface orientation portrait upsidedown
			//Then the notification will come in from its "opposite" side since the ui coor system doesn't flip 180 with the device (for some reason).
			//Therefore when upside down, we pop in the notification from its "opposite notification position" and then flip it 180 degrees about itself (after this if/else).
			BOOL bottomLeftNotUpsideDown =	((ENotificationPosition_BOTTOM_LEFT == position) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomRightNotUpsideDown =	((ENotificationPosition_BOTTOM_RIGHT == position) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topLeftNotUpsideDown =		((ENotificationPosition_TOP_LEFT == position) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topRightNotUpsideDown =	((ENotificationPosition_TOP_RIGHT == position) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topRightUpSideDown =		((ENotificationPosition_TOP_RIGHT == position) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topLeftUpSideDown =		((ENotificationPosition_TOP_LEFT == position) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomRightUpSideDown =	((ENotificationPosition_BOTTOM_RIGHT == position) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomLeftUpSideDown =		((ENotificationPosition_BOTTOM_LEFT == position) && ([OpenFeint getDashboardOrientation]  == UIInterfaceOrientationPortraitUpsideDown));
			
			if(bottomLeftNotUpsideDown || topRightUpSideDown)
			{
				frameX = 0.0f;
				frameY = self.bounds.size.height - notificationSize.height;
				
				if(topRightUpSideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY -= statusBarOffsetSize.height;
				}
				location.deltaY = deltaRange;
			}
			else if(bottomRightNotUpsideDown || topLeftUpSideDown)
			{
				frameX = self.bounds.size.width - notificationSize.width;
				frameY = self.bounds.size.height - notificationSize.height;
				
				if(topLeftUpSideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY -= statusBarOffsetSize.height;
				}
				location.deltaY = deltaRange;
			}
			else if(topLeftNotUpsideDown || bottomRightUpSideDown)
                
			{
				frameX = 0.0f;
				frameY = 0.0f;
				
				if(topLeftNotUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY += statusBarOffsetSize.height;
				}
				location.deltaY = -deltaRange;
			}
			else if(topRightNotUpsideDown || bottomLeftUpSideDown)
                
			{
				frameX = self.bounds.size.width - notificationSize.width;
				frameY = 0.0f;
				
				if(topRightNotUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY = statusBarOffsetSize.height;
				}
				location.deltaY = -deltaRange;
			}
		}
		
		//Make the rect.
		location.frame = CGRectMake(frameX, frameY, notificationSize.width, notificationSize.height);
        
		//If the dashboard is upside down, the corridinate system still think its right side up, so
		//the notification will appear upside down unless we flip it.
		if([OpenFeint getDashboardOrientation]  == UIInterfaceOrientationPortraitUpsideDown)
		{
			location.transform = CGAffineTransformRotate(self.transform, M_PI);
		}
	}
    return location;
}

- (CGAffineTransform)calculateViewTransformFromMainScreen
{
    CGAffineTransform transform = self.transform;
    UIView* view = self.superview;
    while(view)
    {
        transform = CGAffineTransformConcat(view.transform, transform);
        view = view.superview;
    }
    return transform;
}

+ (CGAffineTransform)transformToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationPortrait)
    {
        return CGAffineTransformIdentity;
    }
    else if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
        return CGAffineTransformMake(0, -1, 1, 0, 0, 240);
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
        return CGAffineTransformMake(0, 1, -1, 0, 160, 0);
    }
    else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        return CGAffineTransformMake(-1, 0, 0, -1, 160, 240);
    }
    return CGAffineTransformIdentity;
}

- (CGAffineTransform)calculateTransformFromViewToOpenFeintDashboardOrientation
{
    UIInterfaceOrientation ofOrientation = [OpenFeint getDashboardOrientation];
    CGAffineTransform ofTransform = [UIView transformToInterfaceOrientation:ofOrientation];
    CGAffineTransform viewTransform = [self calculateViewTransformFromMainScreen];
    CGAffineTransform viewTransformInv = CGAffineTransformInvert(viewTransform);
    CGAffineTransform transform = CGAffineTransformConcat(viewTransformInv, ofTransform);
    return transform;
}

@end
