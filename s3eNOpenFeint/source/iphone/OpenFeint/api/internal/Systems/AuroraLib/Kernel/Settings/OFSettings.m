//  Copyright 2011 Aurora Feint, Inc.
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

#import "OFSettings.h"
#import "OFSettingsParser.h"
#import "OpenFeint+AddOns.h"
#import "OpenFeint+UserOptions.h"

@interface OFSettings()
@property (nonatomic, retain) NSMutableDictionary* settingsDict;

@end


static OFSettings* sInstance = nil;
@implementation OFSettings
@synthesize settingsDict = mSettingsDict;

+(OFSettings*) instance {
    if(sInstance == nil)
    {
        sInstance = [OFSettings new];
    }
    return sInstance;
}

+(void)deleteInstance
{
    [sInstance release];
    sInstance = nil;
}

-(id)init
{
    if((self = [super init]))
    {
        self.settingsDict = [NSMutableDictionary dictionaryWithCapacity:20];
        [self setDefaultTag:@"server-url" value:@"https://api.openfeint.com/"]; 
        [self setDefaultTag:@"ad-server-url" value:@"http://ads.openfeint.com/"]; 
        [self setDefaultTag:@"presence-host" value:@"presence.openfeint.com"];
        [self setDefaultTag:@"facebook-application-key" value:@"1a2dcd0bdc7ce8056aeb1dac00c2a886"];
        [self setDefaultTag:@"facebook-callback-url" value:@"https://api.openfeint.com/"];
        [OpenFeint setDefaultAddOnSettings:self];
        [self loadSettingsFile];
    }
    return self;
}

-(void)dealloc
{
    self.settingsDict = nil;
    [super dealloc];
}

-(NSString*) clientBundleIdentifier
{
	NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
	return [infoDict valueForKey:@"CFBundleIdentifier"];
}
-(NSString*) clientBundleVersion
{
	NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
	return [infoDict valueForKey:@"CFBundleVersion"];
}
-(NSString*) clientLocale
{
    return [[NSLocale currentLocale] localeIdentifier];
}
-(NSString*) clientDeviceType
{
    return [UIDevice currentDevice].model;
}
-(NSString*) clientDeviceSystemName
{
    return [UIDevice currentDevice].systemName;
}
-(NSString*) clientDeviceSystemVersion
{
    return [UIDevice currentDevice].systemVersion;
}

-(NSString*)getSetting:(NSString*) key
{
    return [self.settingsDict objectForKey:key];
}
-(void) loadSetting:(OFSettingsParser*) parser forTag:(NSString*) xmlTag
{
    NSString* value = [parser.keys objectForKey:xmlTag];
    if(value) [self.settingsDict setObject:value forKey:xmlTag];
}
-(void) setDefaultTag:(NSString*)tag value:(NSString*)value
{
    [self.settingsDict setObject:value forKey:tag];
}
-(void)loadSettingsFile
{
    OFSettingsParser* parser = [OFSettingsParser parserWithFilename:@"openfeint_internal_settings"];
    
    [self loadSetting:parser forTag:@"server-url"];
    [self loadSetting:parser forTag:@"ad-server-url"];
    [self loadSetting:parser forTag:@"presence-host"];
    [self loadSetting:parser forTag:@"weinre-host"];
    [self loadSetting:parser forTag:@"facebook-callback-url"];
    [self loadSetting:parser forTag:@"facebook-application-key"];
    [self loadSetting:parser forTag:@"debug-override-key"];
    [self loadSetting:parser forTag:@"debug-override-secret"];   
    [self loadSetting:parser forTag:@"use_local_game_feed_config"];
    [self loadSetting:parser forTag:@"use_local_game_feed_items"];
    [self loadSetting:parser forTag:@"force_game_feed_server_error"];
    [self loadSetting:parser forTag:@"force_ad_server_error"];
    [OpenFeint loadAddOnSettings:self fromParser:parser];
}


+ (NSString*)tempPathForFile:(NSString *)fileName
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

+ (NSString*)documentsPathForFile:(NSString *)fileName
{
    NSString* docRoot = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [docRoot stringByAppendingPathComponent:fileName];
}


static NSString* savePathRootKey = @"OpenFeintSavePathRoot";
//will move old document files to the proper location
+ (NSString*)cachingPathRoot
{
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    NSString* extensionName = [def stringForKey:savePathRootKey];
    if(!extensionName)
    {
        NSString* appId = [OpenFeint clientApplicationId];
        extensionName = appId ? [NSString stringWithFormat:@"openfeint_%@", appId] : @"openfeint";
        [def setValue:extensionName forKey:savePathRootKey];  //store the original value to insure that we don't switch it later
        [def synchronize];
    }
    NSString* cacheRoot = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:extensionName];
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:cacheRoot])
    {
        [manager createDirectoryAtPath:cacheRoot withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cacheRoot;    
}



+(NSString*) savePathForFile:(NSString*) fileName
{
    NSString*cacheRoot = [OFSettings cachingPathRoot]; 
    
    NSFileManager* manager = [NSFileManager defaultManager];
    NSString* docRoot = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

	//check for file at the old location
    NSString* oldLocation = [docRoot stringByAppendingPathComponent:fileName];
    NSString* cacheLocation = [cacheRoot stringByAppendingPathComponent:fileName];
    
    if([manager fileExistsAtPath:oldLocation])
    {
        //make sure the directory is valid, so the legacy copy will succeed
        NSString* cacheNewDirectory = [cacheLocation stringByDeletingLastPathComponent];
        if(![manager fileExistsAtPath:cacheNewDirectory])
        {
            [manager createDirectoryAtPath:cacheNewDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        [manager moveItemAtPath:oldLocation toPath:cacheLocation error:nil];
    }
    return cacheLocation;
}






@end
