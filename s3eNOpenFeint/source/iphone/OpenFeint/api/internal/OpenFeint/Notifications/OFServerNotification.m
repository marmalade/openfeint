//
//  OFServerNotification.mm
//  OpenFeint
//
//  Created by Ron Midthun on 3/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OFResourceField.h"
#import "OFServerNotification.h"
#import "OFDependencies.h"

@implementation OFServerNotification

@synthesize text, detail, backgroundDefaultImage, backgroundImage;
@synthesize iconDefaultImage, iconImage, statusDefaultImage, statusImage;
@synthesize score, inputTab, inputControllerName, showDefaultNotification;

#define makeSetter(ivarName, setterName) -(void) setterName:(NSString*) _text {\
OFSafeRelease(ivarName);\
ivarName = [_text retain];\
}


makeSetter(text, setText);
makeSetter(detail, setDetail);
makeSetter(backgroundDefaultImage, setBackgroundDefaultImage);
makeSetter(backgroundImage, setBackgroundImage);
makeSetter(iconDefaultImage, setIconDefaultImage);
makeSetter(iconImage, setIconImage);
makeSetter(statusDefaultImage, setStatusDefaultImage);
makeSetter(statusImage, setStatusImage);
makeSetter(inputTab, setInputTab);
makeSetter(inputControllerName, setInputControllerName);
makeSetter(showDefaultNotification, setShowDefaultNotification);
makeSetter(score, setScore);


+ (NSString*)getResourceName
{
	return @"server_notification";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_server_notification_received";
}

-(void)dealloc 
{
	OFSafeRelease(showDefaultNotification);
    OFSafeRelease(text);
    OFSafeRelease(detail);
    OFSafeRelease(backgroundDefaultImage);
    OFSafeRelease(backgroundImage);
    OFSafeRelease(iconDefaultImage);
    OFSafeRelease(iconImage);
    OFSafeRelease(statusDefaultImage);
    OFSafeRelease(statusImage);
	OFSafeRelease(inputTab);
	OFSafeRelease(inputControllerName);
	OFSafeRelease(score);
    [super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setShowDefaultNotification:)], @"showDefaultNotification",
[OFResourceField fieldSetter:@selector(setText:)], @"text",
[OFResourceField fieldSetter:@selector(setDetail:)], @"detail",
[OFResourceField fieldSetter:@selector(setBackgroundDefaultImage:)], @"backDefaultImage",
[OFResourceField fieldSetter:@selector(setBackgroundImage:)], @"backImage",
[OFResourceField fieldSetter:@selector(setIconDefaultImage:)], @"iconDefaultImage",
[OFResourceField fieldSetter:@selector(setIconImage:)], @"iconImage",
[OFResourceField fieldSetter:@selector(setStatusDefaultImage:)], @"statusDefaultImage",
[OFResourceField fieldSetter:@selector(setStatusImage:)], @"statusImage",
[OFResourceField fieldSetter:@selector(setScore:)], @"score",
[OFResourceField fieldSetter:@selector(setInputTab:)], @"inputTab",
[OFResourceField fieldSetter:@selector(setInputControllerName:)], @"inputControllerName",
        nil] retain];
    }
    return sDataDictionary;
}
@end
