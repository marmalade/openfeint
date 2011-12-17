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

#import "OFEventLogObserver.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+UserStats.h"
#import "OpenFeint+Private.h"
#import "OFReachability.h"
#import "IPhoneOSIntrospection.h"
#import "OpenFeint+EventLog.h"
#import "OFSessionInfo.h"

@implementation OFEventLogObserver

- (id)init
{
    [super init];
    
    // This class also serves the dual purpose of serializing/uploading the event log.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    BOOL isForegroundNotificationPresent = (&UIApplicationWillEnterForegroundNotification != NULL);
    if (isForegroundNotificationPresent)
    {
        [[NSNotificationCenter defaultCenter]	addObserver:self
                                                 selector:@selector(applicationWillEnterForegroundNotification)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter]	addObserver:self
                                                 selector:@selector(applicationDidEnterBackgroundNotification)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    [OFReachability addObserver:self];

    return self;
}

- (void)dealloc
{
    [OFReachability removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

// invoked whenever an event is being logged to allow injection of additional parameters
- (void)eventLog:(OFEventLog*)log willLogEvent:(NSString*)eventName parameters:(NSMutableDictionary*)parameters
{
	[parameters setObject:[OFSessionInfo sharedInstance].sessionId forKey:@"session_id"];
    [parameters setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:[OFSessionInfo sharedInstance].sessionStartDate]] forKey:@"session_length"];
	[parameters setObject:[NSNumber numberWithDouble:[OpenFeint sessionPlayTime]] forKey:@"session_play_time"];
	[parameters setObject:[OpenFeint gameSpecificDeviceIdentifier] forKey:@"gsdi"];
    if ([OpenFeint lastLoggedInUserId])
    {
        [parameters setObject:[OpenFeint lastLoggedInUserId] forKey:@"user_id"];
    }
}

- (void)reachabilityChangedFrom:(OFReachabilityStatus)oldStatus to:(OFReachabilityStatus)newStatus
{
	if (newStatus != OFReachability_Not_Connected && oldStatus == OFReachability_Not_Connected)
		[[OpenFeint eventLog] upload];
}

- (void)applicationWillEnterForegroundNotification
{
    [[OpenFeint eventLog] logEventWithActionKey:@"game_foreground" logName:@"client_sdk" parameters:nil];
	if ([OFReachability isConnectedToInternet])
		[[OpenFeint eventLog] upload];
}

- (void)applicationDidEnterBackgroundNotification
{
    [[OpenFeint eventLog] logEventWithActionKey:@"game_background" logName:@"client_sdk" parameters:nil];
    [[OpenFeint eventLog] serializeToDisk];
}

- (void)applicationWillResignActive
{
    [[OpenFeint eventLog] serializeToDisk];
}

- (void)applicationWillTerminate
{
    [[OpenFeint eventLog] logEventWithActionKey:@"game_exit" logName:@"client_sdk" parameters:nil];    
    [[OpenFeint eventLog] serializeToDisk];
}

@end
