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

#import "OFCloudStorageBlob.h"
#import "OFCloudStorageService.h"
#import "OpenFeint.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFService+Private.h"
#import "OFActionRequestType.h"
#import "OFNotificationData.h"
#import "OFProvider.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OFS3UploadParameters.h"
#import "OFS3Response.h"
#import "OFQueryStringWriter.h"

#import "MPOAuthURLResponse.h"
#import "OFCompressableData.h"
#import "OFResource+ObjC.h"

#import "OFInvocationForwarder.h"
#import "OFInvocation.h"
#import "OFDependencies.h"

#ifndef OF_EXCLUDE_ZLIB
#import "zlib.h"
#endif

#define kCloudStorageBlobSizeMax	(256 * 1024)

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFCloudStorageService)

@implementation OFCloudStorageService

OPENFEINT_DEFINE_SERVICE(OFCloudStorageService);

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		mUseCompression = YES;
		mVerboseCompression = NO;
        mUseLegacyHeaderlessCompression = NO;
		mStatusOk					= [[OFCloudStorageStatus_Ok						alloc] init];
		mStatusNotAcceptable		= [[OFCloudStorageStatus_NotAcceptable			alloc] init];
		mStatusNotFound				= [[OFCloudStorageStatus_NotFound				alloc] init];
		mStatusGatewayTimeout		= [[OFCloudStorageStatus_GatewayTimeout			alloc] init];
		mStatusInsufficientStorage	= [[OFCloudStorageStatus_InsufficientStorage	alloc] init];
	}
	
	return self;
}


- (OFCloudStorageStatus_Object*) getStatusObject_Ok
{
	return mStatusOk;
}


- (OFCloudStorageStatus_Object*) getStatusObject_NotAcceptable
{
	return mStatusNotAcceptable;
}


- (OFCloudStorageStatus_Object*) getStatusObject_NotFound
{
	return mStatusNotFound;
}


- (OFCloudStorageStatus_Object*) getStatusObject_GatewayTimeout
{
	return mStatusGatewayTimeout;
}


- (OFCloudStorageStatus_Object*) getStatusObject_InsufficientStorage
{
	return mStatusInsufficientStorage;
}


- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	// I don't think we need CloudStorageBlob to be a full fledged resource yet.
	// Maybe we will if this service tries to get more sophisticated.
	// In the meantime we can pacify OFResource checks by registering it anyway.
	//
	[namedResourceMap setObject:[OFCloudStorageBlob class] forKey:[OFCloudStorageBlob getResourceName]];
}


+ (OFRequestHandle*) getIndexOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{	
	return [[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"cloud_stores.xml"]
            withParameterArray:nil
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestSilent
	 withNotice:nil];
}


- (void)onUploadFailure:(MPOAuthAPIRequestLoader*)loader nextCall:(OFInvocation*)nextCall
{
	OFCloudStorageStatus_Object *statusObject = [self getStatusObject_GatewayTimeout];
	
	do { // once through
		MPOAuthURLResponse *oauthResponse = loader.oauthResponse;
		if (! oauthResponse){
			break;
		}
		
		NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)oauthResponse.urlResponse;
		if (! urlResponse){
			break;
		}
		
		NSInteger statusCode = [urlResponse statusCode];
		
		switch(statusCode){
			case CSC_Ok:
				statusObject = [self getStatusObject_Ok];
				break;
			case CSC_InsufficientStorage:
				statusObject = [self getStatusObject_InsufficientStorage];
				break;
			case CSC_NotFound:
			default:
				statusObject = [self getStatusObject_NotFound];
				break;
		}
	} while(NO); // once through
	
	[nextCall invokeWith:statusObject];
}


