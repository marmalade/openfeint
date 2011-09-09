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

#import "OFDependencies.h"
#import "OFTableSequenceControllerHelper+ViewDelegate.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFTableSectionDescription.h"
#import "OFControllerLoader.h"
#import "OFViewHelper.h"
#import "OFResourceViewHelper.h"
#import "OFResource.h"

@implementation OFTableSequenceControllerHelper (ViewDelegate)

//note: the row here is the data row, not the table indexrow
- (OFResource*) getResourceFromSection:(NSArray*)sectionCells atRow:(NSUInteger)row
{
	if([self hasStreamingSections])
	{
		const unsigned int baseRowIndex = [self _getLoadedBaseRowIndex];
		const unsigned int numItemsLoaded = [self _getNumItemsLoaded];
		
		if(!(row >= baseRowIndex && row < baseRowIndex + numItemsLoaded))
		{
			return nil;
		}
		
		row -= baseRowIndex;
	}	
    
	
	return (OFResource*)[sectionCells objectAtIndex:row];
}

//note: the row needed here is the data row, not the table indexrow
- (NSString*) getCellControllerNameFromSection:(NSArray*)sectionCells atRow:(NSUInteger)row
{
	OFResource* resource = [self getResourceFromSection:sectionCells atRow:row];

	if([self hasStreamingSections])
	{
		if(resource == nil)
		{
			return [self getCellControllerNameForStreamingCells];
		}
	}

	return mResourceMap->getControllerName([resource class]);
}

- (NSIndexPath*)getFirstIndexPathForResource:(OFResource*)resource
{
	for (unsigned int sectionIndex = 0; sectionIndex < [mSections count]; sectionIndex++)
	{
		OFTableSectionDescription* curSection = [mSections objectAtIndex:sectionIndex];
		for (unsigned int cellIndex = 0; cellIndex < [curSection.page count]; cellIndex++)
		{
			OFResource* curResource = [curSection.page objectAtIndex:cellIndex];
			if ([curResource.resourceId isEqualToString:resource.resourceId])
			{
				NSIndexPath* indexPath = [NSIndexPath indexPathWithIndex:sectionIndex];
				if (curSection.leadingCellName)
				{
					cellIndex++;
				}
				indexPath = [indexPath indexPathByAddingIndex:cellIndex];
				return indexPath;
			}
		}
	}
	return nil;
}

- (OFResource*)getResourceAtIndexPath:(NSIndexPath*)indexPath
{
	if ([indexPath indexAtPosition:0] >= [mSections count])
	{
		return nil;
	}
	OFTableSectionDescription* curSection = [mSections objectAtIndex:[indexPath indexAtPosition:0]];
    NSUInteger resourceIndex, cellType;
    [curSection gatherDataForRow:[indexPath indexAtPosition:1] dataRow:resourceIndex cellType:cellType];
	return [curSection.page objectAtIndex:resourceIndex];
}

- (UIView*)getHeaderForSection:(NSInteger)section
{
	OFTableSectionDescription* tableDescription = (OFTableSectionDescription*)[mSections objectAtIndex:section];
	return tableDescription.headerView;
}

- (UIView*)getFooterForSection:(NSInteger)section
{
	OFTableSectionDescription* tableDescription = (OFTableSectionDescription*)[mSections objectAtIndex:section];
	return tableDescription.footerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	OFTableSectionDescription* tableDescription = (OFTableSectionDescription*)[mSections objectAtIndex:section];
	if (tableDescription.headerView == nil && tableView.style == UITableViewStylePlain && [self usePlainTableSectionHeaders])
	{
		tableDescription.headerView = [self createPlainTableSectionHeader:section];
	}
	return tableDescription.headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	return [self getFooterForSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	UIView* header = [self getHeaderForSection:section];
	if (header)
	{
		return header.frame.size.height;
	}
	else
	{

		if (tableView.style == UITableViewStylePlain && ![self usePlainTableSectionHeaders])
		{
			return 0.f;
		}
		else
		{
			OFTableSectionDescription* tableDescription = (OFTableSectionDescription*)[mSections objectAtIndex:section];
			return tableDescription.title ? 38.f : 0.f;
		}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	UIView* footer = [self getFooterForSection:section];
	return footer ? footer.frame.size.height : 0.f;
}

@end
