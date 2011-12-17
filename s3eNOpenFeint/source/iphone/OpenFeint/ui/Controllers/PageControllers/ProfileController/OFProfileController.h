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

#import "OFBannerProvider.h"
#import "OFViewController.h"

#import "OFPaginatedSeries.h"

@class OFUser;
@class OFForumPost;
@class OFForumThreadViewController;
@class OFPaginatedSeriesHeader;
@class OFDefaultButton;

@interface OFProfileController : OFViewController< OFBannerProvider>
{
@package
	OFPaginatedSeriesHeader* friendsInfo;
	OFPaginatedSeriesHeader* gamesInfo;
	
	OFForumPost *reportUserForumPost;
	OFForumThreadViewController *forumThreadView;
	
	IBOutlet UILabel* friendsSubtextLabel;
	IBOutlet UILabel* gamesSubtextLabel;
	IBOutlet UIView* actionPanelView;
	IBOutlet UIButton* imButton;
	IBOutlet OFDefaultButton* toggleFriendButton;
    
    // By default, we use [self getPageContextUser] for the user.
    // However, this can be overridden by loading this controller with a specific userId.
    OFUser *userOverride;
    NSString *userIdOverride;
    NSString *userNameOverride;
}

@property (retain) OFForumPost *reportUserForumPost;
@property (retain) OFForumThreadViewController *forumThreadView;

@property (nonatomic, readonly) OFPaginatedSeriesHeader* friendsInfo;
@property (nonatomic, readonly) OFPaginatedSeriesHeader* gamesInfo;


+ (void)showProfileForUser:(OFUser*)user;
+ (void)showProfileForUserId:(NSString*)userId;
+ (void)showProfileForPaginatedSeries:(OFPaginatedSeries*)pages;
+ (OFProfileController *)getProfileControllerForUser:(OFUser *)user andNavController:(UINavigationController *)currentNavController;

- (IBAction)onFlag;
- (IBAction)onToggleFollowing;
- (IBAction)onInstantMessage;

- (IBAction)onFriendsClicked;
- (IBAction)onGamesClicked;

@end
