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

#include "OFViewHelper.h"

UIView* OFViewHelper::findSuperviewByClass(UIView* rootView, Class viewClass)
{
	UIView* returnView = nil;
	UIView* view = rootView;

	while (view && !returnView)
	{
		if ([view isKindOfClass:viewClass])
			returnView = view;
		
		view = [view superview];
	}

	return returnView;
}

UIView* OFViewHelper::findViewByClass(UIView* rootView, Class viewClass)
{
	if ([rootView isKindOfClass:viewClass])
	{
		return rootView;
	}
	
	for (UIView* view in rootView.subviews)
	{
		UIView* viewOfType = findViewByClass(view, viewClass);
		if(viewOfType != nil)
		{
			return viewOfType;
		}
	}
	
	return nil;
}

bool OFViewHelper::resignFirstResponder(UIView* rootView)
{
	if([rootView isKindOfClass:[UIResponder class]])
	{
		UIResponder* responder = (UIResponder*)rootView;
		if([responder isFirstResponder])
		{
			[responder resignFirstResponder];
			return true;
		}
	}
	
	for(UIView* view in rootView.subviews)
	{
		if(resignFirstResponder(view))
		{
			return true;
		}
	}
	
	return false;
}

UIScrollView* OFViewHelper::findFirstScrollView(UIView* rootView)
{
	if([rootView isKindOfClass:[UIScrollView class]])
	{
		return (UIScrollView*)rootView;
	}
	
	for(UIView* view in rootView.subviews)
	{
		UIScrollView* targetView = findFirstScrollView(view);
		if(targetView != nil)
		{
			return targetView;
		}
	}
			
	return nil;
}

void OFViewHelper::setReturnKeyForAllTextFields(UIReturnKeyType lastKey, UIView* rootView)
{
	unsigned int i = 1;
	UITextField* textField = nil;
		
	while(true)
	{
		UIView* view = [rootView viewWithTag:i];
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

void OFViewHelper::setAsDelegateForAllTextFields(id<UITextFieldDelegate, UITextViewDelegate> delegate, UIView* rootView)
{
	for(UIView* view in rootView.subviews)
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
		
		setAsDelegateForAllTextFields(delegate, view);
	}
}

CGSize OFViewHelper::sizeThatFitsTight(UIView* rootView)
{
	CGSize sizeThatFits = CGSizeZero;

	if (!rootView)
		return sizeThatFits;
	
	for(UIView* view in rootView.subviews)
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

UIView* OFViewHelper::findViewByTag(UIView* rootView, int targetTag)
{
	if(rootView.tag == targetTag)
	{
		return rootView;
	}

	for(UIView* view in rootView.subviews)
	{
		UIView* targetView = findViewByTag(view, targetTag);
		if(targetView != nil)
		{
			return targetView;
		}
	}
	
	return NULL;
}

void OFViewHelper::enableAllControls(UIView* rootView, bool isEnabled)
{
	if([rootView isKindOfClass:[UIControl class]])
	{
		UIControl* control = (UIControl*)rootView;
		control.enabled = isEnabled;
	}
	
	for(UIView* view in rootView.subviews)
	{
		enableAllControls(view, isEnabled);
	}
}

UIFont* OFViewHelper::getFontToFitStringInSize(NSString * text, CGSize size, UIFont const* font, uint maxFontSize, uint minFontSize)
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
		CGSize sizeWithFont = [text sizeWithFont:fontToFitInRect constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
		if(sizeWithFont.height <= size.height)
		{
			return fontToFitInRect;
		}
	}
	
	return [font fontWithSize:minFontSize];
	
}

static void showParentsOfRecursive(UIView* view)
{	
	UIView* parent = view.superview;
	if(parent)
	{	
		OFLog(@"%@\n", parent);
		showParentsOfRecursive(parent);
	}
}

/*static*/ void OFViewHelper::showParentsOf(id viewOrController)
{
	if(![viewOrController isKindOfClass:[UIView class]] &&
	   ![viewOrController isKindOfClass:[UIViewController class]])
	{
		return;	   
	}
	
	UIView* view = nil;
	if([viewOrController isKindOfClass:[UIView class]])
	{
		view = viewOrController;
	}
	else 
	{
		OFAssert([viewOrController isKindOfClass:[UIViewController class]], @"Must be a UIViewController");
		view = [viewOrController view];
	}
	
	OFLog(@"Looking at parents of %@\n", view);
	OFLog(@"-----------------------------------------------\n");
	
	showParentsOfRecursive(view);
	OFLog(@"-----------------------------------------------\n\n");
}

/*static*/ void OFViewHelper::showChildrenOf(id viewOrController)
{
	if(![viewOrController isKindOfClass:[UIView class]] &&
		 ![viewOrController isKindOfClass:[UIViewController class]])
	{
		return;	   
	}
	
	UIView* parentView = nil;
	if([viewOrController isKindOfClass:[UIView class]])
	{
		parentView = viewOrController;
	}
	else 
	{
		OFAssert([viewOrController isKindOfClass:[UIViewController class]], @"Must be a UIViewController");
		parentView = [viewOrController view];
	}
	
	OFLog(@"Looking at children of %@\n", parentView);
	OFLog(@"-----------------------------------------------\n");
	
	for(UIView* subview in [parentView subviews])
	{
		OFLog(@"%@\n", subview);
	}
	OFLog(@"-----------------------------------------------\n\n");
}