+ (OFRequestHandle*)uploadBlob:(NSData*) blob withKey:(NSString*) keyStr onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFRequestHandle* handle = nil;
	
	if ( blob ) {
        if ([[OFCloudStorageService sharedInstance] isCompressionEnabled])
        {
            blob = [OFCompressableData serializedDataFromData:blob];
        }
		NSUInteger blobLen = [blob length];
		
		// Enable the following line for diagnostic purposes.
		//OFLog(@"blob size: %i", (int)blobLen);
		
		if ( blobLen <= kCloudStorageBlobSizeMax ) {
			if ( [OFCloudStorageService keyIsValid: keyStr] ) {
				OFQueryStringWriter* params = [OFQueryStringWriter writer];
				
				[params ioNSStringToKey:@"key" object:keyStr];
				[params ioNSDataToKey:@"blob" object:blob];
				
				handle = [[self sharedInstance] 
                          postAction:@"/cloud_stores"
                          withParameterArray:params.getQueryParametersAsMPURLRequestParameters
                          withSuccessInvocation:_onSuccess
                          withFailureInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(onUploadFailure:nextCall:) chained:_onFailure]
//				 withFailure:OFDelegate([self sharedInstance], @selector(onUploadFailure:nextCall:), _onFailure)
                          withRequestType:OFActionRequestSilent // OFActionRequestForeground would require non-nil notice
                          withNotice:nil
                          ];
			}else{
				OFLog(@"Cloud storage key is not acceptable. Blob will not be uploaded. Key may only include characters, numbers, underscores and dashes.");
				[_onFailure invokeWith:[[self sharedInstance] getStatusObject_NotAcceptable]];
			}
		}else{
			OFLog(@"Cloud storage blob is too large. Blob will not be uploaded. Max size is 256k.");
			[_onFailure invokeWith:[[self sharedInstance] getStatusObject_InsufficientStorage]];
		}
	}else{
		[_onFailure invokeWith:[[self sharedInstance] getStatusObject_NotAcceptable]];
	}
	
	return handle;
}


+ (OFRequestHandle*)downloadBlobWithKey:(NSString*) keyStr onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFRequestHandle* handle = nil;
	
	if ( [OFCloudStorageService keyIsValid: keyStr] ) {
		NSString *actionStr = [NSString stringWithFormat:@"cloud_stores/%@.blob", keyStr];
		
		handle = [[OpenFeint provider] 
                  performAction:actionStr //@"cloud_stores/wa3.blob"
                  withParameters:nil
                  withHttpMethod:@"GET"
                  withSuccessInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(onBlobDownloaded:nextCall:) chained:_onSuccess]
                  withFailureInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(onDownloadFailure:nextCall:) chained:_onFailure]
//		 withSuccess:OFDelegate([self sharedInstance], @selector(onBlobDownloaded:nextCall:), _onSuccess)
//		 withFailure:OFDelegate([self sharedInstance], @selector(onDownloadFailure:nextCall:), _onFailure)
                  withRequestType:OFActionRequestSilent
                  withNotice:nil
                  requiringAuthentication:YES
                  ];
	}else{
		[_onFailure invokeWith:([[self sharedInstance] getStatusObject_NotAcceptable])];
	}
	
	return handle;
}


- (void)onBlobDownloaded:(MPOAuthAPIRequestLoader*)loader nextCall:(OFInvocation*)nextCall
{
    if ([[OFCloudStorageService sharedInstance] isCompressionEnabled])
	{
        [nextCall invokeWith:[OFCompressableData uncompressedDataFromSerializedData:loader.data]];
    }
    else {
        [nextCall invokeWith:loader.data];
    }
}


- (void)onDownloadFailure:(MPOAuthAPIRequestLoader*)loader nextCall:(OFInvocation*)nextCall
{
	OFCloudStorageStatus_Object *statusObject = [self getStatusObject_GatewayTimeout];
	
	do { // once through
		MPOAuthURLResponse *oauthResponse = loader.oauthResponse;
		if (! oauthResponse){
			break;
		}
		
		NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)oauthResponse.urlResponse;
		if (! urlResponse){
			break;
		}
		
		NSInteger statusCode = [urlResponse statusCode];
		
		switch(statusCode){
			case CSC_Ok:
				statusObject = [self getStatusObject_Ok];
				break;
			case CSC_NotFound:
			default:
				statusObject = [self getStatusObject_NotFound];
				break;
		}
	} while(NO); // once through
	
	[nextCall invokeWith:statusObject];
}


