//
//  ASIInputStream.h
//  Part of OFASIHTTPRequest -> http://allseeing-i.com/OFASIHTTPRequest
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OFASIHTTPRequest;

// This is a wrapper for NSInputStream that pretends to be an NSInputStream itself
// Subclassing NSInputStream seems to be tricky, and may involve overriding undocumented methods, so we'll cheat instead.
// It is used by OFASIHTTPRequest whenever we have a request body, and handles measuring and throttling the bandwidth used for uploading

@interface OFASIInputStream : NSObject {
	NSInputStream *stream;
	OFASIHTTPRequest *request;
}
+ (id)inputStreamWithFileAtPath:(NSString *)path request:(OFASIHTTPRequest *)request;
+ (id)inputStreamWithData:(NSData *)data request:(OFASIHTTPRequest *)request;

@property (retain, nonatomic) NSInputStream *stream;
@property (assign, nonatomic) OFASIHTTPRequest *request;
@end
