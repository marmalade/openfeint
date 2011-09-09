//
//  MPOAuthSignatureParameter.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.07.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#import "MPOAuthSignatureParameter.h"
#import "MPOAuthURLRequest.h"
#import "NSString+URLEscapingAdditions.h"
#import "NSURL+MPURLParameterAdditions.h"

#include "hmac.h"
#include "Base64Transcoder.h"

@interface MPOAuthSignatureParameter ()
- (id)initUsingHMAC_SHA1WithText:(NSString *)inText andSecret:(NSString *)inSecret forRequest:(MPOAuthURLRequest *)inRequest;
@end

@implementation MPOAuthSignatureParameter

+ (NSString *)signatureBaseStringUsingParameterString:(NSString *)inParameterString forRequest:(MPOAuthURLRequest *)inRequest {
	return [NSString stringWithFormat:@"%@&%@&%@",	[inRequest HTTPMethod],
			[[inRequest.url absoluteNormalizedString] stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding],
			[inParameterString stringByAddingURIPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)HMAC_SHA1SignatureForText:(NSString *)inText usingSecret:(NSString *)inSecret {
	NSData *secretData = [inSecret dataUsingEncoding:NSUTF8StringEncoding];
	NSData *textData = [inText dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char result[20];
	hmac_sha1((unsigned char *)[textData bytes], [textData length], (unsigned char *)[secretData bytes], [secretData length], result);
	
	//Base64 Encoding
	char base64Result[32];
	size_t theResultLength = 32;
	Base64EncodeData(result, 20, base64Result, &theResultLength);
	NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];
	NSString *base64EncodedResult = [[[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding] autorelease];
	
	return base64EncodedResult;
}

- (id)initWithText:(NSString *)inText andSecret:(NSString *)inSecret forRequest:(MPOAuthURLRequest *)inRequest usingMethod:(NSString *)inMethod {
	if ([inMethod isEqual:kMPOAuthSignatureMethodHMACSHA1]) {
		self = [self initUsingHMAC_SHA1WithText:inText andSecret:inSecret forRequest:inRequest];
	} else if ([inMethod isEqualToString:kMPOAuthSignatureMethodPlaintext]) {
		self = [super init];
		if (self != nil) {
			self.name = @"oauth_signature";
			self.value = inSecret;
		}
	} else {
		[self release];
		self = nil;
		[NSException raise:@"Unsupported Signature Method" format:@"The signature method \"%@\" is not currently support by MPOAuthConnection", inMethod];
	}
	
	return self;
}

- (id)initUsingHMAC_SHA1WithText:(NSString *)inText andSecret:(NSString *)inSecret forRequest:(MPOAuthURLRequest *)inRequest {
	self = [super init];
	if (self != nil) {
		NSString *signatureBaseString = [MPOAuthSignatureParameter signatureBaseStringUsingParameterString:inText forRequest:inRequest];

		self.name = @"oauth_signature";
		self.value = [MPOAuthSignatureParameter HMAC_SHA1SignatureForText:signatureBaseString usingSecret:inSecret];
	}
	return self;	
}

- (oneway void)dealloc {
	[super dealloc];
}

@end
