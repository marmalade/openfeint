//  Copyright 2009-2011 Aurora Feint, Inc.
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

#import "OFGameFeedView.h"
#import "OpenFeint+Private.h"
#import "OFGameFeedItem.h"
#import "OFJsonCoder.h"
#import "OFWebViewManifestService.h"
#import "OFImageLoader.h"
#import "UIButton+OpenFeint.h"
#import "OpenFeint.h"
#import "OFBadgeView.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+NSNotification.h"
#import "OFCurrentUser.h"
#import "OFGameFeedView+Private.h"
#import "OFControllerLoaderObjC.h"
#import "NSDictionary+OpenFeint.h"
#import "NSString+OpenFeint.h"
#import "OFWebViewCacheLoader.h"
#import "OFTouchView.h"
#import "OFSettings.h"
#import "OFASIHTTPRequest.h"
#import "OFGameFeedTabView.h"
#import "OFColor.h"
#import "OFWebViewManifestService.h"
#import "OFXPRequest.h"
#import "OFGameFeedSettingsInternal.h"
#import "OFReachability.h"
#import "OFGameFeedErrorItem.h"
#import "UIView+OpenFeint.h"
#import "IPhoneOSIntrospection.h"
#import "OFUser.h"
#import "OpenFeint+EventLog.h"
#import "OFSessionObserver.h"
#import "OFSession.h"
#import "OFGameFeedLoadingView.h"
#import "OFABTesting.h"
#import "OFResourceRequest.h"
#import "OFDependencies.h"


#pragma mark -
#pragma mark Local constants

static const int kGameFeedHeightPortrait = 76;
static const int kGameFeedHeightLandscape = 62;
static const int kLoadingSpinnerOffsetX = -60;
static const int kLoadingTextOffsetX = -43;
static const int kLoadingTextOffsetY = -30;
static const float kRefreshDebounceTime = 5.0f;
static const float kButtonFadeInTime = 0.5f;
static const float kFakeResponseTime = 1.0f;
static const float kFirstItemFadeInTime = 0.5f;
static const float kOtherItemsFadeInTime = 1.0f;
NSString* gameFeedShouldDisplayOfflineItem = @"gameFeedShouldDisplayOfflineItem";
NSString* gameFeedShouldRefresh = @"gameFeedShouldRefresh";

typedef enum 
{
    EGameFeedDisplay_NONE,
    EGameFeedDisplay_LOADING,
    EGameFeedDisplay_OFFLINE,
    EGameFeedDisplay_ERROR,
    EGameFeedDisplay_FEED_ITEMS,
} EGameFeedDisplay;

@class OFGameFeedViewHelper;

#pragma mark -
#pragma mark Private interface class extension

@interface OFGameFeedView() <OFASIHTTPRequestDelegate, OFWebViewManifestDelegate, UIScrollViewDelegate>
@property (nonatomic, retain) NSDictionary* configuration;
@property (nonatomic, retain) id itemsWaiting;
@property (nonatomic, retain) NSMutableDictionary* customization;
@property (nonatomic, retain) NSMutableArray* feedItems;
@property (nonatomic, retain) NSDate* loadStartDate;
@property (nonatomic, retain) NSDate* showStartDate;
@property (nonatomic, retain) NSArray* pendingAds;
@property (nonatomic) OFGameFeedAlignment gameFeedAlignment;
@property (nonatomic, retain) UIImage* customizeBackgroundImageLandscape;
@property (nonatomic, retain) UIImage* customizeBackgroundImagePortrait;
@property (nonatomic, retain) OFGameFeedTabView* tabView;
@property (nonatomic, retain) UIScrollView* gameFeedScrollView;
@property (nonatomic, assign) BOOL animateInWhenBecomesVisible;
@property (nonatomic, retain) OFBadgeView* badgeView;
@property (nonatomic, retain) UIView* loadingView;
@property (nonatomic, retain) UIView* offlineItem;
@property (nonatomic, retain) OFGameFeedErrorItem* serverErrorItem;
@property (nonatomic, retain) UIButton* badgeButton;
@property (nonatomic, retain) OFTouchView* badgeTouchView;
@property (nonatomic) EGameFeedDisplay display;
@property (nonatomic, retain) NSDictionary* layouts;
@property (nonatomic, retain) OFResourceRequest* currentRequest;
@property (nonatomic, retain) OFASIHTTPRequest* currentADRequest;
@property (nonatomic, retain) NSString* testConfigFilename;
@property (nonatomic, retain) NSString* testFeedFilename;
@property (nonatomic, retain) NSTimer* refreshDebounceTimer;
@property (nonatomic, retain) NSTimer* fadeInButtonTimer;
@property (nonatomic, retain) OFGameFeedViewHelper* helper;
@property (nonatomic) BOOL useCustomLoading;

- (NSString*)bundlePath;
- (void)buildItems:(id)itemData;
- (void)processConfig:(NSDictionary*)rootConfigutation;
- (void)setupDefaultCustomization:(NSDictionary*)defaultCustomization;
- (NSMutableDictionary*)configWithValidNibs:(NSDictionary*)config;
- (void)createGameFeedView;
- (void)onLaunchDashboard:(id)sender;
- (void)layoutFeedItems;
- (void)removeLoadingView;
- (void)badgeCountChanged;
- (void)checkItemVisibility;
- (OFGameFeedItem*)createLoadingItem;
- (void)moveViewIntoPlace;
- (void)moveViewOffscreen;
- (void)cancelCurrentADRequest;
- (void)cancelCurrentFeedRequest;
- (void)beginLoadingAnimation;
- (void)refresh;
- (void)refreshAlways;
- (BOOL)isLandscapeMode;
- (void)createLoadingView;

@end

#pragma mark -
#pragma mark Online and offline notification

@interface OFGameFeedView(AsOFReachabilityObserver) <OFReachabilityObserver>
- (void)reachabilityChangedFrom:(OFReachabilityStatus)oldStatus to:(OFReachabilityStatus)newStatus;
@end

@implementation OFGameFeedView(AsOFReachabilityObserver)

- (void)reachabilityChangedFrom:(OFReachabilityStatus)oldStatus to:(OFReachabilityStatus)newStatus
{
    if (newStatus != OFReachability_Not_Connected)
    {
            // We now have internet.
            // If we were loading, or displaying the offline item, refresh the game feed.
            // Otherwise we had a game feed still displaying, so leave it up.
            if ([self display] != EGameFeedDisplay_FEED_ITEMS)
            {
                [self refreshAlways];
            }
        }
    else
    {
        // If we were viewing the loading screen, go to the offline screen.
        // Otherwise, it's okay to leave up whatever screen was up.
        if ([self display] == EGameFeedDisplay_LOADING)
        {
            [self setDisplay:EGameFeedDisplay_OFFLINE];
        }
    }
}

@end



// This class is to get around a circular reference issue where OFSession would have a reference to me and me to it.
@interface OFGameFeedViewHelper : NSObject <OFSessionObserver>
{
    OFGameFeedView* gameFeedView;
}

- (id)initWithGameFeedView:(OFGameFeedView*) _gameFeedView;
- (void)removeLoadingView;

@end

@implementation OFGameFeedViewHelper

- (id)initWithGameFeedView:(OFGameFeedView*) _gameFeedView
{
    self = [super init];
    if (self)
    {
        gameFeedView = _gameFeedView;
    }
    return self;
}

- (void)removeLoadingView
{
    [gameFeedView removeLoadingView];
}

- (void)session:(OFSession*)session didLoginOnlyXpUser:(OFUser*)user
{
    [gameFeedView refreshAlways];
}

- (void)session:(OFSession*)session didLoginUser:(OFUser*)user previousUser:(OFUser*)previousUser
{
}

- (void)session:(OFSession*)session didLogoutUser:(OFUser*)user
{
    [gameFeedView refreshAlways];
}

- (void)session:(OFSession*)session failureWithException:(OFServerException*)exception
{
    if([OFReachability isConnectedToInternet])
    {
        //If we are not connected to te internet, then we don't want to override the offline cell because of this error
        [gameFeedView setDisplay:EGameFeedDisplay_ERROR];
    }
}

@end


#pragma mark -
#pragma mark Implementation

@implementation OFGameFeedView

