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

#import "OFPlayedGameController.h"
#import "OFPlayedGame.h"
#import "OFClientApplicationService.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFGameProfileController.h"
#import "OFControllerLoaderObjC.h"
#import "OpenFeint+UserOptions.h"
#import "OFUserGameStat.h"
#import "OFDefaultLeadingCell.h"
#import "OFUser.h"
#import "OFTabbedPageHeaderController.h"
#import "OFApplicationDescriptionController.h"
#import "OFGameDiscoveryService.h"
#import "OFGameDiscoveryNewsItem.h"
#import "OFGameDiscoveryCategory.h"
#import "OFGameDiscoveryNewsItemController.h"
#import "OFGameDiscoveryImageHyperlink.h"
#import "OFTableSectionDescription.h"
#import "OFFramedNavigationController.h"
#import "OFTableCellHelper+Overridables.h"
#import "OFImportFriendsController.h"
#import "OFGameDiscoveryImageHyperlinkCell.h"
#import "OFClientApplicationService+Private.h"
#import "OFDependencies.h"

static const double kShakeUpdateInterval = 1.0 / 10.0;
static const float  kShakeViolence = 1.0;
static const float  kEnableShakeDelay = 1.0;

@implementation OFPlayedGameController

@synthesize scope, defaultDelegate;
@dynamic targetDiscoveryPageName;

- (void)customLoader:(NSDictionary*)params
{    
	NSString* contextString = [params objectForKey:@"context"];
	if ([contextString isEqualToString:@"more_games"])
    {
		self.scope = kPlayedGameScopeTargetServiceIndex;
        self.targetDiscoveryPageName = @"developers_picks";
        self.title = OFLOCALSTRING(@"More Games");
    }
	else if ([contextString isEqualToString:@"feint_five"])
    {
		self.scope = kPlayedGameScopeTargetServiceIndex;
        self.targetDiscoveryPageName = @"feint_five";
        self.title = OFLOCALSTRING(@"Feint Five");
    }
	else if ([contextString isEqualToString:@"my_games"])
    {
        self.title = OFLOCALSTRING(@"Feint Games");
    }
	else if ([contextString isEqualToString:@"friends_games"])
    {
		self.scope = kPlayedGameScopeFriendsGames;
    }
}

- (BOOL)localUsersPage
{
	return [[self getPageContextUser] isLocalUser];
}

- (void)showEditButton
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
											   target:self
											   action:@selector(_toggleEditing)]
											  autorelease];
}

- (void)showDoneButton
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											   target:self
											   action:@selector(_toggleEditing)]
											  autorelease];
}

- (void)hideEditButton
{
	self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    for (int i = 0; i < kNumSamples; i++)
    {
        previousX[i] = 0.f;
        previousY[i] = 0.f;
        previousZ[i] = 0.f;
    }
    
	[super viewWillAppear:animated];	
	if(reloadWhenShownNext)
	{
		[self reloadDataFromServer];
	}
	if (scope == kPlayedGameScopeMyGames && !inFavoriteTab && [self localUsersPage])
	{
		[self showEditButton];
	}
	else
	{
		[self hideEditButton];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	if ([targetDiscoveryPageName isEqualToString:@"feint_five"])
	{
		//Devs can not destroy their delegates or expect accel updates at this point.  We will reset this infomation when the view disapears.
		defaultUpdateInterval = [[UIAccelerometer sharedAccelerometer] updateInterval];
		self.defaultDelegate = [[UIAccelerometer sharedAccelerometer] delegate];

		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Shuffle" style:UIBarButtonItemStylePlain target:self action:@selector(feintFiveShuffle)] autorelease];
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:kShakeUpdateInterval];
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
		enableShake = YES;
	}

	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	if ([targetDiscoveryPageName isEqualToString:@"feint_five"])
	{
        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:defaultUpdateInterval];
        [[UIAccelerometer sharedAccelerometer] setDelegate:defaultDelegate];
	}

	self.defaultDelegate = nil;

	[super viewDidDisappear:animated];
}

