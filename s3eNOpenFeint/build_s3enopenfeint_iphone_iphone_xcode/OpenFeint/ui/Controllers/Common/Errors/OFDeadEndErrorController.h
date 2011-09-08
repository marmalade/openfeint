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

@class OFDefaultButton;

@interface OFDeadEndErrorController : OFViewController
{
@private
	NSString* mMessage;
	UILabel* mMessageView;
	OFDefaultButton* mOfflineButton;
}

@property (nonatomic, retain) NSString* message;
@property (nonatomic, retain) IBOutlet UILabel* messageView;
@property (nonatomic, retain) IBOutlet OFDefaultButton* offlineButton;

- (IBAction)offlinePressed;
+ (id)deadEndErrorWithMessage:(NSString*)errorMessage;
+ (id)deadEndErrorWithMessageAndOfflineButton:(NSString*)errorMessage;
+ (id)mustBeOnlineErrorWithMessage:(NSString*)errorMessage;


@end