@synthesize configuration = mConfiguration;
@synthesize itemsWaiting = mItemsWaiting;
@synthesize feedItems = mFeedItems;
@synthesize customization = mCustomization;
@synthesize loadStartDate = mLoadStartDate;
@synthesize showStartDate = mShowStartDate;
@synthesize pendingAds = mPendingAds;
@synthesize customizeBackgroundImageLandscape = mCustomizeBackgroundImageLandscape;
@synthesize customizeBackgroundImagePortrait = mCustomizeBackgroundImagePortrait;
@synthesize gameFeedAlignment = mGameFeedAlignment;
@synthesize tabView = mTabView;
@synthesize gameFeedScrollView = mGameFeedScrollView;
@synthesize animateInWhenBecomesVisible = mAnimateInWhenBecomesVisible;
@synthesize badgeView = mBadgeView;
@synthesize offlineItem = mOfflineItem;
@synthesize serverErrorItem = mServerErrorItem;
@synthesize badgeButton = mBadgeButton;
@synthesize badgeTouchView = mBadgeTouchView;
@synthesize display = mDisplay;
@synthesize layouts = mLayouts;
@synthesize currentRequest = mCurrentRequest;
@synthesize currentADRequest = mCurrentADRequest;
@synthesize testConfigFilename = mTestConfigFilename;
@synthesize testFeedFilename = mTestFeedFilename;
@synthesize refreshDebounceTimer = mRefreshDebounceTimer;
@synthesize loadingView = mLoadingView;
@synthesize fadeInButtonTimer = mFadeInButtonTimer;
@synthesize helper = mHelper;
@synthesize useCustomLoading = mUseCustomLoading;
@synthesize orientation = mOrientation;

- (BOOL)forceServerError
{
    if([[OFSettings instance] getSetting:@"force_game_feed_server_error"] &&
       [[[OFSettings instance] getSetting:@"force_game_feed_server_error"] isEqualToString:@"true"])
    {
        return YES;
    }
    return NO;
}

- (BOOL)forceAdServerError
{
    if([[OFSettings instance] getSetting:@"force_ad_server_error"] &&
       [[[OFSettings instance] getSetting:@"force_ad_server_error"] isEqualToString:@"true"])
    {
        return YES;
    }
    return NO;
}

- (BOOL)ready
{
    return [self.configuration count] > 0;
}

- (void)copyColorFromSettings:(NSDictionary*)settings named:(NSString*)settingName configKey:(NSString*)configKey
{
    OFColor* color = [settings objectForKey:settingName ifKindOfClass:[OFColor class]];
    if (color)
    {
        [self.customization setObject:[color toString] forKey:configKey];
    }
}

- (void)copyItemFromSettings:(NSDictionary*)settings named:(NSString*)settingName configKey:(NSString*)configKey
{
    NSObject* obj = [settings objectForKey:settingName];
    if (obj)
    {
        [self.customization setObject:obj forKey:configKey];
    }
}

- (int)intValueFromDictionary:(NSDictionary*)dictionary forKey:(id)key defaultingTo:(int)defaultValue
{
    int toReturn = defaultValue;
    NSNumber* obj = (NSNumber*)[dictionary objectForKey:key];
    if (obj)
    {
        toReturn = [obj intValue];
    }
    return toReturn;
}

- (BOOL)boolValueFromDictionary:(NSDictionary*)dictionary forKey:(id)key defaultingTo:(BOOL)defaultValue
{
    BOOL toReturn = defaultValue;
    NSNumber* obj = (NSNumber*)[dictionary objectForKey:key];
    if (obj)
    {
        toReturn = [obj boolValue];
    }
    return toReturn;
}

- (id)initWithSettings:(NSDictionary*)settings
{
    if((self = [super initWithFrame:CGRectMake(0,0,100,100)]))
    {
        if ([OpenFeint sharedInstance] == nil)
        {
            NSLog(@"You must initialize OpenFeint before creating an OFGameFeedView.");
            [OFLogging alwaysShowDeveloperWarningWithMessage:@"You must initialize OpenFeint before creating an OFGameFeedView."];
            OFAssert(0, @"");
            [self release];
            return nil;
        }

        if(![OpenFeint developerAllowsUserGeneratedContent])
        {
            OFLogDevelopment(@"GameFeed is disabled when UGC is explicitly turned off by the developer");
            [self release];
            return nil;
        }


        // Force the singleton to be created.
        // If we wait to do it, it could be created within an OFReachability callback, which causes a problem because
        // creating the singleton itself uses OFReachability, which isn't re-entrant.
        [OpenFeint eventLog];
        
        self.customization = [NSMutableDictionary dictionaryWithCapacity:10];
        
        mOrientation = [OpenFeint getDashboardOrientation];
        
        self.gameFeedAlignment = [self intValueFromDictionary:settings forKey:OFGameFeedSettingAlignment defaultingTo:OFGameFeedAlignment_BOTTOM];
        
        [self copyColorFromSettings:settings named:OFGameFeedSettingUsernameColor configKey:@"username_color"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingTitleColor configKey:@"title_color"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingMessageTextColor configKey:@"text_color"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingIconPositiveColor configKey:@"icon_color_positive"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingIconNegativeColor configKey:@"icon_color_negative"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingIconNeutralColor configKey:@"icon_color"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingDisclosureColor configKey:@"disclosure_color"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingCalloutTextColor configKey:@"call_out_color"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingFrameColor configKey:@"frame_color"];        
        [self copyColorFromSettings:settings named:OFGameFeedSettingHighlightedTextColor configKey:@"highlighted_color"];        

        [self copyItemFromSettings:settings named:OFGameFeedSettingTabLeftImage configKey:@"tab_left_image"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingTabRightImage configKey:@"tab_right_image"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingCellBackgroundImageLandscape configKey:@"cell_background_image_landscape"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingCellBackgroundImagePortrait configKey:@"cell_background_image_portrait"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingCellHitImageLandscape configKey:@"cell_hit_image_landscape"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingCellHitImagePortrait configKey:@"cell_hit_image_portrait"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingCellDividerImageLandscape configKey:@"cell_divider_image_landscape"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingCellDividerImagePortrait configKey:@"cell_divider_image_portrait"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingProfileFrameImage configKey:@"profile_frame_image"];        
        [self copyItemFromSettings:settings named:OFGameFeedSettingSmallProfileFrameImage configKey:@"small_profile_frame_image"];

        self.customizeBackgroundImageLandscape = [settings objectForKey:OFGameFeedSettingFeedBackgroundImageLandscape];
        self.customizeBackgroundImagePortrait = [settings objectForKey:OFGameFeedSettingFeedBackgroundImagePortrait];

        self.testConfigFilename = [settings objectForKey:OFGameFeedSettingTestConfigFilename];
        self.testFeedFilename = [settings objectForKey:OFGameFeedSettingTestFeedFilename];
        
        self.clipsToBounds = NO;
        
        self.animateInWhenBecomesVisible = [self boolValueFromDictionary:settings forKey:OFGameFeedSettingAnimateIn defaultingTo:NO];
        
        BOOL showTab = [self boolValueFromDictionary:settings forKey:OFGameFeedSettingShowTabView defaultingTo:NO];
        if (showTab)
        {
            self.tabView = [[[OFGameFeedTabView alloc] initWithFrame:CGRectZero] autorelease];
            mTabView.alignment = [self intValueFromDictionary:settings forKey:OFGameFeedSettingTabAlignment defaultingTo:OFGameFeedTabAlignment_LEFT];
            mTabView.icon = [settings objectForKey:OFGameFeedSettingTabIcon];
            mTabView.text = [settings objectForKey:OFGameFeedSettingTabText];
            mTabView.brandingTabImage = [settings objectForKey:OFGameFeedSettingTabBrandingImage];
            [self addSubview:self.tabView];
        }
                
        mDisplay = EGameFeedDisplay_NONE;
        
        if (self.testConfigFilename)
        {
            [self performSelector:@selector(webViewCacheItemReady:) withObject:self.testConfigFilename afterDelay:0.1];
        }
        else
        {
            [OFWebViewManifestService trackPath:@"gamefeed/ios/config.json" forMe:self];
        }
        
        [self createGameFeedView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:gameFeedShouldRefresh object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:OFNSNotificationParentalControlsChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:OFNSNotificationAnnouncementRead object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badgeCountChanged) name:OFNSNotificationUnreadInboxCountChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badgeCountChanged) name:OFNSNotificationUnviewedChallengeCountChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badgeCountChanged) name:OFNSNotificationPendingFriendCountChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badgeCountChanged) name:OFNSNotificationUnreadAnnouncementCountChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldDisplayOfflineItem) name:gameFeedShouldDisplayOfflineItem object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dashboardDisappearing) name:OFNSNotificationDashboardWillDisappear object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(approvalScreenDidAppear) name:OFNSNotificationApprovalScreenDidAppear object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(approvalScreenDidDisappear) name:OFNSNotificationApprovalScreenDidDisappear object:nil];
        if (is4PointOhSystemVersion())
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIApplicationWillEnterForegroundNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        // and actually let's log some stuff.
        NSString* alignmentString = nil;
        switch (self.gameFeedAlignment) {
            default:
            case OFGameFeedAlignment_BOTTOM:
                alignmentString = @"bottom";
                break;
            case OFGameFeedAlignment_CUSTOM:
                alignmentString = @"custom";
                break;
            case OFGameFeedAlignment_TOP:
                alignmentString = @"top";
                break;
        }
        NSDictionary* initializationEvent = [NSDictionary dictionaryWithObjectsAndKeys:
                                             ([self isLandscapeMode] ? @"landscape" : @"portrait"), @"orientation",
                                             [NSNumber numberWithBool:self.animateInWhenBecomesVisible], @"animation",
                                             alignmentString, @"placement",
                                             nil];
        [OFGameFeedView logEventWithActionKey:@"initialized" parameters:initializationEvent];        
        
        [OFReachability addObserver:self];
        
        if ([OFReachability reachability] == OFReachability_Unknown)
        {
            // The app has recently laaunched, so we don't know yet.
            // Wait for a callback to reachabilityChangedFrom to go to either offline or game feed items.
            [self setDisplay:EGameFeedDisplay_LOADING];
        }
        else if ([OFReachability isConnectedToInternet])
        {
            [self setDisplay:EGameFeedDisplay_LOADING];
            [self refresh];
        }
        else
        {
            [self setDisplay:EGameFeedDisplay_OFFLINE];
        }
        
        if ([OpenFeint isApprovalScreenOpen])
        {
            self.hidden = YES;
        }

        self.helper = [[[OFGameFeedViewHelper alloc] initWithGameFeedView:self] autorelease];
        [[OpenFeint session] addObserver:self.helper];
        
    }
    return self;
}

