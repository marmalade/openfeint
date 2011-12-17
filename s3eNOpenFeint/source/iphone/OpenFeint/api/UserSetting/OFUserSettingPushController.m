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

#import "OFUserSettingPushController.h"
#import "OFControllerLoaderObjC.h"
#import "OFResourceField.h"
#import "OFDependencies.h"

@implementation OFUserSettingPushController

@synthesize controllerName;
@synthesize settingTitle;
@synthesize selectorToCall;

- (void)setControllerName:(NSString*)_value
{
	controllerName = [_value retain];
}

- (void)setSettingTitle:(NSString*)_value
{
	settingTitle = [_value retain];
}

- (void)setSelectorToCall:(NSString*)_value
{
	if (_value && [_value length] > 0)
	{
		selectorToCall = [_value retain];
	}
	else
	{
		OFSafeRelease(selectorToCall);
	}
}


+(NSDictionary*)dataDictionary
{
    static NSDictionary* sDataDictionary;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
                           [OFResourceField fieldSetter:@selector(setControllerName:)], @"controller_name",
                           [OFResourceField fieldSetter:@selector(setSettingTitle:)], @"setting_title",
                           [OFResourceField fieldSetter:@selector(setSelectorToCall:)], @"selector_to_call",
                           nil] retain];
    }
    return sDataDictionary;
}

+ (NSString*)getResourceName
{
	return @"user_setting_push_controller";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (UIViewController*)getController
{
	UIViewController* controller = [[OFControllerLoaderObjC loader] load:controllerName];// load(controllerName);
	if (selectorToCall)
	{
		SEL selector = sel_registerName([selectorToCall UTF8String]);
		if ([controller respondsToSelector:selector])
		{
			[controller performSelector:selector];
		}
	}
	return controller;
}

- (void) dealloc
{
	OFSafeRelease(controllerName);
	OFSafeRelease(settingTitle);
	OFSafeRelease(selectorToCall);
	[super dealloc];
}

@end