+ (BOOL)keyIsValid:(NSString*) keyStr{
	BOOL	validated = NO;
	int		keyLen = [keyStr length];
	int		idx;
	unichar	character;
	
	do { // once through
		if (keyLen <= 0) {
			break;
		}
		if (! [OFCloudStorageService charIsAlpha:[keyStr characterAtIndex:0]] ) {
			break;
		}
		for (idx = 1; idx < keyLen; idx++) {
			character = [keyStr characterAtIndex:idx];
			if (	! [OFCloudStorageService charIsAlpha:character]
				&&	! [OFCloudStorageService charIsNum:character]
				&&	! [OFCloudStorageService charIsPunctAllowedInKey:character]
			){
				break;
			}
		}
		if (idx < keyLen){
			break;
		}
		// Made it past all validation steps.
		validated = YES;
	} while (NO); // once through
	
	return validated;
}


+ (BOOL)charIsAlpha:(unichar) character{
	return (	(0x0041 <= character)
			&&	(character <= 0x005A)
	)||(		(0x0061 <= character)
			&&	(character <= 0x007A)
	);
}


+ (BOOL)charIsNum:(unichar) character{
	return (	(0x0030 <= character)
			&&	(character <= 0x0039)
	);
}


+ (BOOL)charIsPunctAllowedInKey:(unichar) character{
	return (	(0x005F == character) // Underscore
			||	(0x002D == character) // Dash
		//	||	(0x002E == character) // Period (trouble?)
	);
}


+(OFRequestHandle*)downloadS3Blob:(NSString*)url onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure
{
	return [OFCloudStorageService downloadS3Blob:url passThroughUserData:nil onSuccessInvocation:onSuccess onFailureInvocation:onFailure];
}


+(OFRequestHandle*)downloadS3Blob:(NSString*)url passThroughUserData:(NSObject*)userData onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure
{
    OFInvocation* chained = [OFInvocation invocationForTarget:[OFCloudStorageService sharedInstance] selector:@selector(onS3BlobDownloaded:nextCall:) chained:onSuccess];
    OFBlobInvocationForwarder* forwarder = [OFBlobInvocationForwarder blobForwarderWithString:url success:chained failure:onFailure userData:userData returnAsS3:YES];
    [forwarder start];
    return [OFRequestHandle requestHandle:forwarder.requestID];
    
}

- (void)onS3BlobDownloaded:(OFS3Response*)response nextCall:(OFInvocation*)nextCall
{
	if ([[OFCloudStorageService sharedInstance] isCompressionEnabled])
	{
		response.data = [OFCloudStorageService uncompressBlob:response.data];
	}
	[nextCall invokeWith:response];
}


+(void)uploadS3Blob:(NSData*)blob withParameters:(OFS3UploadParameters*)parameters onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFCloudStorageService uploadS3Blob:blob withParameters:parameters passThroughUserData:nil onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+(void)uploadS3Blob:(NSData*)blob withParameters:(OFS3UploadParameters*)parameters passThroughUserData:(NSObject*)userData onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	NSString* blobUrl = parameters.action;
	if (!blobUrl || [blobUrl length] == 0)
	{
		OFLog(@"Trying to upload a blob without a upload url");
		return;
	}
	if (!blob)
	{
		OFLog(@"Trying to upload a nil blob");
		return;
	}
	
	if ([[OFCloudStorageService sharedInstance] isCompressionEnabled])
	{
		blob = [OFCloudStorageService compressBlob:blob];
	}
    OFBlobInvocationForwarder* forwarder = [OFBlobInvocationForwarder blobForwarderWithString:blobUrl 
                                                                                      success:_onSuccess
                                                                                      failure:_onFailure
                                                                                     userData:userData returnAsS3:YES];
    forwarder.requestMethod = @"POST";
    forwarder.postBody = [NSMutableData dataWithData:[parameters createS3HttpBodyForBlob:blob]];  //why is this mutable inside asiHttpRequest?
    NSString* boundaryHeader = [NSString stringWithFormat:@"multipart/form-data;boundary=%@", [OFS3UploadParameters getMultiPartBoundary]];
    forwarder.requestHeaders = [NSMutableDictionary dictionaryWithObject:boundaryHeader forKey:@"Content-Type"];
    [forwarder startAsynchronous];
}

