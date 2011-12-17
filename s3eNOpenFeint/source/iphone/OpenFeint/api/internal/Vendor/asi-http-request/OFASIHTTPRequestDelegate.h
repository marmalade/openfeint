//
//  OFASIHTTPRequestDelegate.h
//  Part of OFASIHTTPRequest -> http://allseeing-i.com/OFASIHTTPRequest
//
//  Created by Ben Copsey on 13/04/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//

@class OFASIHTTPRequest;

@protocol OFASIHTTPRequestDelegate <NSObject>

@optional

// These are the default delegate methods for request status
// You can use different ones by setting didStartSelector / didFinishSelector / didFailSelector
- (void)requestStarted:(OFASIHTTPRequest *)request;
- (void)request:(OFASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders;
- (void)request:(OFASIHTTPRequest *)request willRedirectToURL:(NSURL *)newURL;
- (void)requestFinished:(OFASIHTTPRequest *)request;
- (void)requestFailed:(OFASIHTTPRequest *)request;
- (void)requestRedirected:(OFASIHTTPRequest *)request;

// When a delegate implements this method, it is expected to process all incoming data itself
// This means that responseData / responseString / downloadDestinationPath etc are ignored
// You can have the request call a different method by setting didReceiveDataSelector
- (void)request:(OFASIHTTPRequest *)request didReceiveData:(NSData *)data;

// If a delegate implements one of these, it will be asked to supply credentials when none are available
// The delegate can then either restart the request ([request retryUsingSuppliedCredentials]) once credentials have been set
// or cancel it ([request cancelAuthentication])
- (void)authenticationNeededForRequest:(OFASIHTTPRequest *)request;
- (void)proxyAuthenticationNeededForRequest:(OFASIHTTPRequest *)request;

@end
