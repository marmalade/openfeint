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

#import "OFProfileController.h"

#import "OFProfileService.h"

#import "OFPlayedGameController.h"
#import "OFFriendsController.h"
#import "OFConversationController.h"

#import "OFControllerLoaderObjC.h"
#import "OFUser.h"
#import "OFDefaultButton.h"
#import "OFPaginatedSeries.h"
#import "OFPaginatedSeriesHeader.h"
#import "OFConversationService+Private.h"
#import "OFConversation.h"
#import "OFAbuseReporter.h"
#import "OFPatternedGradientView.h"
#import "OFForumPost.h"
#import "OFForumThreadViewController.h"
#import "OFFramedNavigationController.h"
#import "OFTableSectionDescription.h"
#import "OFFriendsService.h"
#import "OFUserService.h"

#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+UserStats.h"
#import "OpenFeint+NSNotification.h"
#import "OFParentalControls.h"
#import "OFSession.h"
#import "OFDevice.h"
#import "OFDependencies.h"

@interface OFProfileController ()
- (void)_updateFriendButtonState:(BOOL)isFriend;
- (void)_profileDownloadSucceeded:(OFPaginatedSeries*)resources;
- (OFUser*)getUser;

@property (nonatomic, retain) OFUser *userOverride;
@property (nonatomic, retain) NSString *userIdOverride;
@property (nonatomic, retain) NSString *userNameOverride;

@end

@implementation OFProfileController

@synthesize reportUserForumPost, forumThreadView, friendsInfo, gamesInfo, userOverride, userIdOverride, userNameOverride;

#pragma mark Boilerplate

- (void)dealloc
{
	OFSafeRelease(gamesInfo);
	OFSafeRelease(friendsInfo);
	
	OFSafeRelease(reportUserForumPost);
	OFSafeRelease(forumThreadView);
	
	OFSafeRelease(friendsSubtextLabel);
	OFSafeRelease(gamesSubtextLabel);
	OFSafeRelease(actionPanelView);
	OFSafeRelease(imButton);
	OFSafeRelease(toggleFriendButton);

	OFSafeRelease(userOverride);
	OFSafeRelease(userIdOverride);
	OFSafeRelease(userNameOverride);

	[super dealloc];
}

#pragma mark Creators

+ (OFProfileController *)getProfileControllerForUser:(OFUser *)user andNavController:(UINavigationController *)currentNavController
{
	OFProfileController* newProfile = nil;

	BOOL shouldOpenProfile = YES;
		
	if ([currentNavController.visibleViewController isKindOfClass:[OFProfileController class]])
	{
		OFProfileController* currentProfile = (OFProfileController*)currentNavController.visibleViewController;
		OFUser* profileUser = [currentProfile getPageContextUser];
		if ([user.resourceId isEqualToString:profileUser.resourceId])
			shouldOpenProfile = NO;
	}
	
	if (shouldOpenProfile)
	{
		OFAssert([currentNavController isKindOfClass:[OFFramedNavigationController class]], @"Must have a framed navigation controller for a profile!");
		newProfile = (OFProfileController*)[[OFControllerLoaderObjC loader] load:@"Profile"];// load(@"Profile");
	}
	
	newProfile.title = user.name;
	
	return newProfile;
}

+ (void)showProfileForUser:(OFUser*)user
{
	UINavigationController* currentNavController = [OpenFeint getActiveNavigationController];
	if (currentNavController)
	{
		OFProfileController* newProfile = [OFProfileController getProfileControllerForUser:user andNavController:currentNavController];
		if (newProfile)
			[(OFFramedNavigationController*)currentNavController pushViewController:newProfile animated:YES inContextOfUser:user];
	}
}

+ (void)showProfileForUserId:(NSString*)userId
{
//    OFDelegate success = OFDelegate(self, @selector(showProfileForPaginatedSeries:));
//    OFDelegate failure = OFDelegate(self, @selector(failedToLoadUser));
    [OFUserService getUser:userId 
       onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(showProfileForPaginatedSeries:)] 
       onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(failedToLoadUser)]];
}

+ (void)showProfileForPaginatedSeries:(OFPaginatedSeries*)pages
{
    OFUser *user = [[pages objects] objectAtIndex:0];
    [self showProfileForUser:user];
}

+ (void)failedToLoadUser
{
    [[[[UIAlertView alloc] initWithTitle:@"Failed to Load User"
                                 message:@"We encountered an error finding that user.  Please try again later."
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil] autorelease] show];
}

#pragma mark UIViewController