- (id)init
{
    return [self initWithSettings:nil];
}

- (void)dealloc
{
    [self cancelCurrentFeedRequest];
    [self cancelCurrentADRequest];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [OFReachability removeObserver:self];
    if (mHelper)
    {
        [[OpenFeint session] removeObserver:mHelper];
    }
    OFSafeRelease(mGameFeedScrollView);
    OFSafeRelease(mFeedItems);
    OFSafeRelease(mConfiguration);
    OFSafeRelease(mItemsWaiting);
    OFSafeRelease(mCustomization);
    OFSafeRelease(mTabView);
    OFSafeRelease(mOfflineItem);
    OFSafeRelease(mServerErrorItem);
    OFSafeRelease(mBadgeTouchView);
    OFSafeRelease(mTabView);
    OFSafeRelease(mCustomizeBackgroundImageLandscape);
    OFSafeRelease(mCustomizeBackgroundImagePortrait);
    OFSafeRelease(mBadgeView);
    OFSafeRelease(mBadgeButton);
    OFSafeRelease(mLayouts);
    OFSafeRelease(mTestConfigFilename);
    OFSafeRelease(mTestFeedFilename)
    [mRefreshDebounceTimer invalidate];
    OFSafeRelease(mRefreshDebounceTimer);
    [mFadeInButtonTimer invalidate];
    OFSafeRelease(mFadeInButtonTimer);
    OFSafeRelease(mLoadingView)
    OFSafeRelease(mHelper);
    
    [super dealloc];
}

- (BOOL)isLandscapeMode
{
    //return UIInterfaceOrientationIsLandscape(mOrientation);
    return [OpenFeint isInLandscapeMode];
}

- (void)setDisplay:(EGameFeedDisplay)display
{
    EGameFeedDisplay oldDisplay = mDisplay;
    mDisplay = display;
    
    if (display != EGameFeedDisplay_FEED_ITEMS)
    {
        // If we're going to display items,
        // we can leave up the loading screen.
        // We animate it out in removeLoadingView.
        [self.loadingView removeFromSuperview];
    }
    
    [self.serverErrorItem removeFromSuperview];
    [self.offlineItem removeFromSuperview];

    if (display != EGameFeedDisplay_FEED_ITEMS)
    {
        for(OFGameFeedItem* item in mFeedItems)
        {
            [item removeFromSuperview];
        }
        mGameFeedScrollView.contentSize = mGameFeedScrollView.frame.size;
        mGameFeedScrollView.scrollEnabled = NO;
    }
    
    switch(display)
    {
        case EGameFeedDisplay_LOADING:
        {
            if (!self.loadingView.superview) {
            [self addSubview:self.loadingView];
                self.loadingView.alpha = 1;
            }
            if (!self.useCustomLoading) {
                [self bringSubviewToFront:mGameFeedScrollView];
            }
 
            if (oldDisplay != EGameFeedDisplay_LOADING)
            {
                self.badgeButton.alpha = 0;
                self.badgeView.alpha = 0;
                [mFadeInButtonTimer invalidate];
                self.fadeInButtonTimer = [NSTimer scheduledTimerWithTimeInterval:kButtonFadeInTime target:self
                  selector:@selector(fadeInDashboardButton) userInfo:nil repeats:NO];
            }
        } break;
        case EGameFeedDisplay_OFFLINE:
        {
            if (oldDisplay != EGameFeedDisplay_OFFLINE)
            {
                [OFGameFeedView logEventWithActionKey:@"game_feed_offline" parameters:nil];
            }
            
            if (self.offlineItem == nil) {
                NSString* nibName = @"OFGBIOffline";
                if ([self isLandscapeMode]) {
                    nibName = @"OFGBIOfflineLandscape";
                }
                NSArray* objects = [[OpenFeint getResourceBundle] loadNibNamed:nibName owner:nil options:nil];
                self.offlineItem = [objects objectAtIndex:0];
                int startx = self.badgeView.frame.origin.x + self.badgeView.frame.size.width;
                int starty = 6;
                CGRect frame = self.offlineItem.frame;
                frame.origin.x = startx;
                frame.origin.y = starty;
                self.offlineItem.frame = frame;
            }
            [mGameFeedScrollView addSubview:self.offlineItem];
        } break;
        case EGameFeedDisplay_ERROR:
        {
            if (self.serverErrorItem == nil) {
                self.serverErrorItem = (OFGameFeedErrorItem*)[[OFControllerLoaderObjC loader] loadView:@"GBIServerError"];
                UIImageView* errorIcon = self.serverErrorItem.icon;
                
                UIColor* color = nil;       
                id colorString = [self.customization objectForKey:@"icon_color_negative"];
                
                // If we got a server error before we were able to retrieve the config file from the server, we won't
                // have a customization dictionary, so won't have a "negative icon color".  Use the default one.
                if (!colorString)
                {
                    colorString = @"#FFAC11";
                }
                if ([colorString isKindOfClass:[NSString class]])
                {
                    color = [colorString toColor];
                }
                if (color)
                {
                    [errorIcon setImage:[self.serverErrorItem colorizeImage:errorIcon.image color:color]];
                }
                
                int startx = self.badgeView.frame.origin.x + self.badgeView.frame.size.width;
                int starty = 6;
                CGRect frame = self.serverErrorItem.frame;
                frame.origin.x = startx;
                frame.origin.y = starty;
                self.serverErrorItem.frame = frame;
            }
            [mGameFeedScrollView addSubview:self.serverErrorItem];
        } break;
        case EGameFeedDisplay_FEED_ITEMS:
        {            
            mGameFeedScrollView.scrollEnabled = YES;
            if (oldDisplay == EGameFeedDisplay_LOADING)
            {
                [self beginLoadingAnimation];
            }
            [self layoutFeedItems];
        } break;
        default:break;
    }
}

