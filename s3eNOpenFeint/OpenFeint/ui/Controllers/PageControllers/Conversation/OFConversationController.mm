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

#import "OFConversationController.h"

#import "OFConversationService+Private.h"
#import "OFControllerLoader.h"
#import "OFFramedNavigationController.h"
#import "OFViewHelper.h"
#import "OFExpandableSinglelineTextField.h"
#import "OFConversationMessageBoxController.h"
#import "OFPoller.h"
#import "OFProvider.h"
#import "OFTableSectionDescription.h"
#import "OFPaginatedSeries.h"
#import "OFDelegateChained.h"
#import "OFConversation.h"

#import "OFForumPost.h"

#import "OpenFeint+Private.h"
#import "OpenFeint+Settings.h"

#import "OFPresenceService.h"

#import "OFUser.h"

#import "OFOnlineStatus.h"
#import "OFRootController.h"
#import "OFImageLoader.h"
#import "UIWindow+OpenFeint.h"

static const float gFakeKeyboardHeight = 85.f;

@implementation OFConversationController

@synthesize conversationId;
@synthesize conversationUser;

#pragma mark Boilerplate

+ (id)conversationWithId:(NSString*)conversationId withUser:(OFUser*)conversationUser
{
	return [[[OFConversationController alloc] initWithConversationId:conversationId withConversationUser:conversationUser initialText:nil] autorelease];
}

+ (id)conversationWithId:(NSString*)conversationId withUser:(OFUser*)conversationUser initialText:(NSString*)initialText
{
	return [[[OFConversationController alloc] initWithConversationId:conversationId withConversationUser:conversationUser initialText:initialText] autorelease];
}

- (id)initWithConversationId:(NSString*)_conversationId withConversationUser:(OFUser*)_conversationUser initialText:(NSString*)_initialText
{
	self = [super initWithStyle:UITableViewStylePlain];
	if (self != nil)
	{
		self.conversationId = _conversationId;
		self.conversationUser = _conversationUser;
		
		if ([_initialText length] > 0)
		{
			[messageBox setInitialText:_initialText];
		}
	}
	
	return self;
}

- (void)dealloc
{
	[poller stopPolling];
	OFSafeRelease(poller);
	
	self.conversationId = nil;
	OFSafeRelease(conversationUser);
	OFSafeRelease(messageBox);
	[super dealloc];
}

#pragma mark Internal Methods

- (void)_initialIndexComplete:(OFPaginatedSeries*)resources nextCall:(OFDelegateChained*)nextCall
{
	NSEnumerator* postEnumerator = [resources.objects objectEnumerator];
	long long largestId = 0;
	for (OFForumPost* post = [postEnumerator nextObject]; post != nil; post = [postEnumerator nextObject])
	{
		long long thisId = [post.resourceId longLongValue];
		if (thisId > largestId) {
			largestId = thisId;
		}
	}

	poller = [[OFPoller alloc] initWithProvider:[OpenFeint provider] sourceUrl:[NSString stringWithFormat:@"discussions/%@/posts.xml", self.conversationId]];
	[poller registerResourceClass:[OFForumPost class]];
	[poller clearCacheAndForceLastSeenId:largestId forResourceClass:[OFForumPost class]];

	[poller changePollingFrequency:[OpenFeint getPollingFrequencyInChat]];
	
	hasCompletedInitialIndex = YES;
	
	[nextCall invokeWith:resources];
    
    [self _updateOnlineStatusWithUser:conversationUser isOnline:conversationUser.online];
}

- (void)_adjustTableOffsetY:(float)delta animated:(BOOL)animated
{
	CGPoint contentOffset = [self.tableView contentOffset];
	float newOffset = contentOffset.y + delta;
	const float maxOffset = (self.tableView.contentSize.height - self.tableView.frame.size.height);
	newOffset = MIN(newOffset, maxOffset);
	newOffset = MAX(0.f, newOffset);
	[self.tableView setContentOffset:CGPointMake(contentOffset.x, newOffset) animated:animated];
}

