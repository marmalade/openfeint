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

#import "OFTableSequenceControllerHelper.h"
#import "OFCustomBottomView.h"
#import "OFExpandableSinglelineTextField.h"
#import "OFRootController.h"

@class OFConversationMessageBoxController;
@class OFPoller;
@class OFUser;

@interface OFConversationController : OFTableSequenceControllerHelper< OFCustomBottomView, OFExpandableSinglelineTextFieldDelegate, OFKeyboardAdjustment >
{
	NSString* conversationId;
	OFUser* conversationUser;
	
	OFConversationMessageBoxController* messageBox;
	BOOL isKeyboardShown;
	
	OFPoller* poller;
	BOOL hasCompletedInitialIndex;
    float mViewOriginYWithoutKeyboardiPad;
}

+ (id)conversationWithId:(NSString*)conversationId withUser:(OFUser*)conversationUser;
+ (id)conversationWithId:(NSString*)conversationId withUser:(OFUser*)conversationUser initialText:(NSString*)initialText;
- (id)initWithConversationId:(NSString*)_conversationId withConversationUser:(OFUser*)_conversationUser initialText:(NSString*)initialText;

@property (nonatomic, retain) NSString* conversationId;
@property (nonatomic, retain) OFUser* conversationUser;

- (UIView*)getBottomView;

- (void)_updateOnlineStatusWithUser:(OFUser*)user isOnline:(BOOL)online;

@end
