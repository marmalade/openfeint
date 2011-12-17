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
#pragma once

#import <UIKit/UIKit.h>

@class OFSettingsParser;
@interface OFSettings : NSObject 
{
@private
    NSMutableDictionary* mSettingsDict;
}
    
+ (OFSettings*)instance;
+ (void)deleteInstance;
- (NSString*)getSetting:(NSString*) key;
    
//these are intended for AddOns to use
- (void)loadSetting:(OFSettingsParser*) parser forTag:(NSString*) xmlTag;
- (void)setDefaultTag:(NSString*)tag value:(NSString*)value;
    
+ (NSString*)cachingPathRoot;
+ (NSString*)savePathForFile:(NSString*) fileName;  //things that are not synced, will move legacy files in docs
+ (NSString*)tempPathForFile:(NSString*) fileName;
+ (NSString*)documentsPathForFile:(NSString*) fileName;  //for things that should still be backed up
	
-(void)loadSettingsFile;
    
@property (nonatomic, retain, readonly) NSString* clientBundleIdentifier;
@property (nonatomic, retain, readonly) NSString* clientBundleVersion;
@property (nonatomic, retain, readonly) NSString* clientLocale;
@property (nonatomic, retain, readonly) NSString* clientDeviceType;
@property (nonatomic, retain, readonly) NSString* clientDeviceSystemName;
@property (nonatomic, retain, readonly) NSString* clientDeviceSystemVersion;
    
@end
