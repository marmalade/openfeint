////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009-2010 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma once

class OFSettings;
class OFXmlReader;
@protocol OpenFeintAddOn
@required
+ (void)initializeAddOn:(NSDictionary*)settings;
+ (void)shutdownAddOn;
+ (BOOL)respondToPushNotification:(NSDictionary*)notificationInfo duringApplicationLaunch:(BOOL)duringApplicationLaunch;
+ (void)userLoggedOut;
+ (void)defaultSettings:(OFSettings*)settings;
+ (void)loadSettings:(OFSettings*)settings fromReader:(OFXmlReader&) reader;

@optional
+ (void)userLoggedIn;
+ (void)preInitializeAddOn:(NSDictionary*)settings;
+ (void)userLoggedInPostIntro;
+ (void)offlineUserLoggedInPostIntro;
@end