- (void)refreshTitle
{
    if (userIdOverride && !userOverride)
    {
        // We are loading in a user, but don't have their info yet.
        OFLOCALIZECOMMENT("Assumes possessive case.")
        self.title = [NSString stringWithFormat:OFLOCALSTRING(@"%@'s Profile"), userNameOverride];
    }
    else
    {
        OFUser* user = [self getUser];
        if (user)
        {
            OFLOCALIZECOMMENT("Assumes possessive case.")
            self.title = [NSString stringWithFormat:OFLOCALSTRING(@"%@'s Profile"), user.name];
        }
        else
        {
            self.title = OFLOCALSTRING(@"Profile");
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refreshTitle];
}



- (void)_getUserSuccess:(OFPaginatedSeries*)userData
{
    if ([userData count] > 0)
	{
		self.userOverride = [userData.objects objectAtIndex:0];
        [(OFFramedNavigationController*)self.navigationController changeUserContext:userOverride];
        [self refreshTitle];
        //now we have a user, then we can download as normal
        

        [OFProfileService getProfileForUser:[self getUser].resourceId
                        onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_profileDownloadSucceeded:)]
                        onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(hideLoadingScreen)]];
	}
	else
	{
		[self hideLoadingScreen];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	if (!friendsInfo && !gamesInfo)
	{
		[self showLoadingScreen];
        if (userIdOverride)
        {
            //load the OFUser first
            [OFUserService getUser:userIdOverride
               onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getUserSuccess:)]
               onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(hideLoadingScreen)]];
        }
        else
        {
            [OFProfileService getProfileForUser:[self getUser].resourceId
                        onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_profileDownloadSucceeded:)]
                        onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(hideLoadingScreen)]];
        }
	}
}

#pragma mark Internal Methods

- (OFUser*)getUser
{
    if (userIdOverride)
    {
        return userOverride;
    }
    else
    {
        return [self getPageContextUser];
    }
}

- (void)customLoader:(NSDictionary*)params
{
    self.userIdOverride = [params objectForKey:@"user_id"];
    self.userNameOverride = [params objectForKey:@"user_name"];
}

- (void)_updateFriendButtonState:(BOOL)isFriend
{
	if (isFriend)
	{
		[OFRedBorderedButton setupButton:toggleFriendButton];
		[toggleFriendButton setTitleForAllStates:OFLOCALSTRING(@"Remove Friend")];
	}
	else
	{
		[OFGreenBorderedButton setupButton:toggleFriendButton];
		[toggleFriendButton setTitleForAllStates:OFLOCALSTRING(@"Add Friend")];
	}
}

- (void)_profileDownloadSucceeded:(OFPaginatedSeries*)resources
{
	[self hideLoadingScreen];

	OFSafeRelease(friendsInfo);
	OFSafeRelease(gamesInfo);
	
	for (OFTableSectionDescription* section in resources)
	{
		if ([section.identifier isEqualToString:@"friends"])
		{
			friendsInfo = [section.page.header retain];
		}
		else if ([section.identifier isEqualToString:@"games"])
		{
			gamesInfo = [section.page.header retain];
		}
	}
	
    OFUser* user = [self getUser];
	actionPanelView.hidden = [user isLocalUser];
	[self _updateFriendButtonState:user.followedByLocalUser];
	
	imButton.hidden = ![OpenFeint allowUserGeneratedContent];
	
	if (friendsInfo.totalObjects > 0)
	{
        OFLOCALIZECOMMENT("Needs to be rewritten")
		friendsSubtextLabel.text = [NSString stringWithFormat:@"%@ %@ %d %@", [user isLocalUser] ? @"You" : user.name, [user isLocalUser] ? @"have" : @"has", friendsInfo.totalObjects, friendsInfo.totalObjects > 1 ? @"friends" : @"friend"];
	}
	else
	{
        OFLOCALIZECOMMENT("Needs to be rewritten")
		friendsSubtextLabel.text = [NSString stringWithFormat:@"%@ %@ not added any friends", [user isLocalUser] ? @"You" : user.name, [user isLocalUser] ? @"have" : @"has" ];
	}

	if (gamesInfo.totalObjects > 0)
	{
        OFLOCALIZECOMMENT("Needs to be rewritten")
		gamesSubtextLabel.text = [NSString stringWithFormat:@"%@ %@ played %d %@", [user isLocalUser] ? @"You" : user.name, [user isLocalUser] ? @"have" : @"has", gamesInfo.totalObjects, gamesInfo.totalObjects > 1 ? @"games" : @"game"];
	}
	else
	{
        OFLOCALIZECOMMENT("Needs to be rewritten")
		gamesSubtextLabel.text = [NSString stringWithFormat:@"%@ %@ not played any games", [user isLocalUser] ? @"You" : user.name, [user isLocalUser] ? @"have" : @"has"];
	}
}

#pragma mark OFBannerFrame

- (BOOL)isBannerAvailableNow
{
	return ([self getUser] != nil);
}

- (NSString*)bannerCellControllerName
{
	return @"PlayerBanner";
}

- (OFResource*)getBannerResource
{
    // Will be nil while we load, so the banner does not appear.
    return [self getUser];
}

- (void)onBannerClicked
{
	// generally, ignore clicks
}

