//  Copyright 2009-2011 Aurora Feint, Inc.
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

#ifndef OpenFeint_OFFSLowLevel_h
#define OpenFeint_OFFSLowLevel_h

void* memoryMapDirectoryRW(NSString* dir, size_t size);
void syncMapDrop(void* address, size_t size);
void syncMap(void* address, size_t size);
void* unmapMemorySync(void* address, size_t size);
void* unmapMemoryDrop(void* address, size_t size);
NSArray* posixCreatePathWithBasePath(NSString* path, NSString* basePath);
NSArray* posixCreatePath(NSString* path);
int posixCopyFile(const NSString* source, const NSString* destination, void* copyBuff, size_t buffSize);
#endif