- (void)fadeInDashboardButton
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5f];
 
    self.badgeButton.alpha = 1;
    self.badgeView.alpha = 1;
    
    [UIView commitAnimations];
}

- (void)beginLoadingAnimation
{
    if (self.useCustomLoading) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationDelegate:self];
        self.loadingView.alpha = 0;
        [UIView commitAnimations];
    }

    float firstItemFadeInTime = kFirstItemFadeInTime;
    float otherItemsFadeInTime = kOtherItemsFadeInTime;

    if (self.badgeButton.alpha == 0)
    {
        // The button hasn't yet faded in
        // fade the button in right away now
        [self.fadeInButtonTimer invalidate];
        [self fadeInDashboardButton];
    }
    else
    {
        // The button has already started fading in
        // In this case, we start fading in the first item right away.
        firstItemFadeInTime = 0.0f;
        otherItemsFadeInTime -= kFirstItemFadeInTime;
    }

    if ([mFeedItems count] == 0)
    {
        [self removeLoadingView];
    }
    
    for (int i = 0; i < [mFeedItems count]; i++)
    {
        OFGameFeedItem* item = [mFeedItems objectAtIndex:i];
        // The first item comes in sooner
        if (i == 0)
        {
            OFInvocation* doneLoadingFirstItemInvocation = [OFInvocation invocationForTarget:self.helper selector:@selector(removeLoadingView) userParam:nil];
            [item fadeInAfterSeconds:firstItemFadeInTime doneInvocation:doneLoadingFirstItemInvocation];
        }
        else
        {
            [item fadeInAfterSeconds:otherItemsFadeInTime doneInvocation:nil];
        }
    }
	
}

- (void)shouldDisplayOfflineItem
{
    [self setDisplay:EGameFeedDisplay_OFFLINE];
}

#pragma mark Communication with server & bundle
- (void)webViewCacheItemReady:(NSString *)path
{
    //this is the game feed config, load it, decode JSON and set to configuration
    NSData* data;
    if(self.testConfigFilename)
    {
        data = [[NSData alloc] initWithContentsOfFile:[self.bundlePath stringByAppendingPathComponent:path]];
    }
    else
    {
        data = [[NSData alloc] initWithContentsOfFile:[[OFWebViewManifestService rootPath] stringByAppendingPathComponent:path]];
    }
    NSDictionary* rootConfigutation = [OFJsonCoder decodeJsonFromData:data];
    [self processConfig:rootConfigutation];
	
    [data release];
    
    if(self.itemsWaiting)
    {
        [self buildItems:self.itemsWaiting];
        self.itemsWaiting = nil;
    }
}


- (void)onResponseJSON:(id)body withResponseCode:(unsigned int)responseCode
{
    self.currentRequest = nil;
    if(responseCode == 200)
    {
        if(self.ready)
        {
            [self buildItems:body];
        }
        else
        {
            self.itemsWaiting = body;
        }
    }
    else
    {
        [self setDisplay:EGameFeedDisplay_ERROR];
        [OFGameFeedView logEventWithActionKey:@"game_feed_items_load_failed" parameters:nil];
    }
}

- (void)onFeedRequestResponse:(OFResourceRequest*)request
{
    [self onResponseJSON:request.resources withResponseCode:request.httpResponseCode];
}

- (void)fakeResponse
{
    NSString* openFeintResourceBundleLocation = [[NSBundle mainBundle] bundlePath];    
    NSData* jsonData = [[NSData alloc] initWithContentsOfFile:[openFeintResourceBundleLocation stringByAppendingPathComponent:self.testFeedFilename]];
    NSDictionary* dictionaryData = [OFJsonCoder decodeJsonFromData:jsonData];
    NSArray* arrayData = [dictionaryData objectForKey:@"game_feed" ifKindOfClass:[NSArray class]];
    [self onResponseJSON:arrayData withResponseCode:200];  
    [jsonData release];
}

+ (OFGameFeedView*)gameFeedView
{
    return [[[OFGameFeedView alloc] initWithSettings:nil] autorelease];
}

+ (OFGameFeedView*)gameFeedViewWithSettings:(NSDictionary*)settings
{
    return [[[OFGameFeedView alloc] initWithSettings:settings] autorelease];
}


- (BOOL)shouldWaitForUserLogin
{
    BOOL hasHitApprovedButton = [OpenFeint hasUserApprovedFeint];
    BOOL hasCompletedIntroFlow = [OpenFeint lastLoggedInUserId] && ![[OpenFeint lastLoggedInUserId] isEqualToString:@"0"];

    if (hasHitApprovedButton)
	{
        if (!hasCompletedIntroFlow)
        {
            // There is a special case where the user abandons the intro flow after approving OF but
            // before creating a user.  In that case, we won't ever get the notification that they logged in, so just
            // go ahead and display a feed without waiting.
            return false;
        }
        
        // The user will log in.  Wait for bootstrap if it's not yet completed.
        return [[OpenFeint session] currentUser] == nil;
    }
    
    return false;
}

- (void)refreshDebounceTimerDone
{
    self.refreshDebounceTimer = nil;
}

- (void)refreshAlways
{
    [mRefreshDebounceTimer invalidate];
    self.refreshDebounceTimer = nil;
    [self refresh];
}

- (void)refresh
{
    if ([self shouldWaitForUserLogin])
    {
        return;
    }
    
    if (mRefreshDebounceTimer != nil)
    {
        // There is still a debounce timer running, so don't refresh because we just did recently.
        // This is to make sure we don't refresh twice in a row because of a "user changed" event, for example.
        return;
    }
    
    self.refreshDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshDebounceTime target:self
      selector:@selector(refreshDebounceTimerDone) userInfo:nil repeats:NO];
 
    if (self.testFeedFilename)
    {
        [self setDisplay:EGameFeedDisplay_LOADING];
        [self performSelector:@selector(fakeResponse) withObject:nil afterDelay:kFakeResponseTime];
    }
    else
    {
        if ([OFReachability reachability] == OFReachability_Connected_WiFi ||
            [OFReachability reachability] == OFReachability_Connected_Carrier)
        {
            [self setDisplay:EGameFeedDisplay_LOADING];
            
            [self cancelCurrentFeedRequest];
            OFResourceRequest* req;
            if ([self forceServerError])
            {
                req = [OFResourceRequest getRequestWithPath:@"/testing/errors/immediate"];
            }
            else
            {
                NSString* url = [NSString stringWithFormat:@"/xp/games/%@/feed.json", [OpenFeint clientApplicationId]];
                req = [OFResourceRequest getRequestWithPath:url];
            }
            req.requiresUserSession = NO;
            [req onRespondTarget:self selector:@selector(onFeedRequestResponse:)];
            [req execute];
            self.currentRequest = req;

            [OFGameFeedView logEventWithActionKey:@"game_feed_begin_loading" parameters:nil];
        }
        else if ([OFReachability reachability] == OFReachability_Unknown)
        {
            [self setDisplay:EGameFeedDisplay_LOADING];
        }
        else
        {
            [self setDisplay:EGameFeedDisplay_OFFLINE];
        }
    }
}

//this bundle holds any non-nib files, such as images
//you can't load outside nibs on the iPhone
- (NSString*)bundlePath
{
    if(self.testConfigFilename)
    {
        NSString* openFeintResourceBundleLocation = [[NSBundle mainBundle] bundlePath];
        return openFeintResourceBundleLocation;
    //    return [openFeintResourceBundleLocation stringByAppendingPathComponent:@"gamefeed.bundle"];
    }
    else
    {
        return [[OFWebViewManifestService rootPath] stringByAppendingPathComponent:@"gamefeed"];
    }
}

#pragma mark GameFeedItem creation