- (void)bannerProfilePictureTouched
{
	// except for this!
	if ([[self getUser] isLocalUser])
	{
        if (![OpenFeint session].currentDevice.parentalControls.enabled) {
            [self.navigationController pushViewController:[[OFControllerLoaderObjC loader] load:@"SelectProfilePicture"] /*load(@"SelectProfilePicture")*/ animated:YES];
        }
	}
}

#pragma mark Other Actions

- (IBAction)onFriendsClicked
{
	if (friendsInfo.totalObjects > 0)
	{
		OFFriendsController* friendsController = (OFFriendsController*)[[OFControllerLoaderObjC loader] load:@"Friends"];// load(@"Friends");
		[self.navigationController pushViewController:friendsController animated:YES];
	}
}

- (IBAction)onGamesClicked
{
	if (gamesInfo.totalObjects > 0)
	{
		OFPlayedGameController* playedGameController = (OFPlayedGameController*)[[OFControllerLoaderObjC loader] load:@"PlayedGame"];// load(@"PlayedGame");
		playedGameController.navigationItem.title = OFLOCALSTRING(@"Games Played");
		[self.navigationController pushViewController:playedGameController animated:YES];
	}
}

- (IBAction)onFlag
{
	OFUser* user = [self getUser];
	if (user && ![user isLocalUser])
	{
		if (reportUserForumPost && forumThreadView) 
		{
			[OFAbuseReporter reportAbuseByUser:user.resourceId forumPost:reportUserForumPost.resourceId fromController:forumThreadView];
		}
		else 
		{
			[OFAbuseReporter reportAbuseByUser:user.resourceId fromController:[OpenFeint getRootController]];
		}
	}
}

#pragma mark Friend Handling

- (IBAction)onToggleFollowing
{
	OFUser* user = [self getUser];
	if (!user || (user && [user isLocalUser]))
	{
		return;
	}
	
	[self showLoadingScreen];
//	OFDelegate success(self, @selector(onFollowChangedState));
//	OFDelegate failure(self, @selector(onFollowFailedChangingState));
    OFInvocation* success = [OFInvocation invocationForTarget:self selector:@selector(onFollowChangedState)];
    OFInvocation* failure = [OFInvocation invocationForTarget:self selector:@selector(onFollowFailedChangingState)];
    
	if (user.followedByLocalUser)
	{
		[OFFriendsService makeLocalUserStopFollowing:user.resourceId onSuccessInvocation:success onFailureInvocation:failure];
	}
	else
	{
		[OFFriendsService makeLocalUserFollow:user.resourceId onSuccessInvocation:success onFailureInvocation:failure];
	}
}

- (void)onFollowChangedState 
{
	[self hideLoadingScreen];
	OFUser* user = [self getUser];
	[user setFollowedByLocalUser:!user.followedByLocalUser];

	[self _updateFriendButtonState:user.followedByLocalUser];
	
	if (user.followedByLocalUser)
	{
		[OpenFeint postAddFriend:user];

		// if he follows me, then he moves from pending to friend
		if (user.followsLocalUser)
		{
			if([OpenFeint pendingFriendsCount] - 1 >= 0)
			{
				[OpenFeint setPendingFriendsCount:[OpenFeint pendingFriendsCount] - 1];
			}
		}
	}
	else
	{
		[OpenFeint postRemoveFriend:user];

		// if he follows me, then he moves from friend to pending
		if (user.followsLocalUser)
		{
			[OpenFeint setPendingFriendsCount:[OpenFeint pendingFriendsCount] + 1];
		}
	}	
}

- (void)onFollowFailedChangingState
{
	[self hideLoadingScreen];
}

#pragma mark Conversation / IM Handlers

- (IBAction)onInstantMessage
{
	[self showLoadingScreen];
	OFLog(@"get page context: %@", [self getUser]);
	
	[OFConversationService
		startConversationWithUser:[self getUser].resourceId
     onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_conversationStarted:)]
     onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_conversationError)]];
//		onSuccess:OFDelegate(self, @selector(_conversationStarted:))
//		onFailure:OFDelegate(self, @selector(_conversationError))];
}

- (void)_conversationStarted:(OFPaginatedSeries*)conversationPage
{
	[self hideLoadingScreen];

	if ([conversationPage count] == 1)
	{
		OFConversation* conversation = [conversationPage objectAtIndex:0];
		OFConversationController* controller = [OFConversationController conversationWithId:conversation.resourceId withUser:conversation.otherUser];
		[self.navigationController pushViewController:controller animated:YES];
	}
}

- (void)_conversationError
{
	[self hideLoadingScreen];
	
	[[[[UIAlertView alloc] 
		initWithTitle:OFLOCALSTRING(@"Error") 
		message:OFLOCALSTRING(@"An error occurred. Please try again later.") 
		delegate:nil 
		cancelButtonTitle:OFLOCALSTRING(@"Ok") 
		otherButtonTitles:nil] autorelease] show];
}

@end
