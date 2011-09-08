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

#import "OFFormControllerHelper.h"

@class OFForumTopic;
@class OFForumThread;

@interface OFPostNewMessage : OFFormControllerHelper< UITextViewDelegate >
{
	IBOutlet UIView* subjectView;
	IBOutlet UIView* bodyView;
	
	IBOutlet UITextField* subjectField;
	IBOutlet UITextView* bodyField;
	
	OFForumTopic* topic;
	OFForumThread* thread;
}

@property (retain) OFForumTopic* topic;
@property (retain) OFForumThread* thread;

+ (id)postNewMessageInTopic:(OFForumTopic*)_topic;
+ (id)postNewMessageInThread:(OFForumThread*)_thread topic:(OFForumTopic*)_topic;

@end
