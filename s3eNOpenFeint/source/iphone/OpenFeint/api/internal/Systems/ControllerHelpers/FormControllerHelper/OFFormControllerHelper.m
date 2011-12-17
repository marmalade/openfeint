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

#import "OFFormControllerHelper.h"
#import "UIView+OpenFeint.h"
#import "OFFormControllerHelper+Overridables.h"
#import "OFProvider.h"
#import "UIView+OpenFeint.h"
#import "OFFormControllerHelper+Submit.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

@interface OFFormControllerHelper ()
@property (nonatomic, retain) NSMutableDictionary* tagActions;

@end


@implementation OFFormControllerHelper
@synthesize tagActions = mTagActions;
@synthesize viewDataMap = mViewDataMap;

/////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{	
//	mHttpService = [OFProvider createHttpService];
	
    self.tagActions = [NSMutableDictionary dictionaryWithCapacity:1];
	[self registerActionsNow];
	
    self.viewDataMap = [NSMutableDictionary dictionaryWithCapacity:5];
	[self populateViewDataMap:self.viewDataMap];
	
	[self.view setDelegateForAllTextFields:(id)self];
	[self.view setReturnKeyForAllTextFields:UIReturnKeySend];
	
	mScrollContainerView = [[self.view findFirstScrollView] retain];
	
	CGSize contentSize = [mScrollContainerView sizeThatFitsTight];
	mScrollContainerView.contentSize = contentSize;
}

- (void)viewDidAppear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_KeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_KeyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
//	mHttpService->cancelAllRequests();
	[self.view resignFirstResponderRecursive];
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
	[self hideLoadingScreen];
}

- (void)dealloc
{
    self.viewDataMap = nil;
    self.tagActions = nil;
	[mScrollContainerView release]; mScrollContainerView = NULL;
	[super dealloc];
}


- (IBAction)onTriggerAction:(UIView*)sender
{    
    OFInvocation* invocation = [self.tagActions objectForKey:[NSNumber numberWithInt:sender.tag]];
    if(invocation)
    {
        [invocation invoke];
    }
    else 
    {
		OFAssert(0, @"Attempting to trigger action for tag %d. No action has been registered.", sender.tag); 
		return;
    }
}

- (IBAction)onTriggerBarAction:(UIBarButtonItem*)sender
{
	[self onTriggerAction:(UIView*)sender]; //UIBarButtonItem isn't a UIView, but we're pretending it is for triggering actions
}

- (void)registerActionInvocation:(OFInvocation*)actionInvocation forTag:(int)tag
{
    [self.tagActions setObject:actionInvocation forKey:[NSNumber numberWithInt:tag]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == [OpenFeint getDashboardOrientation];
}

@end
