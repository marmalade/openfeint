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

#import "OFFormControllerHelper+Overridables.h"
#import "OFControllerHelpersCommon.h"
#import "OFDependencies.h"

@implementation OFFormControllerHelper ( Overridables )

- (void)onBeforeFormSubmitted
{
	// do nothing
}

- (void)onAfterFormSubmitted
{
	// do nothing
}

- (void)onPresentingErrorDialog
{
	// do nothing
}

- (OFResourceRequest*)getResourceRequest
{
	if([self usesXP])
	{
		ASSERT_OVERRIDE_MISSING;
	}
	return nil;
}

- (NSString*)getFormSubmissionUrl
{
	if(![self usesXP])
	{
		ASSERT_OVERRIDE_MISSING;
	}
	return @"";
}

- (void)registerActionsNow
{
}

- (NSString*)singularResourceName
{
	if(![self usesXP])
	{
		ASSERT_OVERRIDE_MISSING;
	}
	return @"";
}

- (void)onFormSubmitted:(id)resources
{
	ASSERT_OVERRIDE_MISSING;
}

- (void)populateViewDataMap:(NSMutableDictionary*)dataMap
{
}

- (NSString*)getLoadingScreenText
{
	return OFLOCALSTRING(@"Submitting");
}

- (BOOL)shouldUseOAuth
{
	return YES;
}

- (void)addHiddenParameters:(NSObject<OFISerializer>*)parameterStream
{
}

- (BOOL)shouldShowLoadingScreenWhileSubmitting
{
	return YES;
}

- (BOOL)shouldDismissKeyboardWhenSubmitting
{
	return YES;
}

- (BOOL)usesXP
{
	return NO;
}

- (NSString*)getHTTPMethod
{
	return @"POST";
}

@end
