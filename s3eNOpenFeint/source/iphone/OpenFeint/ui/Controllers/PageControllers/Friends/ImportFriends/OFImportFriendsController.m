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

#import "OFImportFriendsController.h"
#import "OFFriendImporter.h"

@interface OFImportFriendsController ()
@property(nonatomic, retain) OFFriendImporter* importer;
@end


@implementation OFImportFriendsController
@synthesize importer = mImporter;

- (IBAction)onImportFromTwitter
{
	[self.importer importFromTwitter];
}

- (IBAction)onImportFromFacebook
{
	[self.importer importFromFacebook];
}

- (IBAction)onFindByName
{
	[self.importer findByName];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self != nil)
	{
		self.importer = [OFFriendImporter friendImporterWithController:self];
	}
	
	return self;
}

- (void)dealloc
{
	[self.importer controllerDealloced];
	self.importer = NULL;
	[super dealloc];
}

- (void) setController:(UIViewController*)viewController
{
	self.importer->mController = viewController;
}

@end

