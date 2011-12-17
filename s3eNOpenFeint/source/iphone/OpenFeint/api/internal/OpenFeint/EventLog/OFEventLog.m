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

#import "OFEventLog.h"

#import "OFEncryptedFile.h"
#import "OFResourceRequest.h"
#import "OFJsonCoder.h"
#import "OFSettings.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserStats.h"
#import "OpenFeint+UserOptions.h"
#import "IPhoneOSIntrospection.h"
#import "OFTimeIntervalEncoder.h"
#import "OFDependencies.h"

@interface OFEventLog ()
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSMutableArray* pendingEvents;
@property (nonatomic, retain) NSArray* sentEvents;
@property (nonatomic, retain) OFEncryptedFile* diskStore;
@property (nonatomic, retain) NSMutableArray* observers;
@end

@implementation OFEventLog

@synthesize name;
@synthesize pendingEvents;
@synthesize sentEvents;
@synthesize diskStore;
@synthesize observers;

#pragma mark Life-cycle

static BOOL gVerboseConsoleLoggingEnabled = NO;

#define OFEventLogVerbose(message,...)            if (gVerboseConsoleLoggingEnabled) OFLogVerbose(message, ##__VA_ARGS__)
#define OFEventLogSimplified(message,...)         if (!gVerboseConsoleLoggingEnabled) OFLogVerbose(message, ##__VA_ARGS__)

+ (id)eventLog:(NSString*)logName;
{
	return [[[OFEventLog alloc] initWithName:logName] autorelease];
}

+ (void)setVerboseConsoleLoggingEnabled:(BOOL)enabled
{
    gVerboseConsoleLoggingEnabled = enabled;
}

+ (BOOL)verboseConsoleLoggingEnabled
{
    return gVerboseConsoleLoggingEnabled;
}

- (id)initWithName:(NSString*)logName
{
	self = [super init];
	if (self != nil)
	{
		self.name = logName;
		self.diskStore = [OFEncryptedFile encryptedFileWithFilename:[NSString stringWithFormat:@"log_%@", logName]];
		self.pendingEvents = [OFJsonCoder decodeJsonFromData:diskStore.plaintext];
		if (!pendingEvents)
			self.pendingEvents = [NSMutableArray arrayWithCapacity:50];
		self.observers = [NSMutableArray arrayWithCapacity:1];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	self.name = nil;
	self.pendingEvents = nil;
	self.sentEvents = nil;
	self.diskStore = nil;
	self.observers = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark Public Interface

- (void)addObserver:(id<OFEventObserver>)observer
{
	if ([observer respondsToSelector:@selector(eventLog:willLogEvent:parameters:)])
		[observers addObject:[NSValue valueWithNonretainedObject:observer]];
}

- (void)logEventWithActionKey:(NSString*)actionKey parameters:(NSDictionary*)parameters
{
    [self logEventWithActionKey:actionKey logName:name parameters:parameters];
}

- (void)logEventWithActionKey:(NSString*)actionKey logName:(NSString*)logName parameters:(NSDictionary*)parameters
{
	OFEventLogVerbose(@"EventLog: Logging event with action key %@.", actionKey);
    OFEventLogSimplified(@"EventLog: %@", actionKey);
    NSMutableDictionary* mergedParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [mergedParameters setObject:actionKey forKey:@"action"];
    [self logEventNamed:@"event" logName:logName parameters:mergedParameters];
}

- (void)logEventNamed:(NSString*)eventName parameters:(NSDictionary*)parameters
{
    [self logEventNamed:eventName logName:name parameters:parameters];
}

- (void)logEventNamed:(NSString*)eventName logName:(NSString*)logName parameters:(NSDictionary*)parameters
{
	OFEventLogVerbose(@"EventLog: Logging event named %@.", eventName);
	NSMutableDictionary* eventParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    // Add in a timestamp, so we can calculate time_interval on upload.
    [OFTimeIntervalEncoder addTimestampToDictionary:eventParameters];

	// allow observers to inject parameters
	for (NSValue* o in observers)
		[[o nonretainedObjectValue] eventLog:self willLogEvent:eventName parameters:eventParameters];

	NSDictionary* event = [NSDictionary 
		dictionaryWithObject:[NSDictionary dictionaryWithObject:eventParameters forKey:eventName]
		forKey:logName];
	OFEventLogVerbose(@"EventLog: Event: %@", event);
	[pendingEvents addObject:event];
}

- (void)serializeToDisk
{
	OFEventLogVerbose(@"EventLog: Serializing event log '%@'.", name);
	self.diskStore.plaintext = [OFJsonCoder encodeObjectToData:pendingEvents];
}

- (void)upload
{
	// already uploading
	if (sentEvents != nil)
		return;
	
	// nothing to post
	if (![pendingEvents count])
		return;

    // can't make a server request now
    if (applicationTerminating)
		return;
		
	OFEventLogVerbose(@"EventLog: Uploading event log '%@' with %d events.", name, [pendingEvents count]);

	self.sentEvents = self.pendingEvents;
	self.pendingEvents = [NSMutableArray arrayWithCapacity:50];
	
	// static info
	NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
		getHardwareVersion(), @"hardware",
		[OpenFeint clientApplicationId], @"client_application_id",
		[OFSettings instance].clientBundleVersion, @"version",        
        [NSNumber numberWithInteger:[OpenFeint versionNumber]], @"of_version",
        [UIDevice currentDevice].systemVersion, @"os_version",
		@"ios", @"platform",
		[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], @"country",
		nil];

	NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:
		[OFJsonCoder encodeObject:info], @"info",
		[OFTimeIntervalEncoder encodeObject:sentEvents], @"event", 
		nil];

	OFResourceRequest* request = [OFResourceRequest postRequestWithPath:@"xp/events" andBody:body];
	request.requiresDeviceSession = NO;
	request.requiresUserSession = NO;
	[[request onRespondTarget:self selector:@selector(uploadResponse:)] execute];
}

- (void)uploadResponse:(OFResourceRequest*)request
{
	OFEventLogVerbose(@"EventLog: Uploading event log '%@' finished with response %d.", name, request.httpResponseCode);
	
	if (request.httpResponseCode < 200 || request.httpResponseCode >= 300)
		[pendingEvents addObjectsFromArray:sentEvents];

	self.sentEvents = nil;
}

- (void)applicationWillTerminate
{
    applicationTerminating = YES;
}

@end
