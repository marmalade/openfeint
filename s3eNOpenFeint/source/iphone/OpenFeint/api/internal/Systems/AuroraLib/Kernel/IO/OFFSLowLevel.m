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

#import <fcntl.h>
#import <sys/mman.h>
#import <sys/stat.h>

#import <Foundation/Foundation.h>

void* memoryMapDirectoryRW(NSString* dir, size_t size) {
    void* mapping = MAP_FAILED;
    
    int fd = open([dir UTF8String], O_RDWR);
    
    if (fd != -1) {
        mapping = mmap(0, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        close(fd);
    }
    
    return mapping;
}

void syncMapDrop(void* address, size_t size) {
    if (MAP_FAILED != address) {
        msync(address, size, MS_INVALIDATE);
    }
}

void syncMap(void* address, size_t size) {
    if (MAP_FAILED != address) {
        msync(address, size, MS_ASYNC);
    }
}

void* unmapMemorySync(void* address, size_t size) {
    if (MAP_FAILED != address) {
        msync(address, size, MS_SYNC);
        munmap(address, size);
    }
    
    return MAP_FAILED;
}    

void* unmapMemoryDrop(void* address, size_t size) {
    if (MAP_FAILED != address) {
        msync(address, size, MS_INVALIDATE);
        munmap(address, size);
    }
    
    return MAP_FAILED;
}    

NSArray* posixCreatePathWithBasePath(NSString* path, NSString* basePath) {
    NSMutableArray* paths = [NSMutableArray array];
    NSString* currentPath = basePath?[NSString stringWithString:basePath]:[NSString string];
    NSArray* components = basePath?
    [[path stringByReplacingOccurrencesOfString:basePath withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, [path length])] pathComponents]:
    [path pathComponents];
    int error = 0;
    
    for (NSString* pathSuffix in components) {
        currentPath = [currentPath stringByAppendingPathComponent:pathSuffix];
        error = mkdir([currentPath UTF8String], 0777);
        
        if (error) error = errno;
        
        if (error && (error != EEXIST && error != EISDIR))
            return nil;
        
        [paths addObject:currentPath];
    }
    
    return paths;
}

NSArray* posixCreatePath(NSString* path) {
    return posixCreatePathWithBasePath(path, nil);
}

int posixCopyFile(const NSString* source, const NSString* destination, void* copyBuff, size_t buffSize) {
    int error = 0;
    int fdSource = 0;
    int fdDest = 0;
    ssize_t size = 0;
    
    // Copy the document to the destination dir
    if (!(fdSource = open([source UTF8String], O_RDONLY))) error= errno;
    if (!error && !(fdDest = open([destination UTF8String], O_WRONLY | O_APPEND | O_CREAT, 0666))) error= errno;
    
    if (error) {
        if (fdSource) close(fdSource);
        if (fdDest) close(fdDest);
        return error;
    }
    
    // For serial reading/writing caching is counter-productive
    fcntl(fdSource, F_NOCACHE, 1);
    fcntl(fdDest, F_NOCACHE, 1);
    
    while ((size = read(fdSource, copyBuff, buffSize)) > 0) {
        if((write(fdDest, copyBuff, (size_t)size)) != size) {
            error = errno;
            break;
        }
    }
    
    close(fdSource);
    close(fdDest);
    
    if (error) unlink([destination UTF8String]);
    
    return error;
}
