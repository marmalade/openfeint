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

#import "OFLeaderboardController.h"
#import "OFLeaderboard.h"
#import "OFControllerLoaderObjC.h"
#import "OFProfileController.h"
#import "OFLeaderboardService.h"
#import "OFHighScoreController.h"
#import "OFUser.h"
#import "OFTableCellBackgroundView.h"
#import "OFGameProfilePageInfo.h"

#import "OpenFeint+Settings.h"
#import "OpenFeint+UserOptions.h"
#import "OFDependencies.h"

@implementation OFLeaderboardController

@synthesize gameProfileInfo;

- (void)dealloc
{
	self.gameProfileInfo = nil;
	[super dealloc];
}

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"Leaderboard" forKey:[OFLeaderboard class]];		
}

- (OFService*)getService
{
	return [OFLeaderboardService sharedInstance];
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	OFHighScoreController* highScoreController = (OFHighScoreController*)[[OFControllerLoaderObjC loader] load:@"HighScore"];// load(@"HighScore");
	highScoreController.leaderboard = (OFLeaderboard*)cellResource;
	highScoreController.gameProfileInfo = gameProfileInfo;
	[[self navigationController] pushViewController:highScoreController animated:YES];
}

- (NSString*)getNoDataFoundMessage
{
	return [NSString stringWithFormat:OFLOCALSTRING(@"There are no leaderboards for %@"), gameProfileInfo.name];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	BOOL wantsComparison = [self getPageComparisonUser] != nil;
	if (isComparison != wantsComparison)
	{
		isComparison = wantsComparison;
        [self.resourceControllerMap removeAllObjects];
		[self populateResourceControllerMap:self.resourceControllerMap];
	}
	
	[OFLeaderboardService getLeaderboardsForApplication:gameProfileInfo.resourceId comparedToUserId:[self getPageComparisonUser].resourceId 
                                    onSuccessInvocation:success onFailureInvocation:failure];
}

#pragma mark Comparison

- (BOOL)supportsComparison
{
	return NO;
}

- (void)profileUsersChanged:(OFUser*)contextUser comparedToUser:(OFUser*)comparedToUser
{
	[self reloadDataFromServer];
}

@end
