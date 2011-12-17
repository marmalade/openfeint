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

#import "OpenFeint.h"
#import "OpenFeint+Dashboard.h"
#import "OpenFeint+Private.h"
#import "OFWebUIDashboardController.h"
#import "OFLog.h"
#import "OFSession.h"

@interface NSString (capitalized)
-(NSString*)capitalized;
@end

#pragma mark Private Interface

@interface OFWebUIDashboardController (Internal)
@end

@implementation OFWebUIDashboardController

#pragma mark Initialization and Dealloc
// invoked from TabbedDashboardPageController
-(id)init {
    if ( (self = [super init]) ) {
        [self initWithPath:nil];
    }
    return self;
}

- (id)initWithRootPage:(NSString*)_rootPage andPath:(NSString*)_initialPath {
    if ((self = [super initWithRootPage:_rootPage andPath:_initialPath])) {
        NSArray *actions = [NSArray arrayWithObjects:
            @"dashboard",
            @"introFlow",
            @"profilePicture",
            @"logout",
            nil
        ];
        for (NSString *action in actions) {
            SEL selector = NSSelectorFromString([NSString stringWithFormat:@"action%@:", [action capitalized]]);
            if ([self respondsToSelector:selector]) {
                [self mapAction:action toSelector:selector];
            } else {
                OFLog(@"%@ not implemented", action);
            }
        }
    }
    return self;
}

- (NSString*)initialPath {
    BOOL online  = [OFReachability isConnectedToInternet];
    if (online) {
        return @"dashboard/user";
    } else {
        return @"game_channel/offline";
    }
}


- (void)dealloc
{
    [super dealloc];
}

#pragma mark actions
- (void)actionDashboard:(NSDictionary *)options {
    [OpenFeint launchDashboard];
}

- (void)actionIntroFlow:(NSDictionary *)options {
    [OpenFeint launchDashboardWithSwitchUserPage];
}

- (void)actionProfilePicture:(NSDictionary *)options {
    [OpenFeint launchDashboardWithSelectProfilePicturePage];
}

- (void)actionLogout:(NSDictionary *)options {
    [[OpenFeint session] logoutUser];
    [OpenFeint dismissDashboard];
}

#pragma mark OFBannerProvider
- (BOOL)isBannerAvailableNow {
    return NO;
}
- (NSString*)bannerCellControllerName {
    return nil;
}
- (OFResource*)getBannerResource {
    return nil;
}
- (void)onBannerClicked {
    
}

@end

@implementation NSString (capitalized)
-(NSString*)capitalized {
	int n = [self length] + 1;
	char *bf = (char*)malloc(n);
	[self getCString:bf maxLength:n encoding:NSASCIIStringEncoding];
	bf[0] = toupper(bf[0]);
	NSString *capitalized = [NSString stringWithCString:bf encoding:NSASCIIStringEncoding];
	free(bf);
	return capitalized;
}
@end
