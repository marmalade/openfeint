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

#import "OFSendSocialNotificationController.h"
#import "OFSendSocialNotificationCell.h"
#import "OFControllerLoaderObjC.h"
#import "OFImageLoader.h"
#import "OFTableSectionDescription.h"
#import "OFUsersCredentialService.h"
#import "OFUsersCredential.h"
#import "OFFacebookAccountLoginController.h"
#import "OFTwitterAccountLoginController.h"
#import "OFSendSocialNotificationSubmitTextCell.h"
#import "OFSocialNotification.h"
#import "OFSocialNotificationService+Private.h"
#import "OpenFeint+Private.h"
#import "OFTableCellBackgroundView.h"
#import "OFTableControllerHelper+Overridables.h"

#import "UIView+OpenFeint.h"
#import "NSString+OpenFeint.h"
#import "OFXmlElement.h"
#import "OFSocialNotificationApi.h"
#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthURLResponse.h"
#import "OFActionRequest.h"
#import "OFExtendedCredentialController.h"
#import "OFDependencies.h"

static BOOL dismissDashboardWhenSent;

@interface OFSendSocialNotificationController (Private)
- (void)_sendSuccess;
- (void)_sendFailure:(MPOAuthAPIRequestLoader*)request;

- (void)_extendedCredentialsSuccess;
- (void)_extendedCredentialsFailure;
- (void)_extendedCredentialsCancel;
- (void)_clearNeedingExtendedCredentials;
- (void)_launchFacebookLoginFlow;
- (void)_launchTwitterLoginFlow;

-(BOOL) _getNextCredential; //Returns if we are DONE getting credentials
@end

@implementation OFSendSocialNotificationController

