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
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OFHttpService.h"
#import "OFProvider.h"
#import "OFUser.h"


#pragma mark OFBlobDownloadObserver


class OFBlobDownloadObserver : public OFHttpServiceObserver
{
public:
	OFBlobDownloadObserver(OFDelegate const& onSuccess, OFDelegate const& onFailure, bool returnS3Response = false);
	
	void onFinishedDownloading(OFHttpServiceRequestContainer* info);
	void onFailedDownloading(OFHttpServiceRequestContainer* info);
	
private:
	OFDelegate mSuccessDelegate;
	OFDelegate mFailedDelegate;
	bool mReturnS3Response;
	void invokeFailure(OFHttpServiceRequestContainer* info);
};
