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

#pragma once

#import "OFViewController.h"

@class OFInvocation;

@interface OFFormControllerHelper : OFViewController<UITextFieldDelegate, UITextViewDelegate>
{
@package
    NSMutableDictionary* mTagActions;
	UIScrollView* mScrollContainerView;
	UIView* mActiveTextField;	
	NSMutableDictionary* mViewDataMap;
	BOOL mIsKeyboardShown;
	float mViewHeightWithoutKeyboard;
    float mViewOriginYWithoutKeyboardiPad;
	@protected BOOL mIsSubmitting;
}

- (void)registerActionInvocation:(OFInvocation*)actionInvocation forTag:(int)tag;
- (IBAction)onTriggerAction:(UIView*)sender;
- (IBAction)onTriggerBarAction:(UIBarButtonItem*)sender;
@property (nonatomic, retain) NSMutableDictionary* viewDataMap;

@end