- (void)buildItems:(id)itemData
{
    NSMutableArray* returnArray = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray* pendingAds =  [NSMutableArray arrayWithCapacity:10];
    
    for(NSDictionary* gameFeedItemData in itemData)
    {
        OFGameFeedItem* newItem = nil;
        if ([[gameFeedItemData objectForKey:@"type"] isEqualToString:@"ad"])
        {
            newItem = [self createLoadingItem];
            [pendingAds addObject:newItem];
        }
        else
        {
            newItem = [OFGameFeedItem gameFeedItemWithCustom:self.customization itemData:gameFeedItemData
                                           configurationData:self.configuration bundle:[self bundlePath] layouts:self.layouts];
        }

        if(newItem)
        {
            [returnArray addObject:newItem];
            newItem.feedPosition = [returnArray indexOfObject:newItem];
        }
    }
    
    self.feedItems = returnArray;
    
    [OFGameFeedView logEventWithActionKey:@"game_feed_items_shown" parameters:nil];
    
    if ([pendingAds count])
    {
        self.pendingAds = pendingAds;

        NSString* reqURL;
        if ([self forceAdServerError])
        {
            NSString* serverURL = [[[NSURL URLWithString:[[OFSettings instance] getSetting:@"server-url"]] standardizedURL] absoluteString];
            reqURL = [NSString stringWithFormat:@"%@testing/errors/immediate", serverURL];
        }
        else
        {
            NSString* adServerURL = [[[NSURL URLWithString:[[OFSettings instance] getSetting:@"ad-server-url"]] standardizedURL] absoluteString];
            NSString* clientApplicationId = [OpenFeint clientApplicationId];
            NSString* queryString = clientApplicationId ? [NSString stringWithFormat:@"?game_id=%@", clientApplicationId] : @"";
            reqURL = [NSString stringWithFormat:@"%@ads/%d.json%@", adServerURL, [pendingAds count], queryString];
        }
        
        OFASIHTTPRequest* adRequest = [OFASIHTTPRequest requestWithURL:[NSURL URLWithString:reqURL]];
        adRequest.delegate = self;
        [adRequest startAsynchronous];
        [self cancelCurrentADRequest];
        [self setCurrentADRequest:adRequest];
    }
    else
    {
        [OFGameFeedView logEventWithActionKey:@"game_feed_no_ads" parameters:nil];
    }    
}

- (NSSet*) validNibNames
{
    NSArray* validNibs = [[OpenFeint getResourceBundle] pathsForResourcesOfType:@"xib" inDirectory:nil];
    validNibs = [validNibs arrayByAddingObjectsFromArray:[[OpenFeint getResourceBundle] pathsForResourcesOfType:@"nib" inDirectory:nil]];
    NSMutableSet* validNames = [NSMutableSet set];
    for(NSString* path in validNibs)
    {
        NSString* fileName = [path lastPathComponent];
        NSString* noExtension = [[fileName componentsSeparatedByString:@"."] objectAtIndex:0];
        if([noExtension hasPrefix:@"OFGBI"]) 
        {
            [validNames addObject:noExtension];
        }
    }    
    return validNames;    
}

- (void)processConfig:(NSDictionary*)rootConfigutation
{
    NSDictionary* rawConfiguration = [rootConfigutation objectForKey:@"game_feed_config"];
    self.configuration = [self configWithValidNibs:rawConfiguration];

    self.layouts = [rootConfigutation objectForKey:@"game_feed_layouts"];

	NSDictionary* defaultCustomization = [rootConfigutation objectForKey:@"default_customization" ifKindOfClass:[NSDictionary class]];
	[self setupDefaultCustomization:defaultCustomization];
    
    int uploadAnalyticsAfterNumEvents = [[self.customization objectForKey:@"analytics_report_frequency"] intValue];
    if(uploadAnalyticsAfterNumEvents != 0)
    {
        [OpenFeint eventLog].numEventsToUploadAfter = uploadAnalyticsAfterNumEvents;
    }
    
    // ABTesting
    BOOL isInTestGroup = NO;
    BOOL isInControlGroup = NO;
    
    NSDictionary* abTestingSetting = [defaultCustomization objectForKey:@"gamefeed_loading_animation_test_201109"];
    NSString* testStartRatioString = [abTestingSetting objectForKey:@"test_start_ratio"];
    NSString* testEndRatioString = [abTestingSetting objectForKey:@"test_end_ratio"];
    if (testStartRatioString && testEndRatioString)
    {
        float startRatio = [testStartRatioString floatValue];
        float endRatio = [testEndRatioString floatValue];
        isInTestGroup = [OFABTesting isWithinRangeFrom:startRatio to:endRatio];
    }

    NSString* controlStartRatioString = [abTestingSetting objectForKey:@"control_start_ratio"];
    NSString* controlEndRatioString = [abTestingSetting objectForKey:@"control_end_ratio"];
    if (controlStartRatioString && controlEndRatioString)
    {
        float startRatio = [controlStartRatioString floatValue];
        float endRatio = [controlEndRatioString floatValue];
        isInControlGroup = [OFABTesting isWithinRangeFrom:startRatio to:endRatio];
    }

    if (isInTestGroup) {
        NSDictionary* analyticsParams = [NSDictionary dictionaryWithObject:@"test" forKey:@"group"];
       [OFGameFeedView logEventWithActionKey:@"gamefeed_loading_animation_test_201109" parameters:analyticsParams];
    }
    else if(isInControlGroup)
    {
        NSDictionary* analyticsParams = [NSDictionary dictionaryWithObject:@"control" forKey:@"group"];
        [OFGameFeedView logEventWithActionKey:@"gamefeed_loading_animation_test_201109" parameters:analyticsParams];
    }

    if (isInTestGroup != self.useCustomLoading) {
        self.useCustomLoading = isInTestGroup;
        [self createLoadingView];
        if (mDisplay == EGameFeedDisplay_LOADING) {
            [self setDisplay:EGameFeedDisplay_LOADING];
        }
    }
    if (mUseCustomLoading) {
        ((OFGameFeedLoadingView*)self.loadingView).loadingTextArray = [self.customization objectForKey:@"loading_text"];
    }
}

- (void)setupDefaultCustomization:(NSDictionary*)defaultCustomization
{
	// The following values can be looked up in the customization dictionary, but aren't actually
	// customizable by the dev.
	[self.customization setObject:[OFWebViewCacheLoader dpiName] forKey:@"dpi"];
    NSString* serverURL = [[NSURL URLWithString:[[OFSettings instance] getSetting:@"server-url"]] absoluteString];
	[self.customization setObject:serverURL forKey:@"server_url"];
    if ([OpenFeint clientApplicationId])
    {
        [self.customization setObject:[OpenFeint clientApplicationId] forKey:@"game_id"];
    }
	
	// Add the entries from defaultCustomization into self.customization, but only if the entries
	// don't yet exist in self.customization.
    for(NSString* key in defaultCustomization)
    {
		if ([self.customization objectForKey:key] == nil)
		{
			[self.customization setObject:[defaultCustomization objectForKey:key] forKey:key];
		}
	}
}

- (NSMutableDictionary*)configWithValidNibs:(NSDictionary*)config
{
    //first, remove any nibs that aren't in the bundle
    NSSet* validNames = [self validNibNames];
    
    //the valid set of types
    NSMutableDictionary* validTypes = [NSMutableDictionary dictionaryWithCapacity:config.count];
    for(NSString* key in config)
    {
		//for each type, read each config item
		NSMutableArray* validConfigs = [NSMutableArray new];
		NSArray*itemConfig = [config objectForKey:key];

		// Find the latest "min_client_version" from the list of configs that is supported
		NSString* latestItemSupportedVersion = nil;
		for(NSDictionary* config in itemConfig)
		{
			NSString* thisConfigMinVersion = [config objectForKey:@"min_client_version" ifKindOfClass:[NSString class]];
			if (thisConfigMinVersion)
			{
				// If this config's min_client_version is newer latestItemSupportedVersion... 
				if (!latestItemSupportedVersion || [thisConfigMinVersion compareVersionString:latestItemSupportedVersion] == NSOrderedDescending)
				{
					// If this config's min_client_version is one that we support...
					if ([thisConfigMinVersion compareVersionString:[OpenFeint releaseVersionString]] != NSOrderedDescending)
					{
						latestItemSupportedVersion = thisConfigMinVersion;
					}
				}
			}
		}
		// At this point, if any of the configs have "min_client_version" specified, latestItemSupportedVersion is set to the
		// newest one that this client supports, otherwise nil.
		
		for(NSObject* configObj in itemConfig)
		{
			if ([configObj isKindOfClass:[NSMutableDictionary class]])
			{
				NSMutableDictionary* config = (NSMutableDictionary*)configObj;

				BOOL excludeThisConfig = NO;
				NSString* thisConfigMinVersion = [config objectForKey:@"min_client_version" ifKindOfClass:[NSString class]];
				if (thisConfigMinVersion)
				{
					if (!latestItemSupportedVersion || ![thisConfigMinVersion isEqualToString:latestItemSupportedVersion])
					{
						excludeThisConfig = YES;
					}
				}
				else
				{
					// This config is the "base" version.  If we have a newer one that we support, exclude this.
					if (latestItemSupportedVersion)
					{
						excludeThisConfig = YES;
					}
				}
				
				if (!excludeThisConfig)
				{
					//within each item, there's an array of nibs
					NSMutableArray* validNibNames = [NSMutableArray new];
					for(NSString* nibName in [config objectForKey:@"nib"])
					{
						//sadly, I don't think we can trust containsObject....
						BOOL found = NO;
						for(NSString* validNibName in validNames)
						{
							if([validNibName isEqualToString:nibName])
							{
								found = YES;
								break;
							}
						}
						if(found)
						{
							[validNibNames addObject:nibName];
						}
					}
					if(validNibNames.count)
					{
						[config setObject:validNibNames forKey:@"nib"];
						[validConfigs addObject:config];
					}            
					[validNibNames release];
				}
			}
			else
			{
				OFAssert(0, @"Expected an NSMutableDictionary");
			}
        }
        if(validConfigs.count)
        {
            [validTypes setObject:validConfigs forKey:key];
        }
        [validConfigs release];
    }
    return validTypes;
}


