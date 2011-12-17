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

#import "OFAchievementListController.h"
#import "OFControllerLoaderObjC.h"
#import "OFProfileController.h"
#import "OFAchievementService.h"
#import "OFAchievement.h"
#import "OFPlayedGame.h"
#import "OFUserGameStat.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+UserOptions.h"
#import "OFDefaultLeadingCell.h"
#import "OFUser.h"
#import "OFApplicationDescriptionController.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFTableSectionDescription.h"
#import "OFGameProfilePageInfo.h"
#import "OFURLDispatcher.h"
#import "OFUserService.h"
#import "OFFramedNavigationController.h"
#import "OFDependencies.h"

@implementation OFAchievementListController

@synthesize applicationName, applicationId, applicationIconUrl, doesUserHaveApplication, achievementProgressionListLeading, comparisonUserId, comparisonUserName, comparisonUserProfileImageUrl, comparingUserForBannerCell;

- (void)customLoader:(NSDictionary*)params
{
    OFGameProfilePageInfo *gameProfileInfo = [OpenFeint localGameProfileInfo];
    self.applicationName = gameProfileInfo.name;
    self.applicationId = gameProfileInfo.resourceId;
    self.applicationIconUrl = gameProfileInfo.iconUrl;
    self.doesUserHaveApplication = gameProfileInfo.ownedByLocalPlayer;

    
    self.comparisonUserId = [params objectForKey:@"user_id"];
    self.comparisonUserName = [params objectForKey:@"user_name"];
    self.comparisonUserProfileImageUrl = [params objectForKey:@"user_picture"];

    if (comparingUserForBannerCell == nil && comparisonUserId != nil)
    {
        [OFUserService getUser:comparisonUserId 
           onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(getComparingUserSuccess:)] 
           onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(getComparingUserFailure)]];
    }
}

- (BOOL)isComparingToOtherUser
{
    if (!comparisonUserId)
    {
        self.comparisonUserId = [self getPageComparisonUser].resourceId;
    }
    
    return (comparisonUserId &&
			![comparisonUserId isEqualToString:@""] &&
			![comparisonUserId isEqualToString:[OpenFeint lastLoggedInUserId]]);
}

- (void)dealloc
{
	self.applicationName = nil;
	self.applicationId = nil;
	self.applicationIconUrl = nil;
	self.achievementProgressionListLeading = nil;
	self.comparisonUserId = nil;
	self.comparisonUserName = nil;
    self.comparisonUserProfileImageUrl = nil;
    self.comparingUserForBannerCell = nil;
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
  //can't do it here,checkout out postPushAchievementListController.  We need information about the nav controller to do this properly.
}

- (OFService*)getService
{
	return [OFAchievementService sharedInstance];
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	if(self.achievementProgressionListLeading == cell)
	{
		//Currently the only cell resource that is nil is the static cell to share achievements
		[self.navigationController pushViewController:[[OFControllerLoaderObjC loader] load:@"SelectAchievementToShare"] /*load(@"SelectAchievementToShare")*/ animated:YES];
	}
}

- (NSString*)getNoDataFoundMessage
{
	return [NSString stringWithFormat:OFLOCALSTRING(@"There are no achievements for %@"), applicationName];
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	if([self isComparingToOtherUser])
	{
		//get compared to user info
		[OFAchievementService getAchievementsForApplication:applicationId 
											 comparedToUser:comparisonUserId
													   page:oneBasedPageNumber
                                        onSuccessInvocation:success 
                                        onFailureInvocation:failure];
	}
	else if (![applicationId isEqualToString:[[OpenFeint localGameProfileInfo] resourceId]])
	{
		[OFAchievementService getAchievementsForApplication:applicationId 
											 comparedToUser:nil
													   page:oneBasedPageNumber
                                        onSuccessInvocation:success 
                                        onFailureInvocation:failure];
	}
	else
	{
		//Don't make a server call, we have the achievement information locally.
        [success invokeWith:[OFPaginatedSeries paginatedSeriesFromArray:[OFAchievement achievements]]];

        //		success.invoke([OFPaginatedSeries paginatedSeriesFromArray:[OFAchievement achievements]]);
	}

}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{	
	[self doIndexActionWithPage:1 onSuccessInvocation:success onFailureInvocation:failure];
}

