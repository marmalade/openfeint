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

#import "OFSelectChatRoomInstanceController.h"
#import "OFControllerLoaderObjC.h"
#import "OFChatRoomInstance.h"
#import "OFChatRoomInstanceService.h"
#import "OFChatRoomController.h"
#import "OFDeadEndErrorController.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

@implementation OFSelectChatRoomInstanceController

@synthesize preLoadedChatRoomInstances;

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"ChatRoomInstance" forKey:[OFChatRoomInstance class]];
}

- (OFService*)getService
{
	return [OFChatRoomInstanceService sharedInstance];
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	[self showLoadingScreen];
    [OFChatRoomInstanceService attemptToJoinRoom:(OFChatRoomInstance*)cellResource rejoining:NO 
                             onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(onJoinedRoom)] 
                             onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(onFailedToJoinRoom)]];
//	OFDelegate success(self, @selector(onJoinedRoom));
//	OFDelegate failure(self, @selector(onFailedToJoinRoom));
//	[OFChatRoomInstanceService attemptToJoinRoom:(OFChatRoomInstance*)cellResource rejoining:NO onSuccess:success onFailure:failure];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
{
    [success invokeWith:self.preLoadedChatRoomInstances];
//	success.invoke(self.preLoadedChatRoomInstances);
}

- (void)onJoinedRoom
{
	[self hideLoadingScreen];
	if (![self isInHiddenTab])
	{
		[OFSelectChatRoomInstanceController pushChatRoom:[OFChatRoomInstanceService getCachedLastRoomJoined] navController:[self navigationController]];
	}
}

- (void)onFailedToJoinRoom
{
	[self hideLoadingScreen];
	
	if (![OpenFeint isShowingErrorScreenInNavController:self.navigationController])
	{
		[OFSelectChatRoomInstanceController pushRoomFullScreen:[self navigationController]];
	}
}

+ (void)pushChatRoom:(OFChatRoomInstance*)chatRoom navController:(UINavigationController*)navController
{
	OFChatRoomController* chatRoomController = (OFChatRoomController*)[[OFControllerLoaderObjC loader] load:@"ChatRoom"];// load(@"ChatRoom");
	chatRoomController.roomInstance = chatRoom;
	[navController pushViewController:chatRoomController animated:YES];
}

+ (void)pushRoomFullScreen:(UINavigationController*)navController
{
	OFDeadEndErrorController* errorScreen = (OFDeadEndErrorController*)[[OFControllerLoaderObjC loader] load:@"DeadEndError"];// load(@"DeadEndError");
	errorScreen.message = OFLOCALSTRING(@"The room you attempted to join is full. Please try another room.");
	[navController pushViewController:errorScreen animated:YES];
}

- (NSString*)getTableHeaderControllerName
{
	return nil;
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"There are no available chat room instances");
}

- (void)dealloc
{
	self.preLoadedChatRoomInstances = nil;
	[super dealloc];
}
@end
