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

#import "OFUseNewOrOldAccountController.h"

#import "OFControllerLoaderObjC.h"
#import "OFOpenFeintAccountLoginController.h"
#import "OFUserService.h"
#import "OFUser.h"
#import "OFProvider.h"
#import "OFImageLoader.h"
#import "OFFramedContentWrapperView.h"
#import "OFShowMessageAndReturnController.h"

#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

@interface OFUseNewOrOldAccountController (Internal)
- (void)_bootstrapSuccess;
- (void)_bootstrapFailure;
- (void)_popBackToRoot;
@end

@implementation OFUseNewOrOldAccountController

#pragma mark Boilerplate

- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = OFLOCALSTRING(@"Choose Account");
	}
	return self;
}

- (void)dealloc
{
	OFSafeRelease(footerButton);
	[super dealloc];
}

#pragma mark OFTableSequenceControllerHelper

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"User" forKey:[OFUser class]];
}

- (OFService*)getService
{
	return [OFUserService sharedInstance];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFUserService findUsersForLocalDeviceOnSuccessInvocation:success onFailureInvocation:failure];
}

- (BOOL)usePlainTableSectionHeaders
{
	return NO;
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFUser class]])
	{
		OFUser* user = (OFUser*)cellResource;

		[self showLoadingScreen];
		[[OpenFeint provider] destroyLocalCredentials];
		[OpenFeint 
			doBootstrapAsUserId:user.resourceId 
			onSuccess:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapSuccess)] 
			onFailure:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapSuccess)]];
	}
}

#pragma mark UseNewOrOldAccountController Logic

- (void)_createAndDisplayTableHeader
{
	float width = self.view.frame.size.width;
	if ([self.view isKindOfClass:[OFFramedContentWrapperView class]])
	{
		OFFramedContentWrapperView* wrapperView = (OFFramedContentWrapperView*)self.view;
		width = wrapperView.wrappedView.frame.size.width;
	}

	CGRect frame;
	
	UIView* header = [[OFControllerLoaderObjC loader] loadView:@"UseNewOrOldAccountHeader" owner:self];// loadView(@"UseNewOrOldAccountHeader", self);
	frame = header.frame;
	frame.size.width = width;
	header.frame = frame;
	
	self.tableView.tableHeaderView = header;

	UIView* footer = [[OFControllerLoaderObjC loader] loadView:@"UseNewOrOldAccountFooter" owner:self];// loadView(@"UseNewOrOldAccountFooter", self);	
	frame = footer.frame;
	frame.size.width = width;
	footer.frame = frame;

	[footerButton setBackgroundImage:[footerButton.currentBackgroundImage stretchableImageWithLeftCapWidth:7 topCapHeight:7] forState:UIControlStateNormal];
	self.tableView.tableFooterView = footer;
}

- (void)_bootstrapSuccess
{
	[self hideLoadingScreen];
	[OpenFeint reloadInactiveTabBars];

	OFShowMessageAndReturnController* controllerToPush = [OFAccountSetupBaseController getStandardLoggedInController];
	controllerToPush.controllerToPopTo = [self.navigationController.viewControllers objectAtIndex:0];
	[self.navigationController pushViewController:controllerToPush animated:YES];
}

- (void)_popBackToRoot
{
	[OpenFeint reloadInactiveTabBars];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)clickedUseOld
{
	OFAccountSetupBaseController* login = (OFAccountSetupBaseController*)[[OFControllerLoaderObjC loader] load:@"OpenFeintAccountLogin"];// load(@"OpenFeintAccountLogin");
    [(OFOpenFeintAccountLoginController*) login setHideIntroFlowSpacer:YES];

    login.onCancelInvocation = [OFInvocation invocationForTarget:self selector:@selector(_popBackToRoot)];
    login.onCompletionInvocation = [OFInvocation invocationForTarget:self selector:@selector(_bootstrapSuccess)];
    
	// Fogbugz 1086
//	OFDelegate popToStandardLoggedIn(self, @selector(_bootstrapSuccess));
//	[login setCompletionDelegate:popToStandardLoggedIn];
//
//	OFDelegate popToRootDelegate(self, @selector(_popBackToRoot));
//	[login setCancelDelegate:popToRootDelegate];

	[self.navigationController pushViewController:login animated:YES];
}

@end
