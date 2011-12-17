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

#import "OFWhosPlayingController.h"

#import "OFControllerLoaderObjC.h"
#import "OFFriendsService.h"
#import "OFGamePlayer.h"
#import "OFUser.h"
#import "OFProfileController.h"
#import "OFTableSectionDescription.h"
#import "OpenFeint+Settings.h"
#import "OFFullScreenImportFriendsMessage.h"
#import "OFUsersCredential.h"
#import "UIView+OpenFeint.h"
#import "OpenFeint+NSNotification.h"
#import "OFDependencies.h"

@implementation OFWhosPlayingController

@synthesize userId, applicationName, applicationId, applicationIconUrl;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(friendPresenceDidChange:) name:OFNSNotificationFriendPresenceChanged object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OFNSNotificationFriendPresenceChanged object:nil];
}

- (void)dealloc
{
	self.applicationName = nil;
	self.applicationId = nil;
	self.applicationIconUrl = nil;
	self.userId = nil;

	[super dealloc];
}

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"WhosPlaying" forKey:[OFGamePlayer class]];
}

- (OFService*)getService
{
	return [OFFriendsService sharedInstance];
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	OFGamePlayer* resource = (OFGamePlayer*)cellResource;
	[OFProfileController showProfileForUser:resource.user];
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"None of your friends have played this game.  Why don't you tell them about it?");
}

- (UIViewController*)getNoDataFoundViewController
{
	NSMutableArray* missingCredentialTypes = [self getMetaDataOfType:[OFUsersCredential class]];	
	BOOL mayImportFriends = [missingCredentialTypes count] > 0;
	if (mayImportFriends)
	{	
		NSString* notice = [self getNoDataFoundMessage];
		OFFullScreenImportFriendsMessage* noDataController = (OFFullScreenImportFriendsMessage*)[[OFControllerLoaderObjC loader] load:@"FullscreenImportFriendsMessage"];// load(@"FullscreenImportFriendsMessage");	
		[noDataController setMissingCredentials:missingCredentialTypes withNotice:notice];
		noDataController.owner = self;
		return noDataController;
	}
	return nil;
}

- (void)doIndexActionWithPage:(NSUInteger)pageIndex onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFFriendsService getUsersWithAppFollowedByUser:applicationId followedByUser:userId pageIndex:pageIndex onSuccessInvocation:success onFailureInvocation:failure];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
{
	[OFFriendsService getUsersWithAppFollowedByUser:applicationId followedByUser:userId pageIndex:1 onSuccessInvocation:success onFailureInvocation:failure];
}

- (BOOL)usePlainTableSectionHeaders
{
	return YES;
}

- (UIView*)createPlainTableSectionHeader:(NSUInteger)sectionIndex
{
	if (sectionIndex < [mSections count])
	{
		OFTableSectionDescription* tableDescription = (OFTableSectionDescription*)[mSections objectAtIndex:sectionIndex];
		UIView* headerView = [[OFControllerLoaderObjC loader] loadView:@"WhosPlayingSectionHeaderView"];// loadView(@"WhosPlayingSectionHeaderView");
		UILabel* label = (UILabel*)[headerView findViewByTag:1];
		label.text = tableDescription.title;
		return headerView;
	}
	else
	{
		return nil;
	}
}

- (void)friendPresenceDidChange:(id)userInfo {
	[self reloadDataFromServer];
}

@end
