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

#import "OFKeychainWrapper.h"
#import <Security/Security.h>
#import "OFDependencies.h"
#import "OFSettings.h"

static NSData* magicData = nil;

#if TARGET_IPHONE_SIMULATOR
static NSMutableDictionary* simulatorKeychain = nil;
#endif

@interface OFKeychainWrapper ()
- (id)initWithIdentifier:(NSString*)identifier;
- (void)_setDataNoSave:(NSData*)data;
- (void)_loadKeychainData;
- (void)_saveKeychainData;
@end

@implementation OFKeychainWrapper

@synthesize identifier;
@synthesize data;

#pragma mark -
#pragma mark Shared Boilerplate Code
#pragma mark -

+ (id)keychainValueWithIdentifier:(NSString*)identifier
{
	return [[[OFKeychainWrapper alloc] initWithIdentifier:identifier] autorelease];
}

- (id)initWithIdentifier:(NSString*)_identifier
{
	if (!magicData)
	{
		char const ofxMagic[] = "ofx_keychain_magic";
		magicData = [[NSData alloc] initWithBytes:&ofxMagic[0] length:strlen(ofxMagic)];
	}

	self = [super init];
	if (self != nil)
	{
		self.identifier = _identifier;
		[self _loadKeychainData];
	}
		
	return self;
}

- (void)dealloc
{
	self.identifier = nil;
	[self _setDataNoSave:nil];
	[super dealloc];
}

- (void)setData:(NSData*)_data
{
	[self _setDataNoSave:_data];
	[self _saveKeychainData];
}

- (void)_setDataNoSave:(NSData*)_data
{
	OFSafeRelease(data);
	data = [_data retain];
}

#pragma mark -
#pragma mark Device Internal Methods
#pragma mark -

#if !TARGET_IPHONE_SIMULATOR

+ (void)clearKeychain
{
	NSDictionary* findQuery = [NSDictionary dictionaryWithObjectsAndKeys:
		(id)kSecClassGenericPassword, (id)kSecClass,
		magicData, (id)kSecAttrGeneric,
		(id)kSecMatchLimitAll, (id)kSecMatchLimit,
		(id)kCFBooleanFalse, (id)kSecReturnData,
		nil];

	SecItemDelete((CFDictionaryRef)findQuery);
}

- (void)_loadKeychainData
{
	NSDictionary* findQuery = [NSDictionary dictionaryWithObjectsAndKeys:
		(id)kSecClassGenericPassword, (id)kSecClass,
		magicData, (id)kSecAttrGeneric,
		identifier, (id)kSecAttrAccount,
		(id)kSecMatchLimitOne, (id)kSecMatchLimit,
		(id)kCFBooleanTrue, (id)kSecReturnData,
		nil];

	NSData* keychainData = nil;
	int result = SecItemCopyMatching((CFDictionaryRef)findQuery, (CFTypeRef*)&keychainData);
	
	if (result == errSecSuccess)
	{
		[self _setDataNoSave:keychainData];
		[keychainData release];
	}
}

- (void)_saveKeychainData
{
	NSDictionary* findQuery = [NSDictionary dictionaryWithObjectsAndKeys:
		(id)kSecClassGenericPassword, (id)kSecClass,
		magicData, (id)kSecAttrGeneric,
		identifier, (id)kSecAttrAccount,
		(id)kSecMatchLimitOne, (id)kSecMatchLimit,
		(id)kCFBooleanFalse, (id)kSecReturnData,
		nil];

	int result = SecItemCopyMatching((CFDictionaryRef)findQuery, nil);
	
	if (result == errSecSuccess)
	{
		NSDictionary* updateQuery = [NSDictionary dictionaryWithObjectsAndKeys:
			(id)kSecClassGenericPassword, (id)kSecClass,
			magicData, (id)kSecAttrGeneric,
			identifier, (id)kSecAttrAccount,
			data, (id)kSecValueData,
			nil];

		NSDictionary* updatedItem = [NSDictionary dictionaryWithObjectsAndKeys:
			data, (id)kSecValueData,
			nil];

		result = SecItemUpdate((CFDictionaryRef)updateQuery, (CFDictionaryRef)updatedItem);
	}
	else
	{
		NSDictionary* addQuery = [NSDictionary dictionaryWithObjectsAndKeys:
			(id)kSecClassGenericPassword, (id)kSecClass,
			magicData, (id)kSecAttrGeneric,
			identifier, (id)kSecAttrAccount,
			data, (id)kSecValueData,
			nil];

		result = SecItemAdd((CFDictionaryRef)addQuery, NULL);
	}
}

#else

#pragma mark -
#pragma mark Simulator Internal Methods
#pragma mark -

+ (void)clearKeychain
{
    NSString* keychainFile = [OFSettings savePathForFile:@"ofx_simulator_keychain"];
	[[NSFileManager defaultManager] removeItemAtPath:keychainFile error:nil];
}

- (void)_loadKeychainData
{
	if (!simulatorKeychain)
	{
        NSString* keychainFile = [OFSettings savePathForFile:@"ofx_simulator_keychain"];
		simulatorKeychain = [[NSMutableDictionary dictionaryWithContentsOfFile:keychainFile] retain];
		if (!simulatorKeychain)
		{
			simulatorKeychain = [[NSMutableDictionary alloc] initWithCapacity:1];
		}
	}

	id _data = [simulatorKeychain objectForKey:identifier];
	if (_data)
	{
		[self _setDataNoSave:_data];
	}
}

- (void)_saveKeychainData
{
	[simulatorKeychain setObject:data forKey:identifier];
    NSString* keychainFile = [OFSettings savePathForFile:@"ofx_simulator_keychain"];
	[simulatorKeychain writeToFile:keychainFile atomically:YES];
}

- (void)deleteFromKeychain
{
	[simulatorKeychain removeObjectForKey:identifier];
}

#endif

@end
