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

#import "OFForumThreadListController.h"

#import "OFForumThreadViewController.h"
#import "OFForumTopic.h"
#import "OFForumThread.h"
#import "OFForumService.h"
#import "OFPostNewMessage.h"

#import "OFControllerLoaderObjC.h"
#import "UIView+OpenFeint.h"
#import "OFFramedContentWrapperView.h"

#import "OFPageSelectionView.h"
#import "OFDependencies.h"

@interface OFForumThreadListController (Internal)
- (void)_post;
@end

@implementation OFForumThreadListController

@synthesize topic;

#pragma mark Boilerplate

+ (id)threadBrowser:(OFForumTopic*)_topic
{
	OFForumThreadListController* threadBrowser = (OFForumThreadListController*)[[OFControllerLoaderObjC loader] load:@"ForumThreadList"];// load(@"ForumThreadList");
	threadBrowser.topic = _topic;
	return threadBrowser;
}

- (void)customLoader:(NSDictionary*)params
{
    NSString* topicId = [params objectForKey:@"topic_id"];
    NSString* topicTitle = [params objectForKey:@"topic_title"];
    if (topicId)
    {
        OFForumTopic* forumTopic = [[[OFForumTopic alloc] initWithId:topicId] autorelease];
        forumTopic.title = topicTitle;
        self.topic = forumTopic;
    }
}

- (void)dealloc
{
	self.topic = nil;
	[super dealloc];
}

#pragma mark OFViewController

- (void)viewWillAppear:(BOOL)animated
{
	self.title = topic.title;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
												target:self action:@selector(_post)] autorelease];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	justPostedNewThread = NO;
}

#pragma mark OFTableSequenceControllerHelper

- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"ForumThread" forKey:[OFForumThread class]];
}

- (OFService*)getService
{
	return [OFForumService sharedInstance];
}

- (BOOL)shouldAlwaysRefreshWhenShown
{
	return justPostedNewThread;
}

- (BOOL)usePlainTableSectionHeaders
{
	return YES;
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFForumThread class]])
	{
		OFForumThreadViewController* threadView = [OFForumThreadViewController threadView:(OFForumThread*)cellResource topic:topic];
		[self.navigationController pushViewController:threadView animated:YES];
	}
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"There are no discussions");
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFForumService
     getThreadsForTopic:topic.resourceId 
     page:oneBasedPageNumber 
     onSuccessInvocation:success 
     onFailureInvocation:failure];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{	
	[self doIndexActionWithPage:1 onSuccessInvocation:success onFailureInvocation:failure];
}

#pragma mark Internal Interface

- (void)_post
{
	justPostedNewThread = YES;
	OFPostNewMessage* postController = [OFPostNewMessage postNewMessageInTopic:topic];
	[self.navigationController pushViewController:postController animated:YES];
}

@end
