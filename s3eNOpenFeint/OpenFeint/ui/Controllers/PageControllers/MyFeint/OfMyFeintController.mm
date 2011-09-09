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

#import "OFMyFeintController.h"
#import "OFControllerLoader.h"
#import "OFUser.h"
#import "OFProfileController.h"
#import "OFBadgeView.h"

#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+NSNotification.h"
#import "OFProfileService.h"

@implementation OFMyFeintController

- (void)_pendingFriendsChanged:(NSNotification*)notification
{
	NSNumber* count = [notification.userInfo objectForKey:OFNSNotificationInfoPendingFriendCount];
	friendsBadge.value = [count intValue];
	
	[self setBadgeValue:[NSString stringWithFormat:@"%d", friendsBadge.value + inboxBadge.value]];
}

- (void)_inboxCountChanged:(NSNotification*)notification
{
	NSNumber* count = [notification.userInfo objectForKey:OFNSNotificationInfoUnreadInboxCount];
	inboxBadge.value = [count intValue];
	
	[self setBadgeValue:[NSString stringWithFormat:@"%d", friendsBadge.value + inboxBadge.value]];
}

- (void)awakeFromNib
{
	[super awakeFromNib];

	friendsBadge.value = [OpenFeint pendingFriendsCount];
	inboxBadge.value = [OpenFeint unreadInboxTotal];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_pendingFriendsChanged:) name:OFNSNotificationPendingFriendCountChanged object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_inboxCountChanged:) name:OFNSNotificationUnreadInboxCountChanged object:nil];	
	
	if ([self getPageContextUser] == nil || [[self getPageContextUser].resourceId isEqualToString:[OpenFeint localUser].resourceId])
	{
		[OFProfileService viewedOwnProfilePage];
	}
	
	originalSettingsFrame = settingsContainer.frame;
	originalHelpFrame = helpContainer.frame;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OFNSNotificationPendingFriendCountChanged object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OFNSNotificationUnreadInboxCountChanged object:nil];

	OFSafeRelease(friendsPlayingThisGame);
	OFSafeRelease(friendsBadge);
	OFSafeRelease(inboxBadge);

	OFSafeRelease(inboxContainer);
	OFSafeRelease(settingsContainer);
	OFSafeRelease(helpContainer);

	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
		
	if (![OpenFeint allowUserGeneratedContent])
	{
		CGRect frame = CGRectZero;

		inboxContainer.hidden = YES;
		
		frame = settingsContainer.frame;
		frame.origin.y = CGRectGetMinY(inboxContainer.frame);
		settingsContainer.frame = frame;

		frame = helpContainer.frame;
		if ([OpenFeint isInLandscapeMode] || [OpenFeint isLargeScreen])
			frame.origin.y = CGRectGetMinY(inboxContainer.frame);
		else
			frame.origin.y = CGRectGetMaxY(settingsContainer.frame);
		helpContainer.frame = frame;
	}
	else if(inboxContainer.hidden)
	{
		inboxContainer.hidden = NO;
		
		settingsContainer.frame = originalSettingsFrame;
		helpContainer.frame = originalHelpFrame;
	}
}

- (IBAction)onMyFriends
{
	[self.navigationController pushViewController:OFControllerLoader::load(@"Friends") animated:YES];
}

- (IBAction)onMyGames
{
	UIViewController* playedGameController = OFControllerLoader::load(@"PlayedGame");
	playedGameController.navigationItem.title = OFLOCALSTRING(@"Feint Games");
	[self.navigationController pushViewController:playedGameController animated:YES];
}

- (IBAction)onMessageCenter
{
	[self.navigationController pushViewController:OFControllerLoader::load(@"InboxTopLevel") animated:YES];
}

- (IBAction)onSettings
{
	[self.navigationController pushViewController:OFControllerLoader::load(@"UserSetting") animated:YES];
}

- (IBAction)onHelp
{
	[self.navigationController pushViewController:OFControllerLoader::load(@"Help") animated:YES];
}

#pragma mark OFBannerFrame

- (bool)isBannerAvailableNow
{
	return true;
}

- (NSString*)bannerCellControllerName
{
	return @"PlayerBanner";
}

- (OFResource*)getBannerResource
{
	return [OpenFeint localUser];
}

- (void)onBannerClicked
{
	// ehhhhhh @HACK we should really get the user out of the banner.
	[OFProfileController showProfileForUser:[OpenFeint localUser]];
}

@end
