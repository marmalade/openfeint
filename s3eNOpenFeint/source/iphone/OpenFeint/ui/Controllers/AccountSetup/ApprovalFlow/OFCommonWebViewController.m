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

#import "OFCommonWebViewController.h"
#import "OpenFeint+Private.h"

@interface OFCommonWebViewController(Private)

-(void)onDone;

@end

@implementation OFCommonWebViewController

@synthesize webView = mWebView;
@synthesize navigationUrl;
@synthesize isDashbaordModal;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.webView = nil;
    self.navigationUrl = nil;

    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(onDone)];          
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

-(void)onDone
{
    if (self.isDashbaordModal) {
       [OpenFeint dismissRootControllerOrItsModal];
    }
    else
    {
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(void)loadUrl:(NSString*)url
{
    if (url) {
        [mWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        self.navigationUrl = url;
    }
}
@end
