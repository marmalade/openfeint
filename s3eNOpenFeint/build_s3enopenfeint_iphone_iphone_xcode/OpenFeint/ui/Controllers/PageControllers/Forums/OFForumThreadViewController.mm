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

#import "OFForumThreadViewController.h"

#import "OFForumTopic.h"
#import "OFForumThread.h"
#import "OFForumPost.h"
#import "OFForumService.h"
#import "OFPostNewMessage.h"

#import "OFResourceControllerMap.h"
#import "OFControllerLoader.h"
#import "OFFramedContentWrapperView.h"
#import "OFViewHelper.h"
#import "OFForumPostCell.h"
#import "OFTableCellHelper+Overridables.h"
#import "OFButtonPanel.h"
#import "OFProfileController.h"
#import "OFUser.h"
#import "OFTableSequenceControllerHelper+Pagination.h"
#import "OFTableControllerHelper+ViewDelegate.h"
#import "OFTableSectionDescription.h"
#import "OFPaginatedSeries.h"
#import "OFPaginatedSeriesHeader.h"
#import "OFImageLoader.h"

#import "UIButton+OpenFeint.h"

#import "OpenFeint+Private.h"
#import "OFFramedNavigationController.h"

#define SUBSCRIBED_IMAGE_NAME	@"OFButtonStarFilledSmall.png"
#define UNSUBSCRIBED_IMAGE_NAME	@"OFButtonStarEmptySmall.png"

#define REPLY_IMAGE_NAME		@"OFButtonReplyToThread.png"

@implementation OFForumThreadViewController

@synthesize thread, topic, subscribeButton;

#pragma mark Boilerplate

+ (id)threadView:(OFForumThread*)_thread topic:(OFForumTopic*)_topic
{
	OFForumThreadViewController* threadView = (OFForumThreadViewController*)OFControllerLoader::load(@"ForumThreadView");
	threadView.thread = _thread;
	threadView.topic = _topic;
	return threadView;
}

- (void)dealloc
{
	self.thread = nil;
	self.topic = nil;
	
	OFSafeRelease(subscribeButton);
			
	[super dealloc];
}

#pragma mark OFViewController

- (void)viewWillAppear:(BOOL)animated
{
	self.title = thread.title;
	[super viewWillAppear:animated];
	
	if (!hideSubscribeAndReplyButtons && !thread.isLocked)
	{
		UIImage *replyImage = [OFImageLoader loadImage:REPLY_IMAGE_NAME];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage: replyImage
			style:UIBarButtonItemStylePlain target:self action:@selector(_reply)] autorelease];
	}
	
	[self setSubscribeButtonForSubscriptionStatus:thread.isSubscribed];
}

- (void)setSubscribeButton:(UIButton *)button
{
	// don't do self.subscribeButton = [button retain] or you'll get an endless recursion loop
	subscribeButton = [button retain];
#ifdef _IPHONE_3_0    
    if(!is2PointOhSystemVersion()) {
        if (![OpenFeint isInLandscapeMode]) button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    }
#endif
	[self setSubscribeButtonForSubscriptionStatus:thread.isSubscribed];
}

#pragma mark OFTableSequenceControllerHelper

- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
	resourceMap->addResource([OFForumPost class], @"ForumPost");
}

- (OFService*)getService
{
	return [OFForumService sharedInstance];
}

- (bool)shouldAlwaysRefreshWhenShown
{
	return NO;
}

- (bool)usePlainTableSectionHeaders
{
	return true;
}

- (NSString *)getLeadingCellControllerNameForSection:(OFTableSectionDescription *)section
{
	return @"ForumSubscribeButton";
}

