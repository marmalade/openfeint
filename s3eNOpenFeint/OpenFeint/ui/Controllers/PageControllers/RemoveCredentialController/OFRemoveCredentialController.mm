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

#import "OpenFeint.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFRemoveCredentialController.h"
#import "OFDefaultButton.h"
#import "OFService.h"
#import "OFISerializer.h"
#import "OFUser.h"
#import "FBConnect.h"

@implementation OFRemoveCredentialController

@synthesize warningText, warningTextTwo, headerTitle, credentialType, credentialSpokenName, submitButton;

#pragma mark Boilerplate

- (void)dealloc
{
	self.warningText = nil;
	self.warningTextTwo = nil;
	self.headerTitle = nil;
	self.submitButton = nil;
	self.credentialType = nil;
	self.credentialSpokenName = nil;
	[super dealloc];
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

- (NSString*)getFormSubmissionUrl
{
	return @"users_credentials/remove.xml";
}

- (void)registerActionsNow
{
}

- (NSString*)singularResourceName
{
	return @"users";
}

- (NSString*)getHTTPMethod
{
	return @"GET";
}

- (void)addHiddenParameters:(OFISerializer*)parameterStream
{
	parameterStream->io("credential_type", self.credentialType);
}

- (void)onFormSubmitted:(id)resources
{
	if (submittedDelegate.isValid())
	{
		submittedDelegate.invoke();
	}

	OFUser* localUser = [OpenFeint localUser];
	if ([credentialType isEqualToString:localUser.profilePictureSource])
	{
		[localUser changeProfilePictureUrl:nil facebook:NO twitter:NO uploaded:NO];
		[OpenFeint setLocalUser:localUser];
	}
	
	if ([credentialType isEqualToString:@"TwitterCredential"])
	{
		[OpenFeint setLoggedInUserHasTwitterCredential:NO];
	}
	else if ([credentialType isEqualToString:@"FbconnectCredential"])
	{
		[OpenFeint setLoggedInUserHasFbconnectCredential:NO];
	}

	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSubmitPressed
{
	if (![OpenFeint loggedInUserHasHttpBasicCredential])
	{	
		NSString *errorMsg = [NSString stringWithFormat:OFLOCALSTRING(@"By disconnecting %@ you will have no way of recovering your account if you lose your device. You may secure your account by tapping 'Go Back' and choosing 'Secure Account'."), self.credentialSpokenName];
		UIActionSheet* sheet = [[[UIActionSheet alloc] initWithTitle:errorMsg delegate:self cancelButtonTitle:OFLOCALSTRING(@"Go Back") destructiveButtonTitle:OFLOCALSTRING(@"Continue") otherButtonTitles:nil] autorelease];
		[sheet showInView:[OpenFeint getTopLevelView]];
	}
	else
	{
		[self onSubmitForm:self.view];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	warningText.text = [NSString stringWithFormat:OFLOCALSTRING(@"You are about to disconnect %@ from your account."), self.credentialSpokenName];
	warningTextTwo.text = [NSString stringWithFormat:OFLOCALSTRING(@"You will no longer be able use your %@ profile picture."), self.credentialSpokenName];
	
	[super viewWillAppear:animated];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.destructiveButtonIndex)
	{
		[self onSubmitForm:self.view];
	}
	else		
	{
		[[self navigationController] popViewControllerAnimated:YES];
	}
	actionSheet.delegate = nil;
}

- (void)_logoutFacebookSession
{
	[[FBSession session] logout];
}

- (void)setupForFacebook
{
	submittedDelegate = OFDelegate(self, @selector(_logoutFacebookSession));
	
	self.credentialType = @"FbconnectCredential";
	self.credentialSpokenName = @"facebook";
	self.title = OFLOCALSTRING(@"Remove Facebook");
	self.headerTitle.text = OFLOCALSTRING(@"Remove Facebook");
	[self.submitButton setTitleForAllStates:OFLOCALSTRING(@"Remove Facebook")];
}

- (void)setupForTwitter
{
	self.credentialType = @"TwitterCredential";
	self.credentialSpokenName = @"twitter";
	self.title = OFLOCALSTRING(@"Remove Twitter");
	self.headerTitle.text = OFLOCALSTRING(@"Remove Twitter");
	[self.submitButton setTitleForAllStates:OFLOCALSTRING(@"Remove Twitter")];
}

@end