- (void)dealloc
{
	OFSafeRelease(headerBannerResource);
	self.targetDiscoveryPageName = nil;
	[super dealloc];
}

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"PlayedGame" forKey:[OFPlayedGame class]];
	[resourceMap setObject:@"GameDiscoveryImageHyperlink" forKey:[OFGameDiscoveryImageHyperlink class]];
	[resourceMap setObject:@"GameDiscoveryCategory" forKey:[OFGameDiscoveryCategory class]];	
	[resourceMap setObject:@"GameDiscoveryNewsItem" forKey:[OFGameDiscoveryNewsItem class]];
}

- (OFService*)getService
{
	return [OFClientApplicationService sharedInstance];
}

- (BOOL)usePlainTableSectionHeaders
{
	return YES;
}

- (void)_updateEditButtonState
{
	if ([self isEditing])
	{
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
												   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
												   target:self
												   action:@selector(_toggleEditing)]
												  autorelease];
	}
	else
	{
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
												   initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
												   target:self
												   action:@selector(_toggleEditing)]
												  autorelease];
	}
}

- (void)_toggleEditing
{
	if (![self isEditing])
	{
		[self setEditing:YES];
	}
	else
	{
		[self setEditing:NO];
	}
	
	[self _updateEditButtonState];
}

- (BOOL)allowEditing
{
	OFUser* user = [self getPageContextUser];
	return [user isLocalUser];
}

- (BOOL)shouldConfirmResourceDeletion
{
	return YES;
}

- (NSString*)getResourceDeletePromptText:(OFResource*)resource;
{
	if ([resource isKindOfClass:[OFPlayedGame class]])
	{
		OFPlayedGame* gameResource = (OFPlayedGame*)resource;
		return [NSString stringWithFormat:@"%@ will be removed from your games list but it will be added again the next time you play it.", gameResource.name]; 
	}
	else
	{
		return @"Are you sure?";
	}
}

- (NSString*)getResourceDeleteCancelText
{
	return @"Cancel";	
}

- (NSString*)getResourceDeleteConfirmText
{
	return @"OK";
}

- (void)onResourceWasDeleted:(OFResource*)cellResource
{
	[OFClientApplicationService removeGameFromLocalUsersList:cellResource.resourceId onSuccessInvocation:nil onFailureInvocation:nil];
}

- (NSString*)getNoDataFoundMessage
{
	if (scope == kPlayedGameScopeFriendsGames)
	{
		return OFLOCALSTRING(@"You have not added any OpenFeint friends yet. Find friends on the friends tab.");
	}
	else
	{
		if (inFavoriteTab)
		{
			
			OFUser* user = [self getPageContextUser];
			if ([user isLocalUser])
			{
				return OFLOCALSTRING(@"You don't have any favorite games. To favorite this game go to the game tab and press the Fan Club button.");
			}
			else
			{
				return [NSString stringWithFormat:OFLOCALSTRING(@"%@ has not added any favorite games yet."), user.name];
			}
		}
		else
		{			
			return OFLOCALSTRING(@"Failed to download games list");
		}
	}
}

- (NSString*)getTableHeaderControllerName
{
	return (scope == kPlayedGameScopeMyGames) ? @"TabbedPageHeader" : nil;
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
	OFTabbedPageHeaderController* header = (OFTabbedPageHeaderController*)tableHeader;
	header.callbackTarget = self;
	[header addTab:@"All Games" andSelectedCallback:@selector(onAllGamesSelected)];
	[header addTab:@"Favorite Games" andSelectedCallback:@selector(onFavoriteGamesSelected)];
}

- (void)onAllGamesSelected
{
	inFavoriteTab = NO;
	if ([self localUsersPage])
	{
		[self showEditButton];
	}
	[self reloadDataFromServer];
}

