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

#import "OFGameFeedDashboardAnalyticsListener.h"
#import "OFGameFeedItem.h"
#import "OpenFeint+NSNotification.h"
#import "OFGameFeedView+Private.h"
#import "OpenFeint+NSNotification+Private.h"
#import "OpenFeint+EventLog.h"

@interface OFGameFeedDashboardAnalyticsListener()
@property (nonatomic, retain) NSDictionary* analyticsParams;
@property (nonatomic, assign) BOOL listeningForLogin;
@property (nonatomic, retain) NSDate* startDate;
@end

@implementation OFGameFeedDashboardAnalyticsListener
@synthesize analyticsParams, listeningForLogin, startDate;

+ (OFGameFeedDashboardAnalyticsListener*)listenWithParams:(NSDictionary*)analyticsParams;
{
    // Don't autorelease, because NSNotificationCenter won't retain the observer.
    // When we're done listening, we'll [self release].
    
    OFGameFeedDashboardAnalyticsListener* rv = [[self alloc] init];
    rv.analyticsParams = analyticsParams;
    
    return rv;
}

- (id)init
{
    [super init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dashboardWillAppear:) name:OFNSNotificationDashboardWillAppear object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dashboardWillDisappear:) name:OFNSNotificationDashboardWillDisappear object:nil];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark OFURLDispatcherObserver

- (void) dispatcher:(OFURLDispatcher*)dispatcher willDispatchAction:(NSString*)name withParams:(NSDictionary*)params
{
    // @TODO this is sorta tightly coupled to OFURLDispatcher's action map.  It would be nice if we had a persistent
    // aspect-oriented analytics logger, but this will do for now.
    
    if ([@"login" isEqualToString:name])
    {
        self.listeningForLogin = YES;
    }
    else if ([@"dashboardPage" isEqualToString:name])
    {
        self.listeningForLogin = NO;
    }
    else
    {
        // They're performing an action that we don't actually care about.
        // Time to die.
        [self release];
    }
}

- (void) dispatcher:(OFURLDispatcher*)dispatcher wontDispatchAction:(NSURL*)actionURL
{
    // This is not an action, so we should go away.
    [self release];
}


#pragma mark NSNotification handlers

- (void)dashboardWillAppear:(NSNotification*)notification
{
    if (!self.listeningForLogin)
    {
        self.startDate = [NSDate date];
        [OFGameFeedView logEventWithActionKey:@"dashboard_start" parameters:self.analyticsParams];
    }
}

- (void)dashboardWillDisappear:(NSNotification*)notification
{
    if (!self.listeningForLogin)
    {
        double duration = [[NSDate date] timeIntervalSinceDate:self.startDate];
        NSMutableDictionary* newParams = [NSMutableDictionary dictionaryWithDictionary:self.analyticsParams];
        [newParams setObject:[NSNumber numberWithDouble:duration] forKey:@"duration"];
        [OFGameFeedView logEventWithActionKey:@"dashboard_end" parameters:newParams];
    }
    
    // We're done observing
    [self release];
}

@end