-(void)createGameFeedView
{
    CGRect screen = [[UIScreen mainScreen] bounds];
    int screenWidth = screen.size.width;
    int screenHeight = screen.size.height;
    
    int feedHeight = kGameFeedHeightPortrait;
    int feedWidth = 320;
    CGRect badgeRect = CGRectMake(0, 10, 65, 65);
    UIImage* gameFeedBackgroundImage;
    UIImage* badgeIcon = nil;
    self.badgeView = [OFBadgeView redBadge];

    if ([OpenFeint isLargeScreen]) {
        if ([OpenFeint isInLandscapeModeOniPad]) {
             feedWidth = 1024;
        }
        else
        {
            feedWidth = 768;
        }
    }

    if ([OpenFeint isInLandscapeMode]) {
        if (![OpenFeint isLargeScreen]) {
            feedWidth = 480;
        }

        feedHeight = kGameFeedHeightLandscape;
        screenWidth = screen.size.height;
        screenHeight = screen.size.width;
        badgeRect = CGRectMake(0, 5, 57, 57);
        gameFeedBackgroundImage = self.customizeBackgroundImageLandscape;
        if (gameFeedBackgroundImage == nil) {
            if (self.gameFeedAlignment == OFGameFeedAlignment_TOP) {
                gameFeedBackgroundImage = [OFImageLoader loadImage:@"OFGameFeedViewBackgroundTopLandscape.png"];
            }
            else
            {
                gameFeedBackgroundImage = [OFImageLoader loadImage:@"OFGameFeedBackgroundBottomLandscape.png"];
            }
        }
        badgeIcon = [OFImageLoader loadImage:@"OFGameFeedBadgeIconLandscape.png"];
        self.badgeView.frame = CGRectMake(25, 5, 16, 16);
    }
    else
    {
        gameFeedBackgroundImage = self.customizeBackgroundImagePortrait;
        if (gameFeedBackgroundImage == nil) {
            if (self.gameFeedAlignment == OFGameFeedAlignment_TOP) {
                gameFeedBackgroundImage = [OFImageLoader loadImage:@"OFGameFeedViewBackgroundTopPortrait.png"];
            }
            else
            {
                gameFeedBackgroundImage = [OFImageLoader loadImage:@"OFGameFeedBackgroundBottom.png"];
            }
        }
        badgeIcon = [OFImageLoader loadImage:@"OFGameFeedBadgeIcon.png"];
        badgeRect = CGRectMake(0, 7, 65, 65);
        self.badgeView.frame = CGRectMake(35, 5, 16, 16);
    }

    CGRect frame = CGRectMake((screenWidth-feedWidth)/2, screenHeight - feedHeight, feedWidth, feedHeight);
    self.frame = frame;

    // touch view
    OFTouchView* touchView = [[OFTouchView alloc] initWithFrame:CGRectMake(0, 0, feedWidth, feedHeight)];
    [self addSubview:touchView];

    [self createLoadingView];

    mGameFeedScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, feedWidth, feedHeight)];
    [mGameFeedScrollView setDelegate:self];
    [self addSubview:mGameFeedScrollView];
    
    touchView.receiver = mGameFeedScrollView;
    if ([OpenFeint isLargeScreen])
    {
        touchView.forwardSubviewTouches = YES;
    }
    [touchView release];

    self.backgroundColor = [[[UIColor alloc] initWithPatternImage:gameFeedBackgroundImage] autorelease];
    mGameFeedScrollView.backgroundColor = [UIColor clearColor];

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    //mGameFeedScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

    if ([self isLandscapeMode]) {
        if ([OpenFeint isLargeScreen]) {
            if ([OpenFeint isInLandscapeModeOniPad]) {
                mGameFeedScrollView.frame = CGRectMake(65, 0, 304*3+3*3, feedHeight);
            }
            else
            {
                mGameFeedScrollView.frame = CGRectMake(65, 0, 304*2+3*2, feedHeight);
            }
        }
        else
        {
            mGameFeedScrollView.frame = CGRectMake(65, 0, 304+3, feedHeight);
        }
    }
    else
    {
         mGameFeedScrollView.frame = CGRectMake(65, 0, 229+3, feedHeight);
    }

    mGameFeedScrollView.pagingEnabled = YES;
    mGameFeedScrollView.clipsToBounds = NO;
    mGameFeedScrollView.showsHorizontalScrollIndicator = NO;
    mGameFeedScrollView.decelerationRate = 1.0;
    mGameFeedScrollView.delaysContentTouches = NO;
    mGameFeedScrollView.alwaysBounceHorizontal = YES;

    self.badgeTouchView = [[[OFTouchView alloc] initWithFrame:badgeRect] autorelease];
    [self insertSubview:self.badgeTouchView belowSubview:mGameFeedScrollView];

    CGRect badgeViewFrame = self.badgeView.frame;
    if ([self isLandscapeMode]) {
        badgeViewFrame.origin.x -= 65;
        badgeRect.origin.x -= 65;
    }
    else
    {
         badgeViewFrame.origin.x -= 65;
         badgeRect.origin.x -= 65;
    }

    self.badgeView.frame = badgeViewFrame;

    UIButton* badgeButton = [[[UIButton alloc] initWithFrame:badgeRect] autorelease];
	[badgeButton setBackgroundImage:badgeIcon forState:UIControlStateNormal];
    
    
    [badgeButton addTarget:self action:@selector(onLaunchDashboard:) forControlEvents:UIControlEventTouchUpInside];
    [mGameFeedScrollView addSubview:badgeButton];
    self.badgeButton = badgeButton;

    [self.badgeView setValue:[OFCurrentUser OpenFeintBadgeCount]];
    [mGameFeedScrollView addSubview:self.badgeView];
    self.badgeTouchView.receiver = self.badgeButton;
 
    [mGameFeedScrollView addSubview:self.badgeButton];
    [mGameFeedScrollView addSubview:self.badgeView];
}

- (void)createLoadingView
{
    if (self.loadingView) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
    }

    if (!mUseCustomLoading) {
        UIActivityIndicatorView* loadingSpinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        loadingSpinner.center = CGPointMake(self.frame.size.width/2 + kLoadingSpinnerOffsetX, self.frame.size.height/2);
        [loadingSpinner startAnimating];
        UILabel* loadingLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + kLoadingTextOffsetX, self.frame.size.height/2 + kLoadingTextOffsetY, 200, 60)] autorelease];
        loadingLabel.backgroundColor = [UIColor clearColor];
        loadingLabel.font = [UIFont fontWithName:@"Helvetica" size:12.f];
        loadingLabel.textColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1.0f];
        loadingLabel.text = @"Loading GameFeed";
        
        self.loadingView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)] autorelease];
        self.loadingView.userInteractionEnabled = NO;
        [self.loadingView addSubview:loadingSpinner];
        [self.loadingView addSubview:loadingLabel];
    }
    else
    {
        OFGameFeedLoadingView* loadingView = [[[OFGameFeedLoadingView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)] autorelease];
        loadingView.loadingTextArray = [self.customization objectForKey:@"loading_text"];
        self.loadingView = loadingView;
    }

}

