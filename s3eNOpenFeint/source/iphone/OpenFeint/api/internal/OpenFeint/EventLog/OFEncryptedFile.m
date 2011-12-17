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

#import "OFEncryptedFile.h"
#import "OFKeychainWrapper.h"
#import "NSData+AES256.h"
#import "OFSettings.h"
/*
    The file will be stored as [datadir]/secure/[filename] and will be encrypted using AES256.
    The password will be a randomly generated string stored in the keychain under the name "EF.[filename]"
 */
@interface OFEncryptedFile() 
//store data into file
-(void)setPlaintext:(NSData*)data;
@property (nonatomic, retain) NSData* keyData;
@property (nonatomic, retain) NSString* filePath;
@end



@implementation OFEncryptedFile
@synthesize keyData, plaintext, filePath;

+(id) encryptedFileWithFilename:(NSString*) filename {
    return [[[OFEncryptedFile alloc] initWithFilename:filename allowBackup:NO] autorelease];
}

+(id) backedUpEncryptedFileWithFilename:(NSString*) filename {
    return [[[OFEncryptedFile alloc] initWithFilename:filename allowBackup:YES] autorelease];
}


-(id) initWithFilename:(NSString*)_filename allowBackup:(BOOL)allowBackup {
    if((self = [super init])) {
        if(allowBackup)
        {
            self.filePath = [OFSettings documentsPathForFile:[NSString stringWithFormat:@"secure/%@", _filename]];
        }
        else
        {
            self.filePath = [OFSettings savePathForFile:[NSString stringWithFormat:@"secure/%@", _filename]];
        }
        OFKeychainWrapper* keychain = [OFKeychainWrapper keychainValueWithIdentifier:[NSString stringWithFormat:@"OF.%@", _filename]];
        self.keyData = keychain.data;
        if(!keychain.data) {
            //generate new random key
            uint8_t newkey[kCCKeySizeAES256];
            SecRandomCopyBytes(kSecRandomDefault, kCCKeySizeAES256, newkey);
            self.keyData = [NSData dataWithBytes:newkey length:kCCKeySizeAES256];
            keychain.data = self.keyData;
            self.plaintext = nil;
        }
        else {
            //read existing data using known key
            NSData *encryptedData = [NSData dataWithContentsOfFile:self.filePath];
            self.plaintext = [encryptedData AES256DecryptWithKeyData:self.keyData];
        }
    }
    return self;
}


-(void) dealloc {
    self.filePath = nil;
    self.keyData = nil;
    self.plaintext = nil;
    [super dealloc];
}

                      
-(void)setPlaintext:(NSData *)plaintextData {
    NSData*encryptedData = [plaintextData AES256EncryptWithKeyData:self.keyData];
    [[NSFileManager defaultManager] createDirectoryAtPath:[self.filePath stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES attributes:nil error:nil];                
    [encryptedData writeToFile:self.filePath atomically:YES];
    
    [plaintext release];
    plaintext = [plaintextData retain];
}

@end
