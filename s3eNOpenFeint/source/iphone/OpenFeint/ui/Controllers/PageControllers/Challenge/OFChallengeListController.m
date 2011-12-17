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

#import "OFChallengeListController.h"
#import "OFControllerLoaderObjC.h"
#import "OFProfileController.h"
#import "OFChallengeService+Private.h"
#import "OFChallengeDefinitionService.h"
#import "OFChallenge.h"
#import "OFChallengeToUser.h"
#import "OFChallengeDefinitionStats.h"
#import "OFChallengeDefinition.h"
#import "OFChallengeDetailController.h"
#import "OFPlayedGame.h"
#import "OFUserGameStat.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+UserOptions.h"
#import "OFUser.h"
#import "OFApplicationDescriptionController.h"
#import "OFGameProfileController.h"
#import "OFTabbedPageHeaderController.h"
#import "OFTableSectionDescription.h"
#import "OFFramedNavigationController.h"
#import "UIView+OpenFeint.h"
#import "OFTableSequenceControllerHelper+ViewDelegate.h"
#import "OFDependencies.h"

static NSString* kPendingTabName = OFLOCALSTRING(@"Pending");
static NSString* kHistoryTabName = OFLOCALSTRING(@"History");

@implementation OFChallengeListController

@synthesize clientApplicationId, listType, challengeDefinitionStats;

- (void)dealloc
{
	self.clientApplicationId = nil;
	self.challengeDefinitionStats = nil;
	[super dealloc];
}

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"ChallengeToUser" forKey:[OFChallengeToUser class]];
	[resourceMap setObject:@"ChallengeSent" forKey:[OFChallenge class]];
	[resourceMap setObject:@"ChallengeDefinitionStats" forKey:[OFChallengeDefinitionStats class]];
}

- (OFService*)getService
{
	return [OFChallengeService sharedInstance];
}

- (OFUser*)getComparisonUser
{
	OFFramedNavigationController* framedNavController = (OFFramedNavigationController*)self.navigationController;
	return framedNavController.comparisonUser;
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if (listType == kChallengeListDefinitionStats)
	{
		if ([cellResource isKindOfClass:[OFChallengeDefinitionStats class]])
		{
			OFChallengeDefinitionStats* stats = (OFChallengeDefinitionStats*)cellResource;
			OFChallengeListController* historyController = (OFChallengeListController*)[[OFControllerLoaderObjC loader] load:@"ChallengeList"];// load(@"ChallengeList");
			historyController.clientApplicationId = self.clientApplicationId;
			historyController.listType = kChallengeListHistory;
			historyController.challengeDefinitionStats = stats;
			[self.navigationController pushViewController:historyController animated:YES];
		}
	}
	else
	{
        NSString* challengeId = nil;
        
		if(listType == kChallengeListPending)
		{	
            challengeId = ((OFChallengeToUser*)cellResource).challenge.resourceId;
		}
		else if(listType == kChallengeListHistory)
		{
			if ([cellResource isKindOfClass:[OFChallengeToUser class]])
			{
                OFChallengeToUser* challengeToUser = (OFChallengeToUser*)cellResource;
                challengeId = challengeToUser.challenge.resourceId;
            }
			else if ([cellResource isKindOfClass:[OFChallenge class]])
			{
                challengeId = ((OFChallenge*)cellResource).resourceId;
			}
		}
		else
		{
			OFLog(@"OFChallengeList selected segement does not exist-This should never happen");
		}
        
        if (challengeId)
        {
            NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    clientApplicationId, @"application_id",
                                    challengeId, @"challenge_id",
                                    nil];
            
            [[OFControllerLoaderObjC loader] loadAndLaunch:@"ChallengeDetail" withParams:params];
        }
	}
}

- (NSString*)getTableHeaderControllerName
{
	return (listType == kChallengeListHistory) ? nil : @"TabbedPageHeader";
}

- (void)onPendingSelected
{
	listType = kChallengeListPending;
	[self reloadDataFromServer];
}

- (void)onHistorySelected
{
	listType = kChallengeListDefinitionStats;
	[self reloadDataFromServer];
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
	OFTabbedPageHeaderController* header = (OFTabbedPageHeaderController*)tableHeader;
	header.callbackTarget = self;
	[header addTab:kPendingTabName andSelectedCallback:@selector(onPendingSelected)];
	[header addTab:kHistoryTabName andSelectedCallback:@selector(onHistorySelected)];
}