- (void)onLaunchDashboard:(id)sender
{
    [OFGameFeedView logEventWithActionKey:@"leaf_item_clicked" parameters:nil];
    
    [OpenFeint launchDashboard];
}

- (void)setFeedItems:(NSMutableArray *)feedItems
{
    if (mFeedItems == feedItems) {
        return;
    }
    if (mFeedItems) {
        for(OFGameFeedItem* item in mFeedItems)
        {
            [item removeFromSuperview];
        }
        OFSafeRelease(mFeedItems);
    }
    mFeedItems = [feedItems retain];
    [self setDisplay:EGameFeedDisplay_FEED_ITEMS];
}

- (void)layoutFeedItems
{
    int startx = self.badgeView.frame.origin.x + self.badgeView.frame.size.width;
    int starty = 4;
    int space = 3;

    if(mFeedItems == nil)
        return;
    
    int numFeedItems = [mFeedItems count];
    for (int i = 0; i < numFeedItems; ++i)
    {
        OFGameFeedItem* item = [mFeedItems objectAtIndex:i];
        item.feedPosition = i;
        
        CGRect frame = item.frame;
        frame.origin.x = startx;
        frame.origin.y = starty;
        
        item.frame = frame;
        
        item.contentMode = UIViewContentModeCenter;
        
        [mGameFeedScrollView addSubview:item];
        startx += frame.size.width + space;
    }
    if(startx < mGameFeedScrollView.frame.size.width)
    {
        startx = mGameFeedScrollView.frame.size.width;
    }

    int feedHeight = ([self isLandscapeMode] ? kGameFeedHeightLandscape : kGameFeedHeightPortrait);
    mGameFeedScrollView.contentSize = CGSizeMake(startx, feedHeight);

    [self checkItemVisibility];
}

- (OFGameFeedItem*)createLoadingItem
{
    return (OFGameFeedItem*)[[OFControllerLoaderObjC loader] loadView:@"OFGBILoading"];
}

- (void)removeLoadingView
{
    if(self.loadingView)
    {
        [self.loadingView removeFromSuperview];
    }
}

- (void)badgeCountChanged
{
    [self.badgeView setValue:[OFCurrentUser OpenFeintBadgeCount]];
}

#pragma mark -
#pragma mark Positioning and animation

- (CGAffineTransform)calculateTransformFromViewToGameFeedViewOrientation:(UIView*)_view
{
    CGAffineTransform ofTransform = [UIView transformToInterfaceOrientation:mOrientation];
    CGAffineTransform viewTransform = [_view calculateViewTransformFromMainScreen];
    CGAffineTransform viewTransformInv = CGAffineTransformInvert(viewTransform);
    CGAffineTransform transform = CGAffineTransformConcat(viewTransformInv, ofTransform);
    return transform;
}

- (void)moveViewIntoPlace
{
    if (self.gameFeedAlignment == OFGameFeedAlignment_CUSTOM)
    {
        return;
    }
    
    CGAffineTransform viewToOFTransform = [self calculateTransformFromViewToGameFeedViewOrientation:self.superview];
    CGSize superviewSizeInDashboardOrientation = CGSizeApplyAffineTransform(self.superview.bounds.size, viewToOFTransform);
    superviewSizeInDashboardOrientation.width = abs(superviewSizeInDashboardOrientation.width);
    superviewSizeInDashboardOrientation.height = abs(superviewSizeInDashboardOrientation.height);

    int feedHeight = ([self isLandscapeMode] ? kGameFeedHeightLandscape : kGameFeedHeightPortrait);
    int feedWidth = superviewSizeInDashboardOrientation.width;
    
    CGRect newFrame;    
    if (self.gameFeedAlignment == OFGameFeedAlignment_TOP)
    {
        newFrame = CGRectMake(0, 0, feedWidth, feedHeight);
    }
    else if (self.gameFeedAlignment == OFGameFeedAlignment_BOTTOM)
    {
        newFrame = CGRectMake(0, superviewSizeInDashboardOrientation.height-feedHeight, feedWidth, feedHeight);
    }
    CGAffineTransform withoutTranslation = viewToOFTransform;
    withoutTranslation.tx = 0;
    withoutTranslation.ty = 0;
    if (CGAffineTransformIsIdentity(withoutTranslation))
    {
        self.transform = CGAffineTransformIdentity;
        self.frame = newFrame;
    }
    else
    {
        CGPoint center = CGPointMake(newFrame.origin.x + newFrame.size.width*0.5f , newFrame.origin.y + newFrame.size.height*0.5f);
        CGPoint transformedCenter = CGPointApplyAffineTransform(center, viewToOFTransform);
        self.transform = viewToOFTransform;
        self.center = transformedCenter;
        self.bounds = CGRectMake(0, 0, newFrame.size.width, newFrame.size.height);
    }
}

-(void)moveViewOffscreen
{
    if (self.gameFeedAlignment == OFGameFeedAlignment_CUSTOM)
    {
        return;
    }
    
    CGAffineTransform viewToOFTransform = [self calculateTransformFromViewToGameFeedViewOrientation:self.superview];
    CGSize superviewSizeInDashboardOrientation = CGSizeApplyAffineTransform(self.superview.bounds.size, viewToOFTransform);
    superviewSizeInDashboardOrientation.width = abs(superviewSizeInDashboardOrientation.width);
    superviewSizeInDashboardOrientation.height = abs(superviewSizeInDashboardOrientation.height);

    int feedHeight = ([self isLandscapeMode] ? kGameFeedHeightLandscape : kGameFeedHeightPortrait);
    int feedWidth = superviewSizeInDashboardOrientation.width;
    
    CGRect newFrame;    
    if (self.gameFeedAlignment == OFGameFeedAlignment_TOP)
    {
        newFrame = CGRectMake(0, -feedHeight, feedWidth, feedHeight);
    }
    else if (self.gameFeedAlignment == OFGameFeedAlignment_BOTTOM)
    {
        newFrame = CGRectMake(0, superviewSizeInDashboardOrientation.height, feedWidth, feedHeight);
    }

    CGAffineTransform withoutTranslation = viewToOFTransform;
    withoutTranslation.tx = 0;
    withoutTranslation.ty = 0;
    if (CGAffineTransformIsIdentity(withoutTranslation))
    {
        self.transform = CGAffineTransformIdentity;
        self.frame = newFrame;
    }
    else
    {
        CGPoint center = CGPointMake(newFrame.origin.x + newFrame.size.width*0.5f , newFrame.origin.y + newFrame.size.height*0.5f);
        CGPoint transformedCenter = CGPointApplyAffineTransform(center, viewToOFTransform);
        self.transform = viewToOFTransform;
        self.center = transformedCenter;
        self.bounds = CGRectMake(0, 0, newFrame.size.width, newFrame.size.height);
    }
 }

-(void)animateIn
{
    if (self.gameFeedAlignment == OFGameFeedAlignment_CUSTOM)
    {
        return;
    }
    
    [self moveViewOffscreen];
    
    [UIView beginAnimations:@"OFGameBarViewPositioning" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    [self moveViewIntoPlace];
    
    [UIView commitAnimations];
}

- (void)animateOutDone
{
    [self removeFromSuperview];
}

-(void)animateOutAndRemoveFromSuperview
{
    if (self.gameFeedAlignment == OFGameFeedAlignment_CUSTOM)
    {
        [self removeFromSuperview];
        return;
    }
    
    [self cancelCurrentFeedRequest];
    [self cancelCurrentADRequest];
    [self moveViewIntoPlace];
    
    [UIView beginAnimations:@"OFGameBarViewPositioning" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animateOutDone)];
    
    [self moveViewOffscreen];
    
    [UIView commitAnimations];
}

- (void)setOrientation:(UIInterfaceOrientation)orientation
{
    if (self.isLandscapeMode == [OpenFeint isInLandscapeMode])
    {
        mOrientation = orientation;
        [self moveViewIntoPlace];
    }
    else
    {
        // If this view was created in landscape mode, and the game switched to portrait, or vice versa, leave it where it is.
        OFLogDevelopment(@"GameFeed will not rotate from landscape to portrait or vice versa.  If you want this to work, you must recreate the game feed view.");
    }
}

#pragma mark UIScrollViewDelegate