- (void)setSubscribeButtonForSubscriptionStatus:(BOOL)isSubscribed
{
	if (subscribeButton) 
	{
		// don't remove the blanks in the strings, they're a iPhone OS 2.x fix (no, seriously)
		[subscribeButton setTitleForAllStates:isSubscribed ? OFLOCALSTRING(@"Remove From My Conversations    ") : 
                                        OFLOCALSTRING(@"Add To My Conversations    ")];
		UIImage *image = [OFImageLoader loadImage:isSubscribed ? SUBSCRIBED_IMAGE_NAME : UNSUBSCRIBED_IMAGE_NAME];
		[subscribeButton setImage:image forState:UIControlStateNormal];
		[subscribeButton setImage:image forState:UIControlStateHighlighted];
		[subscribeButton setImage:image forState:UIControlStateSelected];
		[subscribeButton setImage:image forState:UIControlStateDisabled];
	}
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFForumPost class]])
	{
		OFForumPost *post = (OFForumPost *)cellResource;

		UINavigationController* currentNavController = [OpenFeint getActiveNavigationController];
		if (currentNavController)
		{
			OFProfileController* newProfile = [OFProfileController getProfileControllerForUser:post.author andNavController: currentNavController];

			if (newProfile) {
				newProfile.reportUserForumPost = post;
				newProfile.forumThreadView = self;

				[(OFFramedNavigationController*)currentNavController pushViewController:newProfile animated:YES inContextOfUser:post.author];
			}
		}
	}
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"There are no available posts");
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	[OFForumService
		getPostsForThread:thread.resourceId 
		page:oneBasedPageNumber 
		onSuccess:success 
		onFailure:failure];
}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	[self doIndexActionWithPage:1 onSuccess:success onFailure:failure];
}

#pragma mark Overridables

- (BOOL)shouldEnableNextButtonWithSection:(OFTableSectionDescription*)section indexPath:(NSIndexPath*)indexPath
{
    return [section isRowLastObject:indexPath.row];
}

#pragma mark Internal Methods

- (void)setThread:(OFForumThread*)_thread
{
	OFSafeRelease(thread);
	if (_thread)
	{
		thread = [_thread retain];
		
		self.title = thread.title;
		
		[self setSubscribeButtonForSubscriptionStatus:thread.isSubscribed];
	}
}

- (IBAction)_reply
{
	if (thread.isLocked)
	{
		[[[[UIAlertView alloc] 
		   initWithTitle:OFLOCALSTRING(@"Thread is Locked") 
		   message:OFLOCALSTRING(@"Cannot post in thread. It is locked.")
		   delegate:nil
		   cancelButtonTitle:OFLOCALSTRING(@"Ok") 
		   otherButtonTitles:nil] autorelease] show];
	}
	else
	{
		OFPostNewMessage* postController = [OFPostNewMessage postNewMessageInThread:thread topic:topic];
		[self.navigationController pushViewController:postController animated:YES];
	}
}

- (void)_subscribeSuccess
{
	[self hideLoadingScreen];
	
	thread.isSubscribed = !thread.isSubscribed;

	[self setSubscribeButtonForSubscriptionStatus:thread.isSubscribed];
}

- (void)_subscribeFailure
{
	[self hideLoadingScreen];
	
    OFLOCALIZECOMMENT("Multipart string generation")
	NSString* message = thread.isSubscribed ? OFLOCALSTRING(@"unsubscribe from") : OFLOCALSTRING(@"subscribe to");
	[[[[UIAlertView alloc] 
		initWithTitle:OFLOCALSTRING(@"Error Occurred") 
		message:[NSString stringWithFormat:OFLOCALSTRING(@"Could not %@ thread. Please try again later."), message]
		delegate:nil
		cancelButtonTitle:OFLOCALSTRING(@"Ok") 
		otherButtonTitles:nil] autorelease] show];
}

- (IBAction)_subscribe
{
	[self showLoadingScreen];
	
	if (thread.isSubscribed)
	{
		[OFForumService
			unsubscribeFromThread:thread.resourceId 
			topic:topic.resourceId 
			onSuccess:OFDelegate(self, @selector(_subscribeSuccess)) 
			onFailure:OFDelegate(self, @selector(_subscribeFailure))];
	}
	else
	{
		[OFForumService
			subscribeToThread:thread.resourceId 
			topic:topic.resourceId 
			onSuccess:OFDelegate(self, @selector(_subscribeSuccess)) 
			onFailure:OFDelegate(self, @selector(_subscribeFailure))];
	}
}

@end
