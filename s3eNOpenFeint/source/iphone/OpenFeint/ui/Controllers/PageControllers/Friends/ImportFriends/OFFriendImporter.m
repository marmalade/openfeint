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

#import "OFFriendImporter.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFControllerLoaderObjC.h"
#import "OFDeadEndErrorController.h"
#import "OFUsersCredential.h"
#import "OFUsersCredentialService.h"
#import "OFAccountSetupBaseController.h"
#import "UIView+OpenFeint.h"
#import "OFTableSectionDescription.h"
#import "OFShowMessageAndReturnController.h"
#import "UIButton+OpenFeint.h"
#import "OFDependencies.h"

@interface OFFriendImporter ()
@property(nonatomic, retain) NSString* importCompleteMessage;
@property(nonatomic, retain) NSString* credentialType;
@property(nonatomic, retain) NSString* linkCredentialControllerName;

@end


@implementation OFFriendImporter
@synthesize importCompleteMessage = mImportCompleteMessage;
@synthesize credentialType = mCredentialType;
@synthesize linkCredentialControllerName = mLinkCredentialControllerName;

- (void)pushCompleteControllerWithMessage:(NSString*)message andTitle:(NSString*)controllerTitle
{
	OFShowMessageAndReturnController* completeController = (OFShowMessageAndReturnController*)[[OFControllerLoaderObjC loader] load:@"ShowMessageAndReturn"];// load(@"ShowMessageAndReturn");
	completeController.messageLabel.text = message;
	completeController.messageTitleLabel.text = OFLOCALSTRING(@"Find Friends");
	completeController.title = controllerTitle;
	[completeController.continueButton setTitleForAllStates:OFLOCALSTRING(@"OK")];
	if ([mController.navigationController.viewControllers count] > 1)
	{
		completeController.controllerToPopTo = [mController.navigationController.viewControllers objectAtIndex:[mController.navigationController.viewControllers count] - 2];
	}	
	[mController.navigationController pushViewController:completeController animated:YES];
}

- (void)importFriendsSucceeded
{
	if (!mController)
	{
		return;
	}
	
	if ([mController respondsToSelector:@selector(hideLoadingScreen)])
		[mController performSelector:@selector(hideLoadingScreen)];
	[self pushCompleteControllerWithMessage:self.importCompleteMessage andTitle:OFLOCALSTRING(@"Finding Friends")];
}

- (void)importFriendsFailed
{
	if (!mController)
	{
		return;
	}
	
	if ([mController respondsToSelector:@selector(hideLoadingScreen)])
		[mController performSelector:@selector(hideLoadingScreen)];
	[self pushCompleteControllerWithMessage:OFLOCALSTRING(@"An error occured when trying to import your friends. Please try again later.") andTitle:OFLOCALSTRING(@"Error")];
}

- (void)onUsersCredentialsDownloaded:(OFPaginatedSeries*)downloadData
{
	if (!mController)
	{
		return;
	}
	
	BOOL linked = NO;
	for (OFTableSectionDescription* section in downloadData.objects)
	{
		for (OFUsersCredential* credential in section.page.objects)
		{
			if ([credential.credentialType isEqualToString:self.credentialType])
			{
				linked = YES;
				break;
			}
		}
	}
	if (linked)
	{															  
		self.importCompleteMessage = [NSString stringWithFormat:OFLOCALSTRING(@"Allow some time for us to find your %@ friends with OpenFeint. Any matches will appear in the friends tab."),
								  [OFUsersCredential getDisplayNameForCredentialType:self.credentialType]];
		
//		OFDelegate success(self, @selector(importFriendsSucceeded));
//		OFDelegate failure(self, @selector(importFriendsFailed));
		[OFUsersCredentialService importFriendsFromCredentialType:self.credentialType 
                                              onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(importFriendsSucceeded)]
                                              onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(importFriendsFailed)]];
    }
	else
	{
		if ([mController respondsToSelector:@selector(hideLoadingScreen)])
			[mController performSelector:@selector(hideLoadingScreen)];
		OFAccountSetupBaseController* linkCredentialController = (OFAccountSetupBaseController*)[[OFControllerLoaderObjC loader] load:self.linkCredentialControllerName];// load(mLinkCredentialControllerName.get());
		if (linkCredentialController)
		{
			linkCredentialController.addingAdditionalCredential = YES;
			[mController.navigationController pushViewController:linkCredentialController animated:YES];
		}
	}
}

- (void)importFromSocialNetwork
{
	if ([mController respondsToSelector:@selector(showLoadingScreen)])
		[mController performSelector:@selector(showLoadingScreen)];

//	OFDelegate success(self, @selector(onUsersCredentialsDownloaded:));
//	OFDelegate failure(self, @selector(importFriendsFailed));
	[OFUsersCredentialService getIndexOnSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(onUsersCredentialsDownloaded:)]
                                      onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(importFriendsFailed)] 
                   onlyIncludeLinkedCredentials:YES];
}

+ (id)friendImporterWithController:(UIViewController*)controller
{
	OFFriendImporter* ret = [[self new] autorelease];
	ret->mController = controller;
	return ret;
}

- (IBAction)importFromTwitter
{
	self.credentialType = @"twitter";
	self.linkCredentialControllerName = @"TwitterAccountLogin";
	[self importFromSocialNetwork];
}

- (IBAction)importFromFacebook
{
	self.credentialType = @"fbconnect";
	self.linkCredentialControllerName = @"FacebookAccountLogin";
	[self importFromSocialNetwork];
}

- (IBAction)findByName
{
	UIViewController* controller = (UIViewController*)[[OFControllerLoaderObjC loader] load:@"FindUser"];// load(@"FindUser");
	controller.title = OFLOCALSTRING(@"Find User");
	[mController.navigationController pushViewController:controller animated:YES];
}

- (void)dealloc
{
    self.importCompleteMessage = nil;
    self.credentialType = nil;
    self.linkCredentialControllerName = nil;
	mController = nil;
	[super dealloc];
}

- (void)controllerDealloced
{
	mController = nil;
}

@end

