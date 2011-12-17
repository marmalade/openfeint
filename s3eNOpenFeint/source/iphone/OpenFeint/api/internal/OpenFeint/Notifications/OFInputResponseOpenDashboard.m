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

#import "OFInputResponseOpenDashboard.h"
#import "OpenFeint+Private.h"
#import "OFControllerLoaderObjC.h"

@implementation OFInputResponseOpenDashboard
@synthesize controllerName = mControllerName;
@synthesize startingTab = mStartingTab;
@synthesize startingController = mStartingController;
- (id)initWithTab:(NSString*)tabName andController:(UIViewController*)controller
{
	self = [super init];
	if (self != nil)
	{
        self.startingTab = tabName;
		self.startingController = controller;
	}
	
	return self;
}

- (id)initWithTab:(NSString*)tabName andControllerName:(NSString*)controllerName
{
	self = [super init];
	if (self != nil)
	{
        self.startingTab = tabName;
        self.controllerName = controllerName;
	}
	
	return self;
}

- (void)dealloc
{
    self.startingTab = nil;
    self.controllerName = nil;
    self.startingController = nil;
	[super dealloc];
}

- (void)respondToInput
{
	if (self.controllerName && !self.startingController)
	{
		self.startingController = [[OFControllerLoaderObjC loader] load:self.controllerName];// load(mControllerName) retain];
	}
	NSArray* controllers = self.startingController ? [NSArray arrayWithObject:self.startingController] : nil;
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:self.startingTab andControllers:controllers];
}

@end
