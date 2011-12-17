//  Copyright 2011 Aurora Feint, Inc.
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

#import "OFURLDispatcher.h"
#import "OpenFeint.h"
#import "OpenFeint+Private.h"
#import "OFJsonCoder.h"
#import "OpenFeint+Dashboard.h"
#import "OFControllerLoaderObjC.h"
#import "OFCommonWebViewController.h"
#import "OFGameProfileController.h"
#import "OFApplicationDescriptionController.h"
#import "OFDependencies.h"

static OFURLDispatcher* gDefaultDispatcher = nil;

@interface OFURLDispatcher()
@property (nonatomic, retain) NSMutableDictionary * actionMap;
@property (nonatomic, retain) NSDictionary * launchAfterApprovalParams;
@end

@implementation OFURLDispatcher

@synthesize actionMap, launchAfterApprovalParams;

+ (id)defaultDispatcher
{
	if (!gDefaultDispatcher)
	{
		gDefaultDispatcher = [[OFURLDispatcher alloc] init];
	}
	return gDefaultDispatcher;
}

- (id)init
{
    self = [super init];
    if (self)
    {        
		self.actionMap = [NSMutableDictionary dictionaryWithCapacity:10];
		[self mapAction:@"login" toInvocation:[OFInvocation invocationForTarget:self selector:@selector(performLoginAction:)]];
		[self mapAction:@"dashboardPage" toInvocation:[OFInvocation invocationForTarget:self selector:@selector(performDashboardPageAction:)]];
		[self mapAction:@"openBrowser" toInvocation:[OFInvocation invocationForTarget:self selector:@selector(performOpenBrowserAction:)]];
        [self mapAction:@"openModalBrowser" toInvocation:[OFInvocation invocationForTarget:self selector:@selector(performOpenModalBrowserAction:)]];
        [self mapAction:@"openGamePage" toInvocation:[OFInvocation invocationForTarget:self selector:@selector(performOpenGamePageAction:)]];
    }
    return self;
}

- (void)dealloc
{
	[super dealloc];
	self.actionMap = nil;
    self.launchAfterApprovalParams = nil;
}

- (void)mapAction:(NSString*)actionName toInvocation:(OFInvocation*)invocation
{
	[actionMap setObject:invocation forKey:actionName];
}

