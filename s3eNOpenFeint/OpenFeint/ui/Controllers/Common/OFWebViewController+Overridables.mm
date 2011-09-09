////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
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

#import "OFWebViewController+Overridables.h"
#import "OFControllerHelpersCommon.h"

@implementation OFWebViewController (Overridables)

#pragma mark Mandatory methods

- (NSString*)getAction
{
	ASSERT_OVERRIDE_MISSING;
	return @"";
}

- (NSString*)getTitle
{
	ASSERT_OVERRIDE_MISSING;
	return @"";
}

#pragma mark Optionally overridable methods

- (NSString*)notificationString
{
	return OFLOCALSTRING(@"Downloading.");
}

- (NSArray*)getParameters
{
	return nil;
}

@end