- (NSString*)getNoDataFoundMessage
{
	OFUser* comparisonUser = [self getComparisonUser];
	if (comparisonUser)
	{
		if (listType == kChallengeListPending)
		{
			return [NSString stringWithFormat:OFLOCALSTRING(@"There are no pending challenges between you and %@."), comparisonUser.name];
		}
		else if (listType == kChallengeListHistory)
		{
			return [NSString stringWithFormat:OFLOCALSTRING(@"There have not been any challenges between you and %@."), comparisonUser.name];
		}
		else
		{
			return [NSString stringWithFormat:OFLOCALSTRING(@"There are no available challenge types for %@ at this moment."), [OpenFeint applicationDisplayName]];
		}
	}
	else
	{
		if (clientApplicationId && ![clientApplicationId isEqualToString:[OpenFeint clientApplicationId]])
		{
			if (listType == kChallengeListPending)
			{
				return OFLOCALSTRING(@"You have no pending challenges for this game.");
			}
			else
			{
				return OFLOCALSTRING(@"You have not sent or received any challenges of this type.");
			}
		}
		else
		{
			return [NSString stringWithFormat:OFLOCALSTRING(@"You don't have any pending challenges for %@."), [OpenFeint applicationDisplayName]];
		}
	}
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	NSString* comparisonUserId = [self getComparisonUser].resourceId;
	if(listType == kChallengeListPending)
	{
		[OFChallengeService getPendingChallengesForLocalUserAndApplication:clientApplicationId
																 pageIndex:oneBasedPageNumber
														  comparedToUserId:comparisonUserId
                                                       onSuccessInvocation:success 
                                                       onFailureInvocation:failure];
	}
	else if(listType == kChallengeListDefinitionStats)
	{
		[OFChallengeDefinitionService getChallengeDefinitionStatsForLocalUser:oneBasedPageNumber
														  clientApplicationId:clientApplicationId
															 comparedToUserId:comparisonUserId
                                                          onSuccessInvocation:success
                                                          onFailureInvocation:failure];
	}
	else if(listType == kChallengeListHistory)
	{
		[OFChallengeService getChallengeHistoryForType:challengeDefinitionStats.resourceId
								   clientApplicationId:clientApplicationId
											 pageIndex:oneBasedPageNumber
									  comparedToUserId:comparisonUserId
                                   onSuccessInvocation:success
                                   onFailureInvocation:failure];
	}
	else
	{
		OFLog(@"OFChallengeList selected segment does not exist-This should never happen");
	}
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[self doIndexActionWithPage:1 onSuccessInvocation:success onFailureInvocation:failure];
}

- (BOOL)usePlainTableSectionHeaders
{
	return YES;
}

- (UIView*)createPlainTableSectionHeader:(NSUInteger)sectionIndex
{
	if (listType == kChallengeListDefinitionStats){
		if ((unsigned int)sectionIndex < [mSections count])
		{
			OFTableSectionDescription* tableDescription = (OFTableSectionDescription*)[mSections objectAtIndex:sectionIndex];
			UIView* headerView = [[OFControllerLoaderObjC loader] loadView:@"ChallengeListSectionHeaderView"];// loadView(@"ChallengeListSectionHeaderView");
			UILabel* label = (UILabel*)[headerView findViewByTag:1];
			label.text = tableDescription.title;
			return headerView;
		}
		else
		{
			return nil;
		}
	}else{
		//return nil;
		return [super createPlainTableSectionHeader:sectionIndex];
	}
}

- (void)onSectionsCreated:(NSMutableArray*)sections
{
	if ([sections count] == 1)
	{
		OFTableSectionDescription* firstSection = [sections objectAtIndex:0];
		if(listType == kChallengeListPending)
		{
			firstSection.title = OFLOCALSTRING(@"Pending Challenges");
		}
		else if(listType == kChallengeListDefinitionStats)
		{
			firstSection.title = OFLOCALSTRING(@"Challenge Types");
		}
		else if(listType == kChallengeListHistory)
		{
			firstSection.title = OFLOCALSTRING(@"Challenge History");
		}
	}
}

#pragma mark Comparison
		
- (BOOL)supportsComparison;
{
	return YES;
}

- (void)profileUsersChanged:(OFUser*)contextUser comparedToUser:(OFUser*)comparedToUser
{
	[self reloadDataFromServer];	
}


@end
