//
//  MPURLParameter.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPURLRequestParameter.h"
#import "NSString+URLEscapingAdditions.h"
#import <objc/runtime.h>

@implementation MPURLRequestParameter

+ (NSArray *)parametersFromString:(NSString *)inString {
	NSMutableArray *foundParameters = [NSMutableArray arrayWithCapacity:10];
	NSScanner *parameterScanner = [[NSScanner alloc] initWithString:inString];
	NSString *name = nil;
	NSString *value = nil;
	MPURLRequestParameter *currentParameter = nil;
	
	while (![parameterScanner isAtEnd]) {
		name = nil;
		value = nil;
		
		[parameterScanner scanUpToString:@"=" intoString:&name];
		[parameterScanner scanString:@"=" intoString:NULL];
		[parameterScanner scanUpToString:@"&" intoString:&value];
		[parameterScanner scanString:@"&" intoString:NULL];		
		
		currentParameter = [[MPURLRequestParameter alloc] init];
		currentParameter.name = name;
		currentParameter.value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[foundParameters addObject:currentParameter];
		
		[currentParameter release];
	}
	
	[parameterScanner release];
	
	return foundParameters;
}

+ (NSArray *)parametersFromDictionary:(NSDictionary *)inDictionary {
	NSMutableArray *parameterArray = [[NSMutableArray alloc] init];
	MPURLRequestParameter *aURLParameter = nil;
	
	for (NSString *aKey in [inDictionary allKeys]) {
		aURLParameter = [[MPURLRequestParameter alloc] init];
		aURLParameter.name = aKey;
		aURLParameter.value = [inDictionary objectForKey:aKey];
		
		[parameterArray addObject:aURLParameter];
		[aURLParameter release];
	}
	
	return [parameterArray autorelease];
}

+ (NSDictionary *)parameterDictionaryFromString:(NSString *)inString {
	NSMutableDictionary *foundParameters = [NSMutableDictionary dictionaryWithCapacity:10];
	if (inString) {
		NSScanner *parameterScanner = [[NSScanner alloc] initWithString:inString];
		NSString *name = nil;
		NSString *value = nil;
		
		while (![parameterScanner isAtEnd]) {
			name = nil;
			value = nil;
			
			[parameterScanner scanUpToString:@"=" intoString:&name];
			[parameterScanner scanString:@"=" intoString:NULL];
			[parameterScanner scanUpToString:@"&" intoString:&value];
			[parameterScanner scanString:@"&" intoString:NULL];		
			
			[foundParameters setObject:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:name];
		}
		
		[parameterScanner release];
	}
	return foundParameters;
}

+ (NSString *)parameterStringForParameters:(NSArray *)inParameters {
	NSMutableString *queryString = [[NSMutableString alloc] init];
	int i = 0;
	int parameterCount = [inParameters count];	
	MPURLRequestParameter *aParameter = nil;
	
	for (; i < parameterCount; i++) {
		aParameter = [inParameters objectAtIndex:i];
		OFAssert(!aParameter.blob, @"Cannot turn blob into parameter string");
		[queryString appendString:[aParameter URLEncodedParameterString]];
		if (i < parameterCount - 1) {
			[queryString appendString:@"&"];
		}
	}
	
	return [queryString autorelease];
}

+ (NSString *)parameterStringForDictionary:(NSDictionary *)inParameterDictionary {
	NSMutableString *queryString = [[NSMutableString alloc] init];
	int i = 0;
	
	for (NSString *aKey in [inParameterDictionary allKeys]) {
		if (i > 0) {
			[queryString appendString:@"&"];
		}
		[queryString appendFormat:@"%@=%@", [aKey stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[inParameterDictionary objectForKey:aKey] stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		i++;
	}
	
	return [queryString autorelease];
}

#pragma mark -

- (id)init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (id)initWithName:(NSString *)inName andValue:(NSString *)inValue {
	self = [super init];
	if (self != nil) {
		self.name = inName;
		self.value = inValue;
	}
	return self;
}

- (id)initWithName:(NSString *)inName andBlob:(NSData *)inBlob andDataType:(NSString*)dataType {
	self = [super init];
	if (self != nil) {
		self.name = inName;
		self.blob = inBlob;
		self.blobDataType = dataType;
	}
	return self;
}

- (oneway void)dealloc {
	self.name = nil;
	self.value = nil;
	self.blob = nil;
	self.blobDataType = nil;
	
	[super dealloc];
}

@synthesize name = _name;
@synthesize value = _value;
@synthesize blob = _blob;
@synthesize blobDataType = _blobDataType;
#pragma mark -

- (NSString *)URLEncodedParameterString 
{
	return [NSString stringWithFormat:@"%@=%@", [self.name stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding], self.value ? [self.value stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @""];
}

#pragma mark -

- (NSComparisonResult)compare:(id)inObject {
	NSComparisonResult result = [self.name compare:[(MPURLRequestParameter *)inObject name]];
	
	if (result == NSOrderedSame) {
		result = [self.value compare:[(MPURLRequestParameter *)inObject value]];
	}
								 
	return result;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%s: %p %@>", class_getName([self class]), self, [self URLEncodedParameterString]];
}

@end