+ (NSData*)compressBlob:(NSData*)blob
{
#ifdef OF_EXCLUDE_ZLIB
	return blob;
#else
    NSData *compressedBlob = nil;
    unsigned int originalBlobSize = [blob length];
    if (blob && originalBlobSize > 0) 
	{
        if(![[OFCloudStorageService sharedInstance] isUsingLegacyHeaderlessCompression]) {
            return [OFCompressableData serializedDataFromData:blob];
        }
		// bufferSize is pretty arbitrary. It really shouldn't double in size when compressing but if you try to compress 4 bytes then who knows
		const unsigned long bufferSize = originalBlobSize * 2 + 128; 
		unsigned char* destBuffer = (unsigned char*) malloc(bufferSize);
		unsigned long destSize = bufferSize;
        int error = compress(destBuffer, &destSize, (const Bytef*)blob.bytes, originalBlobSize);
		if (error == Z_OK)
		{
			compressedBlob = [NSData dataWithBytes:destBuffer length:destSize];
		}
		else
		{
			OFLog(@"Failed to compress blob.");
		}
        free(destBuffer);
    }
	else
	{
		OFLog(@"Trying to compress a nil or empty blob");
	}
	
	if (compressedBlob && [[OFCloudStorageService sharedInstance] isVerboseCompressionEnabled])
	{
		const float ratio = (float)[compressedBlob length] / (float)originalBlobSize;
		const int percent = (int)(ratio * 100.f);
		//NSLog([NSString stringWithFormat:@"OpenFeint: BLOB compressed. Compressed size is %d percent of original size.", percent]);
		NSLog(@"OpenFeint: BLOB compressed. Compressed size is %d percent of original size.", percent);
	}
	
    return compressedBlob;
#endif
}

+ (NSData*)uncompressBlob:(NSData*)compressedBlob
{
#ifdef OF_EXCLUDE_ZLIB
	return compressedBlob;
#else
	if (!compressedBlob || [compressedBlob length] == 0)
	{
		OFLog(@"Trying to decompress a nil or empty blob");
		return nil;
	}
    if(![[OFCloudStorageService sharedInstance] isUsingLegacyHeaderlessCompression]) {
        return [OFCompressableData uncompressedDataFromSerializedData:compressedBlob];
    }
    
    z_stream zStream;
    zStream.next_in = (Bytef *)[compressedBlob bytes];
    zStream.avail_in = [compressedBlob length];
    zStream.total_out = 0;
    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
	
    if (inflateInit(&zStream) != Z_OK) 
	{
		OFLog(@"Error decompressing blob");
        return nil;
    }
	
	const unsigned int compressedSize = [compressedBlob length];
	
	// Assuming 50% compression. Overestimating will decrease the likelyhood of having to increase the buffer size which is rather costly
    NSMutableData *decompressedBlob = [NSMutableData dataWithLength:compressedSize * 2];
	
	BOOL success = NO;
    while (!success) 
	{
        if (zStream.total_out >= [decompressedBlob length]) 
		{
            [decompressedBlob increaseLengthBy:compressedSize];
        }
		
		const char* startAddress = (const char*)decompressedBlob.bytes;
        zStream.next_out = (Bytef*)&startAddress[zStream.total_out];
        zStream.avail_out = [decompressedBlob length] - zStream.total_out;
		
        const int status = inflate(&zStream, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) 
		{
            success = YES;
        } 
		else if (status != Z_OK) 
		{
            break;
        }
    }
    
	if (inflateEnd (&zStream) != Z_OK) 
	{
		OFLog(@"Error decompressing blob");
        return nil;
    }
	
    if (success) 
	{
        [decompressedBlob setLength:zStream.total_out];
        return decompressedBlob;
    } 
	else 
	{
        return nil;
    }
#endif
}

- (void)disableCompression
{
	mUseCompression = NO;
}

- (BOOL)isCompressionEnabled
{
#ifdef OF_EXCLUDE_ZLIB
	return NO;
#else
	return mUseCompression;
#endif
}

- (void)enableVeboseCompression
{
	mVerboseCompression = YES;
}

- (BOOL)isVerboseCompressionEnabled
{
	return mVerboseCompression;
}

-(void)useLegacyHeaderlessCompression
{
    mUseLegacyHeaderlessCompression = YES;
}

-(BOOL)isUsingLegacyHeaderlessCompression
{
    return mUseLegacyHeaderlessCompression;
}

- (void)dealloc
{
	[mStatusOk					release];
	[mStatusNotAcceptable		release];
	[mStatusNotFound			release];
	[mStatusGatewayTimeout		release];
	[mStatusInsufficientStorage	release];
	
	[super dealloc];
}

@end
