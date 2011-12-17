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

#import "NSData+AES256.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (AES256)

//internal which expects a key of 256bits (32 bytes) and operation of kCCEncrypt or kCCDecrypt 
- (NSData*)_AESWithBytes:(const void*) keyBytes operation:(NSInteger) operation{
    
    NSUInteger dataLength = [self length];
	
	//See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyBytes, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
	}
    
	free(buffer); //free the buffer;
	return nil;
    
}

-(NSData *)_AESWithString:(NSString*) key operation:(NSInteger) operation {
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
	[key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    return [self _AESWithBytes:keyPtr operation:operation];
    
}

-(NSData *)_AESWithData:(NSData*) keyData operation:(NSInteger) operation {
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
    [keyData getBytes:keyPtr length:kCCKeySizeAES256];
    return [self _AESWithBytes:keyPtr operation:operation];
    
}

- (NSData *)AES256EncryptWithKeyString:(NSString *)key {
    return [self _AESWithString:key operation:kCCEncrypt];
}

- (NSData *)AES256DecryptWithKeyString:(NSString *)key {
    return [self _AESWithString:key operation:kCCDecrypt];
}

- (NSData *)AES256EncryptWithKeyData:(NSData*) keyData {
    return [self _AESWithData:keyData operation:kCCEncrypt];
}

- (NSData *)AES256DecryptWithKeyData:(NSData*) keyData {
    return [self _AESWithData:keyData operation:kCCDecrypt];
}


@end
