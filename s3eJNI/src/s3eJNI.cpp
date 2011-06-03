/*
 * This file is part of the Airplay SDK Code Samples.
 *
 * Copyright (C) 2001-2010 Ideaworks3D Ltd.
 * All Rights Reserved.
 *
 * This source code is intended only as a supplement to Ideaworks Labs
 * Development Tools and/or on-line documentation.
 *
 * THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 */
 
/**
 * @page ExampleAndroidJNIFacebook Android JNI Facebook Example
 * The following example uses JNI to use the Android Facebook SDK example.
 *
 * The following functions are used to achieve this:
 * - s3eJNIGetVM()
 * 
 * This example uses the official facebook android API.  In order to built it
 * you'll need to download the latest version of the API from github using the
 * following command:
 * 
 * - git clone git://github.com/facebook/facebook-android-sdk.git
 * 
 * For more inforamation on the API see:
 * 
 * http://github.com/facebook/facebook-android-sdk
 * 
 * This example comes in two parts: that native part and the java part.  There is
 * one mkb file to build the jar file from the java source and another mkb to
 * build the airplay application that uses the jar file.
 *
 *
 */

 
#include "ExamplesMain.h"
#include "OpenFeint.h"
#include "JNIHelper.h"

#ifndef HAVE_INTTYPES_H
#define HAVE_INTTYPES_H
#endif

static Button* g_ButtonInit = 0;
static Button* g_ButtonDashboard = 0;
static Button* g_UnlockAchievement = 0;
static Button* g_ButtonHighScore = 0;
static Button* g_CheckLicense = 0;

static LicenseChecker* licenseChecker;

void ExampleInit()
{
	JNIHelper::startup();

	g_ButtonInit = NewButton("Init");
	g_ButtonDashboard = NewButton("Dashboard");
	g_UnlockAchievement = NewButton("Unlock achievement");
	g_ButtonHighScore = NewButton("Highscore");
	g_CheckLicense= NewButton("Check license");

	licenseChecker = new LicenseChecker(NULL); // your license listener here
}

void ExampleShutDown()
{
	JNIHelper::shutdown();
	delete licenseChecker;
}

bool ExampleUpdate()
{
	Button * pressed = GetSelectedButton();	

	licenseChecker->update();

	if (pressed == g_ButtonInit)
	{
		// you can use "Airplay Openfeint Test" test application, but you must provide your own app information in final build)
		OpenFeint::initialize("Airplay Openfeint Test", "KwmzGgaXtHUPEteVyD2fg", "nY7afo8J1meIn61dHKdJvp7dzOPm6AFWPAskJCBA0Ls", "195042", NULL); // specify your custom feint delegate
	}
	else if (pressed == g_ButtonDashboard)
	{
		OpenFeint::launchDashboard();
	}
	else if (pressed == g_UnlockAchievement)
	{
		// you can use for test 748742 and 748752 on "Airplay Openfeint Test" application
		OpenFeint::unlockAchievement("748812");
	}
	else if (pressed == g_ButtonHighScore)
	{
		OpenFeint::setHighScore(1777, "592184");
	}
	else if (pressed == g_CheckLicense)
	{
		licenseChecker->checkLicense("YOU PUBLIC KEY HERE");
	}

	return true;
}

void fillScreen(uint8 r, uint8 g, uint8 b)
{
	uint16* screen = (uint16*)s3eSurfacePtr();
	uint16 colour = (uint16)s3eSurfaceConvertRGB(r, g, b);
	int32 width = s3eSurfaceGetInt(S3E_SURFACE_WIDTH);
	int32 height = s3eSurfaceGetInt(S3E_SURFACE_HEIGHT);
	int32 pitch = s3eSurfaceGetInt(S3E_SURFACE_PITCH);

	int y;
	int x;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			screen[y * pitch / 2 + x] = colour;
		}
	}
}


void ExampleRender()
{
	fillScreen(255, 255, 0);
}