- (void)_startedConversation:(OFPaginatedSeries*)conversationPage
{
	if ([conversationPage count] == 1)
	{
		OFConversation* conversation = [conversationPage objectAtIndex:0];
		self.conversationId = conversation.resourceId;
		[self _refreshData];
	}
	else
	{
		[self hideLoadingScreen];
		[OpenFeint displayErrorMessage:@"An error occurred while initiating your IM."];
	}
}

- (void)_errorStartingConversation
{
	[self hideLoadingScreen];
	[OpenFeint displayErrorMessage:@"An error occurred while initiating your IM."];
}

#pragma mark Property Methods

- (void)setConversationId:(NSString*)_conversationId
{
	OFSafeRelease(conversationId);
	conversationId = [_conversationId retain];
	
	messageBox.conversationId = _conversationId;
}

-(void) _pollingFailed:(NSNotification*) notification {
    NSString* urlPath = notification.object;
    if([urlPath hasPrefix:@"discussions"]) {
        [(id)[self parentViewController] popViewControllerAnimated:NO];
    }
}

#pragma mark OFViewController

- (void)loadView
{
	[super loadView];

	messageBox = [OFControllerLoader::load(@"ConversationMessageBox", self) retain];
	messageBox.conversationId = conversationId;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_pollingFailed:) name:@"OFPollingFailed" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_userDidChangePresence:) name:[OFUser getResourceDiscoveredNotification] object:nil];

	if (hasCompletedInitialIndex)
	{
		[poller changePollingFrequency:[OpenFeint getPollingFrequencyInChat]];
	}

	self.title = self.conversationUser.name;
	
	CGRect ff = messageBox.view.frame;
	ff.size.height = 43.f;
	messageBox.view.frame = ff;
    
    [messageBox viewWillAppear:animated];
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[messageBox messageField] resignFirstResponder];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"OFPollingFailed" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:[OFUser getResourceDiscoveredNotification] object:nil];
	
	[poller stopPolling];
    
	isKeyboardShown = NO;
	
	[messageBox viewWillDisappear:animated];
	[super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[messageBox viewDidAppear:animated];
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[messageBox viewDidDisappear:animated];	
	[super viewDidDisappear:animated];
}

#pragma mark OFTableSequenceControllerHelper

- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
	resourceMap->addResource([OFForumPost class], @"Conversation");
    resourceMap->addResource([OFOnlineStatus class], @"OnlineStatus");
}

- (OFService*)getService
{
	return [OFConversationService sharedInstance];
}

- (bool)shouldAlwaysRefreshWhenShown
{
	return !hasCompletedInitialIndex;
}

- (bool)isNewContentShownAtBottom
{
	return true;
}

- (bool)allowPagination
{
	return false;
}

- (bool)shouldRefreshAfterNotification
{
	return true;
}

- (NSString*)getNotificationToRefreshAfter
{
	return [OFForumPost getResourceDiscoveredNotification];
}

- (bool)isNotificationResourceValid:(OFResource*)resource
{
	OFForumPost* post = (OFForumPost*)resource;
	return [post.discussionId isEqualToString:conversationId];
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	[messageBox.messageField resignFirstResponder];
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"Start the conversation by typing a message and sending it below!");
}

- (NSString*)getTableHeaderViewName
{
	return nil;
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	if (self.conversationId != nil)
	{
		OFDelegate chainedSuccess(self, @selector(_initialIndexComplete:nextCall:), success);

		[OFConversationService
			getConversationHistory:conversationId 
			page:1
			onSuccess:chainedSuccess 
			onFailure:failure];
	}
	else
	{
		[OFConversationService 
			startConversationWithUser:self.conversationUser.resourceId 
			onSuccess:OFDelegate(self, @selector(_startedConversation:)) 
			onFailure:OFDelegate(self, @selector(_errorStartingConversation))];
	}
}

- (void)configureCell:(OFTableCellHelper*)_cell asLeading:(BOOL)_isLeading asTrailing:(BOOL)_isTrailing asOdd:(BOOL)_isOdd
{
}

#pragma mark OFCustomBottomView

- (UIView*)getBottomView
{    
    return messageBox.view;
}

#pragma mark OFExpandableSinglelineTextFieldDelegate

