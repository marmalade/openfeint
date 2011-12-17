//
//  MPOAuthAPIRequestLoader.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *MPOAuthNotificationRequestTokenReceived;
extern NSString *MPOAuthNotificationAccessTokenReceived;
extern NSString *MPOAuthNotificationAccessTokenRefreshed;
extern NSString *MPOAuthNotificationErrorHasOccurred;

@protocol MPOAuthCredentialStore;
@protocol MPOAuthParameterFactory;

@class MPOAuthURLRequest;
@class MPOAuthURLResponse;
@class MPOAuthCredentialConcreteStore;
@class MPOAuthConnection;
@class OFInvocation;

@interface MPOAuthAPIRequestLoader : NSObject 
{
@package
	MPOAuthCredentialConcreteStore	*_credentials;
	MPOAuthURLRequest				*_oauthRequest;
	MPOAuthURLResponse				*_oauthResponse;
	MPOAuthConnection				*_activeConnection;
	NSMutableData					*_dataBuffer;
	NSString						*_dataAsString;
	NSError							*_error;
    OFInvocation                    *successInvocation;
    OFInvocation                    *failureInvocation;
}

@property (nonatomic, readwrite, retain) id <MPOAuthCredentialStore, MPOAuthParameterFactory> credentials;
@property (nonatomic, readwrite, retain) MPOAuthURLRequest *oauthRequest;
@property (nonatomic, readwrite, retain) MPOAuthURLResponse *oauthResponse;
@property (nonatomic, readonly, retain) NSData *data;
@property (nonatomic, readonly, retain) NSString *responseString;
@property (nonatomic, readwrite, retain) NSError* error;
@property (nonatomic, readwrite, retain) OFInvocation* successInvocation;
@property (nonatomic, readwrite, retain) OFInvocation* failureInvocation;

- (void)forceSetData:(NSData*)dataToRetain;

- (id)initWithURL:(NSURL *)inURL;
- (id)initWithRequest:(MPOAuthURLRequest *)inRequest;

- (void)loadSynchronously:(BOOL)inSynchronous;
- (NSURLRequest*)getConfiguredRequest;

- (void)cancel;

@end

