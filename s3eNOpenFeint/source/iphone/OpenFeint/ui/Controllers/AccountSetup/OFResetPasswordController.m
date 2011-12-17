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

#import "OFResetPasswordController.h"
#import "OFShowMessageAndReturnController.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"

#import "OFISerializer.h"
#import "UIView+OpenFeint.h"
#import "OFSelectAccountTypeController.h"
#import "OFControllerLoaderObjC.h"
#import "OFDefaultButton.h"
#import "OFDependencies.h"

@implementation OFResetPasswordController

@synthesize resetButton;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[resetButton setTitleForAllStates:@"Reset Your Password"];
}

- (void)addHiddenParameters:(NSObject<OFISerializer>*)parameterStream
{
    [parameterStream ioNSStringToKey:@"id" object:OpenFeint.lastLoggedInUserId];
}

- (void)registerActionsNow
{
}

- (void)onFormSubmitted:(id)resources
{
	OFShowMessageAndReturnController *controller = (OFShowMessageAndReturnController *)[[OFControllerLoaderObjC loader] load:@"ShowMessageAndReturn"];// load(@"ShowMessageAndReturn");
	controller.messageLabel.text = OFLOCALSTRING(@"We generated a new password and sent an email to the address we have on file. It should be there in a few minutes.");
	controller.messageTitleLabel.text = OFLOCALSTRING(@"Password Reset");
	[[self navigationController] pushViewController:controller animated:YES];
}

- (NSString*)singularResourceName
{
	return @"credential";
}

- (NSString*)getFormSubmissionUrl
{
	return @"support/do_pw_reset.xml";
}

- (NSString*)getHTTPMethod
{
	return @"POST";
}

- (void)dealloc
{
	[super dealloc];
}

@end