- (BOOL)scrollViewIsVisible
{
    if (!mGameFeedScrollView.window.keyWindow) return NO;
    
    for (UIView* v = mGameFeedScrollView; v; v = [v superview]) {
        if (v.hidden) {
            return NO;
        }
    }
    
    return YES;
}

- (void)dashboardDisappearing
{
    for (OFGameFeedItem* item in mFeedItems)
    {
        item.isVisible = NO;
    }

    [self checkItemVisibility];
}

- (void)approvalScreenDidAppear
{
    self.hidden = YES;
}

- (void)approvalScreenDidDisappear
{
    self.hidden = NO;
}

- (void)applicationDidBecomeActive
{
    for (OFGameFeedItem* item in mFeedItems)
    {
        item.isVisible = NO;
    }
    
    [self checkItemVisibility];
}

- (void)checkItemVisibility
{
    // check to ensure we're actually visible.
    if (![self scrollViewIsVisible]) return;

    UIWindow* window = mGameFeedScrollView.window;
    CGRect windowBounds = [window bounds];
    for (OFGameFeedItem* item in mFeedItems)
    {
        CGRect rectInViewport = [item convertRect:item.bounds toView:window];
        BOOL newVisible = CGRectContainsRect(windowBounds, rectInViewport);

        if (item.isVisible && !newVisible)
        {
            item.isVisible = NO;
        }
        else if (!item.isVisible && newVisible)
        {
            item.isVisible = YES;
            NSDictionary* params = [item analyticsParams];
            if (params)
            {
                [OFGameFeedView logEventWithActionKey:@"feed_item_show" parameters:params];
                [item wasShown];
            }
        }


        BOOL partlyVisible = CGRectIntersectsRect(windowBounds, rectInViewport);
        if (partlyVisible)
        {
            // For lazy loading.  This will tell the item to load if it hasn't yet.
            [item wasPartlyShown];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetx = scrollView.contentOffset.x;
    if (offsetx < 65) {
        self.badgeTouchView.receiver = self.badgeButton;

        if (mGameFeedScrollView.frame.origin.x < 65 || ([self isLandscapeMode] && fabs(mGameFeedScrollView.frame.origin.x - 86) < 0.1)) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.3];
            CGRect frame = mGameFeedScrollView.frame;
            frame.origin.x = 65;
            mGameFeedScrollView.frame = frame;
            [UIView commitAnimations];
        }

    }
    else
    {
        self.badgeTouchView.receiver = nil;

        if ([mFeedItems count] > 1 && fabs(mGameFeedScrollView.frame.origin.x - 65) < 0.1) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.3];
            CGRect frame = mGameFeedScrollView.frame;
            if ([self isLandscapeMode]) {
                frame.origin.x = 86;
            }
            else
                frame.origin.x = 44;
            mGameFeedScrollView.frame = frame;
            [UIView commitAnimations];
        }
    }

    if (scrollView == mGameFeedScrollView)
    {
        [self checkItemVisibility];
    }
}

#pragma mark -
#pragma mark UIView

- (void)willMoveToWindow:(UIWindow *)window
{
    if (!window.keyWindow)
    {
        NSDictionary* analyticsParams = nil;
        if (self.showStartDate)
        {
            NSDate* now = [NSDate date];
            double duration = [now timeIntervalSinceDate:self.showStartDate];
                analyticsParams = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:duration] forKey:@"duration"];
                self.showStartDate = nil;
        }
        
        [OFGameFeedView logEventWithActionKey:@"game_feed_end" parameters:analyticsParams];
        
        // Now's a good time to upload!
        [[OpenFeint eventLog] upload];
    }
}

- (void)didMoveToWindow
{
    if (self.superview && self.window)
    {        
        if (self.animateInWhenBecomesVisible)
        {
            [self animateIn];
        }
        else
        {
            [self moveViewIntoPlace];
        }
        self.loadStartDate = [NSDate date];
        [OFGameFeedView logEventWithActionKey:@"game_feed_begin" parameters:nil];
        
        [self checkItemVisibility];
    }
}

#pragma mark -
#pragma mark OFASIHTTPRequestDelegate

- (void)adResponseSuccess:(OFASIHTTPRequest *)request
{
    // holy yes.
    id response = [OFJsonCoder decodeJson:[request responseString]];
    NSMutableArray* remainingAds = [NSMutableArray arrayWithArray:[response objectForKey:@"ads"]];
    for (OFGameFeedItem* loadingItem in self.pendingAds)
    {
        // Make sure the loading item from pendingAds is actually IN the feed, otherwise this is pointless.
        if (![mFeedItems containsObject:loadingItem])
        {
            continue;
        }
        BOOL needToRemoveLoadingItem = YES;
        int feedPosition = [mFeedItems indexOfObject:loadingItem];
        
        // Make an ad if possible.
        OFGameFeedItem* ad = nil;
        while (!ad && [remainingAds count] > 0)
        {
            // pop an ad, and try to build an item out of it.
            NSDictionary* adConfig = [remainingAds objectAtIndex:0];
            [remainingAds removeObjectAtIndex:0];
            
            ad = [OFGameFeedItem gameFeedItemWithCustom:self.customization itemData:adConfig
                                      configurationData:self.configuration bundle:[self bundlePath] layouts:self.layouts];
        }
        
        // If we successfully created an ad item:
        if (ad)
        {
            if (loadingItem.fadeInTimer.isValid)
            {
                [ad fadeInAtDate:loadingItem.fadeInTimer.fireDate doneInvocation:nil];
            }
            else
            {
                // This will remove loadingItem from its superview once this item fades in over it.
                [ad fadeInAfterSeconds:0.0f doneInvocation:nil replacingItem:loadingItem];
                needToRemoveLoadingItem = NO;
            }
            // Swap it into the feed.
            [mFeedItems replaceObjectAtIndex:feedPosition withObject:ad];
        }
        else
        {
            // Otherwise, all we can do is remove the loading item.
            [mFeedItems removeObjectAtIndex:feedPosition];
        }
        
        if (needToRemoveLoadingItem)
        {
            // Since loadingItem is going to get removed from mFeedItems one way or the other, layoutFeedItems
            // won't know about it to remove it from its superview - so we remove it manually here.
            [loadingItem removeFromSuperview];
        }
    }

    // Clear the pending ads, since we've rendered them.
    self.pendingAds = nil;
    
    // This will reset the items in the view, and adjust the scroll view to the right size.
    [self setDisplay:EGameFeedDisplay_FEED_ITEMS];

    NSDictionary* analyticsParams = nil;
    if (self.loadStartDate)
    {
        NSDate* now = [NSDate date];
        double duration = [now timeIntervalSinceDate:self.loadStartDate];
        analyticsParams = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:duration] forKey:@"duration"];
        self.loadStartDate = nil;
        self.showStartDate = now;
    }

    [OFGameFeedView logEventWithActionKey:@"game_feed_ads_shown" parameters:analyticsParams];
}

- (void)adResponseFailure
{
    for (OFGameFeedItem* item in self.pendingAds)
    {
        [item removeFromSuperview];
        [mFeedItems removeObject:item];
    }
    
    self.pendingAds = nil;
    
    // This will reset the items in the view, and adjust the scroll view to the right size.
    [self setDisplay:EGameFeedDisplay_FEED_ITEMS];

    [OFGameFeedView logEventWithActionKey:@"game_feed_ads_load_failed" parameters:nil];
}

- (void)requestFinished:(OFASIHTTPRequest *)request
{
    [self setCurrentADRequest:nil];
    int responseCode = [request responseStatusCode];
    if (responseCode >= 200 && responseCode <= 299)
    {
        [self adResponseSuccess:request];
    }
    else
    {
        [self adResponseFailure];
    }
}

- (void)requestFailed:(OFASIHTTPRequest *)request
{
    [self adResponseFailure];
}

#pragma mark -
#pragma mark request release helper
- (void)cancelCurrentADRequest
{
    if (mCurrentADRequest) {
        mCurrentADRequest.delegate = nil;
        [mCurrentADRequest cancel];
        self.currentADRequest = nil;
    }
    [self.currentRequest cancel];
    self.currentRequest = nil;
}

- (void)cancelCurrentFeedRequest
{
    if (self.currentRequest) {
        [self.currentRequest cancel];
        self.currentRequest = nil;
    }
}


@end
