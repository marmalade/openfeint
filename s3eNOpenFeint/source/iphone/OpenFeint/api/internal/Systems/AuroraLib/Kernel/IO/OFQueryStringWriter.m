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

#import "OFQueryStringWriter.h"
#import "MPURLRequestParameter.h"
@interface OFQueryStringWriterScope : NSObject {
    NSString* name;
    BOOL isArray;
}
@property (nonatomic, retain) NSString* name;
@property (nonatomic) BOOL isArray;
-(id) initWithName:(NSString*) _name isArray:(BOOL) _isArray;

@end

@implementation OFQueryStringWriterScope
@synthesize name, isArray;

-(id) initWithName:(NSString*) _name isArray:(BOOL) _isArray {
    if((self = [super init])) {
        self.name = _name;
        self.isArray = _isArray;
    }
    return self;
}

-(void) dealloc {
    self.name = nil;
    [super dealloc];
}
@end



@interface OFQueryStringWriter  ()

@property (nonatomic, retain) NSMutableArray* parameterArray;
@property (nonatomic, retain) NSMutableArray* scopeStack;
//assert base 1 pages?
- (void) addStringParameter:(NSString*) name value:(NSString*) value;
- (void) addDataParameter:(NSString*) name value:(NSData*) value;
- (NSMutableString*) getCurrentScope;
- (NSString*) formatScoped:(NSString*) keyName;
@end


@implementation OFQueryStringWriter
@synthesize escapeStrings;
@synthesize parameterArray;
@synthesize scopeStack;

+(id) writer 
{
    return [[self new] autorelease];
}

-(id) init {
    if((self = [super init])) {
        self.parameterArray = [NSMutableArray arrayWithCapacity:10];
        self.scopeStack = [NSMutableArray arrayWithCapacity:5];
    }
    return self;
}

-(void) dealloc {
    self.parameterArray = nil;
    self.scopeStack = nil;
    [super dealloc];
}

- (NSArray*) getQueryParametersAsMPURLRequestParameters {
    return parameterArray;
}

#pragma mark OFISerialized protocol
- (void) pushScope:(NSString*) scopeName isArray:(BOOL) isArray {
    [self.scopeStack addObject:[[[OFQueryStringWriterScope alloc] initWithName:scopeName isArray:isArray] autorelease]];
}

- (void) popScope {
    NSAssert(self.scopeStack.count, @"Stack must not be empty when popping!");
    [self.scopeStack removeLastObject];
}

- (void) serializeToKey:(NSString*) key object:(id<OFISerialized>) obj {
    [self pushScope:key isArray:NO];
    [obj serializeToOFISerializer:self];
    [self popScope];
}

- (void) serializeArrayToKey:(NSString*) key elementName:(NSString*) elementKey container:(NSArray*) data {
    //this needs to do stuff...
    [self pushScope:key isArray:YES];
    for(NSObject* element in data) {
        if([element isKindOfClass:NSString.class]) {
            [self ioNSStringToKey:elementKey object:(NSString*)element];        
        }
        else if([element conformsToProtocol:@protocol(OFISerialized)]) {
            [self pushScope:elementKey isArray:NO];
            id<OFISerialized> castObj = (id<OFISerialized>)element;
            [castObj serializeToOFISerializer:self]; 
            [self popScope];
        }        
        else {
            NSAssert1(NO, @"Need to support protocol OFISerialized for %@", element.class);
        }
    }
    [self popScope];
}


- (void) ioIntToKey:(NSString*) key value:(NSInteger) value {
    [self addStringParameter:[self formatScoped:key] value:[NSString stringWithFormat:@"%d", value]];
}
- (void) ioUIntToKey:(NSString*) key value:(NSUInteger) value {
    [self addStringParameter:[self formatScoped:key] value:[NSString stringWithFormat:@"%d", value]];
}
- (void) ioBoolToKey:(NSString*) key value:(BOOL) value {
    [self addStringParameter:[self formatScoped:key] value:[NSString stringWithFormat:@"%d", value ? 1 : 0]];
}
- (void) ioInt64ToKey:(NSString*) key value:(long long) value {
    [self addStringParameter:[self formatScoped:key] value:[NSString stringWithFormat:@"%qi", value]];
}
- (void) ioFloatToKey:(NSString*) key value:(float) value {
    [self addStringParameter:[self formatScoped:key] value:[NSString stringWithFormat:@"%f", value]];
}
- (void) ioDoubleToKey:(NSString*) key value:(double) value {
    [self addStringParameter:[self formatScoped:key] value:[NSString stringWithFormat:@"%f", value]];
}
- (void) ioNSDataToKey:(NSString*) key object:(NSData*) obj {
    //NOTE: the old OFHttpNestedQueryStringWriter did NOT scope these keys...
    [self addDataParameter:[self formatScoped:key] value:obj];
}
- (void) ioNSStringToKey:(NSString*) key object:(NSString*) obj {
    [self addStringParameter:[self formatScoped:key] value:obj];
}

#pragma mark Private
static CFStringRef illegalCharacters = CFSTR("!@#$%^&*()+=\\][{}|';:\"/.,<>?`~ ");
- (void) addStringParameter:(NSString*) name value:(NSString*) value {
    if(!value) value = @""; //the multipart builder requires that either value or blob is set or it doesn't understand what to do
    NSString*escaped = [value retain];
    if(self.escapeStrings)
    {
        escaped = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, illegalCharacters, kCFStringEncodingUTF8);
    }

    MPURLRequestParameter* param = [[MPURLRequestParameter alloc] initWithName:name andValue:escaped];
    [parameterArray addObject:param];    
    [param release];    
    [escaped release];
}

- (void) addDataParameter:(NSString*) name value:(NSData*) value {
    MPURLRequestParameter* param = [[MPURLRequestParameter alloc] initWithName:name andBlob:value andDataType:@"blob"];
    [parameterArray addObject:param];
    [param release];    
}

- (NSMutableString*) getCurrentScope {
    NSMutableString* output = [NSMutableString stringWithCapacity:1024];
    if(self.scopeStack.count == 0) return output;
    OFQueryStringWriterScope* previous = nil;
    
    for(OFQueryStringWriterScope* scope in self.scopeStack) {
        if(!previous) {
            [output appendFormat:@"%@", scope.name];
        }
        else {
            if(previous.isArray) {
                [output appendString:@"[]"];
            }
            else {
                [output appendFormat:@"[%@]", scope.name];
            }
        }
        previous = scope;
    }
    return output;
}

- (NSString*) formatScoped:(NSString*) keyName {
    NSMutableString* output = [self getCurrentScope];
    if(!self.scopeStack.count) {
        [output appendString:keyName];
    }
    else {
        OFQueryStringWriterScope* finalScope = self.scopeStack.lastObject;
        if(finalScope.isArray) {
            [output appendString:@"[]"];
        }
        else {
            [output appendFormat:@"[%@]", keyName];
        }
    }
    return output;
}
@end
