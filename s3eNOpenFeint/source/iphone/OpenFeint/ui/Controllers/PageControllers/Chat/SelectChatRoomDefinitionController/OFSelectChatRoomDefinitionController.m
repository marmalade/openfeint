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

#import "OFSelectChatRoomDefinitionController.h"
#import "OFSelectChatRoomInstanceController.h"
#import "OFControllerLoaderObjC.h"
#import "OFChatRoomDefinition.h"
#import "OFChatRoomDefinitionService.h"
#import "OFChatRoomInstanceService.h"
#import "OFChatRoomInstance.h"
#import "OFDeadEndErrorController.h"
#import "OFTableSectionDescription.h"

#import "OpenFeint+Private.h"
#import "OFDependencies.h"

@implementation OFSelectChatRoomDefinitionController

@synthesize includeGlobalRooms;
@synthesize includeApplicationRooms;
@synthesize includeDeveloperRooms;

- (BOOL)usePlainTableSectionHeaders
{
	return YES;
}

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"ChatRoomDefinition" forKey:[OFChatRoomDefinition class]];
	[resourceMap setObject:@"ChatRoomInstance" forKey:[OFChatRoomInstance class]];
}

- (OFService*)getService
{
	return [OFChatRoomDefinitionService sharedInstance];
}

- (BOOL)hideLoadingScreenIfInHiddenTab
{
	if ([self isInHiddenTab])
	{
		[self hideLoadingScreen];
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)onFailedLoadingInstances
{
	[self hideLoadingScreen];
	if (![OpenFeint isShowingErrorScreenInNavController:self.navigationController])
	{
		OFDeadEndErrorController* errorScreen = (OFDeadEndErrorController*)[[OFControllerLoaderObjC loader] load:@"DeadEndError"];// load(@"DeadEndError");
		errorScreen.message = OFLOCALSTRING(@"An error occurred when trying to download available rooms. Please try again.");
		[[self navigationController] pushViewController:errorScreen animated:YES];
	}
}

- (void)attemptToJoinRoom:(OFChatRoomInstance*)room
{
	if ([self hideLoadingScreenIfInHiddenTab])
	{
		return;
	}
    [OFChatRoomInstanceService attemptToJoinRoom:room rejoining:NO 
                             onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(onJoinedRoom)] 
                             onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(onFailedToJoinRoom)]];
//	OFDelegate success(self, @selector(onJoinedRoom));
//	OFDelegate failure(self, @selector(onFailedToJoinRoom));
//	[OFChatRoomInstanceService attemptToJoinRoom:room rejoining:NO onSuccess:success onFailure:failure];
}

- (void)onLoadedInstances:(OFResource*)loadedInstances
{
	if ([self hideLoadingScreenIfInHiddenTab])
	{
		return;
	}
	NSArray* resourceArray = (NSArray*)loadedInstances;
	
	if ([resourceArray count] == 0)
	{
		[self onFailedLoadingInstances];
	}
	else if ([resourceArray count] == 1)
	{
		[self attemptToJoinRoom:[resourceArray objectAtIndex:0]];	
	}
	else
	{
		[self hideLoadingScreen];
		OFSelectChatRoomInstanceController* roomInstanceController = (OFSelectChatRoomInstanceController*)[[OFControllerLoaderObjC loader] load:@"SelectChatRoomInstance"];// load(@"SelectChatRoomInstance");
		roomInstanceController.preLoadedChatRoomInstances = resourceArray;
		[[self navigationController] pushViewController:roomInstanceController animated:YES];
	}
	
}

- (IBAction)onClickedButton
{
	OFChatRoomInstance* lastRoom = [OFChatRoomInstanceService getCachedLastRoomJoined];
	if (lastRoom)
	{
		[self showLoadingScreen];
		[self attemptToJoinRoom:lastRoom];
	}
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFChatRoomDefinition class]])
	{
		[self showLoadingScreen];
//		OFDelegate success(self, @selector(onLoadedInstances:));
//		OFDelegate failure(self, @selector(onFailedLoadingInstances));
		[OFChatRoomInstanceService getPage:1 forChatRoomDefinition:(OFChatRoomDefinition*)cellResource 
                                 onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(onLoadedInstances:)] 
                                 onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(onFailedLoadingInstances)]];		
	}
	else if ([cellResource isKindOfClass:[OFChatRoomInstance class]])
	{
		[self showLoadingScreen];
		[self attemptToJoinRoom:(OFChatRoomInstance*)cellResource];
	}
}

- (void)onJoinedRoom
{
	if ([self hideLoadingScreenIfInHiddenTab])
	{
		return;
	}
	[self hideLoadingScreen];
	[OFSelectChatRoomInstanceController pushChatRoom:[OFChatRoomInstanceService getCachedLastRoomJoined] navController:[self navigationController]];
}

- (void)onFailedToJoinRoom
{
	[self hideLoadingScreen];
	if (![OpenFeint isShowingErrorScreenInNavController:self.navigationController])
	{
		[OFSelectChatRoomInstanceController pushRoomFullScreen:[self navigationController]];
	}
}

- (NSString*)getTableHeaderControllerName
{
	return nil;
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"There are no available chat rooms");
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{	
	
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFChatRoomDefinitionService getPage:1 
							 includeGlobalRooms:self.includeGlobalRooms 
						  includeDeveloperRooms:self.includeDeveloperRooms 
						includeApplicationRooms:self.includeApplicationRooms 
						 includeLastVisitedRoom:YES
                     onSuccessInvocation:success 
                     onFailureInvocation:failure];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	OFChatRoomInstance* lastRoom = [OFChatRoomInstanceService getCachedLastRoomJoined];
	if (lastRoom && [mSections count] > 0)
	{
		OFTableSectionDescription* lastRoomSection = [mSections objectAtIndex:0];
		if ([lastRoomSection.page count] == 1 && [[lastRoomSection.page objectAtIndex:0] isKindOfClass:[OFChatRoomInstance class]])
		{
			[lastRoomSection.page.objects removeObjectAtIndex:0];
			[lastRoomSection.page.objects addObject:lastRoom];
			
		}
		else
		{
			lastRoomSection = [[[OFTableSectionDescription alloc] initWithTitle:OFLOCALSTRING(@"Last Visited Room") 
																		andPage:[OFPaginatedSeries paginatedSeriesWithObject:lastRoom]] autorelease];
			[self insertSection:lastRoomSection atIndex:0];
		}
		[self _reloadTableData];
	}
	
}

- (void)dealloc
{
	[super dealloc];
}

- (void)customLoader:(NSDictionary*)params
{
    self.includeGlobalRooms = YES;
    self.includeDeveloperRooms = NO;
    self.includeApplicationRooms = NO;
}

@end