- (NSDictionary *)optionsForAction:(NSURL*)actionURL
{
    NSString *query = [actionURL query];
	
	if (!query)
	{
		return nil;
	}
	
	NSString * firstThreeChars = [query substringToIndex:3];
	// If the first character is the escaped version of '{' then we have json
	if ([firstThreeChars isEqualToString:@"%7B"])
	{
        query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        return [OFJsonCoder decodeJson:query];
	}

	//find parameters
	NSArray* params = [query componentsSeparatedByString:@"&"];
	if (params.count == 0)
	{
		return nil;
	}
	NSMutableDictionary* actionParams = [NSMutableDictionary dictionaryWithCapacity:params.count];
	for(NSString* param in params)
	{
		NSArray* keyAndValue = [param componentsSeparatedByString:@"="];
		if (keyAndValue.count == 2)
		{
			NSString * valueUnescaped = [[keyAndValue objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[actionParams setObject:valueUnescaped forKey:[keyAndValue objectAtIndex:0]];
		}
	}
	return actionParams;
}

- (void)dispatchAction:(NSURL*)actionURL
{
    [self dispatchAction:actionURL withObserver:nil];
}

- (void)dispatchAction:(NSURL*)actionURL withObserver:(id<OFURLDispatcherObserver>)observer
{
    if([actionURL.scheme isEqualToString:@"openfeint"])
	{
		// Ignore the "host" part of the url

		NSString * path = [actionURL path];
		if (path && [path length] > 1)
		{
			// Get rid of the leading slash
			NSString *name = [path substringFromIndex:1];
			NSDictionary *params = [self optionsForAction:actionURL];
			[self dispatchAction:name params:params withObserver:observer];
		}
        else
        {
            // Let the observer know we're not dispatching an action
            [observer dispatcher:self wontDispatchAction:actionURL];
        }
	}
	else
	{
		OFLog(@"Unknown scheme launching URL %@", actionURL);
        
        // Let the observer know we're not dispatching an action
        [observer dispatcher:self wontDispatchAction:actionURL];
	}
}

- (void)dispatchAction:(NSString*)name params:(NSDictionary*)params
{
    [self dispatchAction:name params:params withObserver:nil];
}

- (void)dispatchAction:(NSString*)name params:(NSDictionary*)params withObserver:(id<OFURLDispatcherObserver>)observer
{
    [observer dispatcher:self willDispatchAction:name withParams:params];
    
    OFInvocation *invocation = [actionMap objectForKey:name];
    if (invocation)
	{
        [invocation invokeWith:params];
    }
	else
	{
        OFLog(@"UNHANDLED ACTION: %@ %@", name, params);
		[OpenFeint launchDashboard];
    }
}


// Actions

- (void)performLoginAction:(NSDictionary*)params
{
	if (![OpenFeint hasUserApprovedFeint])
	{
		[OpenFeint presentUserFeintApprovalModalInvocation:nil
										  deniedInvocation:nil];
	}
	else
	{
		[OpenFeint launchDashboard];
	}
}

- (void)launchDashboardPageWithParams:(NSDictionary*)params
{
    NSObject * pageNameObj = [params objectForKey:@"page"];
    if (pageNameObj == nil || ![pageNameObj isKindOfClass:[NSString class]])
    {
        OFLog(@"Can't get property \"page\"\n%@", params);
        return;
    }
    NSString * pageName = (NSString*)pageNameObj;
    
    [[OFControllerLoaderObjC loader] loadAndLaunch:pageName withParams:params];
}

- (void)performDashboardPageAction:(NSDictionary*)params
{
    if (![OpenFeint hasUserApprovedFeint])
    {
        // If the user has not approved OpenFeint, launch the intro flow.
        // When it's done, we will continue with the page that was requested.
        self.launchAfterApprovalParams = params;
        [OpenFeint presentUserFeintApprovalModalInvocation:[OFInvocation invocationForTarget:self selector:@selector(approvalAccepted)]
                                          deniedInvocation:[OFInvocation invocationForTarget:self selector:@selector(approvalDenied)]];
    }
    else
    {
        [self launchDashboardPageWithParams:params];
    }
}

- (void)performOpenBrowserAction:(NSDictionary*)params
{
	NSObject * urlStringObj = [params objectForKey:@"url"];
	if (urlStringObj == nil || ![urlStringObj isKindOfClass:[NSString class]])
	{
		OFLog(@"openBrowser action needs a \"url\" property: %@", params);
		return;
	}
	NSString * urlString = (NSString*)urlStringObj;

	urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL* url = [NSURL URLWithString:urlString];
    if (!url)
    {
        OFLog(@"Unable to make url from string: %@", urlString);
        return;
    }
    if(![[UIApplication sharedApplication] openURL:url])
    {
        OFLog(@"Failed to launch URL %@", url);
    }
}

- (void)performOpenModalBrowserAction:(NSDictionary*)params
{
    NSObject * urlStringObj = [params objectForKey:@"url"];
	if (urlStringObj == nil || ![urlStringObj isKindOfClass:[NSString class]])
	{
		OFLog(@"openModalBrowser action needs a \"url\" property: %@", params);
		return;
	}
	NSString * urlString = (NSString*)urlStringObj;

	urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	OFCommonWebViewController* webController = (OFCommonWebViewController*)[[OFControllerLoaderObjC loader] load:@"CommonWebView"];
    [webController loadUrl:urlString];
    UINavigationController* navController = [[[UINavigationController alloc] initWithRootViewController:webController] autorelease];
    webController.isDashbaordModal = YES;
    [OpenFeint presentRootControllerWithModal:navController];

}

- (void)performOpenGamePageAction:(NSDictionary*)params
{
    NSObject * clientAppIDObj = [params objectForKey:@"appid"];
    if (clientAppIDObj == nil || ![clientAppIDObj isKindOfClass:[NSString class]])
	{
        OFLog(@"OpenGamePage action needs a \"appid\" property: %@", params);
		return;
    }
    NSString* clientAppID = (NSString*)clientAppIDObj;
    
    [OFGameProfileController showGameProfileWithClientApplicationId:clientAppID compareToUser:nil];
}

- (void)approvalAccepted
{
    [self launchDashboardPageWithParams:launchAfterApprovalParams];
    self.launchAfterApprovalParams = nil;
}

- (void)approvalDenied
{
    self.launchAfterApprovalParams = nil;
}

@end