@synthesize submitTextCell, notification, currentExtendedCredentialsController;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if(self.isViewLoaded)
	{
        OFTableSectionDescription* tableDesc = [mSections objectAtIndex:0];
        NSMutableArray* cells = tableDesc.staticCells;
        
        // NOTE: onlyCheckNetwork is NONE on initialization unless overridden by calling class
		// NOTE: onlyCheckNetwork is set to INVALILD after our first _onDataLoaded
        if (onlyCheckNetwork != ESocialNetworkCellType_INVALID)
        {
            for(int i = 0; i < ESocialNetworkCellType_COUNT; i++)
            {
                //Default should be "send to all", so all checked.
                if (onlyCheckNetwork == ESocialNetworkCellType_NONE)
                {
                    initChecked[i] = YES;
                }
                
                // If onlyCheckNetwork is set to a network, only check that one
                else
                {
                    initChecked[i] = (i == onlyCheckNetwork);
                }
            }
        }
        
        // Refresh, so save whether or not the cell is checked so we can restore the checked state after the refresh
        else
        {
		for(uint i = 0; i < [cells count]; i++)
		{
			OFTableCellHelper* cellHelper = [cells objectAtIndex:i];
			if([cellHelper isKindOfClass:[OFSendSocialNotificationCell class]])
			{
				OFSendSocialNotificationCell* cell = (OFSendSocialNotificationCell*)cellHelper;
				initChecked[cell.networkType] = cell.checked;
			}
		}
        }
		
		//We can't be sure if the user connected to facebook or twitter while we were away from this screen.  Lets just refresh the whole thing, its fast.
		[self _refreshData];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	dismissDashboardWhenSent = NO;
    onlyCheckNetwork = ESocialNetworkCellType_NONE; // Setting this to the NONE means check ALL
	
	UIBarButtonItem* right = [[[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(send)] autorelease];
	self.navigationItem.rightBarButtonItem = right;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	self.submitTextCell = (OFSendSocialNotificationSubmitTextCell*)[[OFControllerLoaderObjC loader] loadCell:@"SendSocialNotificationSubmitText"];// loadCell(@"SendSocialNotificationSubmitText");

	UIImage* bgImage = [OFImageLoader loadImage:@"OFLeadingCellBackground.png"];
	
	OFTableCellBackgroundView* backgroundView = nil;
	OFTableCellBackgroundView* selectedBackgroundView = nil;
	self.submitTextCell.backgroundView = backgroundView = [OFTableCellBackgroundView defaultBackgroundView];
	self.submitTextCell.selectedBackgroundView = selectedBackgroundView = [OFTableCellBackgroundView defaultBackgroundView];
	backgroundView.image = bgImage;
	selectedBackgroundView.image = bgImage;
	
	submitTextCell.sendSocialNotificationController = self;
}

- (void)send
{
    // If the send button is disabled, then we cant send right now.  So only dismiss the keyboard.
    if (!self.navigationItem.rightBarButtonItem.enabled)
    {
        [submitTextCell resignFirstResponder];
        return;
    }
    
	//Disable send button so we can't send twice.
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	//the notification has hopefully been created by this time, but incase it has not.
	NSString* sendMessage = [NSString stringWithFormat:@"%@  %@", self.submitTextCell.prePopulatedText.text, self.submitTextCell.message.text];
	if(!self.notification)
	{
		self.notification = [[[OFSocialNotification alloc] initWithText:sendMessage] autorelease];
	}
	else
	{
		//We're about to fill this out, so clear it.
		[self.notification clearSendToNetworks];
		
		self.notification.text = sendMessage;
	}
	
	//Add appropirate networks to send to.
	OFTableSectionDescription* tableDesc = [mSections objectAtIndex:0];
	NSMutableArray* cells = tableDesc.staticCells;
	for(uint i = 0; i < [cells count]; i++)
	{
		OFTableCellHelper* cellHelper = [cells objectAtIndex:i];
		if([cellHelper isKindOfClass:[OFSendSocialNotificationCell class]])
		{
			OFSendSocialNotificationCell* cell = (OFSendSocialNotificationCell*)cellHelper;
			if(cell.checked && cell.connectedToNetwork)
			{
				[self.notification addSendToNetwork:cell.networkType];
			}
		}
	}
	
	//Trigger the send to the server. 
	[OFSocialNotificationService sendSocialNotification:self.notification 
                                              onSuccess:[OFInvocation invocationForTarget:self selector:@selector(_sendSuccess)]
                                              onFailure:[OFInvocation invocationForTarget:self selector:@selector(_sendFailure:)]];
//											  onSuccess:OFDelegate(self, @selector(_sendSuccess)) 
//											  onFailure:OFDelegate(self, @selector(_sendFailure:))];
}

// Activate the send button only if one or more networks are checked.
-(void)activateSendButton
{
    BOOL shouldBeTappable = NO;
    
    OFTableSectionDescription* tableDesc = [mSections objectAtIndex:0];
	NSMutableArray* cells = tableDesc.staticCells;
    for(uint i = 0; i < [cells count]; i++)
    {
        OFTableCellHelper* cellHelper = [cells objectAtIndex:i];
        OFSendSocialNotificationCell *notificationCell = (OFSendSocialNotificationCell*)cellHelper;
		if([notificationCell isKindOfClass:[OFSendSocialNotificationCell class]] && notificationCell.checked && notificationCell.connectedToNetwork)
        {
            shouldBeTappable = YES;
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = shouldBeTappable;
}

- (void)doIndexActionOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
{
	OFSafeRelease(mSections);
	
	//Reload table after this is done.
	[OFUsersCredentialService getIndexOnSuccessInvocation:success onFailureInvocation:failure onlyIncludeLinkedCredentials:YES];
}

- (void) createCell:(NSMutableArray*)cellArray withType:(ESocialNetworkCellType)eSocialNetworkType andConnectToNetworkText:(NSString*)connectToNeworkText andPostToNetworkText:(NSString*)postToNetworkText andConnectToNetworkImageName:(NSString*)connetToNetworkImageName andConnectedToNeworkIconName:(NSString*)connectedToNetworkIconName andConnectedToNetwork:(BOOL)connectedToNetwork
{
	OFSendSocialNotificationCell* curCell = (OFSendSocialNotificationCell*)[[OFControllerLoaderObjC loader] loadCell:@"SendSocialNotification"];// loadCell(@"SendSocialNotification");
	curCell.connectToNeworkLabel.text = connectToNeworkText;
	curCell.postToNetworkLabel.text = postToNetworkText;
	
	curCell.connectToNetworkImage.image = connetToNetworkImageName ? [OFImageLoader loadImage:connetToNetworkImageName] : nil;
	curCell.connectedNetworkIcon.image = connectedToNetworkIconName ? [OFImageLoader loadImage:connectedToNetworkIconName] : nil;
	curCell.checked = initChecked[eSocialNetworkType];

    curCell.networkType = eSocialNetworkType;

	curCell.connectedToNetwork = connectedToNetwork;
	
	[cellArray addObject:curCell];
}

- (void)_onDataLoaded:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental
{
	//Figure out what networks we are connected too.
	NSMutableArray* credentials = [[(OFTableSectionDescription*)[[resources objects] objectAtIndex:0] page] objects];
	BOOL connectedToNetwork[ESocialNetworkCellType_COUNT];
	BOOL connectedToAny = NO;
	for(uint i = 0; i < ESocialNetworkCellType_COUNT; i++)
	{
		connectedToNetwork[i] = NO;
	}
	
	for (OFUsersCredential* credential in credentials)
	{
		if ([credential isTwitter])
		{
			connectedToNetwork[ESocialNetworkCellType_TWITTER] = YES;
			connectedToAny = YES;
		}
		else if([credential isFacebook])
		{
			connectedToNetwork[ESocialNetworkCellType_FACEBOOK] = YES;
			connectedToAny = YES;
		}
	}
	
	NSMutableArray* staticCells = [NSMutableArray arrayWithCapacity:3];
	
	//Fill out the first cell appropriately.
	if(connectedToAny)
	{
		[staticCells addObject:self.submitTextCell];
	}
	else
	{
		self.navigationItem.rightBarButtonItem.enabled = NO;
		[staticCells addObject:[[OFControllerLoaderObjC loader] loadCell:@"NotConnectedToSocialNetwork"]];
	}
	

	
	//Create the next (n) cells for social networks.
	[self createCell:staticCells withType:ESocialNetworkCellType_TWITTER andConnectToNetworkText:@"Connect to Twitter" andPostToNetworkText:@"Post to Twitter" andConnectToNetworkImageName:@"OFConnectToTwitter.png" andConnectedToNeworkIconName:@"OFConnectedToTwitter.png" andConnectedToNetwork:connectedToNetwork[ESocialNetworkCellType_TWITTER]];
	[self createCell:staticCells withType:ESocialNetworkCellType_FACEBOOK andConnectToNetworkText:@"Connect to Facebook" andPostToNetworkText:@"Post to Facebook" andConnectToNetworkImageName:@"OFConnectToFacebook.png" andConnectedToNeworkIconName:@"OFConnectedToFacebook.png" andConnectedToNetwork:connectedToNetwork[ESocialNetworkCellType_FACEBOOK]];
	
	mSections = [[NSMutableArray arrayWithObject:[OFTableSectionDescription sectionWithTitle:@"" andStaticCells:staticCells]] retain];
	
	[self _reloadTableData];
    
    [self activateSendButton];
	
	//At this point, we've loaded our data cells.  If the caller wanted us to only check one network, and we are not logged 
	//into that network, then we should launch the login flow for that network immediately.  Note that we immediately set
	//onlyCheckNetwork to INVALID below us so we'll never try to do this more than the first time this data is loaded.
	if((onlyCheckNetwork == ESocialNetworkCellType_FACEBOOK) && !connectedToNetwork[ESocialNetworkCellType_FACEBOOK])
	{
		[self _launchFacebookLoginFlow];
	}
	else if((onlyCheckNetwork == ESocialNetworkCellType_TWITTER) && !connectedToNetwork[ESocialNetworkCellType_TWITTER])
	{
		[self _launchTwitterLoginFlow];
	}
	
	//We've used this all we need to on our first load, set it to invalid so we don't use it on subsiquent viewWillAppear calls and _onDataLoaded calls.
	onlyCheckNetwork = ESocialNetworkCellType_INVALID;
}

- (void)configureCell:(OFTableCellHelper*)_cell asLeading:(BOOL)_isLeading asTrailing:(BOOL)_isTrailing asOdd:(BOOL)_isOdd
{
	//The submitTextCell has already been configured (background/backgroundSelected) in viewDidLoad.
	if(_cell != self.submitTextCell)
	{
		[super configureCell:_cell asLeading:_isLeading asTrailing:_isTrailing asOdd:_isOdd];
	}
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if([mSections count] <= 0)
	{
		return;
	
	}
	NSMutableArray* staticCells = [[mSections objectAtIndex:0] staticCells];
	if(indexPath.row >= [staticCells count])
	{
		return;
	}

	OFTableCellHelper* cellHelper = [staticCells objectAtIndex:indexPath.row];
	if([cellHelper isKindOfClass:[OFSendSocialNotificationCell class]])
	{
		OFSendSocialNotificationCell* cell = (OFSendSocialNotificationCell*)cellHelper;
		if(cell.connectedToNetwork) //Cell is connected
		{
			//Logged in, check or uncheck the network.
			cell.checked = !cell.checked;
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
		else //cell's network is not connected.
		{
			//Not logged in, try to login to network.
			if(cell.networkType == ESocialNetworkCellType_FACEBOOK)
			{
				[self _launchFacebookLoginFlow];
			}
			else if(cell.networkType == ESocialNetworkCellType_TWITTER)
			{
				[self _launchTwitterLoginFlow];
			}
		}
	}
    
    [self activateSendButton];
}

-(void)setPrepopulatedText:(NSString*)prepopulatedText andOriginalMessage:(NSString*)message
{
	//Max out the prepopuated text
	NSString* prepopulatedTextToSet = @"";
	if(prepopulatedText)
	{
		prepopulatedTextToSet = [NSString stringWithString:prepopulatedText];
		if(prepopulatedText.length > SocialNotification_MAX_PREPOPULATED_CHARACTERS)
		{
			prepopulatedTextToSet = [prepopulatedText substringToIndex:SocialNotification_MAX_PREPOPULATED_CHARACTERS];
		}
		self.submitTextCell.prePopulatedText.text = prepopulatedTextToSet;
        UIFont* labelFont = [prepopulatedTextToSet getFontToFitSize:self.submitTextCell.prePopulatedText.frame.size font:self.submitTextCell.prePopulatedText.font 
                                                                max:self.submitTextCell.prePopulatedText.font.pointSize min:self.submitTextCell.prePopulatedText.minimumFontSize];
		self.submitTextCell.prePopulatedText.font = labelFont;
		
	}
	self.submitTextCell.maxMessageCharacters = SocialNotification_MAX_TOTAL_CHARACTERS 
												- SocialNotification_MAX_LINK_CHARACTERS 
												- [prepopulatedTextToSet length];

	//max out the message length.
	if(message)
	{
		NSString* messageToSet = [NSString stringWithString:message];
		if(message.length > self.submitTextCell.maxMessageCharacters)
		{
			messageToSet = [message substringToIndex:self.submitTextCell.maxMessageCharacters];
		}
		self.submitTextCell.message.text = messageToSet;
	}
}

-(void)setImageUrl:(NSString*)iconUrl defaultImage:(NSString*)defaultImage;
{
	if(self.notification)
	{
		self.notification.imageUrl = iconUrl;
		if(defaultImage)
		{
			[submitTextCell setDefaultImageName:defaultImage];
		}
		
		if(iconUrl)
		{
			[submitTextCell setIconUrl:iconUrl];
		}
	}
	else
	{
		OFLog(@"Warning: call setImageUrl after setImageName:linkedUrl or setImageType:imageId:linkedUrl: on OFSendSocialNotificationController");
	}

}

-(void)setImageName:(NSString*)imageName linkedUrl:(NSString*)url
{
	self.notification = [[[OFSocialNotification alloc] initWithText:@"" imageNamed:imageName linkedUrl:url] autorelease];
	[submitTextCell setSocialNotificationImageName:imageName];
}

-(void)setImageType:(NSString*)imageType imageId:(NSString*)imageId linkedUrl:(NSString*)url
{
	self.notification = [[[OFSocialNotification alloc] initWithText:@"" imageType:imageType imageId:imageId linkedUrl:url] autorelease];
	//Don't know what to set for submit TextCell setDefaultImageName here....
}

-(void)setDismissDashboardWhenSent:(BOOL)_dismissDashboard
{
	dismissDashboardWhenSent = _dismissDashboard;
}

-(void)setUseNetwork:(ESocialNetworkCellType)type
{
    onlyCheckNetwork = type;
}

-(void)dismiss
{
	if(dismissDashboardWhenSent)
	{
		[OpenFeint dismissDashboard];
	}
	else if(self.navigationController)
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)_sendSuccess
{
	[OFSocialNotificationApi sendSuccess];
	[self dismiss];
}

- (void)_sendFailure:(MPOAuthAPIRequestLoader*)request
{
    OFXmlElement* errorDocument = [OFXmlElement elementWithData:request.data];
	
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)request.oauthResponse.urlResponse;
	if(httpResponse.statusCode == OpenFeintHttpStatusCodePermissionsRequired)
	{
        if ([errorDocument.name isEqualToString:@"errors"])
        {
            if ([[errorDocument getChildWithName:@"FbconnectCredential"].value isEqualToString:@"extended_credentials"])
            {
                needCredentialsForNetwork[ESocialNetworkCellType_FACEBOOK] = YES;
            }
            if ([[errorDocument getChildWithName:@"TwitterCredential"].value isEqualToString:@"extended_credentials"])
            {
                needCredentialsForNetwork[ESocialNetworkCellType_TWITTER] = YES;
            }
        }

#ifdef _DEBUG
		BOOL doneWithExtendedCredentials = [self _getNextCredential];
		OFAssert(!doneWithExtendedCredentials, @"The server has sent back a 430 response, but there are no additional credentials specified to get...");
#else
		[self _getNextCredential];
#endif


	}
    else
    {
        // This could happen when a developer's game hasn't yet been approved by us.
        if ([errorDocument.name isEqualToString:@"errors"])
        {
            OFXmlElement* element = [errorDocument getChildWithName:@"error"];
            if (element)
            {
                NSString* reason = [element.attributes objectForKey:@"reason"];
                if (reason)
                {
                    [[[[UIAlertView alloc] 
                        initWithTitle:nil
                        message:[NSString stringWithFormat:@"Social post failed: %@", reason] 
                        delegate:nil
                        cancelButtonTitle:@"Ok" 
                        otherButtonTitles:nil] autorelease] show];
                }
            }
        }
        
        [OFSocialNotificationApi sendFailure];
    }
}

- (BOOL)_getNextCredential
{
	//Find the next netowrk we need credentials for and initiate it.
	while(currentGettingCredentialForNetwork < ESocialNetworkCellType_COUNT &&
		  needCredentialsForNetwork[currentGettingCredentialForNetwork] == NO)
	{
		currentGettingCredentialForNetwork++;
	}
	
	switch(currentGettingCredentialForNetwork)
	{
		case ESocialNetworkCellType_FACEBOOK:
		{
			self.currentExtendedCredentialsController = (UIViewController< OFExtendedCredentialController >*)[[OFControllerLoaderObjC loader] load:@"FacebookExtendedCredential"];
		}
		break;
			
		case ESocialNetworkCellType_TWITTER:
		{
			self.currentExtendedCredentialsController = (UIViewController< OFExtendedCredentialController >*)[[OFControllerLoaderObjC loader] load:@"TwitterExtendedCredential" ];
		}
		break;
			
		case ESocialNetworkCellType_COUNT:
		{
			return YES;
		}
		break;
		
		default:
		{
			OFAssert(0, @"You have added a new social network, but have not handled how to get extended credentials from it");
			return YES;
		}
	};
	
	OFAssert(currentExtendedCredentialsController, @"Must have have a current Extended credential by this point");
	[currentExtendedCredentialsController retain];
    [currentExtendedCredentialsController getExtendedCredentials:[OFInvocation invocationForTarget:self selector:@selector(_extendedCredentialsSuccess)]
                                                       onFailure:[OFInvocation invocationForTarget:self selector:@selector(_extendedCredentialsFailure)]
                                                        onCancel:[OFInvocation invocationForTarget:self selector:@selector(_extendedCredentialsCancel)]];
	return NO;
}

- (void)_extendedCredentialsSuccess
{
	//On success, try to get the next credentials we need
	self.currentExtendedCredentialsController = nil;
	needCredentialsForNetwork[currentGettingCredentialForNetwork] = NO;
	if([self _getNextCredential])
	{
		//If we have gotten all credentials we need then send again.
		//Make the enable button active so the send call will work -__-
		self.navigationItem.rightBarButtonItem.enabled = YES;
		[self send];
	}
}

- (void)_extendedCredentialsFailure
{
	//On failure of one credential we'll cancel out getting the rest since we have some problem communicating witht he server (most likely).
	self.currentExtendedCredentialsController = nil;
	[self _clearNeedingExtendedCredentials];
	
	//We'll leave them on this controller with the option to try and send again (and get credentials again).
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)_extendedCredentialsCancel
{
	//They canceled one of the credentials, so we're canceling the whole send of the social notification.
	self.currentExtendedCredentialsController = nil;
	[self dismiss];
}
		
- (void)_clearNeedingExtendedCredentials
{
	for(int i = 0; i < ESocialNetworkCellType_COUNT; i++)
	{
		needCredentialsForNetwork[i] = NO;
	}
	currentGettingCredentialForNetwork = 0;
}

- (void)_launchFacebookLoginFlow
{
	OFFacebookAccountLoginController* controllerToPush =
	(OFFacebookAccountLoginController*)[[OFControllerLoaderObjC loader] load:@"FacebookAccountLogin"];
	
	[controllerToPush setAddingAdditionalCredential:YES];
	controllerToPush.controllerToPopTo = self;
	controllerToPush.getPostingPermission = YES;
	[self.navigationController pushViewController:controllerToPush animated:YES];
}

- (void)_launchTwitterLoginFlow
{
	OFTwitterAccountLoginController* controllerToPush =
	(OFTwitterAccountLoginController*)[[OFControllerLoaderObjC loader] load:@"TwitterAccountLogin"];
	
	[controllerToPush setAddingAdditionalCredential:YES];
	controllerToPush.controllerToPopTo = self;
	[self.navigationController pushViewController:controllerToPush animated:YES];
}

- (void)dealloc
{
	self.notification = nil;
	self.submitTextCell = nil;
	self.currentExtendedCredentialsController = nil;

	[super dealloc];
}

@end
