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

#import "OFTableSequenceControllerHelper.h"
#import "OFTableControllerHelper+Overridables.h"

@class OFService;
@class OFResource;

@interface OFTableSequenceControllerHelper ( Overridables )

- (void)populateResourceControllerMap:(NSMutableDictionary*)mapToPopulate;
- (void)populateSectionHeaderFooterResourceControllerMap:(NSMutableDictionary*)mapToPopulate;
- (void)onSectionsCreated:(NSMutableArray*)sections;
- (BOOL)allowPagination;
- (BOOL)usePlainTableSectionHeaders;
- (void)onRefreshingData;

// This can be ignored if pagination is disallowed
- (NSString*)getCellControllerNameForStreamingCells;

// Optional
- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
- (void)doIndexActionWithOffset:(unsigned int)zeroBasedRowIndex onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
- (void)onBeforeResourcesProcessed:(OFPaginatedSeries*)resources;
- (void)onResourcesDownloaded:(OFPaginatedSeries*)resources;
- (BOOL)hasStreamingSections;

- (BOOL)usesHeaderResource;
- (NSUInteger)getHeaderResourceSectionIndex;
- (void)onHeaderResourceDownloaded:(OFResource*)headerResource;

@end
