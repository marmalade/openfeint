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

#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFControllerHelpersCommon.h"
#import "OFService+Overridables.h"
#import "OFTableSequenceControllerLoadMoreCell.h"
#import "OFTableCellBackgroundView.h"
#import "OFTableSequenceControllerHelper+Pagination.h"

@implementation OFTableSequenceControllerHelper ( Overridables )

- (void)populateResourceControllerMap:(NSMutableDictionary*)mapToPopulate
{
	ASSERT_OVERRIDE_MISSING;
}

- (void)populateSectionHeaderFooterResourceControllerMap:(NSMutableDictionary*)mapToPopulate
{
	// Optional
}

- (void)onBeforeResourcesProcessed:(OFPaginatedSeries*)resources
{
	// optional
}

- (void)onResourcesDownloaded:(OFPaginatedSeries*)resources
{
	//Optional
}

- (void)onSectionsCreated:(NSMutableArray*)sections
{
	// Optional
}

- (void)onRefreshingData
{
	mNumLoadedPages = 1;
}

- (BOOL)allowPagination
{
	return YES;
}

- (void)doIndexActionWithOffset:(unsigned int)zeroBasedRowIndex onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	ASSERT_OVERRIDE_MISSING;
}

- (NSString*)getCellControllerNameForStreamingCells
{
	ASSERT_OVERRIDE_MISSING;
	return @"";
}

- (BOOL)usePlainTableSectionHeaders
{
	return [self isAlphabeticalList];
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
{
	OFService* service = [self getService];    
    [[service class] getIndexOnSuccessInvocation:success onFailureInvocation:failure];
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	ASSERT_OVERRIDE_MISSING;
}

- (BOOL)hasStreamingSections
{
	return NO;
}

- (BOOL)usesHeaderResource
{
	return NO;
}

- (NSUInteger)getHeaderResourceSectionIndex
{
	return 0;
}

- (void)onHeaderResourceDownloaded:(OFResource*)headerResource
{
}

- (void)configureCell:(OFTableCellHelper*)_cell asLeading:(BOOL)_isLeading asTrailing:(BOOL)_isTrailing asOdd:(BOOL)_isOdd
{
	if (_isTrailing && [_cell isKindOfClass:[OFTableSequenceControllerLoadMoreCell class]])
	{
		// don't do anything
	}
	else
	{
		[super configureCell:_cell asLeading:_isLeading asTrailing:_isTrailing asOdd:_isOdd];
	}
}

@end

