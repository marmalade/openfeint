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

#import "OFChallengeDetailController.h"
#import "OFChallengeDefinition.h"
#import "OFChallenge.h"
#import "OFChallengeToUser.h"
#import "OFChallengeService+Private.h"
#import "UIView+OpenFeint.h"
#import "OFImageView.h"
#import "OpenFeint+Private.h"
#import "OFPaginatedSeries.h"
#import "OFChallengeDetailCell.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFUser.h"
#import "OFControllerLoaderObjC.h"
#import "OFTableSectionDescription.h"
#import "OFChallengeDetailHeaderController.h"
#import "OFProfileController.h"
#import "OpenFeint+Settings.h"
#import "OFDependencies.h"

@interface OFChallengeDetailController()

@property (nonatomic, retain) NSString* challengeId;
@property (nonatomic, retain) NSString* clientApplicationId;

@end


@implementation OFChallengeDetailController

@synthesize userChallenge, challengeId, clientApplicationId;

- (void)customLoader:(NSDictionary*)params
{
    self.challengeId = [params objectForKey:@"challenge_id"];
    self.clientApplicationId = [params objectForKey:@"application_id"];
}

- (void)dealloc 
{
	self.userChallenge = nil;
	self.challengeId = nil;
	self.clientApplicationId = nil;
	OFSafeRelease(challengeData);
	OFSafeRelease(oneShotAlertView);
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.title = @"Challenge";
}


- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"ChallengeDetail" forKey:[OFChallengeToUser class]];
}

- (NSString*)getTableHeaderControllerName
{
	return @"ChallengeDetailHeader";
}

- (BOOL)usePlainTableSectionHeaders
{
	return YES;
}

- (void)onSectionsCreated:(NSMutableArray*)sections
{
	if ([sections count] == 1)
	{
		OFTableSectionDescription* firstSection = [sections objectAtIndex:0];
		firstSection.title = OFLOCALSTRING(@"People Who Received This Challenge");
	}
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFChallengeService getUsersWhoReceivedChallengeWithId:challengeId 
									   clientApplicationId:clientApplicationId
												 pageIndex:oneBasedPageNumber 
                                       onSuccessInvocation:success 
                                       onFailureInvocation:failure];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{	
	[self doIndexActionWithPage:1 onSuccessInvocation:success onFailureInvocation:failure];
}

- (NSString*)getNoDataFoundMessage
{
	return [NSString stringWithFormat:OFLOCALSTRING(@"You have not received any challenges yet. You can send challenges to your friends from within %@."), [OpenFeint applicationDisplayName]];
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFChallengeToUser class]])
	{
		OFChallengeToUser* challengeToUser = (OFChallengeToUser*)cellResource;
		[OFProfileController showProfileForUser:challengeToUser.recipient];
	}
}

- (OFService*)getService
{
	return [OFChallengeService sharedInstance];
}

- (void)startChallenge
{
	[self hideLoadingScreen];
	id<OFChallengeDelegate>delegate = [OpenFeint getChallengeDelegate];
	if([delegate respondsToSelector:@selector(userLaunchedChallenge:withChallengeData:)])
	{
		[OpenFeint dismissDashboard];
		[delegate userLaunchedChallenge:userChallenge withChallengeData:challengeData];
	}
	OFSafeRelease(challengeData);
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	alertView.delegate = nil;
	OFSafeRelease(oneShotAlertView);
	if (challengeData || ![userChallenge.challenge usesChallengeData])
	{
		[self startChallenge];
	}
}

- (IBAction)acceptChallenge:(id)sender
{
	[self showLoadingScreen];
	if (!userChallenge.challenge.challengeDefinition.multiAttempt)
	{
		OFSafeRelease(oneShotAlertView);
		oneShotAlertView = [[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"One Shot Challenge") 
													  message:OFLOCALSTRING(@"You only have one attempt to beat this challenge!") 
													 delegate:self 
											cancelButtonTitle:OFLOCALSTRING(@"OK") 
											otherButtonTitles:nil];
		[oneShotAlertView show];
	}
	
	if ([userChallenge.challenge usesChallengeData])
	{
//		OFDelegate success(self, @selector(_challengeDataDownloaded:));
//		OFDelegate failure(self, @selector(_challengeDataDownloadFailed));
		[OFChallengeService downloadChallengeData:userChallenge.challenge.challengeDataUrl 
                              onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_challengeDataDownloaded:)]
                              onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_challengeDataDownloadFailed)]];
	}
	else if (!oneShotAlertView)
	{
		[self startChallenge];
	}
}

- (void)_challengeDataDownloaded:(NSData*)_challengeData
{
	challengeData = [_challengeData retain];
	if (!oneShotAlertView)
	{
		[self startChallenge];
	}
}

- (void)_challengeDataDownloadFailed
{
	[self hideLoadingScreen];
	[[[[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"Error downloading data") 
								 message:OFLOCALSTRING(@"Please try again.") 
								delegate:nil 
					   cancelButtonTitle:OFLOCALSTRING(@"OK") 
					   otherButtonTitles:nil] autorelease] show];
}

- (void)onResourcesDownloaded:(OFPaginatedSeries*)resources
{
	NSArray* metaDataObjects = [self getMetaDataOfType:[OFChallengeToUser class]];
	if ([metaDataObjects count] > 0)
	{
		self.userChallenge = (OFChallengeToUser*)[metaDataObjects objectAtIndex:0];
	}
	else if ([resources count] > 0)
	{
		self.userChallenge = [resources objectAtIndex:0];
	}
}

@end
