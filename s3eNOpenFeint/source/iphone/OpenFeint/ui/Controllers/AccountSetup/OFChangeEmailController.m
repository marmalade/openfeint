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

#import "OFChangeEmailController.h"
#import "OFShowMessageAndReturnController.h"
#import "OFHttpBasicCredential.h"

#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"

#import "OFISerializer.h"
#import "UIView+OpenFeint.h"
#import "OFSelectAccountTypeController.h"
#import "OFControllerLoaderObjC.h"

#import "OFUserService.h"
#import "OFPaginatedSeries.h"
#import "OFDependencies.h"

static const int kEmailInputFieldTag = 1;
@implementation OFChangeEmailController

@synthesize currentEmailLabel;
@synthesize changedEmailField;


- (void)populateViewDataMap:(NSMutableDictionary*)dataMap
{
    [dataMap setObject:@"email" forKey:[NSNumber numberWithInt:kEmailInputFieldTag]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	currentEmailLabel.text = @"";
	changedEmailField.text = @"";

//	OFDelegate success(self, @selector(onGetEmailSuccess:));
//	OFDelegate failure(self, @selector(onGetEmailFailure:));
	[OFUserService getEmailForUser:@"me" onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(onGetEmailSuccess:)] 
               onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(onGetEmailFailure:)]];
}

- (void)onGetEmailSuccess:(OFPaginatedSeries *)emails
{
	//OFLog(@"onGetEmailSuccess: %@", [emails.objects objectAtIndex:0]);
	currentEmailLabel.text = [(OFHttpBasicCredential *)[emails.objects objectAtIndex:0] email];
}

- (void)onGetEmailFailure:(OFPaginatedSeries *)emails
{
	//OFLog(@"onGetEmailFailure: %@", [emails.objects objectAtIndex:0]);
	currentEmailLabel.text = OFLOCALSTRING(@"error getting email for user");
}

- (void)onBeforeFormSubmitted
{
	[emailAttemptingToClaim release];
	UITextField* emailField = (UITextField*)[self.view findViewByTag:kEmailInputFieldTag];
	emailAttemptingToClaim = [emailField.text retain];
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
	changedEmailField.text = emailAttemptingToClaim;
	[OpenFeint reloadInactiveTabBars];
	OFShowMessageAndReturnController* controller = (OFShowMessageAndReturnController*)[[OFControllerLoaderObjC loader] load:@"ShowMessageAndReturn"];// load(@"ShowMessageAndReturn");
	controller.messageLabel.text = [NSString stringWithFormat:OFLOCALSTRING(@"Your email has been changed to\n%@."), emailAttemptingToClaim];
	controller.messageTitleLabel.text = OFLOCALSTRING(@"Change Email");
	[[self navigationController] pushViewController:controller animated:YES];
	OFSafeRelease(emailAttemptingToClaim);
}

- (NSString*)singularResourceName
{
	return @"http_basic_credential";
}

- (NSString*)getFormSubmissionUrl
{
	return @"http_basic_credentials/update_email.xml";
}

- (NSString*)getHTTPMethod
{
	return @"POST";
}

- (void)dealloc
{
	self.changedEmailField = nil;
	self.currentEmailLabel = nil;
	OFSafeRelease(emailAttemptingToClaim);
	[super dealloc];
}

@end