- (void)onFavoriteGamesSelected
{
	inFavoriteTab = YES;
	[self hideEditButton];
	[self reloadDataFromServer];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[self doIndexActionWithPage:1 onSuccessInvocation:success onFailureInvocation:failure];
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	if (scope == kPlayedGameScopeFriendsGames)
	{
		[OFClientApplicationService getPlayedGamesForLocalUsersFriends:oneBasedPageNumber onSuccessInvocation:success onFailureInvocation:failure];
	}
	else if(scope == kPlayedGameScopeTargetServiceIndex)
	{
		[OFGameDiscoveryService getDiscoveryPageNamed:targetDiscoveryPageName withPage:oneBasedPageNumber onSuccessInvocation:success onFailureInvocation:failure];
	}
	else
	{
		NSString* userId = [self getPageContextUser].resourceId;
		if (inFavoriteTab)
		{
			[OFClientApplicationService getFavoriteGamesForUser:userId withPage:oneBasedPageNumber andCountPerPage:10 
                                            onSuccessInvocation:success onFailureInvocation:failure];	
		}
		else
		{
			[OFClientApplicationService getPlayedGamesForUser:userId withPage:oneBasedPageNumber andCountPerPage:10 
                                          onSuccessInvocation:success onFailureInvocation:failure];	
		}
	}
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	UIViewController* nextController = nil;

	NSString* categoryToPush = nil;
	NSString* categoryPageDisplayTitle = nil;
	NSString* appPurchaseIdToPush = nil;

	reloadWhenShownNext = NO;

	NSString* displayContext = [NSString stringWithFormat:@"playedGameController_%@_%d", targetDiscoveryPageName, [indexPath row]];

	
	if([cellResource isKindOfClass:[OFGameDiscoveryImageHyperlink class]])
	{
		// This is slightly janky =)  may wanna fix.  @ben's bad.
		OFTableCellHelper* cell = (OFTableCellHelper*)[self.tableView cellForRowAtIndexPath:indexPath];
		if ([cell isKindOfClass:[OFGameDiscoveryImageHyperlinkCell class]])
		{
			OFGameDiscoveryImageHyperlinkCell* hyper = (OFGameDiscoveryImageHyperlinkCell*)cell;
			[hyper onCellWasClicked:self.navigationController];	
		}
	}
	else if([cellResource isKindOfClass:[OFPlayedGame class]])
	{
		OFPlayedGame* playedGameResource = (OFPlayedGame*)cellResource;

		if ([playedGameResource isOwnedByCurrentUser])
		{
			[OFGameProfileController showGameProfileWithClientApplicationId:playedGameResource.clientApplicationId compareToUser:[self getPageContextUser]];
		}		
		else if (playedGameResource.iconUrl != nil)
		{
			appPurchaseIdToPush = playedGameResource.clientApplicationId;		
		}
	}
	else if([cellResource isKindOfClass:[OFGameDiscoveryNewsItem class]])
	{
		OFGameDiscoveryNewsItemController* newsItemController = [[OFGameDiscoveryNewsItemController new] autorelease];
		newsItemController.newsItem = (OFGameDiscoveryNewsItem*)cellResource;
		nextController = newsItemController;
	}
	else if([cellResource isKindOfClass:[OFGameDiscoveryCategory class]])
	{
		OFGameDiscoveryCategory* category = (OFGameDiscoveryCategory*)cellResource;
		
		if([category.targetDiscoveryActionName isEqualToString:@"what_are_my_friends_playing_find_friends"])
		{
			OFImportFriendsController* friendsController = (OFImportFriendsController*)[[OFControllerLoaderObjC loader] load:@"ImportFriends"];// load(@"ImportFriends", nil);
			nextController = friendsController;	
			reloadWhenShownNext = YES;
		}
		else
		{
			categoryToPush = category.targetDiscoveryActionName;
			categoryPageDisplayTitle = category.targetDiscoveryPageTitle;		
		}
	}
	
	if(nextController == nil)
	{
		if(appPurchaseIdToPush != nil)
		{
			nextController = [OFApplicationDescriptionController applicationDescriptionForId:appPurchaseIdToPush appBannerPlacement:displayContext];
		}
		else if(categoryToPush != nil)
		{
			OFPlayedGameController* gameList = (OFPlayedGameController*)[[OFControllerLoaderObjC loader] load:@"PlayedGame"];// load(@"PlayedGame", nil);
			[gameList setTargetDiscoveryPageName:categoryToPush];
			gameList.navigationItem.title = categoryPageDisplayTitle;
			nextController = gameList;
		}
	}

	if (nextController)
	{
		[self.navigationController pushViewController:nextController animated:YES];
	}
	else
	{
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}

- (void)profileUsersChanged:(OFUser*)contextUser comparedToUser:(OFUser*)comparedToUser
{
	[self reloadDataFromServer];
}

- (void)onLeadingCellWasLoaded:(OFTableCellHelper*)leadingCell forSection:(OFTableSectionDescription*)section
{
	if ([leadingCell isKindOfClass:[OFDefaultLeadingCell class]])
	{
		OFDefaultLeadingCell* cell = (OFDefaultLeadingCell*)leadingCell;

		OFUser* userContext = [self getPageContextUser];
		[cell populateRightIconsAsComparison:userContext];
		if (scope == kPlayedGameScopeMyGames)
		{
            OFLOCALIZECOMMENT("Possessive case")
			cell.headerLabel.text = [self localUsersPage] ? OFLOCALSTRING(@"Feint Games") : [NSString stringWithFormat:OFLOCALSTRING(@"%@'s Games"), userContext.name];
		}
		else if (scope == kPlayedGameScopeFriendsGames)
		{
			cell.headerLabel.text = OFLOCALSTRING(@"Friends' Games");
		}
	}
}

- (NSString*)getLeadingCellControllerNameForSection:(OFTableSectionDescription*)section
{
	if(scope != kPlayedGameScopeTargetServiceIndex)
	{
		return @"DefaultLeading";
	}
	
	return nil;
}

- (void)setTargetDiscoveryPageName:(NSString*)pageName
{
    OFSafeRelease(targetDiscoveryPageName);
	targetDiscoveryPageName = [pageName copy];
	scope = kPlayedGameScopeTargetServiceIndex;
}

- (void)feintFiveShuffle
{
    for (int i = 0; i < kNumSamples; i++)
    {
        previousX[i] = 0.f;
        previousY[i] = 0.f;
        previousZ[i] = 0.f;
    }
	[self reloadDataFromServer];
}

- (BOOL)isBannerAvailableNow
{
	return headerBannerResource != nil;
}

- (NSString*)bannerCellControllerName;
{
	return @"GameDiscoveryImageHyperlink";
}

- (OFResource*)getBannerResource
{
	return headerBannerResource;
}

- (void)onBeforeResourcesProcessed:(OFPaginatedSeries*)resources
{
	OFTableSectionDescription* bannerSection = nil;
	for(id currentResource in resources.objects)
	{
		if([currentResource isKindOfClass:[OFTableSectionDescription class]])
		{
			OFTableSectionDescription* currentSection = (OFTableSectionDescription*)currentResource;
			if([currentSection.identifier isEqualToString:@"banner_frame_content"])
			{
				bannerSection = [[currentSection retain] autorelease];
				[resources.objects removeObject:currentSection];
				break;
			}		
		}
	}
	
	headerBannerResource = [[bannerSection.page.objects objectAtIndex:0] retain];	
	[(OFFramedNavigationController*)self.navigationController refreshBanner];
}

- (void)onBannerClicked
{
	[self onCellWasClicked:headerBannerResource indexPathInTable:nil];
}

- (void)hideLoadingScreen
{
	[super hideLoadingScreen];
	if ([targetDiscoveryPageName isEqualToString:@"feint_five"]  && enableShake == NO)
		[self performSelector:@selector(enableShakeAgain) withObject:nil afterDelay:kEnableShakeDelay];
}

- (void)enableShakeAgain
{
	enableShake = YES;
}

- (BOOL)checkShakeOnAxis:(CGFloat*)oldValues
{
    const CGFloat violence = kShakeViolence;
    CGFloat min = 0.f;
    CGFloat max = 0.f;
    for (int i = 0; i < kNumSamples; i++)
    {
        min = MIN(min, oldValues[i]);
        max = MAX(max, oldValues[i]);
    }
    if (min < -violence && max > violence)
    {
        return YES;
    }
    return NO;
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
    if (!enableShake) return;
    
    for (int i = 1; i < kNumSamples; i++)
    {
        previousX[i] = previousX[i - 1];
        previousY[i] = previousY[i - 1];
        previousZ[i] = previousZ[i - 1];
    }
    previousX[0] = acceleration.x;
    previousY[0] = acceleration.y;
    previousZ[0] = acceleration.z;
    
    if ([self checkShakeOnAxis:previousX] ||
        [self checkShakeOnAxis:previousY] ||
        [self checkShakeOnAxis:previousZ])
	{
		enableShake = NO;
		[self feintFiveShuffle];
	}
    
}

@end
