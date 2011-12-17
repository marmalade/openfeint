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

#import "OFTableControllerHelper+Overridables.h"
#import "OFService.h"
#import "OFControllerHelpersCommon.h"
#import "OFPatternedGradientView.h"
#import "OFTableCellBackgroundView.h"
#import "OFImageLoader.h"
#import "OpenFeint+Private.h"
#import "OFTableCellHelper+Overridables.h"
#import "OFDependencies.h"

@implementation OFTableControllerHelper (Overridables)

- (NSString*)getTextToShowWhileLoading
{
	return @"Downloading";
}

- (UIViewController*)getNoDataFoundViewController
{
	// Optional
	return nil;
}

- (NSString*)getNoDataFoundMessage
{
	ASSERT_OVERRIDE_MISSING;
	return OFLOCALSTRING(@"No data results were found");
}

- (NSString*)getTableHeaderViewName
{
	return nil;
}

- (NSString*)getTableHeaderControllerName
{
	return nil;
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
	// Do Nothing
}

- (void)onTableFooterCreated:(UIViewController*)tableFooter
{
	// Do Nothing
}

- (void)onCell:(OFTableCellHelper*)cell resourceChanged:(OFResource*)resource
{
	// Do Nothing
}

- (OFService*) getService
{
	ASSERT_OVERRIDE_MISSING;
	return nil;
}

- (BOOL)shouldDisplayEmptyDataSet
{
	return YES;
}

- (void)onLeadingCellWasClickedForSection:(OFTableSectionDescription*)section
{
	// Do Nothing
}

- (void)onTrailingCellWasClickedForSection:(OFTableSectionDescription*)section
{
	// Do Nothing
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	// Do Nothing
}

- (void)onRefreshingData
{
	// Do Nothing
}

- (BOOL)shouldAlwaysRefreshWhenShown
{
	return NO;
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	ASSERT_OVERRIDE_MISSING;
}

- (void)_onDataLoaded:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental
{
	ASSERT_OVERRIDE_MISSING;
}

- (BOOL)isNewContentShownAtBottom
{
	return NO;
}

- (OFResource*) getResourceFromSection:(NSArray*)sectionCells atRow:(NSUInteger)row
{
	ASSERT_OVERRIDE_MISSING;
	return nil;
}

- (NSString*) getCellControllerNameFromSection:(NSArray*)sectionCells atRow:(NSUInteger)row
{
	ASSERT_OVERRIDE_MISSING;
	return @"";
}

- (BOOL)shouldRefreshAfterNotification
{
	return NO;
}

- (NSString*)getNotificationToRefreshAfter
{
	return @"";
}

- (BOOL)isNotificationResourceValid:(OFResource*)resource
{
	return YES;
}

- (NSString*)getLeadingCellControllerNameForSection:(OFTableSectionDescription*)section
{
	return nil;
}

- (NSString*)getTrailingCellControllerNameForSection:(OFTableSectionDescription*)section
{
	return nil;
}

- (void)onLeadingCellWasLoaded:(OFTableCellHelper*)leadingCell forSection:(OFTableSectionDescription*)section
{
	
}

- (void)onTrailingCellWasLoaded:(OFTableCellHelper*)trailingCell forSection:(OFTableSectionDescription*)section
{
	
}

- (BOOL)autoLoadData
{
	return YES;
}

- (NSString*)getDataNotLoadedYetMessage
{
	return @"";
}

- (UIView*)getBackgroundView
{
	return nil;
}

- (void)configureCell:(OFTableCellHelper*)_cell asLeading:(BOOL)_isLeading asTrailing:(BOOL)_isTrailing asOdd:(BOOL)_isOdd
{
	if (!_cell)
		return;

	if([_cell wantsToConfigureSelf])
	{
		[_cell configureSelfAsLeading:_isLeading asTrailing:_isTrailing asOdd:_isOdd];
	}
	else
	{
		OFTableCellBackgroundView* background = (OFTableCellBackgroundView*)_cell.backgroundView;
		OFTableCellBackgroundView* selectedBackground = (OFTableCellBackgroundView*)_cell.selectedBackgroundView;
		if (![background isKindOfClass:[OFTableCellBackgroundView class]])
		{
			_cell.backgroundView = background = [OFTableCellBackgroundView defaultBackgroundView];
			_cell.selectedBackgroundView = selectedBackground = [OFTableCellBackgroundView defaultBackgroundView];
			//TODO: customize accessory view?
		}

		if (_isLeading && !_cell.userInteractionEnabled)
		{
			UIImage* bgImage = [OFImageLoader loadImage:@"OFLeadingCellBackground.png"];
			background.image = bgImage;
			selectedBackground.image = bgImage;
		}
		else if (_isTrailing && !_cell.userInteractionEnabled)
		{
			UIImage* bgImage = [OFImageLoader loadImage:@"OFTableCellDefaultBackground.png"];
			background.image = bgImage;
			selectedBackground.image = bgImage;
		}
		else if (_isOdd)
		{
			background.image = [OFImageLoader loadImage:@"OFTableCellDefaultBackgroundOdd.png"];
			selectedBackground.image = [OFImageLoader loadImage:@"OFTableCellDefaultBackgroundOddSelected.png"];
		}
		else
		{
			background.image = [OFImageLoader loadImage:@"OFTableCellDefaultBackground.png"];
			selectedBackground.image = [OFImageLoader loadImage:@"OFTableCellDefaultBackgroundSelected.png"];
		}		
	}
}

//- (void)didSwipeCell:(OFTableCellHelper*)_cell
//{
//}
//
//- (void)clearSwipedCell
//{
//}

- (BOOL)hasStreamingSections
{
	return NO;
}

- (BOOL)isAlphabeticalList
{
	return NO;
}

- (BOOL)allowEditing
{
	return NO;
}

- (BOOL)shouldConfirmResourceDeletion
{
	return NO;
}

- (NSString*)getResourceDeletePromptText:(OFResource*)resource
{
	return OFLOCALSTRING(@"Are you sure?");
}

- (NSString*)getResourceDeleteCancelText
{
	return OFLOCALSTRING(@"Cancel");
}

- (NSString*)getResourceDeleteConfirmText
{
	return OFLOCALSTRING(@"Confirm");
}

- (void)onResourceWasDeleted:(OFResource*)cellResource
{
}

#pragma mark Action Cells
//if you ever call toggleExpansionAtIndexPath: you must override these two calls
-(NSString*)actionCellClassName {
    ASSERT_OVERRIDE_MISSING;
    return nil;
}

- (void) actionPressedForTag:(NSUInteger) tag indexPath:(NSIndexPath*) indexPath {
    ASSERT_OVERRIDE_MISSING;
}


@end
