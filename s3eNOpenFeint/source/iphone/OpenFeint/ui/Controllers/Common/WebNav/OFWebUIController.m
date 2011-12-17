////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "OFWebUIController.h"

#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Settings.h"
#import "OFSettings.h"
#import "OFUser.h"
#import "OFXPRequest.h"
#import "UIScreen+OpenFeint.h"
#import "NSString+URLEscapingAdditions.h"
#import "OFWebUIConfirmationDelegate.h"
#import "OFWebUIChoiceDelegate.h"
#import "OFWebUINavigationItem.h"
#import "OFXPGenericRequestHandler.h"
#import "OFWebViewCacheLoader.h"
#import "OFNavigationController.h"
#import "OFColors.h"
#import "OFReachability.h"

#import <QuartzCore/QuartzCore.h>
#import "OFDependencies.h"

@interface OFWebUIController (Private)
- (void)_disableBarButtons;
- (void)_enableBarButtons;

- (void)_loadEnvironment;
- (NSString*)_clientBootJSON;

- (UIImage*)_generateTransitionImage;
- (void)_animateTransition:(BOOL)isPush;

- (void)_accumulateQueryParametersForDictionary:(NSDictionary*)dict withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum;
- (void)_accumulateQueryParametersForArray:(NSArray*)array withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum;

- (void)hideLoadingScreen;
@end

@implementation OFWebUIController

@synthesize webView, navBar, navBarBackground, loadingView, transitionImage, destinationImage, contentView;
@synthesize actionMap, initialPath;

#pragma mark -
#pragma mark Lifecycle

- (id)initWithRootPage:(NSString*)_rootPage andPath:(NSString*)_initialPath {
    if ((self = [super initWithNibName:nil bundle:nil])) {
		rootPage = [_rootPage retain];
        self.initialPath = _initialPath;
        self.actionMap = [NSMutableDictionary dictionary];
        
        [self mapAction:@"batch"            toSelector:@selector(actionBatch:)];
        [self mapAction:@"log"              toSelector:@selector(actionLog:)];
        [self mapAction:@"startLoading"     toSelector:@selector(actionStartLoading:)];
        [self mapAction:@"contentLoaded"    toSelector:@selector(actionContentLoaded:)];
        [self mapAction:@"back"             toSelector:@selector(actionBack:)];
        [self mapAction:@"showLoader"       toSelector:@selector(actionShowLoader:)];
        [self mapAction:@"hideLoader"       toSelector:@selector(actionHideLoader:)];
        [self mapAction:@"addBarButton"     toSelector:@selector(actionAddBarButton:)];
        [self mapAction:@"alert"            toSelector:@selector(actionAlert:)];
        [self mapAction:@"confirm"          toSelector:@selector(actionConfirm:)];
        [self mapAction:@"choose"           toSelector:@selector(actionChoose:)];
        [self mapAction:@"dismiss"          toSelector:@selector(actionDismiss:)];
        [self mapAction:@"reload"           toSelector:@selector(actionReload:)];
        [self mapAction:@"apiRequest"       toSelector:@selector(actionApiRequest:)];
        [self mapAction:@"writeSetting"     toSelector:@selector(actionWriteSetting:)];
        [self mapAction:@"readSetting"      toSelector:@selector(actionReadSetting:)];
    }
    return self;
}

- (id)initWithPath:(NSString*)_initialPath {
	return [self initWithRootPage:@"index.html" andPath:_initialPath];
}

- (id)initForSpecWithPath:(NSString*)_initialPath {
	return [self initWithRootPage:@"spec.html" andPath:_initialPath];
}

- (void)dealloc {
	webView.delegate = nil;
    self.webView = nil;
    self.navBar = nil;
    self.loadingView = nil;
    self.transitionImage = nil;
    self.destinationImage = nil;
    [contentView release];
    
    self.actionMap = nil;
    self.initialPath = nil;
    
	OFSafeRelease(rootPage);
    OFSafeRelease(crashReporter);
    
    [super dealloc];
}

- (UIImage*)navBarBackgroundImage
{
	return nil;
}

