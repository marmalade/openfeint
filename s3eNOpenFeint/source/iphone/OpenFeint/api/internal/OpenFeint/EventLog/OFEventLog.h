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

@class OFEncryptedFile;

@protocol OFEventObserver;

@interface OFEventLog : NSObject
{
	NSString* name;
	NSMutableArray* pendingEvents;
	NSArray* sentEvents;
	OFEncryptedFile* diskStore;
	NSMutableArray* observers;
    BOOL applicationTerminating;
}

- (id)initWithName:(NSString*)logName;
+ (id)eventLog:(NSString*)logName;
+ (void)setVerboseConsoleLoggingEnabled:(BOOL)enabled;
+ (BOOL)verboseConsoleLoggingEnabled;

// weak reference
- (void)addObserver:(id<OFEventObserver>)observer;

- (void)logEventNamed:(NSString*)eventName parameters:(NSDictionary*)parameters;
- (void)logEventNamed:(NSString*)eventName logName:(NSString*)logName parameters:(NSDictionary*)parameters;
- (void)logEventWithActionKey:(NSString*)actionKey parameters:(NSDictionary*)parameters;
- (void)logEventWithActionKey:(NSString*)actionKey logName:(NSString*)logName parameters:(NSDictionary*)parameters;

- (void)serializeToDisk;
- (void)upload;

@end

@protocol OFEventObserver<NSObject>
@optional
// invoked whenever an event is being logged to allow injection of additional parameters
- (void)eventLog:(OFEventLog*)log willLogEvent:(NSString*)eventName parameters:(NSMutableDictionary*)parameters;
@end
