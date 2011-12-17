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

#import "OFUsersCredentialService.h"
#import "OFUsersCredential.h"
#import "OFService+Private.h"

#import "OFResource+ObjC.h"
#import "OFQueryStringWriter.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFUsersCredentialService);

@implementation OFUsersCredentialService

OPENFEINT_DEFINE_SERVICE(OFUsersCredentialService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFUsersCredential class] forKey:[OFUsersCredential getResourceName]];
}

+ (OFRequestHandle*) getIndexOnSuccessInvocation:(OFInvocation*)_onSuccess 
                             onFailureInvocation:(OFInvocation*)_onFailure 
                 onlyIncludeNotLinkedCredentials:(BOOL)onlyIncludeNotLinkedCredentials
                   onlyIncludeFriendsCredentials:(BOOL)onlyIncludeFriendsCredentials
{   
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioBoolToKey:@"only_include_not_linked_credentials" value:onlyIncludeNotLinkedCredentials];
	[params ioBoolToKey:@"only_include_friends_credentials" value:onlyIncludeFriendsCredentials];
	[params ioNSStringToKey:@"user_id" object:@"me"];
	
	return [[self sharedInstance]
            getAction:@"users_credentials"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestForeground
            withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded")]];
}


+ (OFRequestHandle*) getIndexOnSuccessInvocation:(OFInvocation*)_onSuccess 
                             onFailureInvocation:(OFInvocation*)_onFailure 
                    onlyIncludeLinkedCredentials:(BOOL)onlyIncludeLinkedCredentials
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioBoolToKey:@"only_include_linked_credentials" value:onlyIncludeLinkedCredentials];
	[params ioNSStringToKey:@"user_id" object:@"me"];
	
	return [[self sharedInstance]
	 getAction:@"users_credentials"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void)importFriendsFromCredentialType:(NSString*)credentialType 
							  onSuccessInvocation:(OFInvocation*)_onSuccess 
							  onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"credential_name" object:credentialType];
	[params ioNSStringToKey:@"user_id" object:@"me"];
	
	[[self sharedInstance]
	 getAction:@"users_credentials/import_friends"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void)getProfilePictureCredentialsForLocalUserOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	[[self sharedInstance]
		getAction:@"profile_picture"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)selectProfilePictureSourceForLocalUser:(NSString*)credentialSource onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	if ([credentialSource length] == 0)
		credentialSource = @"http_basic";
	
	[[self sharedInstance]
		postAction:[NSString stringWithFormat:@"profile_picture/select/%@", credentialSource]
		withParameterArray:params.getQueryParametersAsMPURLRequestParameters
		withSuccessInvocation:_onSuccess
		withFailureInvocation:_onFailure
		withRequestType:OFActionRequestSilent
		withNotice:nil];
}

+ (void)uploadProfilePictureLocalUser:(UIImage *)image onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure 
{
    OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
    NSString *credentialSource = @"http_basic";
    
    if (image) {
        NSData* retainedImageData = UIImageJPEGRepresentation(image, 0.7);
        [params ioNSDataToKey:@"uploaded_profile_picture" object:retainedImageData];
    } else {
        [params ioNSStringToKey:@"uploaded_profile_picture" object:( @"")];
    }
    
    [[self sharedInstance]
        postAction:[NSString stringWithFormat:@"profile_picture/select/%@", credentialSource]
        withParameterArray:params.getQueryParametersAsMPURLRequestParameters
        withSuccessInvocation:_onSuccess
        withFailureInvocation:_onFailure
        withRequestType:OFActionRequestSilent
        withNotice:nil];
}

+ (void)requestProfilePictureUpdateForLocalUserOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[[self sharedInstance]
		postAction:@"profile_picture/refresh"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

@end