- (void)_orderViewDepthsForNavItem:(UINavigationItem*)navItem
{
	if (navBarBackground)
	{
		[navBar sendSubviewToBack:navBarBackground];
		UIView* titleView = navItem.titleView;
		[titleView.superview bringSubviewToFront:titleView];
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.navBar = nil;
	self.navBarBackground = nil;
	webView.delegate = nil;
	self.webView = nil;
	self.transitionImage = nil;
	self.loadingView = nil;	
    envIsLoaded = NO;
    backTriggeredFromCode = NO;
}

+(float)navigationBarHeight {
    // navigation bar height is always 44px on iPad.
    return ([OpenFeint isLargeScreen] || UIInterfaceOrientationIsPortrait([OpenFeint getDashboardOrientation])) ? 44.f : 32.f;
}

-(void)setContentView:(UIView *)_contentView {
    if (contentView == _contentView) return;
    [contentView removeFromSuperview];
    [contentView release];
    contentView = [_contentView retain];
    if (_contentView != nil) [self.view insertSubview:_contentView belowSubview:self.navBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float navigationBarHeight = [OFWebUIController navigationBarHeight];
    
    CGRect navBarFrame  = CGRectMake(0, 0, self.view.frame.size.width - 1, navigationBarHeight - 1);
    CGRect contentFrame = CGRectMake(0, navBarFrame.size.height + 1,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height - navBarFrame.size.height);
        
    // Main view
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];

    // Nav Bar
    self.navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, navigationBarHeight)] autorelease];
    navBar.barStyle = OpenFeintUIBarStyle;
    navBar.tintColor = OFColors.navBarColor;
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    navBar.delegate = self;
    [self.view addSubview:navBar];

	UIImage* navBG = [self navBarBackgroundImage];
	if (navBG)
	{
		self.navBarBackground = [[[UIImageView alloc] initWithImage:navBG] autorelease];
		navBarBackground.frame = navBar.bounds;
		navBarBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		navBarBackground.userInteractionEnabled = NO;
		
		[navBar addSubview:navBarBackground];
		[navBar sendSubviewToBack:navBarBackground];
	}

    // Main view
    self.contentView = nil;
    
    // Web View
    self.webView = [[[UIWebView alloc] initWithFrame:contentFrame] autorelease];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.dataDetectorTypes = UIDataDetectorTypeNone;
    webView.delegate = self;
    [webView setBackgroundColor:[UIColor clearColor]];
    [webView setOpaque:NO];
    
    // Remove drop shadows from the areas past the rubber band scroll
    // the shadow views should be the only UIImageViews
    for (UIView *subview in [[[webView subviews] objectAtIndex:0] subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            subview.hidden = YES;
        }
    }
    
    // Transition Image
    self.transitionImage = [[UIImageView alloc] initWithFrame:contentFrame];
    transitionImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Destination Image
    self.destinationImage = [[UIImageView alloc] initWithFrame:contentFrame];
    destinationImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Loading View
    self.loadingView = [self createLoadingView];
    
    self.contentView = loadingView;
    // Done with view setup
    
    // Ensure we are synced for the global base assets
    [OFWebViewManifestService trackPath:rootPage forMe:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self executeJavascriptAsync:[NSString stringWithFormat:@"OF.setOrientation('%@')",
                             UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? @"portrait" : @"landscape"]];
}

- (BOOL)shouldUnloadViewOnMemoryWarning
{
	return NO;
}

- (void)didReceiveMemoryWarning
{
	// by default, do NOT call super, so we do NOT unload our view and lose all JS context.
	if ([self shouldUnloadViewOnMemoryWarning])
	{
		[super didReceiveMemoryWarning];
	}
}

- (OFWebUILoadingView*)createLoadingView {
    return [[[OFWebUILoadingView alloc] initWithFrame:webView.frame] autorelease];
}

// Load up the base HTML and JS environment of WebUI by loading the root page
- (void)_loadEnvironment {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [OFWebViewManifestService rootPath], rootPage];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:url]]];
}

- (NSString*)_clientBootJSON {
    return [OFJsonCoder encodeObject:[self environmentData]];
}

