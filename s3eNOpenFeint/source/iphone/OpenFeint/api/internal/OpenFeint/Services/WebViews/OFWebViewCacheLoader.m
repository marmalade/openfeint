////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2010 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/mount.h>

#import "OFWebViewCacheLoader.h"
#import "OFWebViewManifestData.h"
#import "OFSettings.h"
#import "OFFSLowLevel.h"
#import "OpenFeintSettings.h"
#import "OpenFeint+Private.h"
#import "OFWebUIController.h"
#import "OFWebViewManifestService.h"
#import "OFRunLoopThread.h"
#import "IPhoneOSIntrospection.h"
#import "OFASIFormDataRequest.h"
#import "OFZipArchive.h"
#import "NSDateFormatter+OpenFeint.h"
#import "UIScreen+OpenFeint.h"
#import "OFDependencies.h"

NSOperationQueue* webManifestQueue = nil;

@interface OFManifestOperation : NSOperation {
@private
    NSInvocation* invocation;
    BOOL executing;
    BOOL finished;
}
+ (OFManifestOperation*)operationWithTarget:(NSObject*)target selector:(SEL)sel object:(id)obj;
- (id)initWithInvocation:(NSInvocation*)_invocation;
@end

@interface OFWebViewLoaderHelper : NSObject {
@private
    OFWebViewCacheLoader *loader;    
    NSUInteger httpStatus;
    NSMutableData* httpData;
    NSString* path;
}

-(id)initWithPath:(NSString*) url loader:(OFWebViewCacheLoader*) loader;
@property (nonatomic, retain) OFWebViewCacheLoader *loader;
@property (nonatomic) NSUInteger httpStatus;
@property (nonatomic, retain) NSMutableData* httpData;
@property (nonatomic, retain) NSString* path;
@end

@interface OFWebViewZipLoaderHelper : NSObject {
@private
    OFASIFormDataRequest *request;
    OFWebViewCacheLoader *loader;
    NSString *path;
    NSString *localPath;
    BOOL returnValue;
}

@property (nonatomic, retain) OFASIFormDataRequest *request;
@property (nonatomic, retain) OFWebViewCacheLoader *loader;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *localPath;
@property (nonatomic) BOOL returnValue;

-(id)initWithPath:(NSString*) _path loader:(OFWebViewCacheLoader*) _loader;
-(BOOL)execute;
@end

@interface OFWebViewCacheLoader ()
-(void)copyDefaultManifest;
-(void)didSucceedDataForHelper:(OFWebViewLoaderHelper*)helper;
-(void)didFailDataForHelper:(OFWebViewLoaderHelper*)helper;
-(void)didSucceedDataForZipHelper:(OFWebViewZipLoaderHelper*)helper;
-(void)didFailDataForZipHelper:(OFWebViewZipLoaderHelper*)helper;
-(void)notifyAllTrackedPathsReady;
-(void)loadNextItem;
-(void)_getServerManifest;
-(void)startFetchNextItem;
-(void)updateFromServer;

@property (nonatomic, retain, readwrite) NSString* rootPath;   
@property (nonatomic, retain, readwrite) NSString* modifiedDate;
@property (nonatomic, retain) OFWebViewManifestData* serverManifest;
@property (nonatomic, retain) NSMutableDictionary* localManifest;
@property (nonatomic, retain) NSString* manifestApplication;

@property (nonatomic, retain) NSMutableSet* pathsToLoad;
@property (nonatomic, retain) NSMutableDictionary* tracked;
@property (nonatomic, retain) NSMutableSet* globals;
@property (nonatomic, retain) NSMutableSet* priority;
@property (nonatomic) unsigned int maxHelperCount;
@property (nonatomic, retain) NSMutableSet* helpers;
@property (nonatomic, retain) NSMutableSet* pathsRetrieving;

@property (nonatomic) BOOL abortedByReset;
@property (nonatomic, retain) NSMutableDictionary* observers;
@property (nonatomic) BOOL defaultCopied;
@property (nonatomic, retain) NSLock *trackingLock;
@property (nonatomic) BOOL thrifty;
@end

