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

#import "OFFindUserController.h"
#import "OFUserService.h"
#import "OFUser.h"
#import "OFDefaultLeadingCell.h"
#import "OFProfileController.h"
#import "OFControllerLoaderObjC.h"
#import "UIView+OpenFeint.h"
#import "OFDependencies.h"

@interface OFFindUserController ()
@property (nonatomic, retain) NSString* currentName;
@end


@implementation OFFindUserController
@synthesize currentName = mCurrentName;
- (void)populateResourceControllerMap:(NSMutableDictionary*)resourceMap
{
	[resourceMap setObject:@"User" forKey:[OFUser class]];
}

- (OFService*)getService
{
	return [OFUserService sharedInstance];
}

- (void)doIndexActionWithPage:(NSUInteger)pageIndex onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[OFUserService findUsersByName:self.currentName pageIndex:pageIndex onSuccessInvocation:success onFailureInvocation:failure];	
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
{
	[OFUserService findUsersByName:self.currentName pageIndex:1 onSuccessInvocation:success onFailureInvocation:failure];	
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"No user with that name was found.");
}

- (NSString*)getDataNotLoadedYetMessage
{
	return OFLOCALSTRING(@"Search for friends by their Feint name.");
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFUser class]])
	{
		OFUser* userResource = (OFUser*)cellResource;
		[OFProfileController showProfileForUser:userResource];
	}
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
	
}

- (BOOL)autoLoadData
{
	return NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self showLoadingScreen];
	[self.view resignFirstResponderRecursive];			
	self.currentName = searchBar.text;
	[self reloadDataFromServer];
}

- (NSString*)getTableHeaderControllerName
{
	return @"FindUserHeader";
}

- (void)dealloc
{
    self.currentName = nil;
	[super dealloc];
}

@end