- (void)_disableBarButtons {
    if (navBar.topItem)
    {
        if (navBar.topItem.rightBarButtonItem) navBar.topItem.rightBarButtonItem.enabled = NO;
        if (navBar.topItem.leftBarButtonItem) navBar.topItem.leftBarButtonItem.enabled = NO;
        if (navBar.topItem.backBarButtonItem) navBar.topItem.backBarButtonItem.enabled = NO;
    }
}

- (void)_enableBarButtons {
    if (navBar.topItem)
    {
        if (navBar.topItem.rightBarButtonItem) navBar.topItem.rightBarButtonItem.enabled = YES;
        if (navBar.topItem.leftBarButtonItem) navBar.topItem.leftBarButtonItem.enabled = YES;
        if (navBar.topItem.backBarButtonItem) navBar.topItem.backBarButtonItem.enabled = YES;
    }
}

- (void)_reenableBarButton:(NSTimer*)theTimer
{
    [self _enableBarButtons];
}

- (void)didTapBarButton {
        // Prevent hammering
    [self _disableBarButtons];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(_reenableBarButton:) userInfo:nil repeats:NO];
    [self executeJavascriptAsync:@"if (OF.page.barButtonTouch) OF.page.barButtonTouch()"];
}

- (void)setPageTitle:(NSString*)pageTitle forNavItem:(UINavigationItem*)navItem {
    if ([pageTitle hasSuffix:@".png"]) {
        if (navItem.titleView) return;
        
        navItem.title = nil;
        
        NSString *imagePath = [pageTitle stringByReplacingOccurrencesOfString:@"xdpi" withString:[OFWebViewCacheLoader dpiName]];
        imagePath = [[OFWebViewManifestService rootPath] stringByAppendingFormat:@"/%@", imagePath];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
		if ([image respondsToSelector:@selector(initWithCGImage:scale:orientation:)])
		{
			image = [[[UIImage alloc] initWithCGImage:image.CGImage scale:[UIScreen mainScreen].safeScale orientation:UIImageOrientationUp] autorelease];
		}
        navItem.titleView = [[[UIImageView alloc] initWithImage:image] autorelease];
    } else {
        navItem.title = pageTitle;
    }
	
	[self performSelector:@selector(_orderViewDepthsForNavItem:) withObject:navItem afterDelay:0.05];
}

#pragma mark -
#pragma mark Environment Dictionaries

- (NSDictionary*)environmentData {
    NSDictionary *supports = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], @"actionJSON",
                              nil];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) ? @"portrait" : @"landscape", @"orientation",
#ifdef _DEBUG
            [NSNumber numberWithBool:YES],                      @"disableGA",
#endif
            [OFWebViewCacheLoader dpiName],                    @"dpi",
            [[OFSettings instance] getSetting:@"server-url"],   @"serverUrl",
            @"ios",                                             @"platform",
            [NSNumber numberWithBool:NO],                       @"hasNativeInterface",
            [[NSLocale currentLocale] localeIdentifier],        @"locale",
            [self actions],                                     @"actions",
            [self currentDeviceData],                           @"device",
            [self currentUserData],                             @"user",
            [self currentGameData],                             @"game",
            supports,                                           @"supports",
            nil];    
}

- (NSDictionary*)currentUserData {
    NSDictionary *socialNetworks = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:[OpenFeint loggedInUserHasFbconnectCredential]], @"facebook",
                                    [NSNumber numberWithBool:[OpenFeint loggedInUserHasTwitterCredential]],   @"twitter",
                                    nil];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [[OpenFeint localUser] name],         @"name",
            [[OpenFeint localUser] resourceId],   @"id",
            socialNetworks,                       @"socialNetworks",
            [NSNumber numberWithBool:[OpenFeint loggedInUserHasHttpBasicCredential]], @"unsecured",
            nil];
}

- (NSDictionary*)currentDeviceData {
    UIDevice *currentDevice = [UIDevice currentDevice];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [OpenFeint uniqueDeviceId],  @"identifier",
            currentDevice.model, @"hardware",
            [NSString stringWithFormat:@"%@ %@", currentDevice.systemName, currentDevice.systemVersion], @"os",
            nil];
}

- (NSDictionary*)currentGameData {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [OpenFeint applicationDisplayName], @"name",
            [OpenFeint clientApplicationId], @"id",
            [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], @"version",
            nil];
}

