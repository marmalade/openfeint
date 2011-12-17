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
@class OFURLDispatcher;
@class OFInvocation;

@protocol OFURLDispatcherObserver <NSObject>
- (void) dispatcher:(OFURLDispatcher*)dispatcher willDispatchAction:(NSString*)name withParams:(NSDictionary*)params;
- (void) dispatcher:(OFURLDispatcher*)dispatcher wontDispatchAction:(NSURL*)actionURL;
@end

@interface OFURLDispatcher : NSObject
{
}

+ (id)defaultDispatcher;

- (void)mapAction:(NSString*)actionName toInvocation:(OFInvocation*)invocation;
- (void)dispatchAction:(NSURL*)actionURL;
- (void)dispatchAction:(NSURL*)actionURL withObserver:(id<OFURLDispatcherObserver>)observer;
- (void)dispatchAction:(NSString*)name params:(NSDictionary*)params;
- (void)dispatchAction:(NSString*)name params:(NSDictionary*)params withObserver:(id<OFURLDispatcherObserver>)observer;


@end
