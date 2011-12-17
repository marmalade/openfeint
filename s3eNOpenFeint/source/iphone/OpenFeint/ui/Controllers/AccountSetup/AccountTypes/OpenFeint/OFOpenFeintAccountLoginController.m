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

#import "OFOpenFeintAccountLoginController.h"
#import "OFProvider.h"
#import "OFISerializer.h"
#import "OFProvider.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFShowMessageAndReturnController.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFSelectAccountTypeController.h"
#import "OFControllerLoaderObjC.h"
#import "UIView+OpenFeint.h"
#import "OFFBConnect.h"
#import "OFIntroNavigationController.h"

@implementation OFOpenFeintAccountLoginController

@synthesize contentView;
@synthesize scrollView;
@synthesize introFlowSpacer;

- (IBAction)usedOtherAccountType
{
	OFSelectAccountTypeController* accountController = (OFSelectAccountTypeController*)[[OFControllerLoaderObjC loader] load:@"SelectAccountType"];// load(@"SelectAccountType");
    accountController.onCancelInvocation = self.onCancelInvocation;
    accountController.onCompletionInvocation = self.onCompletionInvocation;
//	[accountController setCancelDelegate:mCancelDelegate];
//	[accountController setCompletionDelegate:mCompletionDelegate];
	[[self navigationController] pushViewController:accountController animated:YES];
}

- (IBAction)createNewAccount
{
	[self showLoadingScreen];
	[OpenFeint doBootstrapAsNewUserOnSuccess:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapSucceeded)] 
                                   onFailure:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapFailed)]];
	
	self.navigationItem.hidesBackButton = YES;
}

- (void)_bootstrapSucceeded
{
	[self hideLoadingScreen];

	[[OFFBSession session] logout];
	
	OFNewAccountController* newAccountController = (OFNewAccountController*)[[OFControllerLoaderObjC loader] load:@"NewAccount"];// load(@"NewAccount");        
//	OFDelegate completeDelegate = mCompletionDelegate;
//	if (!mCompletionDelegate.isValid())
//	{
//		completeDelegate = OFDelegate(self, @selector(popOutOfAccountFlow));
//	}
    OFInvocation* invocation = self.onCompletionInvocation;
    if(!invocation)
        invocation = [OFInvocation invocationForTarget:self selector:@selector(popOutOfAccountFlow)];

    newAccountController.onCompletionInvocation = invocation;
    newAccountController.onCancelInvocation = self.onCancelInvocation;
    
//	[newAccountController setCompleteDelegate:completeDelegate];
//	[newAccountController setCancelDelegate:mCancelDelegate];
    newAccountController.allowNavigatingBack = YES;
    newAccountController.hideNavigationBar = NO;
	[[self navigationController] pushViewController:newAccountController animated:YES];
    
    if ([OpenFeint isShowingFullScreen])
    {
        [newAccountController hideIntroFlowViews];
    }    
}

- (void)_bootstrapFailed
{
	[self hideLoadingScreen];
	[[[[UIAlertView alloc] 
		initWithTitle:@"Error"
		message:@"There was an error creating a new account. Please verify you are online and try again."
		delegate:nil
		cancelButtonTitle:@"Ok"
		otherButtonTitles:nil] autorelease] show];
		
	self.navigationItem.hidesBackButton = NO;
}

- (void)cancelSetup
{
	[self hideLoadingScreen];
	[super cancelSetup];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OFNSNotificationFullscreenFrameOn" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OFNSNotificationFullscreenFrameOff" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)shouldUseOAuth
{
	return NO;
}

- (void)populateViewDataMap:(NSMutableDictionary*)dataMap
{
    [dataMap setObject:@"email" forKey:[NSNumber numberWithInt:1]];
    [dataMap setObject:@"password" forKey:[NSNumber numberWithInt:2]];
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
	return @"session.xml";
}

- (OFShowMessageAndReturnController*)controllerToPushOnCompletion
{
	return [self getStandardLoggedInController];
}

- (void)dealloc
{
	self.contentView = nil;
	self.scrollView = nil;
    self.introFlowSpacer = nil;
	[super dealloc]; 
}

-(void) setHideIntroFlowSpacer: (BOOL) hidden
{
    [introFlowSpacer setHidden:hidden];
}


@end