- (NSArray*)actions {
    NSMutableArray *actions = [NSMutableArray array];
    for (NSString *actionName in [actionMap allKeys]) {
        [actions addObject:actionName];
    }
    return actions;
}

#pragma mark -
#pragma mark Utility

- (NSString*)executeJavascript:(NSString*)js {
    return [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)executeJavascriptAsync:(NSString*)js {
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setTimeout(function(){%@}, 0);", js]];
}

- (NSString*)unescapeUrlEncoding:(NSString*)str {
    return [(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
																			   (CFStringRef)str,
																			   CFSTR(""),
																			   kCFStringEncodingUTF8)
			autorelease];
}

- (NSString*)escapeUrlEncoding:(NSString*)str {
	
	return [str stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)jsonifyPath:(NSString*)path {
    // Get just the filename
    if ([path rangeOfString:@"?"].location != NSNotFound) {
        path = [[path componentsSeparatedByString:@"?"] objectAtIndex:0];
    }
    
    // Ensure it's a json file
    if (![path hasSuffix:@".json"]) {
        path = [path stringByAppendingString:@".json"];
    }
    
    return path;
}

#pragma mark -
#pragma mark Animation

- (UIImage*)_generateTransitionImage {
    UIImage *image = nil;
    
    // TODO: The UIGraphicsBeginImageContextWithOptions creates an image in the right DPI (retina vs normal) but is not supported on < 3.x
    //       We need to choose which methdo to call at runtime...
    if(&UIGraphicsBeginImageContextWithOptions != NULL)
        UIGraphicsBeginImageContextWithOptions(webView.frame.size, NO, 0.0);
    else
        UIGraphicsBeginImageContext(webView.frame.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
 
    if (context) {
        CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.5f alpha:0.5f].CGColor);
        [webView.layer renderInContext:context];
        CGContextBeginTransparencyLayer(context, NULL);
        CGContextSetBlendMode(context, kCGBlendModeOverlay);
        CGContextFillRect(context, webView.bounds);
        CGContextEndTransparencyLayer(context);
        CGContextFlush(context);
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    
    UIGraphicsEndImageContext();

    return image;
}

- (void)_animateFade
{
    transitionImage.image = [self _generateTransitionImage];
    CATransition *transition = nil;
    
    // Animate the fade
    [CATransaction begin];
    transition = [CATransition animation];
    transition.duration = 0.25f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    self.contentView = transitionImage;
    [self _disableBarButtons];
    [self.view.layer addAnimation:transition forKey:@"transition"];
    [CATransaction flush];
    [CATransaction commit];
}

- (void)_animateTransition:(BOOL)isPush
{
    // Pushing a view. Save the image to the previous navItem as well so we can
    // restore it when going back.
    if (isPush)
    {
        OFWebUINavigationItem *navItem = (OFWebUINavigationItem *)navBar.backItem;
//        transitionImage.image = [self _generateTransitionImage];555
        navItem.image = transitionImage.image;
        
        
    }
    // Popping a view.  Restore the saved image while it loads and renders
    else 
    {
        OFWebUINavigationItem *navItem = (OFWebUINavigationItem *)navBar.topItem;
        destinationImage.image = navItem.image;
        // When going back transition image needs to be generated before web view starts loading
    }
    
    CATransition *transition = nil;
    
    // Animate the view transition
    [CATransaction begin];
    transition = [CATransition animation];
    transition.duration = 0.35f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = isPush ? kCATransitionFromRight : kCATransitionFromLeft;
    
    if (isPush) self.contentView = loadingView;
    else self.contentView = destinationImage;
    [self _disableBarButtons];
    [self.view.layer addAnimation:transition forKey:@"transition"];
    [CATransaction commit];
}

- (void)animatePush {
    [self _animateTransition:YES];
}

- (void)animatePop {
    [self _animateTransition:NO];
}


-(void) crashReporterFinished {
    [self webViewCacheItemReady:rootPage];
    OFSafeRelease(crashReporter);
}

#pragma mark -
#pragma mark UIWebViewManifestDelegate

- (void)webViewCacheItemReady:(NSString *)path {
	if (![self isViewLoaded])
	{
		// In the case where we unloaded the view due to a low memory warning,
		// the bootup sequence can be aborted.
		return;
	}
    
    // global base assets load
    if ([path isEqualToString:rootPage]) {
        [self _loadEnvironment];
    }
    
    // page content load
    else {
        NSString *pageJson = [NSString stringWithContentsOfFile:[[OFWebViewManifestService rootPath] stringByAppendingFormat:@"/%@", path] usedEncoding:nil error:NULL];
        if ([pageJson hasPrefix:@"{"] && [pageJson hasSuffix:@"}"]) {
            if ([navBar.items count] > 1) [self animatePush];
            [self executeJavascriptAsync:[NSString stringWithFormat:@"OF.push.ready(%@)", pageJson]];
        } else {
            [self executeJavascriptAsync:[NSString stringWithFormat:@"alert('Missing or invalid template! %@')", path]];
        }
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate

// Action passing URL format:
//      openfeint://<instruction>/<name>[?<arg1>=<val1>]
//      openfeint://action/log?message=sampleLogMessage

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *requestURL = [request URL];
    if ([[requestURL absoluteString] isEqualToString:@"about:blank"]) {
        // Allow iframes that start without a src to make themselves ready
        return YES;
    }
    else if ([[requestURL path] rangeOfString:@"webui/analytics"].location != NSNotFound) {
        // Allow Google Analytics to load
        return YES;
    }
    else if (envIsLoaded) {
        // Process action messages
        if ([[requestURL scheme] isEqualToString:@"openfeint"]) {
            if ([[requestURL host] isEqualToString:@"action"]) {
                [self dispatchAction:requestURL];
            }
        }
        
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(error.code != -999) { //this means the action was canceled, which isn't an error
        [[[[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"Failed to load")
                                     message:OFLOCALSTRING(@"Sorry, but we had a problem displaying this screen.  Please try again soon.")
                                    delegate:nil
                           cancelButtonTitle:OFLOCALSTRING(@"OK")
                           otherButtonTitles:nil] autorelease] show];
#if _DEBUG
        OFLog(@"OFWebUIController load error: %@", error);
#endif
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (envIsLoaded) return;
    envIsLoaded = YES;
    
#if _DEBUG
    // connect to weinre
    NSString *weinreHost = [[OFSettings instance] getSetting:@"weinre-host"];
    if ([weinreHost length] > 0) {
        NSString *jscode = [NSString stringWithFormat:@"OF.DEBUG.enableWeinre('%@'); ", weinreHost];
        [self executeJavascriptAsync:jscode];
    }
#endif
    
    NSString* checkForFailure = [self executeJavascript:[NSString stringWithFormat:@"OF.init.clientBoot(%@);", [self _clientBootJSON]]];
    if(![checkForFailure isEqualToString:@"true"]) {
        crashReporter = [[OFWebUICrashReporter alloc] initWithDelegate:self];
    }
    else {
        [self executeJavascriptAsync:[NSString stringWithFormat:@"OF.push('%@');", [self initialPath]]];
    }
}

#pragma mark -
#pragma mark UINavigationBarDelegate

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    // abort if we are already loading stuff.
    if (!envIsLoaded/*[[self executeJavascript:@"OF.init.isLoaded"] isEqualToString:@"true"]*/) return NO;
    
    if (backTriggeredFromCode) {
        backTriggeredFromCode = NO;
        return YES;
    } else {
        [self _animateFade];
        [self executeJavascriptAsync:@"OF.goBack()"];
        return NO;
    }
}

#pragma mark -
#pragma mark Action Handling

// Maps an action name to a method to handle it.
- (void)mapAction:(NSString*)actionName toSelector:(SEL)selector {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:self];
    [actionMap setObject:invocation forKey:actionName];
}

// Breaks a url encoded URL like:"openfeint://action/actionName?foo=bar&zing=bang"
// into a dictionary like: { "foo":"bar", "zing":"bang" }
- (NSDictionary*)optionsForAction:(NSURL*)actionURL {
    NSString *query = [actionURL query];
    if (query) {
        query = [self unescapeUrlEncoding:query];        
        return [OFJsonCoder decodeJson:query];
    } else {
        return nil;
    }
}

- (void)_accumulateQueryParametersForDictionary:(NSDictionary*)dict withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum
{
	
	for (NSString* k in [dict allKeys])
	{
		id v = [dict objectForKey:k];
		NSString* p = prefix ? [NSString stringWithFormat:@"%@[%@]", prefix, k] : k;
		if ([v isKindOfClass:[NSArray class]])
		{
			[self _accumulateQueryParametersForArray:(NSArray*)v withPrefix:p intoArray:accum];
		}
		else if ([v isKindOfClass:[NSDictionary class]])
		{
			[self _accumulateQueryParametersForDictionary:(NSDictionary*)v withPrefix:p intoArray:accum];
		}
		else
		{
			[accum addObject:[NSString stringWithFormat:@"%@=%@", p, [v description]]];
		}
	}
}

- (void)_accumulateQueryParametersForArray:(NSArray*)array withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum
{
	NSString* p = [NSString stringWithFormat:@"%@[]", prefix];
	for (NSString* o in array)
	{
		if ([o isKindOfClass:[NSArray class]])
		{
			[self _accumulateQueryParametersForArray:(NSArray*)o withPrefix:p intoArray:accum];
		}
		else if ([o isKindOfClass:[NSDictionary class]])
		{
			[self _accumulateQueryParametersForDictionary:(NSDictionary*)o withPrefix:p intoArray:accum];
		}
		else
		{
			[accum addObject:[NSString stringWithFormat:@"%@=%@", p, [o description]]];
		}
	}
}

- (NSString*)queryStringForOptions:(NSDictionary*)options
{
	NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[options count]];
	[self _accumulateQueryParametersForDictionary:options withPrefix:nil intoArray:arr];
	NSString* rv = [arr componentsJoinedByString:@"&"];
	[arr release];
	return rv;
}

// Convert a url into an action name and arguments, then invoke it
- (void)dispatchAction:(NSURL*)actionURL {
    NSURL *innerActionURL = actionURL;
    NSString *name = nil;
    NSString *result = nil;
    
    while (TRUE) {
        name = [[innerActionURL path] substringFromIndex:1];
        NSDictionary *options = [self optionsForAction:innerActionURL];
        [self dispatchAction:name options:options];
        if ([name isEqualToString:@"startLoading"] || [name isEqualToString:@"batch"] || [name isEqualToString:@"contentLoaded"]) break;
        result = [self executeJavascript:@"OF.action.sendController.pull()"];
        if (!result || [result isEqualToString:@""])
            break;
        innerActionURL = [NSURL URLWithString:result];
#if _DEBUG
        OFLog(@"Post Dispatch requests: %@", innerActionURL);
#endif
    }
}

// Dispatcher for mapping a string action name and it's arguments to action handler methods
- (void)dispatchAction:(NSString*)name options:(NSDictionary*)options
{
#if _DEBUG    
    if (![name isEqualToString:@"log"])
    {
        OFLog(@"ACTION: %@ %@", name, options);
    }
#endif
    
    NSInvocation *invocation = [actionMap objectForKey:name];
    if (invocation)
    {
        if ([[invocation methodSignature] numberOfArguments] > 2) // Always has at least 2 args. 3 means method takes one argument (Our options dictionary)
        {
            [invocation setArgument:&options atIndex:2];
        }
        [invocation invokeWithTarget:self];
    }
#if _DEBUG    
    else
    {
        OFLog(@"UNHANDLED ACTION: %@ %@", name, options);
    }
#endif
}

#pragma mark Specific Action Handlers

// Handle multiple actions at once in a batch
- (void)actionBatch:(NSDictionary *)options {
    NSArray *actions = [options objectForKey:@"actions"];
    //OFLog(@"========================================\nACTION BATCH: %d actions", [actions count]);
    OFAssert([actions count] > 0, @"Zero action batch", __FILE__, __LINE__);
    
    for (NSDictionary *action in actions) {
        NSString     *name    = [action objectForKey:@"name"];
        NSDictionary *options = [action objectForKey:@"options"];
        [self dispatchAction:name options:options];
    }
}

// Print something to the native log
- (void)actionLog:(NSDictionary*)options {
#if _DEBUG    
    OFLog(@"WEBLOG: %@", [options objectForKey:@"message"]);
#else
    return;
#endif
}

// Start loading a new page.  Verify manifest is up to date for this content.
- (void)actionStartLoading:(NSDictionary*)options {
    OFWebUINavigationItem *navItem = [[[OFWebUINavigationItem alloc] init] autorelease];
    [self setPageTitle:[options objectForKey:@"title"] forNavItem:navItem];
    if ([navBar.items count] > 0) {
        [navBar pushNavigationItem:navItem animated:YES];
    } else {
        [navBar pushNavigationItem:navItem animated:NO];
    }
    
    // Animate the next page in, unless it's the first page
    if ([navBar.items count] > 1) {
        [self _animateFade];
    }
    
    if ([OFWebViewManifestService trackPath:[self jsonifyPath:[options objectForKey:@"path"]] forMe:self]) {
        [self showLoadingScreen];
    }
}

// Content loaded and ready for interaction
- (void)actionContentLoaded:(NSDictionary*)options {
    if ( self.contentView != self.webView ) {
        [CATransaction begin];
        CATransition *transition = nil;
        transition = [CATransition animation];
        transition.duration = 0.25f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.view.layer addAnimation:transition forKey:@"transition"];
    }
    
    // Make sure we dont have more navbar items that WebUI does
    NSNumber* webuiStackSize = [options valueForKey:@"pageStackSize"];
//    uint webuiStackSize = [[self executeJavascript:@"OF.pages.length"] intValue];
    
    while ([navBar.items count] > [webuiStackSize intValue]) {
        NSMutableArray *items = [NSMutableArray arrayWithArray:navBar.items];
        [items removeObjectAtIndex:0];
        navBar.items = items;
    }
    
    // Make sure we dont have less navbar items that WebUI does
    while ([navBar.items count] < [webuiStackSize intValue]) {
        NSMutableArray *items = [NSMutableArray arrayWithArray:navBar.items];
        [items insertObject:[[[OFWebUINavigationItem alloc] initWithTitle:@""] autorelease] atIndex:0];
        navBar.items = items;
    }
    
    // Ensure page title is up to date
    [self setPageTitle:[options objectForKey:@"title"] forNavItem:[navBar topItem]];
    
// Fade in
    if ( self.contentView != self.webView ) {
        [self hideLoadingScreen];
        [CATransaction commit];
    }
}

// Go back
- (void)actionBack:(NSDictionary*)options {
    backTriggeredFromCode = YES;
    if ([[options objectForKey:@"root"] boolValue]) {
        [navBar setItems:[navBar.items subarrayWithRange:NSMakeRange(0, 1)] animated:YES];
    } else {
        [navBar popNavigationItemAnimated:YES];
    }
    [self animatePop];
}

// Not curently used as there is no globally blocking client based loader
- (void)actionShowLoader:(NSDictionary*)options {}
- (void)actionHideLoader:(NSDictionary*)options {}

// Add a bar button to the navbar fo this screen
- (void)actionAddBarButton:(NSDictionary*)options {
    UIBarButtonItem *button;
    if ([options objectForKey:@"title"]) {
        button = [[[UIBarButtonItem alloc] initWithTitle:[options objectForKey:@"title"]
                                                   style:UIBarButtonItemStyleBordered
                                                  target:self
                                                  action:@selector(didTapBarButton)] autorelease];        
    } else {
        NSString *imagePath = [[OFWebViewManifestService rootPath] stringByAppendingFormat:@"/%@", [options objectForKey:@"image"]];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        button = [[[UIBarButtonItem alloc] initWithImage:image
                                                   style:UIBarButtonItemStyleBordered
                                                  target:self
                                                  action:@selector(didTapBarButton)] autorelease];
    }
    
    navBar.topItem.rightBarButtonItem = button;
}

// Show a native alert
- (void)actionAlert:(NSDictionary*)options {
    [[[[UIAlertView alloc] initWithTitle:[options objectForKey:@"title"]
                                 message:[options objectForKey:@"message"]
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil] autorelease] show];
}

// Show a native confirmation dialog
- (void)actionConfirm:(NSDictionary*)options {
    [[[[UIAlertView alloc] initWithTitle:[options objectForKey:@"title"]
                                 message:[options objectForKey:@"message"]
                                delegate:[OFWebUIConfirmationDelegate delegateWithNav:self andCb:[options objectForKey:@"callback"]]
                       cancelButtonTitle:[options objectForKey:@"negative"]
                       otherButtonTitles:[options objectForKey:@"positive"], nil] autorelease] show];
}

// Show a multiple choice action sheet
- (void)actionChoose:(NSDictionary*)options {
    UIActionSheet *sheet = [[[UIActionSheet alloc] init] autorelease];
    sheet.title = [options objectForKey:@"title"];
    
    NSArray *buttons = [options objectForKey:@"options"];
    NSMutableArray *callbacks = [NSMutableArray arrayWithCapacity:[buttons count]];
    
    for (NSDictionary *button in buttons) {
        // Set button title
        [sheet addButtonWithTitle:[button objectForKey:@"title"]];
        
        // Save the calback
        id callback = [button objectForKey:@"callback"];
        [callbacks addObject:callback ? callback : [NSNull null]];
        
        // Set button type
        if ([[button objectForKey:@"cancel"]      boolValue]) sheet.cancelButtonIndex      = sheet.numberOfButtons - 1;
        if ([[button objectForKey:@"destructive"] boolValue]) sheet.destructiveButtonIndex = sheet.numberOfButtons - 1;
    }
    
    sheet.delegate = [OFWebUIChoiceDelegate delegateWithNav:self andCallbacks:callbacks];
    
    [sheet showInView:self.view];
}

// Reload this flow from scratch
- (void)actionReload:(NSDictionary*)options {
    envIsLoaded = NO;
    navBar.items = [NSArray array];
    [webView reload];
}


// Make this controller go away
- (void)actionDismiss:(NSDictionary*)options {
    [self dismissModalViewControllerAnimated:YES];
}

// Perform an XP API request
- (void)actionApiRequest:(NSDictionary*)options {
    if ( [OFReachability isConnectedToInternet ])
    {
        OFXPRequest *req = [OFXPRequest requestWithPath:[options objectForKey:@"path"]
                                              andMethod:[options objectForKey:@"method"]
                                           andArgString:[options objectForKey:@"params"]];
        
        // WebUI flows need to work without OFUser login non-authenticated
        req.requiresUserSession = NO;
        
        [req onRespondText:[OFXPGenericRequestHandler handlerWithWebView:self andRequestId:[options objectForKey:@"request_id"]]];
        [req execute];
    }
    else
    {
        OFAssert(1, @"Called the API while offline!", __FILE__, __LINE__);
        [self executeJavascriptAsync:[NSString stringWithFormat:
                                 @"OF.api.completeRequest(\"%@\", \"%d\", %@)",
                                 [options objectForKey:@"request_id"], 403, @""]];
    }
}

// Write a key and value to NSUserDefaults
- (void)actionWriteSetting:(NSDictionary*)options {
    id object = [options objectForKey:@"key"];
    id value = [options objectForKey:@"value"];
    
    OFAssert(object != nil, @"Object is nil", __FILE__, __LINE__);
    
    if ( object != nil )
    {
        NSString *key = [@"OF_" stringByAppendingString:[options objectForKey:@"key"]];
        NSString *val = (value != nil)?[options objectForKey:@"value"]:@"null";
        [[NSUserDefaults standardUserDefaults] setObject:val forKey:key];
    }
}

// Read a setting from NSUserDefaults, and return its value to the webui flow
- (void)actionReadSetting:(NSDictionary*)options {
    NSString *key       = [@"OF_" stringByAppendingString:[options objectForKey:@"key"]];
    NSString *callback  = [options objectForKey:@"callback"];
    NSString *val       = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    [self executeJavascriptAsync:[NSString stringWithFormat:@"%@(%@)", callback, (val ? val : @"null")]];
}

- (void)replaceFlow:(NSString*)templatePath
{
	navBar.items = [NSArray array];
    [self showLoadingScreen];
	[self executeJavascriptAsync:[NSString stringWithFormat:@"OF.pages.replace('%@');", templatePath]];
}

- (void)showLoadingScreen
{
    self.contentView = loadingView;
}

- (void)hideLoadingScreen
{
    self.contentView = webView;
    [self _enableBarButtons];
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame]; 
    self.view = view; 
    [view release]; 
}

@end
