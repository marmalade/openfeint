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

#import "OFChangeNameController.h"
#import "OFShowMessageAndReturnController.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"

#import "OFISerializer.h"
#import "UIView+OpenFeint.h"
#import "OFSelectAccountTypeController.h"
#import "OFControllerLoaderObjC.h"
#import "OFWebNavController.h"
#import "UIViewController+OpenFeint.h"
#import "OFDependencies.h"

static const int kNameInputFieldTag = 1;

@implementation OFChangeNameController

@synthesize currentNameLabel;

- (void)populateViewDataMap:(NSMutableDictionary*)dataMap
{
    [dataMap setObject:@"name" forKey:[NSNumber numberWithInt:kNameInputFieldTag]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	currentNameLabel.text = [OpenFeint lastLoggedInUserName];	
	
	if ([OpenFeint loggedInUserHasNonDeviceCredential])
	{
		UIView* oldUserButton = [self.view findViewByTag:5];
		oldUserButton.hidden = YES;
	}
}

- (void)onBeforeFormSubmitted
{
	[nameAttemptingToClaim release];
	UITextField* nameField = (UITextField*)[self.view findViewByTag:kNameInputFieldTag];
	nameAttemptingToClaim = [nameField.text retain];
}

- (void)addHiddenParameters:(NSObject<OFISerializer>*)parameterStream
{
    [parameterStream ioNSStringToKey:@"id" object:@"me"];
}

- (void)registerActionsNow
{
}

- (void)onFormSubmitted:(id)resources
{
	[OpenFeint loggedInUserChangedNameTo:nameAttemptingToClaim];
	currentNameLabel.text = nameAttemptingToClaim;
	[OpenFeint reloadInactiveTabBars];
	
	OFShowMessageAndReturnController* controller = (OFShowMessageAndReturnController*)[[OFControllerLoaderObjC loader] load:@"ShowMessageAndReturn"];// load(@"ShowMessageAndReturn");
	controller.messageLabel.text = [NSString stringWithFormat:OFLOCALSTRING(@"You have changed your OpenFeint name to %@."), nameAttemptingToClaim];
	controller.messageTitleLabel.text = OFLOCALSTRING(@"Change Name");
	[[self navigationController] pushViewController:controller animated:YES];
	OFSafeRelease(nameAttemptingToClaim);
}

- (NSString*)singularResourceName
{
	return @"user";
}

- (NSString*)getFormSubmissionUrl
{
	return @"users/update_name.xml";
}

- (NSString*)getHTTPMethod
{
	return @"POST";
}

- (void)dealloc
{
	self.currentNameLabel = nil;
	OFSafeRelease(nameAttemptingToClaim);
	[super dealloc];
}

@end
