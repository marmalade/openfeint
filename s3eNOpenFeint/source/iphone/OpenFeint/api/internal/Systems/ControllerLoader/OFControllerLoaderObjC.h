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

#import <UIKit/UIKit.h>

@interface OFControllerLoaderObjC : NSObject
//global settings - apply to all loaders
+ (void)setAssetFileSuffix:(NSString*) suffixString;
+ (void)setClassNamePrefix:(NSString*) prefixString;
+ (void)setOverrideAssetFileSuffix:(NSString*) suffixString;
+ (void)setOverrideClassNamePrefix:(NSString*) prefixString;
+ (void)registerResourceBundle:(NSBundle*) bundle;

+ (id)loader;

- (UIViewController*) load:(NSString*)name;
- (UIViewController*) load:(NSString*)name owner:(NSObject*) owner;
- (UIViewController*) load:(NSString*)name withParams:(NSDictionary*)params;
- (UIViewController*) load:(NSString*)name withParams:(NSDictionary*)params owner:(NSObject*) owner;
- (UITableViewCell*) loadCell:(NSString*)cellName;
- (UITableViewCell*) loadCell:(NSString*)cellName owner:(NSObject*) owner;
- (UIView*) loadView:(NSString*)viewName;
- (UIView*) loadView:(NSString*)viewName owner:(NSObject*) owner;
- (Class) viewClass:(NSString*) viewName;
- (Class) controllerClass:(NSString*) controllerName;

- (void) loadAndLaunch:(NSString*)name withParams:(NSDictionary*)params;

@end
