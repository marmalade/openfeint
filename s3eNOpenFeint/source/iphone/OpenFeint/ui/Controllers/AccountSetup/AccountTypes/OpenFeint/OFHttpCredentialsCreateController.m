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

#import "OFHttpCredentialsCreateController.h"
#import "OFFormControllerHelper+Overridables.h"

#import "OFProvider.h"
#import "OFISerializer.h"
#import "OFProvider.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFShowMessageAndReturnController.h"
#import "OFControllerLoaderObjC.h"
#import "OFDependencies.h"

@implementation OFHttpCredentialsCreateController

- (BOOL)shouldUseOAuth
{
	return YES;
}

- (void)populateViewDataMap:(NSMutableDictionary*)dataMap
{	
    [dataMap setObject:@"email" forKey:[NSNumber numberWithInt:2]];
    [dataMap setObject:@"password" forKey:[NSNumber numberWithInt:3]];
    [dataMap setObject:@"password_confirmation" forKey:[NSNumber numberWithInt:4]];
}

- (void)addHiddenParameters:(NSObject<OFISerializer>*)parameterStream
{
	[super addHiddenParameters:parameterStream];

	[parameterStream ioNSStringToKey:@"credential_type" object:@"http_basic"];
}

- (void)registerActionsNow
{
}

- (NSString*)singularResourceName
{
	return @"credential";
}

- (NSString*)getFormSubmissionUrl
{
	return @"users_credentials.xml";
}

- (OFShowMessageAndReturnController*)controllerToPushOnCompletion
{
	OFShowMessageAndReturnController* nextController =  (OFShowMessageAndReturnController*)[[OFControllerLoaderObjC loader] load:@"ShowMessageAndReturn"];// load(@"ShowMessageAndReturn");
	nextController.messageLabel.text = OFLOCALSTRING(@"Your account is secured! You may now login from any device.");
	nextController.messageTitleLabel.text = OFLOCALSTRING(@"Secure Account");
	nextController.title = OFLOCALSTRING(@"Account Secured");
	return nextController;
}

- (void)onFormSubmitted:(id)resources
{
	[OpenFeint setLoggedInUserHasHttpBasicCredential:YES];
	[super onFormSubmitted:resources];
}

@end
