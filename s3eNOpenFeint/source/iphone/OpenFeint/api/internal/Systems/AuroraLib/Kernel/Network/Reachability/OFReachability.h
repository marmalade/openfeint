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

#pragma once

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

typedef enum 
{
	OFReachability_Not_Connected = 0,
	OFReachability_Connected_WiFi,
	OFReachability_Connected_Carrier,
	OFReachability_Unknown
} OFReachabilityStatus;

@protocol OFReachabilityObserver
- (void)reachabilityChangedFrom:(OFReachabilityStatus)oldStatus to:(OFReachabilityStatus)newStatus;
@end

@interface OFReachability : NSObject
{
	SCNetworkReachabilityRef reachability;
	OFReachabilityStatus status;
	NSMutableArray* observers;
    BOOL iteratingObservers;
}

+ (void)initializeReachability;
+ (void)shutdownReachability;

+ (void)addObserver:(id)reachabilityObserver;
+ (void)removeObserver:(id)reachabilityObserver;

+ (OFReachabilityStatus)reachability;
+ (BOOL)isConnectedToInternet;

@end
