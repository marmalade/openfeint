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

#import "OFAccountSetupBaseController.h"
#import "OFShowMessageAndReturnController.h"
#import "OFFormControllerHelper+Submit.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFProvider.h"
#import "OFISerializer.h"
#import "OFControllerLoaderObjC.h"
#import "OFNavigationController.h"
#import "OFDependencies.h"

@implementation OFAccountSetupBaseController

@synthesize privacyDisclosure;
@synthesize addingAdditionalCredential = mAddingAdditionalCredential;
@synthesize onCancelInvocation;
@synthesize onCompletionInvocation;

+ (OFShowMessageAndReturnController*)getStandardLoggedInController
{
	OFShowMessageAndReturnController* nextController =  (OFShowMessageAndReturnController*)[[OFControllerLoaderObjC loader] load:@"ShowMessageAndReturn"];// load(@"ShowMessageAndReturn");
    OFLOCALIZECOMMENT("Built string, possibly trouble")
	nextController.messageLabel.text = [NSString stringWithFormat:OFLOCALSTRING(@"You are now logged into OpenFeint as:\n %@"), [OpenFeint lastLoggedInUserName]];;
	nextController.messageTitleLabel.text = OFLOCALSTRING(@"Switch Accounts");
    nextController.navigationItem.hidesBackButton = YES;
	return nextController;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
//	[OFNavigationController addCloseButtonToViewController:self target:self action:@selector(cancelSetup)];
}

- (BOOL)isInModalController
{
	return self.navigationController.parentViewController && self.navigationController.parentViewController.modalViewController != nil;
}

- (void)cancelSetup
{
//	if (mCancelDelegate.isValid())
//	{
//		mCancelDelegate.invoke();
//	}
    if(self.onCancelInvocation) {
        [self.onCancelInvocation invoke];

    }
    else if ([self isInModalController])
	{
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (void)addHiddenParameters:(NSObject<OFISerializer>*)parameterStream
{
    [parameterStream ioNSStringToKey:@"udid" object:[OpenFeint uniqueDeviceId]];
}

- (OFShowMessageAndReturnController*)getStandardLoggedInController
{
	return [OFAccountSetupBaseController getStandardLoggedInController];
}

- (OFShowMessageAndReturnController*)controllerToPushOnCompletion
{
	return nil;
}

- (UIViewController*)getControllerToPopTo
{
	// When logging in we always pop all the way back to the root. This is to make sure you don't pop back into a chat room you're no longer part of
	if (self.addingAdditionalCredential)
	{
		for (int i = [self.navigationController.viewControllers count] - 1; i >= 1; i--)
		{
			UIViewController* curController = [self.navigationController.viewControllers objectAtIndex:i];
			if (![curController isKindOfClass:[OFAccountSetupBaseController class]])
			{
				return curController;
			}
		}
	}
	return nil;
}

- (void)popOutOfAccountFlow
{
	if ([self isInModalController])
	{
		[self dismissModalViewControllerAnimated:YES];
	}
	else
	{
		UIViewController* controllerToPopTo = [self getControllerToPopTo];
		if (controllerToPopTo)
		{
			[self.navigationController popToViewController:controllerToPopTo animated:YES];
		}
		else
		{
			[self.navigationController popToRootViewControllerAnimated:YES];
		}
	}
}

- (void)pushCompletionControllerOrPopOut
{
    if(self.onCompletionInvocation)
    //	if (mCompletionDelegate.isValid())
	{
        [self.onCompletionInvocation invoke];
        //		mCompletionDelegate.invoke();
	}
	else
	{
		OFShowMessageAndReturnController* controllerToPush = [self controllerToPushOnCompletion];
		if (controllerToPush)
		{
			controllerToPush.navigationItem.hidesBackButton = YES;
			controllerToPush.controllerToPopTo = [self getControllerToPopTo];
			[self.navigationController pushViewController:controllerToPush animated:YES];
		}
		else
		{
			[self popOutOfAccountFlow];
		
		}
	}
}

- (BOOL)isComplete
{
	return YES;
}

// [adill] i said i was going to hell for this
- (NSString*)overrideUserIdToBootstrapWith
{
	// [adill] ...and i wasn't kidding
	return nil;
}

- (void)onFormSubmitted:(id)resources
{
	if (self.addingAdditionalCredential)
	{
		[OpenFeint setLoggedInUserHasNonDeviceCredential:YES];
		if([self isComplete])
		{
			[self pushCompletionControllerOrPopOut];
		}
	}
	else
	{
		NSString* oldUserId = [self overrideUserIdToBootstrapWith];
		[self showLoadingScreen];
		[[OpenFeint provider] destroyLocalCredentials];
		[OpenFeint doBootstrapAsUserId:oldUserId 
                             onSuccess:[OFInvocation invocationForTarget:self selector:@selector(onBootstrapDone)] 
                             onFailure:[OFInvocation invocationForTarget:self selector:@selector(onBootstrapDone)]];
	}	
}

- (void)onBootstrapDone
{
	[self hideLoadingScreen];
	[OpenFeint reloadInactiveTabBars];
	[self pushCompletionControllerOrPopOut];
}

- (void)dealloc
{
    self.onCancelInvocation = nil;
    self.onCompletionInvocation = nil;
	self.privacyDisclosure = nil;
	[super dealloc];
}

//- (void)setCancelDelegate:(OFDelegate const&)delegate
//{
//	mCancelDelegate = delegate;
//}
//
//- (void)setCompletionDelegate:(OFDelegate const&)delegate
//{
//	mCompletionDelegate = delegate;
//}

@end
