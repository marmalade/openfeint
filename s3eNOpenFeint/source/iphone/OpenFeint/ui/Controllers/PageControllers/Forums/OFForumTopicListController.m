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

#import "OFForumTopicListController.h"

#import "OFForumThreadListController.h"
#import "OFForumTopic.h"
#import "OFForumService.h"
#import "OFControllerLoaderObjC.h"
#import "OFForumTopicCell.h"
#import "OFGameProfilePageInfo.h"
#import "OFTableSectionDescription.h"
#import "OFPaginatedSeries.h"

#import "OpenFeint+UserOptions.h"

#import "OFSelectChatRoomDefinitionController.h"
#import "OFDependencies.h"

@implementation OFForumTopicListController

#pragma mark Boilerplate

+ (id)topicBrowser
{
	OFForumTopicListController* browser = (OFForumTopicListController*)[[OFControllerLoaderObjC loader] load:@"ForumTopicList"];// load(@"ForumTopicList");
	return browser;
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark OFViewController

- (void)viewWillAppear:(BOOL)animated
{
	self.title = OFLOCALSTRING(@"Forums & Chat");
	[super viewWillAppear:animated];
}

#pragma mark OFTableSequenceControllerHelper

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"ForumTopic" forKey:[OFForumTopic class]];
}

- (OFService*)getService
{
	return [OFForumService sharedInstance];
}

- (BOOL)usePlainTableSectionHeaders
{
	return YES;
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFForumTopic class]])
	{
		// Hack! The "Real Time Chat" forum topic is created in the server side action
		// It has a resource id of 0 because it's not a record, it's a topic model created on the fly with Topic.new
		if (cellResource.resourceId == 0)
		{
			OFSelectChatRoomDefinitionController* realTimeChat = (OFSelectChatRoomDefinitionController*)[[OFControllerLoaderObjC loader] load:@"SelectChatRoomDefinition"];// load(@"SelectChatRoomDefinition");
			realTimeChat.includeGlobalRooms = YES;
			realTimeChat.includeApplicationRooms = NO;
			realTimeChat.includeDeveloperRooms = NO;
			[self.navigationController pushViewController:realTimeChat animated:YES];
		}
		else 
		{
			OFForumThreadListController* threads = [OFForumThreadListController threadBrowser:(OFForumTopic*)cellResource];
			[self.navigationController pushViewController:threads animated:YES];
		}
	}
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"There are no available discussions");
}

- (NSString*)getTableHeaderControllerName
{
	return nil;
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{	
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFGameProfilePageInfo* info = [self getPageContextGame];
	if (!info)
	{
		info = [OpenFeint localGameProfileInfo];
	}
	
	[OFForumService
     getTopicsForApplication:info.resourceId 
     onSuccessInvocation:success 
     onFailureInvocation:failure];
}

@end
