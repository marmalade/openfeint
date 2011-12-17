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

#import <UIKit/UIKit.h>
#import "OFWebViewManifestService.h"
#import "OFWebUILoadingView.h"
#import "OFWebUICrashReporter.h"

@interface OFWebUIController : UIViewController <UIWebViewDelegate, UINavigationBarDelegate, OFWebViewManifestDelegate, OFWebUICrashReporterDelegate> {
    UIView *contentView;
    UIWebView *webView;
    UINavigationBar *navBar;
	UIView* navBarBackground;
    OFWebUILoadingView *loadingView;
    UIImageView *transitionImage;
    UIImageView *destinationImage;
    
    NSMutableDictionary *actionMap;
	NSString *rootPage;
    NSString *initialPath;
    
    OFWebUICrashReporter* crashReporter;
    
    BOOL envIsLoaded;
    BOOL backTriggeredFromCode;
}

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIWebView *webView;               // The web context where most interaction takes place.
@property (nonatomic, retain) UINavigationBar *navBar;          
@property (nonatomic, retain) UIView *navBarBackground;
@property (nonatomic, retain) OFWebUILoadingView *loadingView;  // View that shows when content isn't ready to show.
@property (nonatomic, retain) UIImageView *transitionImage;     // Screencap of the current page to show when naivating away.
@property (nonatomic, retain) UIImageView *destinationImage;    // Screencap of previous page to show before the destination page is rendered.

@property (nonatomic, retain) NSMutableDictionary *actionMap;
@property (nonatomic, copy) NSString *initialPath;

- (id)initWithRootPage:(NSString*)_rootPage andPath:(NSString*)_initialPath;
- (id)initWithPath:(NSString*)initialPath;
- (id)initForSpecWithPath:(NSString*)initialPath;
- (NSString*)executeJavascript:(NSString*)js;
- (void)executeJavascriptAsync:(NSString*)js;
- (OFWebUILoadingView*)createLoadingView;
- (NSString*)jsonifyPath:(NSString *)path;
- (void)didTapBarButton;

- (void)animatePush;
- (void)animatePop;

- (void)mapAction:(NSString*)actionName toSelector:(SEL)selector;
- (void)dispatchAction:(NSURL*)actionURL;
- (void)dispatchAction:(NSString*)name options:(NSDictionary*)options;

#pragma mark Environment Data
- (NSDictionary*)environmentData;
- (NSDictionary*)currentUserData;
- (NSDictionary*)currentDeviceData;
- (NSDictionary*)currentGameData;
- (NSArray*)actions;

#pragma mark Actions
- (void)actionBatch:(NSDictionary*)options;
- (void)actionLog:(NSDictionary*)options;
- (void)actionStartLoading:(NSDictionary*)options;
- (void)actionContentLoaded:(NSDictionary*)options;
- (void)actionBack:(NSDictionary*)options;
- (void)actionShowLoader:(NSDictionary*)options;
- (void)actionHideLoader:(NSDictionary*)options;
- (void)actionAddBarButton:(NSDictionary*)options;
- (void)actionAlert:(NSDictionary*)options;
- (void)actionConfirm:(NSDictionary*)options;
- (void)actionChoose:(NSDictionary*)options;
- (void)actionDismiss:(NSDictionary*)options;
- (void)actionReload:(NSDictionary*)options;
- (void)actionApiRequest:(NSDictionary*)options;
- (void)actionWriteSetting:(NSDictionary*)options;
- (void)actionReadSetting:(NSDictionary*)options;

#pragma mark Helper methods for derived classes
- (NSString*)queryStringForOptions:(NSDictionary*)options;
- (void)replaceFlow:(NSString*)templatePath;
- (void)showLoadingScreen;
- (BOOL)shouldUnloadViewOnMemoryWarning;

@end