@implementation OFManifestOperation

+ (OFManifestOperation*)operationWithTarget:(NSObject*)target selector:(SEL)sel object:(id)obj {
    NSMethodSignature* sig = [target methodSignatureForSelector:sel];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = target;
    invocation.selector = sel;
    [invocation retainArguments];
    return [[[OFManifestOperation alloc] initWithInvocation:invocation] autorelease];
}

- (id)initWithInvocation:(NSInvocation*)_invocation {
    if ((self = [super init])) {
        invocation = [_invocation retain];
        executing = NO;
        finished = NO;
    }
    
    return self;
}

- (void)dealloc {
    [invocation release];
    [super dealloc];
}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    executing=YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self main];
}

- (void)main {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    [invocation invoke];
    
    [self willChangeValueForKey:@"isFinished"];
    finished=YES;
    [self didChangeValueForKey:@"isFinished"];
    
    [pool drain];
}

- (BOOL)isConcurrent {
    return NO;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

@end

@implementation OFWebViewLoaderHelper 

@synthesize loader, httpStatus, httpData, path;

-(id)initWithPath:(NSString*) _path loader:(OFWebViewCacheLoader*) _loader{
    if((self = [super init])) {
        self.path = _path;
        self.loader = _loader;
        NSString* url = [NSString stringWithFormat:@"%@webui/%@", [[OFSettings instance] getSetting:@"server-url"], _path];
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
        NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
        if(connection) {
            self.httpData = [NSMutableData data];
            self.httpStatus = 0;
            //            OFLog(@"WebView Cache loading %@", _path);
        }
        else {
            OFLog(@"WebView Cache: Failed to create connection for %@", path);
            [self.loader didFailDataForHelper:self];
        }
    }
    return self;
}

-(void) dealloc {
    self.loader = nil;
    self.httpData = nil;
    [super dealloc];
}
#pragma mark NSUrlConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    
    // receivedData is an instance variable declared elsewhere.
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    self.httpStatus = httpResponse.statusCode;
    [self.httpData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)_data
{
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [self.httpData appendData:_data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{    
    // inform the user
	NSString* failingURL = @"(unknown URL)";
	if (is4PointOhSystemVersion())
	{
		failingURL = [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey];
	}
    NSLog(@"WebView Cache Load Connection failed! Error - %@ %@",
          [error localizedDescription], failingURL);
    [self.loader didFailDataForHelper:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //    NSLog(@"WebView Cache Load Succeeded! Status %d Received %d bytes of data", self.httpStatus, [self.httpData length]);    
    //any kind of response is considered success for this purpose
    [self.loader didSucceedDataForHelper:self];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

@end

@implementation OFWebViewZipLoaderHelper
@synthesize request, loader, path, localPath, returnValue;

-(id)initWithPath:(NSString*) _path loader:(OFWebViewCacheLoader*) _loader {
    if ( (self = [super init]) ) {
        self.returnValue = FALSE;
        self.localPath = nil;
        self.path = _path;
        self.loader = _loader;
        
        self.request = [OFASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@webui/%@", [[OFSettings instance] getSetting:@"server-url"], _path]]];
        self.request.requestMethod = @"POST";
        [self.request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded; charset=UTF-8"];
        for (NSString* item in self.loader.pathsToLoad) {
            [self.request addPostValue:item forKey:@"files[][path]"];
            [self.request addPostValue:[[self.loader.serverManifest.objects objectForKey:item]serverHash] forKey:@"files[][hash]"];
        }
        //self.request.delegate = self;
        [self.request addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
        self.request.postFormat = ASIURLEncodedPostFormat;
        NSString *tempDir = NSTemporaryDirectory();
        self.localPath = [NSString stringWithFormat:@"%@/%@", tempDir, @"WebUIUpdate.zip"];
        self.request.downloadDestinationPath = self.localPath;
        self.returnValue = FALSE;
    }

    return self;
}

-(void)dealloc {
    self.localPath = nil;
    self.path = nil;
    self.loader = nil;
    self.request = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    OFASIHTTPRequest* requestObject = object;
    OFAssert(requestObject == self.request, @"OFWebViewZipLoaderHelper request does not match observed request: %@, %@", __FILE__, __LINE__);
    if (requestObject.isFinished) {
        if (requestObject.error == nil) {
            [self.loader didSucceedDataForZipHelper:self];
            self.returnValue = TRUE;
            OFLog(@"OFWebViewZipLoaderHelper Finished Request: %@\n%@", self.request.url, self.request);
        } else {
            [self.loader didFailDataForZipHelper:self];
            self.returnValue = FALSE;
            OFLog(@"OFWebViewZipLoaderHelper Failed Request: %@\n%@ with error: %@", self.request.url, self.request, requestObject.error);
        }
    }
}

-(BOOL)execute {
    OFLog(@"OFWebViewZipLoaderHelper Starting Request: %@\n%@", self.request.url, self.request);
    [self.request buildPostBody];
    self.request.numberOfTimesToRetryOnTimeout = 3;
    self.request.timeOutSeconds = 2.0f;
    [self.request startSynchronous];
    return self.returnValue;
}

@end

@implementation OFWebViewCacheLoader

@synthesize delegate, rootPath;
@synthesize modifiedDate;
@synthesize pathsToLoad, tracked, globals, priority;
@synthesize maxHelperCount, helpers, pathsRetrieving;
@synthesize serverManifest, localManifest, manifestApplication;
@synthesize abortedByReset, observers, defaultCopied, trackingLock;
@synthesize thrifty;

#pragma mark Public interface

+ (NSString*)dpiName {
	if ([UIScreen mainScreen].safeScale != 1.0) {
		return @"udpi";
	} else {
        return @"mdpi";
    }
}

-(id)initForApplication:(NSString*) _manifestApplication {
    if((self = [super init])) {
        self.manifestApplication = _manifestApplication;
        self.observers = [NSMutableDictionary dictionaryWithCapacity:5];
        self.trackingLock = [[NSLock new] autorelease];
        self.tracked = [NSMutableDictionary dictionaryWithCapacity:5];
        self.priority = [NSMutableSet setWithCapacity:10];
        self.maxHelperCount = 4;
        self.helpers = [NSMutableSet setWithCapacity:self.maxHelperCount];
        self.pathsRetrieving = [NSMutableSet setWithCapacity:self.maxHelperCount];
        self.rootPath = [OFSettings savePathForFile:@"webui"];
        self.modifiedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"webUIManifestModifiedDate"];
        self.thrifty = [[[OFSettings instance] getSetting:OpenFeintSettingThriftyWebUIMemoryUsage] boolValue];

        if (nil == webManifestQueue) {
            webManifestQueue = [[NSOperationQueue alloc] init];
            [webManifestQueue setMaxConcurrentOperationCount:1];
            [webManifestQueue setSuspended:FALSE];
        }
        
        OFManifestOperation* copyDefaultManifestOp = [OFManifestOperation operationWithTarget:self selector:@selector(copyDefaultManifest) object:nil];
        [webManifestQueue addOperation:copyDefaultManifestOp];
    }
    return self;
}

-(void) dealloc {
    [webManifestQueue release];
    self.manifestApplication = nil;
    self.observers = nil;
    self.trackingLock = nil;
    self.rootPath = nil;
    self.modifiedDate = nil;
    self.localManifest = nil;
    self.serverManifest = nil;
    self.pathsToLoad = nil;
    self.tracked = nil;
    self.priority = nil;
    self.globals = nil;
    [super dealloc];
}

-(BOOL)trackPath:(NSString*)path forMe:(id<OFWebViewManifestDelegate>)caller {
    [self.trackingLock lock];
    BOOL needsTracking = ![self isPathLoaded:path];
    
    if(needsTracking) {
		NSMutableSet* existingCallers = (NSMutableSet*)[self.tracked objectForKey:path];
		if (existingCallers)
		{
			[existingCallers addObject:caller];
		}
		else
		{
			[self.tracked setObject:[NSMutableSet setWithObject:caller] forKey:path];
		}

        [self prioritizePath:path];
    }
    else {
        [(NSObject*)caller performSelectorOnMainThread:@selector(webViewCacheItemReady:) withObject:path waitUntilDone:NO];            
    }
    [self.trackingLock unlock];
    return needsTracking;
}

-(void)prioritizePath:(NSString*)path {
    NSMutableSet *priorityAdds = [[NSMutableSet alloc] initWithObjects:path, nil];
    if(self.pathsToLoad) {
        OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:path];
        [priorityAdds unionSet:item.dependentObjects];
        [priorityAdds intersectSet:self.pathsToLoad];
    }
    [self.priority unionSet:priorityAdds];
    [priorityAdds release];
}

-(BOOL)isPathLoaded:(NSString*)path {
    if(self.pathsToLoad) {
        if(self.globals.count) return NO;
        if([self.pathsToLoad containsObject:path]) return NO;
        OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:path];

        [item.dependentObjects intersectSet:self.pathsToLoad];
        return item.dependentObjects.count == 0;
        
    }
    else {
        return NO;
    }
}

-(BOOL)isPathValid:(NSString*)path {
    if(self.pathsToLoad) {
        return [self isPathLoaded:path];
    }
    else {        
        return YES;  //the cache isn't yet ready, this is potentially a race condition, but it shouldn't cause issues
    }
}

-(void)enable {
}

-(void)disable {
}

-(void)resetToSeed {
    self.abortedByReset = YES;
    self.pathsToLoad = [NSMutableSet set];
    NSString* manifestPath = [self.rootPath stringByAppendingPathComponent:@"manifest.plist"];
    [[NSFileManager defaultManager] removeItemAtPath:manifestPath error:nil];
    [self copyDefaultManifest];
    
    //can't call loaderIsFinished if there's still stuff waiting on that thread
    if([self.observers count] == 0) {
        [self loadNextItem];
    }
    //else the observer callback will take care of calling the finish
}

#pragma mark Private Methods (background thread)
-(void)copyDefaultManifest {
    [self.trackingLock lock];
    NSString* manifestPath = [self.rootPath stringByAppendingPathComponent:@"manifest.plist"];
    NSMutableSet* existingDirs = [NSMutableSet setWithCapacity:10];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    
    [existingDirs addObjectsFromArray:(posixCreatePathWithBasePath(self.rootPath, [self.rootPath stringByDeletingLastPathComponent]))];

    if(![fileMgr fileExistsAtPath:manifestPath]) {
        // Look in the main bundle first, then fall back to the SDK bundle
        NSString* openFeintResourceBundleLocation = [[NSBundle mainBundle] bundlePath];
        NSString* bundlePath = [openFeintResourceBundleLocation stringByAppendingPathComponent:@"webui.bundle"];
        
        if (![fileMgr fileExistsAtPath:bundlePath]) {
            openFeintResourceBundleLocation = [[OpenFeint getResourceBundle] bundlePath];
            bundlePath = [openFeintResourceBundleLocation stringByAppendingPathComponent:@"webui.bundle"];
        }
        
        self.localManifest = [NSMutableDictionary dictionaryWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"manifest.plist"]];
        NSMutableArray* documentsToSkip = [NSMutableArray arrayWithCapacity:10];
        NSString* skipType = ([[OFWebViewCacheLoader dpiName] isEqualToString:@"mdpi"])?@"udpi":@"mdpi";
        
        struct stat dirStat;
        stat([bundlePath UTF8String], &dirStat);
        
        struct statfs fsStat;
        statfs([self.rootPath UTF8String], &fsStat);
        
        size_t blocks = (dirStat.st_size / fsStat.f_iosize) + 1;
        size_t mapSize = blocks * fsStat.f_iosize;      
        
        void* mapAddress = nil;
        if (!self.thrifty) mapAddress = memoryMapDirectoryRW(self.rootPath, mapSize);
        
        size_t buffSize = fsStat.f_iosize;
        void* copyBuff = malloc(buffSize);
        int error = 0;
        
        NSArray *allDocs = [(self.localManifest) allKeys];
        
        for (NSString* document in allDocs) {
            if ([document rangeOfString:skipType].length > 0) {
                [documentsToSkip addObject:document];
                continue;
            } else {
                // Create the destination path to the document
                NSString* source = [bundlePath stringByAppendingPathComponent:document];
                NSString* destination = [rootPath stringByAppendingPathComponent:document];
                NSString* destDir = [destination stringByDeletingLastPathComponent];
                
                if (![existingDirs containsObject:destDir]) {
                    [existingDirs addObjectsFromArray:posixCreatePathWithBasePath(destDir, self.rootPath)];
                }
                
                // Copy the file
                error = posixCopyFile(source, destination, copyBuff, buffSize);
                if (error) break;
            }
        }
        
        free(copyBuff);
        
        [self.localManifest removeObjectsForKeys:documentsToSkip];
        [self.localManifest writeToFile:[rootPath stringByAppendingPathComponent:@"manifest.plist"] atomically:TRUE];
        if (!self.thrifty) mapAddress = unmapMemorySync(mapAddress, mapSize);

        OFLog(@"WebView Cache loaded default bundle");    
    }
    
    self.defaultCopied = YES;
    [self.trackingLock unlock];
}

-(void) getServerManifest {
    OFManifestOperation* getServerManifestOp = [OFManifestOperation operationWithTarget:self selector:@selector(_getServerManifest) object:nil];
    [webManifestQueue addOperation:getServerManifestOp];
}

-(void)_notifyItemReady:(NSString*)trackedPath
{
	NSMutableSet* callers = (NSMutableSet*)[self.tracked objectForKey:trackedPath];
	for (id caller in callers)
	{
		[caller performSelectorOnMainThread:@selector(webViewCacheItemReady:) withObject:trackedPath waitUntilDone:NO];
	}
}							 

-(void)_getServerManifest {
	
	//do nothing for now, we don't need a manifest for the base sdk
//	if(!(self.manifestApplication))
//	{
//		return;
//	}
//	NSString* applicationName = self.manifestApplication;
	
	//Use this later when the base SDK needs a manifest
    NSString* applicationName = @"gamefeed";
    if(self.manifestApplication) {
        applicationName = self.manifestApplication;
    }
	
    
    NSString *url = [NSString stringWithFormat:@"%@webui/manifest/ios.%@.%@", [[OFSettings instance] getSetting:@"server-url"], applicationName, [self.class dpiName]];
    //we load this async, thereby blocking the other performSelectors
#ifdef _DEBUG
    //when debugging, the manifest is built on the fly, which takes a long time
    const float timeOut = 100.0f;
#else
    const float timeOut = 10.f;
#endif
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:timeOut];
    [req setValue:self.modifiedDate forHTTPHeaderField:@"If-Modified-Since"];

    NSHTTPURLResponse* response;
    NSError* error = nil;
    NSData* manifestData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    if( error || response.statusCode < 200 || response.statusCode > 299 ) {
        //send ready to everything in the tracked list
        OFManifestOperation* notifyOp = [OFManifestOperation operationWithTarget:self selector:@selector(notifyAllTrackedPathsReady) object:nil];
        [webManifestQueue addOperation:notifyOp];
        self.pathsToLoad = [NSMutableSet set];  //this signals that the server manifest was loaded for purposes of tracking
        OFLog(@"OFWebViewCacheLoader web ui up to date");
    } else {
        //build itemsToLoad, strip deps
        //for everything in priority, add deps, screen by itemsToLoad
        //perform loadNextItem
        NSDictionary *responseHeaders = [response allHeaderFields];
        self.modifiedDate = [responseHeaders objectForKey:@"Last-Modified"];
        
        [self.trackingLock lock];
        self.serverManifest = [[OFWebViewManifestData new] autorelease];
        [self.serverManifest populateWithData:manifestData];        
        self.localManifest = [NSMutableDictionary dictionaryWithContentsOfFile:[self.rootPath stringByAppendingPathComponent:@"manifest.plist"]];
        if(!self.localManifest) self.localManifest = [NSMutableDictionary dictionaryWithCapacity:10];

        //build list of items to load
        NSMutableSet *priorityAdds = [[NSMutableSet alloc] initWithCapacity:10];

        self.pathsToLoad = [NSMutableSet setWithCapacity:10];
        for (OFWebViewManifestItem* item in [self.serverManifest.objects allValues]) {
            if (![item.serverHash isEqualToString:[self.localManifest objectForKey:item.path]]) {
                [self.pathsToLoad addObject:item.path];
                [priorityAdds unionSet:item.dependentObjects];
            }
        }        
        
        //filter the serverManifest dependencies down to these items
        [priorityAdds intersectSet:self.pathsToLoad];

        //find globals
        self.globals = [NSMutableSet setWithSet:self.serverManifest.globalObjects];
        [self.globals intersectSet:self.pathsToLoad];
        
        //maybe nuke items that don't need loading? (not in ITL and deps = empty set)//!no dependency
        //since the serverManifest is never iterated, this is likely of no use
        [self.priority unionSet:priorityAdds];
        [priorityAdds release];
        
        [self.trackingLock unlock];
        
        OFManifestOperation* updateFromServerOp = [OFManifestOperation operationWithTarget:self selector:@selector(updateFromServer) object:nil];
        [webManifestQueue addOperation:updateFromServerOp];
    }
}
        
-(void) writeManifest {
    [self.trackingLock lock];
    NSString* manifestPath = [self.rootPath stringByAppendingPathComponent:@"manifest.plist"];
    [self.localManifest writeToFile:manifestPath atomically:YES];
    [[NSUserDefaults standardUserDefaults] setObject:self.modifiedDate forKey:@"webUIManifestModifiedDate"];   
    [self.trackingLock unlock];
}

-(void) finishItem:(NSString*) path success:(BOOL) loadingSuccess {
#ifdef _DEBUG    
    OFLog(@"Finishing up %@ (success:%@)", path, loadingSuccess ? @"YES" : @"NO");
#endif    
    //update client manifest
    OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:path];
    NSString* objectHash = loadingSuccess ? item.serverHash : @"FAILED" ;  //if if failed to load, put bogus hash so it will try again next time
    [self.localManifest setObject:objectHash forKey:path];
    [self.pathsToLoad removeObject:path];
    [self.observers removeObjectForKey:path];
}
    
-(void)finishCurrentItem:(OFWebViewLoaderHelper*) helper success:(BOOL) loadingSuccess {
    [self.helpers removeObject:helper];
    [self.pathsRetrieving removeObject:helper.path];
    [self finishItem:helper.path success:loadingSuccess];
    [self performSelector:@selector(loadNextItem) withObject:nil afterDelay:0];
}

-(void)didSucceedDataForHelper:(OFWebViewLoaderHelper*)helper{
    if(self.abortedByReset) {
        return;
    }
    
    if(helper.httpStatus == 200) {
        NSString* location = [self.rootPath stringByAppendingPathComponent:helper.path];
        //now need to clip last item from path, so I can get the directory path
        //wrteToFile doesn't have a "make dir" option
        NSString* lastPiece = [location lastPathComponent];
        NSString* locationDirectory = [location substringToIndex:[location length] - [lastPiece length] - 1];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:locationDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        [helper.httpData writeToFile:location atomically:YES];        
    }
    [self finishCurrentItem:helper success:YES];
}

-(void)didFailDataForHelper:(OFWebViewLoaderHelper*)helper{
    if(self.abortedByReset) {
        return;
    }
    
    [self finishItem:helper.path success:NO];
}

-(BOOL)writeZipUpdate {
    OFLog(@"OFWebViewCacheLoader Unzipping WebUI update");
    NSString* zipPath = [self.rootPath stringByAppendingPathComponent:@".update.zip"];
    OFZipArchive *zip = [[OFZipArchive alloc] init];
    BOOL updated = NO;
    
    if (nil != zip) {
        if ([zip UnzipOpenFile:zipPath]) {
            if ([zip UnzipFileTo:self.rootPath overWrite:TRUE]) {
                updated = YES;
            }
            [zip UnzipCloseFile];
        }
        
        [zip release];
    }
    
    if (!updated) {
        return NO;
    }
	
    OFLog(@"OFWebViewCacheLoader Updating manifest file");
    
    NSString *path = nil;

    [self.trackingLock lock];
    while ((path = [self.pathsToLoad anyObject])) {
        [self finishItem:path success:TRUE];
    }
    
    self.pathsToLoad = [NSMutableSet set];
    self.globals = [NSMutableSet set];
    [self.trackingLock unlock];

    OFLog(@"OFWebViewCacheLoader Removing temporary download files");
    [[NSFileManager defaultManager] removeItemAtPath:zipPath error:NULL];
    
    return YES;
}

-(void)didSucceedDataForZipHelper:(OFWebViewZipLoaderHelper*)helper{
    OFLog(@"OFWebViewCacheLoader Unzipping WebUI update");
    OFZipArchive *zip = [[OFZipArchive alloc] init];
    BOOL updated = NO;
    
    if (nil != zip) {
        if ([zip UnzipOpenFile:helper.localPath]) {
            if ([zip UnzipFileTo:self.rootPath overWrite:TRUE]) {
                updated = YES;
            }
        }
        
        [zip release];
    }
    
    if (!updated) {
        [self didFailDataForZipHelper:helper];
        return;
    }
	
    OFLog(@"OFWebViewCacheLoader Updating manifest file");
    
    NSString *path = nil;
    
    [self.trackingLock lock];
    while ((path = [self.pathsToLoad anyObject])) {
        [self finishItem:path success:TRUE];
    }
    
    self.pathsToLoad = [NSMutableSet set];
    self.globals = [NSMutableSet set];
    [self.trackingLock unlock];
    
    OFLog(@"OFWebViewCacheLoader Removing temporary download files");
    [[NSFileManager defaultManager] removeItemAtPath:helper.localPath error:NULL];
    
    return;
}

-(void)didFailDataForZipHelper:(OFWebViewZipLoaderHelper*)helper{
    OFLog(@"Removing temporary download files");
    [[NSFileManager defaultManager] removeItemAtPath:helper.localPath error:NULL];
    OFLog(@"Zip download failed. Performing individual file downloads");        
    helper.returnValue = FALSE;
}

-(void)notifyAllTrackedPathsReady {
    NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
    
    [self.trackingLock lock];
    for(NSString* trackedPath in [self.tracked allKeys]) {
        [self _notifyItemReady:trackedPath];
    }
    self.tracked = [NSMutableDictionary dictionaryWithCapacity:5];
    [self.trackingLock unlock];
    
    [currentRunLoop run];
    
    return;
}

-(void)updateTrackedPaths {
	NSMutableSet* pathsToClear = nil;
	
    //scan each tracked to see if it is finished
    [self.globals intersectSet:self.pathsToLoad];
    if(self.globals.count == 0) {
        for(NSString* trackedPath in [self.tracked allKeys]) {
            BOOL loading = NO;
            if([self.pathsToLoad containsObject:trackedPath]) {
                loading = YES;
            }
            else {
                OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:trackedPath];
                NSMutableSet* testSet = [NSMutableSet setWithSet:item.dependentObjects];
                [testSet intersectSet:self.pathsToLoad];
                if(testSet.count) loading = YES;
            }
            if(!loading) {
				[self _notifyItemReady:trackedPath];
				
				// don't mutate a hash while iterating over it
				if (!pathsToClear) pathsToClear = [NSMutableSet setWithCapacity:1];
				[pathsToClear addObject:trackedPath];
            }
        }
    }
	
	if (pathsToClear)
	{
		for (NSString* path in pathsToClear)
		{
			[self.tracked removeObjectForKey:path];
		}
	}
}

-(void)loadNextItem {
    if(self.abortedByReset) {
        return;
    }
	
	[self updateTrackedPaths];
	
    //are we done done?
    if(!self.pathsToLoad.count) {
        [self writeManifest];
    } else {
        [self startFetchNextItem];
    }
}

-(void)startFetchNextItem {
    while ([self.helpers count] < self.maxHelperCount) {
        //find next item to load
        [self.trackingLock lock];

        [self.priority intersectSet:self.pathsToLoad];
        [self.globals intersectSet:self.pathsToLoad];

        NSString* nextItem = nil;
        for (NSSet* s in [NSArray arrayWithObjects:self.priority, self.globals, self.pathsToLoad, nil]) {
            for (NSString* path in s) {
                if(![self.pathsRetrieving containsObject:path]) {
                    nextItem = path;
                    break;
                }
            }
            if (nextItem) break;
        }
        [self.trackingLock unlock];
        
        if(nextItem == nil) {
            break;
        }
        
        //create the HTTP load helper
        OFWebViewLoaderHelper* helper = [[OFWebViewLoaderHelper alloc] initWithPath:nextItem loader:self];
        [self.observers setObject:helper forKey:nextItem];
        [helper autorelease];

        [self.helpers addObject:helper];
        [self.pathsRetrieving addObject:nextItem];
    }
}

-(void) updateFromServer {
    struct stat dirStat;
    stat([self.rootPath UTF8String], &dirStat);
    
    struct statfs fsStat;
    statfs([self.rootPath UTF8String], &fsStat);
    
    size_t blocks = (dirStat.st_size / fsStat.f_iosize) + 1;
    size_t mapSize = blocks * fsStat.f_iosize * 2;      
    
    void* mapAddress = nil;
    if (!self.thrifty) mapAddress = memoryMapDirectoryRW(self.rootPath, mapSize);

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@webui/%@", [[OFSettings instance] getSetting:@"server-url"], @"assets"]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    NSMutableData* formData = [NSMutableData dataWithLength:0];
    int count = [self.pathsToLoad count];
    int i = 0;
    for (NSString* item in self.pathsToLoad) {
        NSString* formString = [NSString stringWithFormat:@"files[][path]=%@&files[][hash]=%@%@", item, [[self.serverManifest.objects objectForKey:item]serverHash], ++i < count ? @"&": @""];
        NSString* encodedString = [formString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [formData appendData:[encodedString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [request setHTTPBody:formData];
    NSURLResponse* response = nil;
    NSError* error = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (!error) {
        [[NSFileManager defaultManager] createFileAtPath:[self.rootPath stringByAppendingPathComponent:@".update.zip"] contents:responseData attributes:nil];
    }
    
    if (!error && [self writeZipUpdate]) {
        OFManifestOperation* updateTrackedPathsOp = [OFManifestOperation operationWithTarget:self selector:@selector(notifyAllTrackedPathsReady) object:nil];
        [webManifestQueue addOperation:updateTrackedPathsOp];
        if (!self.thrifty) mapAddress = unmapMemorySync(mapAddress, mapSize);
    } else {
        if (!self.thrifty) mapAddress = unmapMemoryDrop(mapAddress, mapSize);
        [self loadNextItem];
        while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                        beforeDate:[NSDate distantFuture]]) { }
    }
        
    OFManifestOperation* writeManifestOp = [OFManifestOperation operationWithTarget:self selector:@selector(writeManifest) object:nil];
    [webManifestQueue addOperation:writeManifestOp];
}
@end
