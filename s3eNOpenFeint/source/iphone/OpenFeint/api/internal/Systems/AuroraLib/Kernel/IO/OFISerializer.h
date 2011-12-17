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

@protocol OFISerializer;

@protocol OFISerialized
- (void) serializeToOFISerializer:(id<OFISerializer>) serializer;
@end

@protocol OFISerializer
- (void) pushScope:(NSString*) scopeName isArray:(BOOL) isArray;
- (void) popScope;

- (void) serializeToKey:(NSString*) key object:(id<OFISerialized>) obj;
- (void) serializeArrayToKey:(NSString*) key elementName:(NSString*) elementKey container:(NSArray*) data;

//direct to parameter
- (void) ioIntToKey:(NSString*) key value:(NSInteger) value;
- (void) ioUIntToKey:(NSString*) key value:(NSUInteger) value;
- (void) ioBoolToKey:(NSString*) key value:(BOOL) value;
- (void) ioInt64ToKey:(NSString*) key value:(long long) value;
- (void) ioFloatToKey:(NSString*) key value:(float) value;
- (void) ioDoubleToKey:(NSString*) key value:(double) value;
- (void) ioNSDataToKey:(NSString*) key object:(NSData*) obj;
- (void) ioNSStringToKey:(NSString*) key object:(NSString*) obj;

@end
