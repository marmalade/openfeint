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

#pragma once

#import "OFTableControllerHelper.h"

@class OFService;
@class OFTableSectionDescription;
@class OFTableCellHelper;
@class OFResource;

@interface OFTableControllerHelper (Overridables)

- (OFResource*) getResourceFromSection:(NSArray*)sectionCells atRow:(NSUInteger)row;
- (NSString*) getCellControllerNameFromSection:(NSArray*)sectionCells atRow:(NSUInteger)row;
- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
- (void)_onDataLoaded:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental;
- (OFService*) getService;
- (BOOL)shouldDisplayEmptyDataSet; //Should display any empty data set controller?
- (UIViewController*)getNoDataFoundViewController;
- (NSString*)getNoDataFoundMessage;

// These are optional.
- (NSString*)getLeadingCellControllerNameForSection:(OFTableSectionDescription*)section;
- (NSString*)getTrailingCellControllerNameForSection:(OFTableSectionDescription*)section;
- (void)onLeadingCellWasLoaded:(OFTableCellHelper*)leadingCell forSection:(OFTableSectionDescription*)section;
- (void)onTrailingCellWasLoaded:(OFTableCellHelper*)trailingCell forSection:(OFTableSectionDescription*)section;
- (void)onRefreshingData;
- (BOOL)shouldRefreshAfterNotification;
- (NSString*)getNotificationToRefreshAfter;
- (BOOL)isNotificationResourceValid:(OFResource*)resource;
- (BOOL)isNewContentShownAtBottom;
- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath;
- (void)onLeadingCellWasClickedForSection:(OFTableSectionDescription*)section;
- (void)onTrailingCellWasClickedForSection:(OFTableSectionDescription*)section;
- (NSString*)getTextToShowWhileLoading;
- (BOOL)shouldAlwaysRefreshWhenShown;
- (NSString*)getTableHeaderControllerName;
- (NSString*)getTableHeaderViewName;
- (void)onTableHeaderCreated:(UIViewController*)tableHeader;
- (void)onTableFooterCreated:(UIViewController*)tableFooter;
- (void)onCell:(OFTableCellHelper*)cell resourceChanged:(OFResource*)resource;
- (BOOL)autoLoadData;
- (NSString*)getDataNotLoadedYetMessage;
- (UIView*)getBackgroundView;
- (void)configureCell:(OFTableCellHelper*)_cell asLeading:(BOOL)_isLeading asTrailing:(BOOL)_isTrailing asOdd:(BOOL)_isOdd;
//- (void)didSwipeCell:(OFTableCellHelper*)_cell;
//- (void)clearSwipedCell;
- (BOOL)hasStreamingSections;
- (BOOL)isAlphabeticalList;

//action cell processing
- (NSString*) actionCellClassName;
- (void) actionPressedForTag:(NSUInteger) tag indexPath:(NSIndexPath*) indexPath;

// editing
- (BOOL)allowEditing;
- (BOOL)shouldConfirmResourceDeletion;
- (NSString*)getResourceDeletePromptText:(OFResource*)resource;
- (NSString*)getResourceDeleteCancelText;
- (NSString*)getResourceDeleteConfirmText;
- (void)onResourceWasDeleted:(OFResource*)cellResource;
@end
