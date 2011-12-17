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

#import "OFAbuseReporter.h"
#import "OFProvider.h"
#import "OpenFeint+Private.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OFQueryStringWriter.h"
#import "OFRootController.h"
#import "OFXPRequest.h"
#import "OFDependencies.h"

static NSString* sAbuseTypeToNSStringMap[] = 
{
    @"chat",	// kAbuseType_Chat
    @"forum"	// kAbuseType_Forum
};

@interface OFAbuseReporter (Internal)
- (id)initWithUserId:(NSString*)_userId andType:(OFAbuseType)type andController:(UIViewController*)_viewController;
- (void)report;
- (void)_reportSuccess:(MPOAuthAPIRequestLoader*)response;
- (void)_reportFailed:(MPOAuthAPIRequestLoader*)response;
- (void)_reportFinished;
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex;
@end

@implementation OFAbuseReporter

@synthesize flaggableId, flaggableType;

+ (void)reportAbuseByUser:(NSString*)userId fromController:(UIViewController*)viewController
{
	[[[OFAbuseReporter alloc] initWithUserId:userId andType:kAbuseType_Chat andController:viewController] report];
}

+ (void)reportAbuseByUser:(NSString*)userId forumPost:(NSString*)forumPostId fromController:(UIViewController*)viewController
{
	OFAbuseReporter* abuse = [[OFAbuseReporter alloc] initWithUserId:userId andType:kAbuseType_Forum andController:viewController];
	abuse.flaggableId = forumPostId;
	abuse.flaggableType = @"Post";	
	[abuse report];
}

+ (void)reportAbuseByUser:(NSString*)userId forumThread:(NSString*)forumThreadId fromController:(UIViewController*)viewController
{
	OFAbuseReporter* abuse = [[OFAbuseReporter alloc] initWithUserId:userId andType:kAbuseType_Forum andController:viewController];
	abuse.flaggableId = forumThreadId;
	abuse.flaggableType = @"Discussion";	
	[abuse report];
}

- (id)initWithUserId:(NSString*)_userId andType:(OFAbuseType)_type andController:(UIViewController*)_viewController
{
	self = [super init];
	if (self != nil)
	{
		userId = [_userId retain];
		viewController = [_viewController retain];
		abuseType = _type;
		reported = NO;
	}
	
	return self;
}

- (void)dealloc
{
	self.flaggableId = nil;
	self.flaggableType = nil;
	
	OFSafeRelease(userId);
	OFSafeRelease(viewController);
	[super dealloc];
}

- (void)report
{
	if ([userId length] == 0 || !viewController)
	{
		[self _reportFinished];
		return;
	}
	
	UIView* viewToUse = [OpenFeint getRootController].view; //viewController.view;
	[[[UIActionSheet alloc] initWithTitle:OFLOCALSTRING(@"Are you sure you want to submit an abuse report?") delegate:self cancelButtonTitle:OFLOCALSTRING(@"Cancel") destructiveButtonTitle:OFLOCALSTRING(@"Yes, Report") otherButtonTitles:nil] showInView:viewToUse];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		reported = YES;
		
		if ([viewController respondsToSelector:@selector(showLoadingScreen)])
		{
			[viewController performSelector:@selector(showLoadingScreen)];
		}
        
        NSMutableDictionary* queryDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            sAbuseTypeToNSStringMap[abuseType], @"abuse_type", nil];
        
        if ([flaggableId length])
        {
            [queryDictionary setObject:flaggableId forKey:@"flaggable_id"];
        }
        if ([flaggableType length])
        {
            [queryDictionary setObject:flaggableType forKey:@"flaggable_type"];
        }
        
        NSString* url = [NSString stringWithFormat:@"/xp/users/%@/abuse_flags", userId];
        OFXPRequest* req = [OFXPRequest postRequestWithPath:url andQuery:queryDictionary];
        req.requiresUserSession = YES;
        [req onRespondText:self];
        [req execute];
	}
	else
	{
		[self _reportFinished];
	}
}

- (void)onResponseText:(id)body withResponseCode:(unsigned int)responseCode
{
	[self _reportFinished];
}

- (void)_reportFinished
{
	if (reported && [viewController respondsToSelector:@selector(hideLoadingScreen)])
	{
		[viewController performSelector:@selector(hideLoadingScreen)];
	}
	
	[self autorelease];
}

@end