- (void)multilineTextFieldDidResize:(OFExpandableSinglelineTextField*)multilineTextField
{
    float oldHeight = messageBox.view.frame.size.height;

    float offset = ([OpenFeint isLargeScreen]) ? 12.f : 6.f;
    CGRect frame = messageBox.view.frame;
    frame.origin.y = CGRectGetMaxY(frame) - multilineTextField.frame.size.height - offset;
    frame.size.height = multilineTextField.frame.size.height + offset;
    messageBox.view.frame = frame;
    
    if ([self.navigationController isKindOfClass:[OFFramedNavigationController class]])
    {
        [(OFFramedNavigationController*)self.navigationController refreshBottomView];
    }

    float heightDelta = messageBox.view.frame.size.height - oldHeight;
    if (heightDelta > 0.f)
    {
        [self _adjustTableOffsetY:heightDelta animated:YES];
    }
}

#pragma mark Keyboard Handling

- (CGFloat)_keyboardAdjustment
{
	return gFakeKeyboardHeight;
}

- (void)_keyboardWillShow:(NSNotification*)notification
{
	if (isKeyboardShown)
		return;

	if (![OpenFeint isLargeScreen])
    {
		//No navigation allowed when keyboard is up (there is a problem when pressing back when the keyboard is up,
		//the view sizes get all screwy).
		[self.navigationController setNavigationBarHidden:YES animated:YES];
        
		float keyboardHeight = [UIWindow OFgetKeyboardSize:[notification userInfo]].height;

        if ([self.navigationController isKindOfClass:[OFFramedNavigationController class]])
        {
            [(OFFramedNavigationController*)self.navigationController adjustForKeyboard:YES ofHeight:keyboardHeight];
        }

        [self _adjustTableOffsetY:keyboardHeight animated:NO];
    }
	else
	{
        [self _adjustTableOffsetY:[self _keyboardAdjustment] animated:YES];
	}

    isKeyboardShown = YES;
}

- (void)_keyboardWillHide:(NSNotification*)notification
{
    if (!isKeyboardShown)
        return;

	if (![OpenFeint isLargeScreen])
    {
        float additionalContentOffset = 0.0f;

		[self.navigationController setNavigationBarHidden:NO animated:YES];
		additionalContentOffset = self.navigationController.navigationBar.frame.size.height;

		float keyboardHeight = [UIWindow OFgetKeyboardSize:[notification userInfo]].height;

        if ([self.navigationController isKindOfClass:[OFFramedNavigationController class]])
        {
            [(OFFramedNavigationController*)self.navigationController adjustForKeyboard:NO ofHeight:keyboardHeight];
        }

        [self _adjustTableOffsetY:additionalContentOffset animated:YES];
    }
	
	[messageBox setInitialText:@""];

    isKeyboardShown = NO;
}

- (void)_userDidChangePresence:(NSNotification*)notification {
    // Get user online status
    OFUser *otherUser = [[[notification userInfo] objectForKey:@"OFPollerNotificationKeyResources"] objectAtIndex:0];
	
	if ([otherUser.resourceId isEqualToString:conversationUser.resourceId])
	{
		BOOL isOnline = [otherUser online];
		//OFLog(@"userDidChangePresence: %i", (int)isOnline);
		[self _updateOnlineStatusWithUser:otherUser isOnline:isOnline];
	}
}

- (void)_updateOnlineStatusWithUser:(OFUser*)user isOnline:(BOOL)online
{
    OFOnlineStatus *status = [[[OFOnlineStatus alloc] initWithUser:user onlineStatus:online] autorelease];
    
    OFTableSectionDescription *section = (OFTableSectionDescription*)[mSections objectAtIndex:0];
    OFPaginatedSeries *page = (OFPaginatedSeries*)[section page];
    [page prependObject:status];
    [self _reloadTableData];
    
    // TODO: Probably a cleaner way to do this in the OF framework files somewhere that I am not finding...
    NSInteger objectCount = [[(OFTableSectionDescription*)[mSections objectAtIndex:0] page] count];
    if (objectCount > 0)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:objectCount-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

@end