- (void)_onDataLoaded:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental
{
	if([self isComparingToOtherUser])
	{
        if (!comparingUserForBannerCell)
        {
            self.comparingUserForBannerCell = [self getPageComparisonUser];
            [(OFFramedNavigationController*)self.navigationController refreshBanner];
        }
		[super _onDataLoaded:resources isIncremental:isIncremental];
	}
	else
	{
		NSArray* achievements = resources.objects;
		uint totalAchievementCount = [achievements count];
		uint unlockedAchievementCount = 0;
		for(uint i = 0; i < [achievements count]; i++)
		{
			OFAchievement* achievement = [achievements objectAtIndex:i];
			if(achievement.percentComplete == 100.0)
			{
				unlockedAchievementCount++;
			}
		}
		
		OFTableSectionDescription* mainAchievementTableSection = [OFTableSectionDescription sectionWithTitle:[NSString stringWithFormat:@"%d/%d Achievements Unlocked", unlockedAchievementCount, totalAchievementCount] andPage:resources];
		
		OFPaginatedSeries* series = nil;

		if(unlockedAchievementCount > 0 && [OpenFeint isOnline])
		{
			//Add a leading section for the "share" button if you have any unlocked achievements and you are online
			NSMutableArray* tableDescriptions = [[[NSMutableArray alloc] init] autorelease];
			OFTableSectionDescription* leadingTableSection = nil;
			
			self.achievementProgressionListLeading = (OFTableCellHelper*)[[OFControllerLoaderObjC loader] loadCell:@"AchievementProgressionListLeading"];// loadCell(@"AchievementProgressionListLeading");
			leadingTableSection = [OFTableSectionDescription sectionWithTitle:@"" andStaticCells:[NSMutableArray arrayWithObject:achievementProgressionListLeading]];
			
			[tableDescriptions addObject:leadingTableSection];
			[tableDescriptions addObject:mainAchievementTableSection];
			
			series = [OFPaginatedSeries paginatedSeriesFromArray:tableDescriptions];
		}
		else
		{
			//Just stick the achievements in there.
			series = [OFPaginatedSeries paginatedSeriesWithObject:mainAchievementTableSection];
		}
		
		[super _onDataLoaded:series isIncremental:isIncremental];
	}
}

- (BOOL)usePlainTableSectionHeaders
{
	if([self isComparingToOtherUser])
	{
		return [super usePlainTableSectionHeaders];
	}
	else
	{
		return YES;
	}
}

- (void)populateContextualDataFromPlayedGame:(OFPlayedGame*)playedGame
{
	self.applicationName = playedGame.name;
	self.applicationId = playedGame.clientApplicationId;
	self.applicationIconUrl = playedGame.iconUrl;
	for (OFUserGameStat* gameStat in playedGame.userGameStats)
	{
		if ([gameStat.userId isEqualToString:[OpenFeint lastLoggedInUserId]])
		{
			self.doesUserHaveApplication = gameStat.userHasGame;
		}
	}
}

- (void)postPushAchievementListController
{	
	if([self isComparingToOtherUser])
	{
		//We are comparing to another user, use the comparision cells
        [self.resourceControllerMap setObject:@"AchievementCompareList" forKey:[OFAchievement class]];
	}
	else
	{
		//We are not comparing.
        [self.resourceControllerMap setObject:@"AchievementProgressionList" forKey:[OFAchievement class]];
	}
}

- (BOOL)supportsComparison;
{
	return YES;
}

- (void)profileUsersChanged:(OFUser*)contextUser comparedToUser:(OFUser*)comparedToUser
{
	[self reloadDataFromServer];
}

- (void)onLeadingCellWasLoaded:(OFTableCellHelper*)leadingCell forSection:(OFTableSectionDescription*)section
{
	if([self isComparingToOtherUser])
	{
		OFDefaultLeadingCell* defaultCell = (OFDefaultLeadingCell*)leadingCell;
		[defaultCell enableLeftIconViewWithImageUrl:applicationIconUrl andDefaultImage:@"OFDefaultApplicationIcon.png"];
		defaultCell.headerLabel.text = applicationName;
        
        OFUser* otherUser = [self getPageComparisonUser];
        if (otherUser)
        {
            [defaultCell populateRightIconsAsComparison:otherUser];
        }
        else
        {
            [defaultCell populateRightIconsAsComparisonWithImageUrl:comparisonUserProfileImageUrl];
        }
        [defaultCell setCallbackTarget:self];
        [defaultCell setRightIconSelector:@selector(launchComparisonUserProfile)];
	}
}

- (NSString*)getLeadingCellControllerNameForSection:(OFTableSectionDescription*)section
{
	if([self isComparingToOtherUser])
	{
		return @"DefaultLeading";
	}
	else
	{
		return nil;
	}
}

- (NSString*)getTableHeaderControllerName
{
	return nil;
}

- (void)launchComparisonUserProfile
{
    if([self isComparingToOtherUser])
    {
        NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.comparisonUserId, @"user_id",
                                self.comparisonUserName, @"user_name",
                                nil];

        [[OFControllerLoaderObjC loader] loadAndLaunch:@"Profile" withParams:params];
    }
}

#pragma mark OFBannerProvider

- (void)getComparingUserSuccess:(OFPaginatedSeries*)pages
{
    NSObject* obj = [[pages objects] objectAtIndex:0];
    if ([obj isKindOfClass:[OFUser class]])
    {
        self.comparingUserForBannerCell = (OFUser*)obj;
        [(OFFramedNavigationController*)self.navigationController refreshBanner];
    }
}

- (void)getComparingUserFailure
{
    OFLog(@"Failed to get user.");
}

- (BOOL)isBannerAvailableNow
{
    return (comparingUserForBannerCell != nil);
}

- (NSString*)bannerCellControllerName
{
	return @"PlayerBanner";
}

- (OFResource*)getBannerResource
{
    return comparingUserForBannerCell;
}

- (void)onBannerClicked
{
	[OFProfileController showProfileForUser:comparingUserForBannerCell];
}

@end
