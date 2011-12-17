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

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCryptor.h>

/*
    For best entropy, the key passed in should be kCCKeySizeAES256 (32) bytes in length
    Anything more is lost and anything shorter is a weak key
    The crypto header is included so you have access to this constant.
 */

@interface NSData (AES256)
- (NSData *)AES256EncryptWithKeyString:(NSString *)key;
- (NSData *)AES256DecryptWithKeyString:(NSString *)key;
- (NSData *)AES256EncryptWithKeyData:(NSData *)key;
- (NSData *)AES256DecryptWithKeyData:(NSData *)key;
@end
