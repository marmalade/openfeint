/*
 * Copyright 2009 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

#import "OFFBSession.h"
#import "OFFBRequest.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kAPIRestURL = @"http://api.facebook.com/restserver.php";
static NSString* kAPIRestSecureURL = @"https://api.facebook.com/restserver.php";

static const int kMaxBurstRequests = 3;
static const NSTimeInterval kBurstDuration = 2;

static OFFBSession* sharedSession = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation OFFBSession

@synthesize delegates = _delegates, apiKey = _apiKey, apiSecret = _apiSecret,
  getSessionProxy = _getSessionProxy, uid = _uid, sessionKey = _sessionKey,
  sessionSecret = _sessionSecret, expirationDate = _expirationDate;

///////////////////////////////////////////////////////////////////////////////////////////////////
// class public

+ (OFFBSession*)session {
  return sharedSession;
}

+ (void)setSession:(OFFBSession*)session {
  sharedSession = session;
}

+ (OFFBSession*)sessionForApplication:(NSString*)key secret:(NSString*)secret
    delegate:(id<OFFBSessionDelegate>)delegate {
  OFFBSession* session = [[[OFFBSession alloc] initWithKey:key secret:secret
    getSessionProxy:nil] autorelease];
  [session.delegates addObject:delegate];
  return session;
}

+ (OFFBSession*)sessionForApplication:(NSString*)key getSessionProxy:(NSString*)getSessionProxy
    delegate:(id<OFFBSessionDelegate>)delegate {
  OFFBSession* session = [[[OFFBSession alloc] initWithKey:key secret:nil
    getSessionProxy:getSessionProxy] autorelease];
  [session.delegates addObject:delegate];
  return session;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)save {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if (_uid) {
    [defaults setObject:[NSNumber numberWithLongLong:_uid] forKey:@"OFFBUserId"];
  } else {
    [defaults removeObjectForKey:@"OFFBUserId"];
  }

  if (_sessionKey) {
    [defaults setObject:_sessionKey forKey:@"OFFBSessionKey"];
  } else {
    [defaults removeObjectForKey:@"OFFBSessionKey"];
  }

  if (_sessionSecret) {
    [defaults setObject:_sessionSecret forKey:@"OFFBSessionSecret"];
  } else {
    [defaults removeObjectForKey:@"OFFBSessionSecret"];
  }

  if (_expirationDate) {
    [defaults setObject:_expirationDate forKey:@"OFFBSessionExpires"];
  } else {
    [defaults removeObjectForKey:@"OFFBSessionExpires"];
  }
  
  [defaults synchronize];
}

- (void)unsave {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:@"OFFBUserId"];
  [defaults removeObjectForKey:@"OFFBSessionKey"];
  [defaults removeObjectForKey:@"OFFBSessionSecret"];
  [defaults removeObjectForKey:@"OFFBSessionExpires"];
  [defaults synchronize];
}

- (void)startFlushTimer {
  if (!_requestTimer) {
    NSTimeInterval t = kBurstDuration + [_lastRequestTime timeIntervalSinceNow];
    _requestTimer = [NSTimer scheduledTimerWithTimeInterval:t target:self
      selector:@selector(requestTimerReady) userInfo:nil repeats:NO];
  }
}

- (void)enqueueRequest:(OFFBRequest*)request {
  [_requestQueue addObject:request];
  [self startFlushTimer];
}

- (BOOL)performRequest:(OFFBRequest*)request enqueue:(BOOL)enqueue {
  // Stagger requests that happen in short bursts to prevent the server from rejecting
  // them for making too many requests in a short time
  NSTimeInterval t = [_lastRequestTime timeIntervalSinceNow];
  BOOL burst = t && t > -kBurstDuration;
  if (burst && ++_requestBurstCount > kMaxBurstRequests) {
    if (enqueue) {
      [self enqueueRequest:request];
    }
    return NO;
  } else {
    [request performSelector:@selector(connect)];

    if (!burst) {
      _requestBurstCount = 1;
      [_lastRequestTime release];
      _lastRequestTime = [[request timestamp] retain];
    }
  }
  return YES;
}

- (void)flushRequestQueue {
  while (_requestQueue.count) {
    OFFBRequest* request = [_requestQueue objectAtIndex:0];
    if ([self performRequest:request enqueue:NO]) {
      [_requestQueue removeObjectAtIndex:0];
    } else {
      [self startFlushTimer];
      break;
    }
  }
}

- (void)requestTimerReady {
  _requestTimer = nil;
  [self flushRequestQueue];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (OFFBSession*)initWithKey:(NSString*)key secret:(NSString*)secret
    getSessionProxy:(NSString*)getSessionProxy {
  self = [super init];
  if (self != nil) {
    if (!sharedSession) {
      sharedSession = self;
    }
    
    _delegates = OFFBCreateNonRetainingArray();    
    _apiKey = [key copy];
    _apiSecret = [secret copy];
    _getSessionProxy = [getSessionProxy copy];
    _uid = 0;
    _sessionKey = nil;
    _sessionSecret = nil;
    _expirationDate = nil;
    _requestQueue = [[NSMutableArray alloc] init];
    _lastRequestTime = nil;
    _requestBurstCount = 0;
    _requestTimer = nil;    
  }
  return self;
}

- (void)dealloc {
  if (sharedSession == self) {
    sharedSession = nil;
  }

  [_delegates release];
  [_requestQueue release];
  [_apiKey release];
  [_apiSecret release];
  [_getSessionProxy release];
  [_sessionKey release];
  [_sessionSecret release];
  [_expirationDate release];
  [_lastRequestTime release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (NSString*)apiURL {
  return kAPIRestURL;
}

- (NSString*)apiSecureURL {
  return kAPIRestSecureURL;
}

- (BOOL)isConnected {
  return !!_sessionKey;
}

- (void)begin:(FBUID)uid sessionKey:(NSString*)sessionKey
    sessionSecret:(NSString*)sessionSecret expires:(NSDate*)expires {
  _uid = uid;
  _sessionKey = [sessionKey copy];
  _sessionSecret = [sessionSecret copy];
  _expirationDate = [expires retain];
  
  [self save];
}

- (BOOL)resume {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  FBUID uid = [[defaults objectForKey:@"OFFBUserId"] longLongValue];
  if (uid) {
    NSDate* expirationDate = [defaults objectForKey:@"OFFBSessionExpires"];
    if (!expirationDate || [expirationDate timeIntervalSinceNow] > 0) {
      _uid = uid;
      _sessionKey = [[defaults stringForKey:@"OFFBSessionKey"] copy];
      _sessionSecret = [[defaults stringForKey:@"OFFBSessionSecret"] copy];
      _expirationDate = [expirationDate retain];

      for (id<OFFBSessionDelegate> delegate in _delegates) {
        [delegate session:self didLogin:_uid];
      }
      return YES;
    }
  }
  return NO;
}

- (void)cancelLogin {
  if (![self isConnected]) {
    for (id<OFFBSessionDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(sessionDidNotLogin:)]) {
        [delegate sessionDidNotLogin:self];
      }
    }
  }
}

- (void)logout {
  if (_sessionKey) {
    for (id<OFFBSessionDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(session:willLogout:)]) {
        [delegate session:self willLogout:_uid];
      }
    }

    [self deleteFacebookCookies];
    

    _uid = 0;
    [_sessionKey release];
    _sessionKey = nil;
    [_sessionSecret release];
    _sessionSecret = nil;
    [_expirationDate release];
    _expirationDate = nil;
    [self unsave];

    for (id<OFFBSessionDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(sessionDidLogout:)]) {
        [delegate sessionDidLogout:self];
      }
    }
  } else {
    [self deleteFacebookCookies];
    [self unsave];
  }
}

- (void)send:(OFFBRequest*)request {
  [self performRequest:request enqueue:YES];
}

- (void)deleteFacebookCookies {
		NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:
      [NSURL URLWithString:@"http://login.facebook.com"]];
    for (NSHTTPCookie* cookie in facebookCookies) {
				[cookies deleteCookie:cookie];
    }
}

@end
